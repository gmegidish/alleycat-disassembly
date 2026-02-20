; --- read_rom_id ---
; Reads the BIOS ROM ID byte at F000:FFFE.
; Output: [rom_id] = ROM ID (0xFD = PCjr, 0xFF = PC/XT, 0xFE = XT)
read_rom_id:
    mov ax,0xf000
    mov es,ax
    db 0x26, 0xa0, 0xfe, 0xff           ; MOV AL,ES:[DAT_f000_fffe]
    mov [rom_id],al
    ret

; --- read_pit_timer ---
; Reads the current PIT channel 0 counter value.
; Output: AX = 16-bit PIT counter value (high byte read first, then low)
read_pit_timer:
    mov al,0x0
    out 0x43,al                         ; PIT: control word (latch counter 0)
    nop
    nop
    in al,0x40                          ; PIT Ch0: read counter value
    db 0x8a, 0xe0                       ; mov ah,al
    nop
    in al,0x40                          ; PIT Ch0: read counter value
    db 0x86, 0xc4                       ; xchg ah,al
    ret
    call read_pit_timer
    db 0x8b, 0xd8                       ; mov bx,ax
    db 0x2b, 0xc1                       ; sub ax,cx
    db 0x8b, 0xcb                       ; mov cx,bx
    db 0x3b, 0xc2                       ; cmp ax,dx
    jnb short lab_13d5
    ret
lab_13d5:
    db 0x3b, 0xd2                       ; cmp dx,dx
    ret

; --- check_vsync ---
; Checks if CGA vertical sync is active.
; Output: AL = 0x08 if in vsync, 0 otherwise (ZF set = not in vsync)
check_vsync:
    mov dx,0x3da
    in al,dx                            ; CGA: read status (bit3=vsync)
    and al,0x8
    ret
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00

; --- init_bios_data ---
; Initializes the keyboard state buffer and keyboard_prev counter.
; Fills 22 bytes at DS:0x6B7 with 0x80 (keyboard state), sets keyboard_prev.
init_bios_data:
    push ax
    push es
    push di
    push cx
    db 0xb8, 0x10, 0x00                 ; mov ax,0x1010
    mov es,ax
    cld
    mov di,0x6b7
    mov cx,0x16
    mov al,0x80
    rep stosb
    mov ax,[es:keyboard_counter]
    db 0x2d, 0x70, 0x00                 ; sub ax,0x70
    mov [es:keyboard_prev],ax
    mov ax,0x40
    mov es,ax
    mov al,[es:0x12]
    mov [cs:0x13e7],al
    pop cx
    pop di
    pop es
    pop ax
    ret

; --- install_handlers ---
; Saves original INT 9 (keyboard) and INT 48 vectors, then installs
; custom handlers. Uses PCjr-specific handler if rom_id == 0xFD.
install_handlers:
    db 0x2b, 0xc0                       ; sub ax,ax
    mov es,ax
    mov ax,[es:0x24]
    mov bx,word [es:0x26]
    mov cx,word [es:0x120]
    mov dx,word [es:0x122]
    mov [cs:0x13df],ax
    mov word [cs:0x13e1],bx
    mov word [cs:0x13e3],cx
    mov word [cs:0x13e5],dx
    mov bx,0x14b3
    cmp byte [rom_id],0xfd
    jnz lab_1450
    mov bx,0x14fb
lab_1450:
    cli
    mov word [es:0x24],bx
    mov word [es:0x26],cs
    cmp byte [rom_id],0xfd
    jnz lab_147d
    db 0x26  ; 1462
    db 0xc7  ; 1463
    db 0x06  ; 1464
    db 0x20  ; 1465
    db 0x01  ; 1466
    db 0x54  ; 1467
    db 0x15  ; 1468
    mov word [es:0x122],cs
    mov ax,0x40
    mov es,ax
    mov al,[es:0x18]
    or al,0x1
    mov [es:0x18],al
lab_147d:
    sti
    ret

; --- restore_handlers ---
restore_handlers:
    db 0x2b, 0xc0                       ; sub ax,ax
    mov es,ax
    mov ax,[cs:0x13df]
    mov bx,word [cs:0x13e1]
    mov cx,word [cs:0x13e3]
    mov dx,word [cs:0x13e5]
    cli
    mov [es:0x24],ax
    mov word [es:0x26],bx
    cmp byte [rom_id],0xfd
    jnz lab_14b1
    mov word [es:0x120],cx
    mov word [es:0x122],dx
lab_14b1:
    sti
    ret
    push ax
    push es
    push di
    push cx
    mov di,0x10
    mov es,di
    in al,byte 0x60
    db 0x8a, 0xe0                       ; mov ah,al
    and al,0x7f
    test ah,0x80
    jnz short lab_14cc
    inc word [es:0x693]
lab_14cc:
    mov di,0x6a1
    mov cx,0x16
    cld
    repne scasb
    jnz short lab_14e3
    sub di,0x6a2
    and ah,0x80
    mov [es:di+0x6b7],ah
lab_14e3:
    in al,byte 0x61
    db 0x8a, 0xe0                       ; mov ah,al
    or al,0x80
    out byte 0x61,al
    db 0x8a, 0xc4                       ; mov al,ah
    out byte 0x61,al
    call check_special_keys
    pop cx
    pop di
    pop es
    mov al,0x20
    out byte 0x20,al
    pop ax
    iret
    sti
    push ax
    push es
    push di
    push cx
    mov di,0x10
    mov es,di
    db 0x8a, 0xe0                       ; mov ah,al
    and al,0x7f
    test ah,0x80
    jnz short lab_1513
    inc word [es:0x693]
lab_1513:
    cmp ah,0xff
    jz short lab_1530
    cmp ah,0x55
    jz short lab_1530
    push es
    mov di,0x40
    mov es,di
    mov cl,[es:0x12]
    pop es
    cmp cl,[cs:0x13e7]
    jz short lab_1535
lab_1530:
    call init_bios_data
    jmp short lab_154c
lab_1535:
    mov di,0x6a1
    mov cx,0x16
    cld
    repne scasb
    jnz short lab_154c
    sub di,0x6a2
    and ah,0x80
    mov [es:di+0x6b7],ah
lab_154c:
    call check_special_keys
    pop cx
    pop di
    pop es
    pop ax
    iret
    int byte 0x9
    iret
lab_1557:
    mov ax,0xf000
    mov ss,ax
    mov ax,0x40
    mov ds,ax
    mov bx,0x72
    mov word [bx],0x1234
    mov ax,0x0
    mov es,ax
    jmp word 0xf000:word 0xe05b
check_special_keys:
    mov al,[es:0x6c9]
    or al,[es:0x6b7]
    cmp al,0x0
    jnz short lab_15c9
    test byte [es:0x6ca],0x80
    jnz short lab_158d
    mov al,0x20
    out byte 0x20,al
    jmp short lab_1557
lab_158d:
    test byte [es:0x6b9],0x80
    jnz short lab_15a4
    cmp byte [es:0x690],0x1
    jb short lab_15c9
    dec byte [es:0x690]
    jmp short lab_15b9
lab_15a4:
    test byte [es:0x6bb],0x80
    jnz short lab_15c9
    cmp byte [es:0x690],0x7
    jnb short lab_15c9
    inc byte [es:0x690]
lab_15b9:
    push dx
    mov al,0x2
    mov dx,0x3d4
    out dx,al
    mov al,[es:0x690]
    add al,0x27
    inc dx
    out dx,al
    pop dx
lab_15c9:
    ret
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00


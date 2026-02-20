; --- calc_cga_addr ---
calc_cga_addr:
    db 0x8a, 0xc2                       ; mov al,dl
    mov ah,0x28
    mul ah
    test dl,0x1
    jz lab_2cbe
    add ax,0x1fd8
lab_2cbe:
    db 0x8b, 0xd1                       ; mov dx,cx
    shr dx,0x1
    shr dx,0x1
    db 0x03, 0xc2                       ; add ax,dx
    and cl,0x3
    shl cl,0x1
    ret

; --- blit_transparent ---
blit_transparent:
    cld
    mov byte [blit_width],cl
    mov byte [blit_height],ch
    db 0x2a, 0xed                       ; sub ch,ch
    mov dx,0xff0
lab_2cda:
    mov cl,byte [blit_width]
lab_2cde:
    mov dx,0x30c0
    mov bx,word [es:di]
    mov word [ds:bp + 0x0],bx
    lodsw
    mov [blit_mask_tmp],ax
lab_2cec:
    test dl,ah
    jnz lab_2cf2
    db 0x0a, 0xe2                       ; or ah,dl
lab_2cf2:
    test dh,ah
    jnz lab_2cf8
    db 0x0a, 0xe6                       ; or ah,dh
lab_2cf8:
    test dl,al
    jnz lab_2cfe
    db 0x0a, 0xc2                       ; or al,dl
lab_2cfe:
    test dh,al
    jnz lab_2d04
    db 0x0a, 0xc6                       ; or al,dh
lab_2d04:
    xor dx,0x33cc
    test dh,0x3
    jnz lab_2cec
    db 0x23, 0xc3                       ; and ax,bx
    or ax,word [blit_mask_tmp]
    stosw
    add bp,0x2
    loop lab_2cde
    sub di,word [blit_width]
    sub di,word [blit_width]
    xor di,0x2000
    test di,0x2000
    jnz lab_2d2e
    add di,0x50
lab_2d2e:
    dec byte [blit_height]
    jnz lab_2cda
    ret

; --- blit_masked ---
blit_masked:
    cld
    mov byte [blit_width],cl
    mov byte [blit_height],ch
    db 0x2a, 0xed                       ; sub ch,ch
lab_2d40:
    mov cl,byte [blit_width]
lab_2d44:
    mov bx,word [es:di]
    mov word [ds:bp + 0x0],bx
    lodsw
    db 0x23, 0xc3                       ; and ax,bx
    stosw
    add bp,0x2
    loop lab_2d44
    sub di,word [blit_width]
    sub di,word [blit_width]
    xor di,0x2000
    test di,0x2000
    jnz lab_2d69
    add di,0x50
lab_2d69:
    dec byte [blit_height]
    jnz lab_2d40
    ret

; --- copy_with_stride ---
copy_with_stride:
    cld
    mov word [stride_src],si
    mov byte [blit_width],cl
    mov byte [blit_height],ch
    shl al,0x1
    mov [stride_step],al
    db 0x2a, 0xed                       ; sub ch,ch
lab_2d84:
    mov cl,byte [blit_width]
    rep movsw
    mov cl,byte [stride_step]
    add word [stride_src],cx
    mov si,word [stride_src]
    dec byte [blit_height]
    jnz lab_2d84
    ret

; --- blit_to_cga ---
blit_to_cga:
    cld
    mov byte [blit_width],cl
    mov byte [blit_height],ch
    db 0x2a, 0xed                       ; sub ch,ch
lab_2da8:
    mov cl,byte [blit_width]
    rep movsw
    sub di,word [blit_width]
    sub di,word [blit_width]
    xor di,0x2000
    test di,0x2000
    jnz lab_2dc3
    add di,0x50
lab_2dc3:
    dec byte [blit_height]
    jnz lab_2da8
    ret

; --- save_from_cga ---
save_from_cga:
    cld
    mov byte [es:blit_width],cl
    mov byte [es:blit_height],ch
    db 0x2a, 0xed                       ; sub ch,ch
lab_2dd7:
    mov cl,byte [es:blit_width]
    rep movsw
    sub si,word [es:blit_width]
    sub si,word [es:blit_width]
    xor si,0x2000
    test si,0x2000
    jnz lab_2df5
    add si,0x50
lab_2df5:
    dec byte [es:blit_height]
    jnz lab_2dd7
    ret

; --- random ---
; 16-bit LFSR pseudo-random number generator.
; Output: DX = pseudo-random 16-bit value
random:
    mov dx,word [rng_seed]
    db 0x32, 0xd6                       ; xor dl,dh
    shr dl,0x1
    shr dl,0x1
    rcr word [rng_seed],0x1
    mov dx,word [rng_seed]
    ret

; --- read_pit_counter ---
; Reads PIT counter 0 and stores it as the RNG seed.
; If the counter reads zero, uses 0xFA59 as a fallback seed.
; Output: [rng_seed] = RNG seed
read_pit_counter:
    mov al,0x0
    out 0x43,al                         ; PIT: control word (latch counter 0)
    nop
    nop
    in al,0x40                          ; PIT Ch0: read counter value
    db 0x8a, 0xe0                       ; mov ah,al
    nop
    in al,0x40                          ; PIT Ch0: read counter value
    db 0x3d, 0x00, 0x00                 ; cmp ax,0x0
    jnz lab_2e25
    mov ax,0xfa59
lab_2e25:
    mov [rng_seed],ax
    ret


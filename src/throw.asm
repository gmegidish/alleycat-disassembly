; --- update_thrown_objects ---
; Per-frame update for objects thrown from windows (shoes, boots, etc.).
; Moves active objects downward, checks collision with the cat, and
; sets [object_hit] if the cat is struck. Waits for vsync before drawing.
update_thrown_objects:
    dec byte [throw_timer]
    jz lab_04a7
lab_04a6:
    ret
lab_04a7:
    inc byte [throw_timer]
    call check_vsync                           ;undefined check_vsync()
    jnz lab_04a6
    cmp byte [transitioning],0x0
    jnz lab_04a6
    cmp byte [gravity_y],0x0
    jnz lab_04a6
    db 0x2a, 0xe4                       ; sub ah,ah
    int 0x1a                            ; BIOS Timer: Get tick count → CX:DX
    cmp dx,word [throw_last_tick]
    jz lab_04a6
    mov word [throw_last_tick],dx
    mov bx,word [difficulty_level]
    mov al,byte [bx + throw_delay]
    cmp byte [cat_y],0x60
    ja lab_04df
    shr al,0x1
    shr al,0x1
lab_04df:
    mov [throw_timer],al
    mov bx,word [current_floor]
    call check_throw_range                           ;undefined check_throw_range()
    jz lab_050c
    mov al,[window_column]
    add al,byte [bx + throw_col_step]
    cmp al,0x4
    jc lab_04a6
lab_04f6:
    call random                           ;undefined random()
    and dl,0x3
    cmp dl,byte [current_floor]
    jz lab_04f6
    cmp dl,0x3
    jz lab_04f6
    db 0x8a, 0xda                       ; mov bl,dl
    jmp short lab_0535
    db 0x90
lab_050c:
    mov al,byte [bx + throw_col_step]
    add byte [window_column],al
    cmp byte [window_column],0x4
    jc lab_0583
    call random                           ;undefined random()
    cmp dl,0x40
    ja lab_0539
lab_0523:
    call random                           ;undefined random()
    and dl,0x3
    cmp dl,0x3
    jz lab_0523
    db 0x8a, 0xda                       ; mov bl,dl
    call check_throw_range                           ;undefined check_throw_range()
    jnz lab_0523
lab_0535:
    mov word [current_floor],bx
lab_0539:
    mov al,byte [bx + throw_col_init]
    mov [window_column],al
    db 0xb8, 0x10, 0x00                 ; mov ax,0x1010
    mov es,ax
    mov di,throw_obj_buf
    mov ah,byte [bx + throw_y_param]
    mov bx,word [difficulty_level]
    mov bl,byte [bx + throw_chance]
    db 0x8a, 0xfc                       ; mov bh,ah
    call generate_throw_object                           ;undefined generate_throw_object()
    cmp word [current_floor],0x1
    jz lab_056e
    shr byte [throw_bits],0x1
    call rotate_throw_bits                           ;undefined rotate_throw_bits()
    shr byte [throw_bits],0x1
    jmp short lab_057c
    db 0x90
lab_056e:
    mov al,[throw_bits]
    shr al,0x1
    shr al,0x1
    call rotate_throw_bits                           ;undefined rotate_throw_bits()
    shr byte [throw_bits],0x1
lab_057c:
    call rotate_throw_bits                           ;undefined rotate_throw_bits()
    mov bx,word [current_floor]
lab_0583:
    cmp byte [in_throw_range],0x0
    jz lab_05d0
    mov ax,[cat_x]
    cmp bl,0x1
    jz lab_05bf
    inc word [cat_draw_pos]
    db 0x05, 0x04, 0x00                 ; add ax,0x4
    cmp ax,0x123
    jc lab_05cd
lab_059e:
    mov byte [transition_timer],0x11
    mov byte [in_level_mode],0x1
    mov byte [anim_counter],0x1
    mov byte [anim_step],0x18
    mov byte [scroll_speed],0x1
    mov byte [at_platform],0x0
    jmp short lab_05d0
    db 0x90
lab_05bf:
    dec word [cat_draw_pos]
    db 0x2d, 0x04, 0x00                 ; sub ax,0x4
    jc lab_059e
    db 0x3d, 0x08, 0x00                 ; cmp ax,0x8
    jc lab_059e
lab_05cd:
    mov [cat_x],ax
lab_05d0:
    push ds
    shl bx,0x1
    mov ax,word [bx + throw_draw_col]
    mov [throw_draw_tmp],ax
    mov si,word [bx + throw_scroll_src]
    mov ax,0xb800
    mov ds,ax
    mov es,ax
    db 0x8b, 0xfe                       ; mov di,si
    cmp bx,0x2
    jnz lab_05f1
    cld
    dec di
    jmp short lab_05f3
    db 0x90
lab_05f1:
    std
    inc di
lab_05f3:
    mov cx,0x27f
    push di
    push si
    rep movsb
    pop si
    pop di
    add si,0x2000
    add di,0x2000
    mov cx,0x280
    rep movsb
    pop ds
    mov di,word [throw_draw_tmp]
    mov bl,byte [window_column]
    db 0x2a, 0xff                       ; sub bh,bh
    add bx,throw_obj_buf
    mov cx,0x10
lab_061b:
    mov al,byte [bx]
    mov byte [es:di],al
    add bx,0x4
    xor di,0x2000
    test di,0x2000
    jnz lab_0630
    add di,0x50
lab_0630:
    loop lab_061b
    ret

; --- rotate_throw_bits ---
rotate_throw_bits:
    lahf
    mov bx,word [current_floor]
    mov bl,byte [bx + throw_rotate_dir]
    mov cx,0x5
    cmp bl,0x9
    jz lab_064e
lab_0644:
    sahf
    rcr byte [bx + throw_col_data],0x1
    lahf
    inc bx
    loop lab_0644
    ret
lab_064e:
    sahf
    rcl byte [bx + throw_col_data],0x1
    lahf
    dec bx
    loop lab_064e
    ret

; --- check_throw_range ---
check_throw_range:
    mov byte [in_throw_range],0x0
    mov al,[cat_y_bottom]
    cmp al,byte [bx + floor_y_top]
    jc lab_0679
    cmp al,byte [bx + floor_y_bottom]
    jnc lab_0679
    cmp byte [at_platform],0x1
    jnc lab_0674
    ret
lab_0674:
    mov byte [in_throw_range],0x1
lab_0679:
    db 0x3a, 0xc0                       ; cmp al,al
    ret
    db 0xc3

; --- generate_throw_object ---
generate_throw_object:
    mov byte [throw_bits],0x0
    cld
    mov cx,0x20
    mov ax,0xaaaa
    rep stosw
    sub di,0x40
    mov ax,0x4444
    mov word [es:di + 0x4],ax
    mov word [es:di + 0x6],ax
    call random                           ;undefined random()
    db 0x3a, 0xd3                       ; cmp dl,bl
    jc lab_06a4
    db 0x3a, 0xf7                       ; cmp dh,bh
    ja lab_06a5
lab_06a4:
    ret
lab_06a5:
    call random                           ;undefined random()
    cmp dl,0x18
    jc lab_06c7
    cmp dl,0x60
    jc lab_06d0
    push di
    call generate_throw_pattern                           ;undefined generate_throw_pattern()
    shl al,0x1
    mov [throw_bits],al
    pop di
    add di,0x2
    call generate_throw_pattern                           ;undefined generate_throw_pattern()
    or byte [throw_bits],al
    ret
lab_06c7:
    mov cx,0x20
    mov si,throw_sprite_large
    jmp short lab_06d6
    db 0x90
lab_06d0:
    mov cx,0x10
    mov si,throw_sprite_small
lab_06d6:
    rep movsw
    mov byte [throw_bits],0x3
    ret

; --- generate_throw_pattern ---
generate_throw_pattern:
    call random                           ;undefined random()
    db 0x81, 0xe2, 0x06, 0x00           ; and dx,0x6
    cmp dl,0x6
    jnz lab_06ed
    db 0x2a, 0xc0                       ; sub al,al
    ret
lab_06ed:
    db 0x8b, 0xda                       ; mov bx,dx
    mov si,word [bx + throw_pattern_ptrs]
    mov cx,0x8
lab_06f6:
    lodsw
    stosw
    add di,0x2
    loop lab_06f6
    mov al,0x1
    ret

; --- reset_window_state ---
reset_window_state:
    mov word [anim_last_tick],0x0
    mov word [pcjr_delay],0x0
    ret


; --- clear_screen ---
; Fills the CGA framebuffer (B800:0000, both banks) with color pattern 0xAA
; (CGA color 2 in all pixels), then draws the complete alley scene:
; background details, buildings, windows, and initializes alley objects.
; Called when transitioning to the alley from a level or on game start.
clear_screen:
    mov ax,0xb800
    mov es,ax
    cld
    db 0x2b, 0xff                       ; sub di,di
    mov ax,0xaaaa
    mov cx,0xfa0
    rep stosw
    mov di,0x2000
    mov cx,0xfa0
    rep stosw
    call draw_alley_details                           ;undefined draw_alley_details()
    mov bx,0x28a0
    db 0x2b, 0xc0                       ; sub ax,ax
    call draw_block_list                           ;undefined draw_block_list()
    call draw_difficulty_icon                           ;undefined draw_difficulty_icon()
    call draw_all_buildings                           ;undefined draw_all_buildings()
    call draw_all_windows                           ;undefined draw_all_windows()
    call init_alley_objects                           ;undefined init_alley_objects()
    ret

; --- draw_alley_scene ---
draw_alley_scene:
    mov ax,0xb800
    mov es,ax
    cld
    db 0x2b, 0xff                       ; sub di,di
    mov ax,0xaaaa
    mov cx,0xfa0
    rep stosw
    mov di,0x2000
    mov cx,0xfa0
    rep stosw
    call draw_alley_details                           ;undefined draw_alley_details()
    mov bx,0x28a0
    db 0x2b, 0xc0                       ; sub ax,ax
    call draw_block_list                           ;undefined draw_block_list()
    call draw_difficulty_icon                           ;undefined draw_difficulty_icon()
    mov ax,[difficulty_level]
    push ax
    mov word [difficulty_level],0x1
    call draw_all_buildings                           ;undefined draw_all_buildings()
    pop ax
    mov [difficulty_level],ax
    ret

; --- draw_difficulty_icon ---
draw_difficulty_icon:
    mov bx,word [diff_icon_idx]
    db 0x81, 0xe3, 0x03, 0x00           ; and bx,0x3
    shl bl,0x1
    mov si,word [bx + diff_icon_table]
    mov di,0x1902
    mov cx,0x801
    call blit_to_cga                           ;undefined blit_to_cga()
    ret

; --- init_alley_objects ---
init_alley_objects:
    mov bx,0xf
lab_2a83:
    mov byte [bx + alley_obj_state],0x0
    dec bx
    jnz lab_2a83
    mov di,0x140
    mov bh,0x80
    mov word [draw_row_offset],0x0
    call draw_object_row                           ;undefined draw_object_row()
    mov di,0x640
    mov bh,0x30
    mov word [draw_row_offset],0x5
    call draw_object_row                           ;undefined draw_object_row()
    mov di,0xb40
    mov bh,0x0
    mov word [draw_row_offset],0xa
    call draw_object_row                           ;undefined draw_object_row()
    mov byte [window_column],0x10
    mov word [current_floor],0x0
    mov byte [throw_timer],0x1
    ret

; --- draw_object_row ---
draw_object_row:
    mov byte [draw_row_param],bh
    mov byte [draw_loop_count],0x0
lab_2acf:
    push di
    push es
    mov bx,word [difficulty_level]
    mov bl,byte [bx + throw_chance]
    mov bh,byte [draw_row_param]
reloc_7:
    mov ax,DATA_SEG_PARA                ; relocated: ES = data segment
    mov es,ax
    mov di,throw_obj_buf
    call generate_throw_object                           ;undefined generate_throw_object()
    pop es
    pop di
    push di
    mov si,throw_obj_buf
    mov cx,0x1002
    call blit_to_cga                           ;undefined blit_to_cga()
    db 0x2a, 0xff                       ; sub bh,bh
    mov bl,byte [draw_loop_count]
    db 0x8a, 0xcb                       ; mov cl,bl
    shr bl,0x1
    shr bl,0x1
    not cl
    and cl,0x3
    shl cl,0x1
    mov al,[throw_bits]
    shl al,cl
    mov si,word [draw_row_offset]
    or byte [bx + si + throw_col_data],al
    pop di
    add di,0x4
    inc byte [draw_loop_count]
    cmp byte [draw_loop_count],0x14
    jc lab_2acf
    ret

; --- draw_block_list ---
draw_block_list:
    mov cx,word [bx]
    mov word [draw_block_dims],cx
    mov [draw_block_base],ax
    add bx,0x2
lab_2b30:
    mov si,word [bx]
    db 0x81, 0xfe, 0xff, 0xff           ; cmp si,0xffff
    jnz lab_2b39
    ret
lab_2b39:
    mov di,word [bx + 0x2]
    add di,word [draw_block_base]
    cld
    mov byte [draw_block_rows],ch
    db 0x2a, 0xed                       ; sub ch,ch
    mov word [draw_block_cols],cx
lab_2b4b:
    mov cx,word [draw_block_cols]
    rep movsb
    sub di,word [draw_block_cols]
    xor di,0x2000
    test di,0x2000
    jnz lab_2b62
    add di,0x50
lab_2b62:
    dec byte [draw_block_rows]
    jnz lab_2b4b
    add bx,0x4
    mov cx,word [draw_block_dims]
    jmp short lab_2b30

; --- draw_window_strip ---
draw_window_strip:
    mov byte [draw_loop_count],0x4
lab_2b76:
    mov si,0x2680
    mov cx,0x1005
    push di
    call blit_to_cga                           ;undefined blit_to_cga()
    pop di
    add di,0x14
    dec byte [draw_loop_count]
    jnz lab_2b76
    ret

; --- draw_all_windows ---
draw_all_windows:
    mov di,0x3c5
    call draw_window_strip                           ;undefined draw_window_strip()
    mov di,0x8c5
    call draw_window_strip                           ;undefined draw_window_strip()
    mov di,0xdc5
    call draw_window_strip                           ;undefined draw_window_strip()
    ret

; --- draw_alley_details ---
draw_alley_details:
    mov word [draw_pos_tmp],0x103e
lab_2ba4:
    add word [draw_pos_tmp],0x2
    mov di,word [draw_pos_tmp]
    cmp di,0x1090
    jnc lab_2bd2
lab_2bb3:
    call random                           ;undefined random()
    db 0x81, 0xe2, 0x30, 0x00           ; and dx,0x30
    cmp dl,byte [draw_loop_count]
    jz lab_2bb3
    mov byte [draw_loop_count],dl
    add dx,0x2904
    db 0x8b, 0xf2                       ; mov si,dx
    mov cx,0x801
    call blit_to_cga                           ;undefined blit_to_cga()
    jmp short lab_2ba4
lab_2bd2:
    mov di,0x1180
    mov ax,0x5655
    mov cx,0x500
    cld
    rep stosw
    mov di,0x3180
    mov cx,0x500
    rep stosw
    mov word [draw_pos_tmp],0x2944
lab_2bec:
    mov byte [draw_loop_count],0x9
lab_2bf1:
    call random                           ;undefined random()
    and dx,0x776
    add dx,0x12c0
    db 0x8b, 0xfa                       ; mov di,dx
    mov si,word [draw_pos_tmp]
    mov cx,0x501
    call blit_to_cga                           ;undefined blit_to_cga()
    dec byte [draw_loop_count]
    jnz lab_2bf1
    add word [draw_pos_tmp],0xa
    cmp word [draw_pos_tmp],0x296c
    jc lab_2bec
    mov byte [draw_loop_count],0x5
lab_2c20:
    call random                           ;undefined random()
    db 0x81, 0xe2, 0x3e, 0x00           ; and dx,0x3e
    add dx,0x3a98
    db 0x8b, 0xfa                       ; mov di,dx
    mov si,0x296c
    mov cx,0x501
    call blit_to_cga                           ;undefined blit_to_cga()
    dec byte [draw_loop_count]
    jnz lab_2c20
    ret

; --- draw_building ---
draw_building:
    mov word [draw_pos_tmp],di
    mov al,0x3
    cmp di,0x1720
    jc lab_2c4b
    dec al
lab_2c4b:
    mov [draw_loop_count],al
    add word [draw_pos_tmp],0x1e0
    mov si,0x2976
    mov cx,0xc05
    call blit_to_cga                           ;undefined blit_to_cga()
lab_2c5d:
    mov di,word [draw_pos_tmp]
    add word [draw_pos_tmp],0x140
    mov si,0x29ee
    mov cx,0x804
    call blit_to_cga                           ;undefined blit_to_cga()
    dec byte [draw_loop_count]
    jnz lab_2c5d
    mov di,word [draw_pos_tmp]
    mov si,0x2a2e
    mov cx,0xb04
    call blit_to_cga                           ;undefined blit_to_cga()
    ret

; --- draw_all_buildings ---
draw_all_buildings:
    mov bx,word [difficulty_level]
    mov bl,byte [bx + building_offsets]
lab_2c8c:
    mov word [draw_bx_save],bx
    mov di,word [bx + building_pos_table]
    cmp di,0x0
    jnz lab_2c9a
    ret
lab_2c9a:
    call draw_building                           ;undefined draw_building()
    mov bx,word [draw_bx_save]
    add bx,0x2
    jmp short lab_2c8c
    ret
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00


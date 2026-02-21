; --- update_viewport ---
update_viewport:
    mov cx,0xb03
    db 0x2a, 0xc8                       ; sub cl,al
    mov word [cat_sprite_dims],cx
    cmp ah,0xff
    jz lab_0fa6
    db 0x2a, 0xe4                       ; sub ah,ah
    shl al,0x1
    add word [cat_sprite_data],ax
    mov word [cat_x],0x0
    jmp short lab_0fb4
    db 0x90
lab_0fa6:
    db 0x2a, 0xe4                       ; sub ah,ah
    shl al,0x1
    shl al,0x1
    shl al,0x1
    add ax,0x128
    mov [cat_x],ax
lab_0fb4:
    push ds
    pop es
    mov si,word [cat_sprite_data]
    mov di,0xe
    mov al,0x3
    call copy_with_stride                           ;undefined copy_with_stride()
    mov word [cat_sprite_data],0xe
    ret

; --- update_scroll ---
update_scroll:
    mov word [scroll_left_bound],0x8
    mov word [scroll_right_bound],0x123
    cmp word [level_number],0x7
    jnz lab_0fe8
    mov word [scroll_left_bound],0x24
    mov word [scroll_right_bound],0x10f
lab_0fe8:
    mov ax,[cat_x]
    cmp byte [scroll_direction],0x1
    jc lab_101e
    jnz lab_1007
    add ax,word [scroll_speed]
    cmp ax,word [scroll_right_bound]
    jc lab_101b
    mov ax,[scroll_right_bound]
    dec ax
    mov [cat_x],ax
    stc
    ret
lab_1007:
    sub ax,word [scroll_speed]
    jc lab_1013
    cmp ax,word [scroll_left_bound]
    jnc lab_101b
lab_1013:
    mov ax,[scroll_left_bound]
    mov [cat_x],ax
    stc
    ret
lab_101b:
    mov [cat_x],ax
lab_101e:
    clc
    ret

; --- update_walk_frame ---
update_walk_frame:
    mov al,[scroll_direction]
    cmp al,byte [prev_scroll_dir]
    jz lab_102f
    mov word [scroll_speed],0x2
lab_102f:
    cmp word [scroll_speed],0x8
    jnc lab_1045
    dec byte [anim_accumulator]
    mov al,[anim_accumulator]
    and al,0x3
    jnz lab_1045
    inc word [scroll_speed]
lab_1045:
    mov bl,byte [walk_anim_frame]
    inc bl
    cmp bl,0x6
    jc lab_1052
    mov bl,0x0
lab_1052:
    mov byte [walk_anim_frame],bl
    cmp byte [scroll_direction],0xff
    jnz lab_1060
    add bl,0x6
lab_1060:
    shl bl,0x1
    db 0x2a, 0xff                       ; sub bh,bh
    mov bx,word [bx + walk_frame_table]
    ret

; --- spawn_window_event ---
spawn_window_event:
    mov word [scroll_speed],0x2
    mov byte [anim_accumulator],0x8
    cmp word [buffer_size],0xc02
    jnz lab_1087
    inc byte [window_event_count]
    test byte [window_event_count],0x7
    jnz lab_10dc
lab_1087:
    call restore_alley_buffer                           ;undefined restore_alley_buffer()
    call check_dog_collision                           ;undefined check_dog_collision()
    jc lab_10dc
    call check_enemy_activate                           ;undefined check_enemy_activate()
    jc lab_10dc
    call random                           ;undefined random()
    db 0x8a, 0xda                       ; mov bl,dl
    db 0x81, 0xe3, 0x0e, 0x00           ; and bx,0xe
    mov si,word [bx + window_sprite_top]
    mov ax,0xb800
    mov es,ax
    mov di,word [cat_draw_pos]
    mov bp,alley_save_buf
    mov word [buffer_size],0xc02
    mov cx,0x602
    call blit_masked                           ;undefined blit_masked()
    call random                           ;undefined random()
    db 0x8a, 0xda                       ; mov bl,dl
    db 0x81, 0xe3, 0x06, 0x00           ; and bx,0x6
    mov si,word [bx + window_sprite_bot]
    mov di,word [cat_draw_pos]
    add di,0xf0
    mov bp,0x612
    mov cx,0x602
    call blit_masked                           ;undefined blit_masked()
    mov byte [sprite_hidden],0x0
lab_10dc:
    ret

; --- enter_building ---
enter_building:
    mov byte [at_platform],0x0
    mov byte [in_level_mode],0x1
    mov byte [anim_counter],0x2
    mov byte [anim_step],0x1
    mov byte [anim_accumulator],0xff
    mov byte [scroll_direction],0x0
    mov byte [transitioning],0x1
    mov ax,[enter_sprite_data]
    mov [vert_sprite_data],ax
    mov ax,[enter_sprite_dims]
    mov [vert_sprite_dims],ax
    mov byte [game_mode],0x2
    ret
save_cat_background:
    mov cx,[cat_x]
    mov dl,[cat_y]
    call calc_cga_addr
    mov [cat_draw_pos],ax
    call save_alley_buffer
    ret

; --- save_alley_buffer ---
save_alley_buffer:
reloc_3:
    mov ax,DATA_SEG_PARA                ; relocated: ES = data segment
    mov es,ax
    mov di,alley_save_buf
    push ds
    mov si,word [cat_draw_pos]
    mov ax,0xb800
    mov ds,ax
    mov cx,word [es:buffer_size]
    call save_from_cga                           ;undefined save_from_cga()
    pop ds
    mov byte [sprite_hidden],0x0
    ret

; --- draw_alley_foreground ---
draw_alley_foreground:
    mov ax,0xb800
    mov es,ax
    mov di,word [cat_draw_pos]
    mov bp,alley_save_buf
    mov si,word [cat_sprite_data]
    mov cx,word [cat_sprite_dims]
    mov word [buffer_size],cx
    mov byte [sprite_hidden],0x0
    call blit_masked                           ;undefined blit_masked()
    ret

; --- handle_cat_death ---
handle_cat_death:
    mov dl,byte [cat_y]
    mov cx,word [cat_x]
    sub cx,0xc
    jnc lab_1175
    db 0x2b, 0xc9                       ; sub cx,cx
lab_1175:
    cmp cx,0x10f
    jc lab_117e
    mov cx,0x10e
lab_117e:
    call calc_cga_addr                           ;undefined calc_cga_addr()
    mov [death_draw_pos],ax
    db 0x8b, 0xf8                       ; mov di,ax
    mov ax,0xb800
    mov es,ax
    mov bp,0xe
    mov si,death_sprite
    mov cx,0x1205
    call blit_transparent                           ;undefined blit_transparent()
    db 0x2a, 0xe4                       ; sub ah,ah
    int 0x1a                            ; BIOS Timer: Get tick count → CX:DX
    mov word [anim_tick_delay],dx
    mov word [fall_sound_x],0x0
    mov word [fall_sound_y],0x0
lab_11ab:
    call play_falling_sound                           ;undefined play_falling_sound()
    db 0x2a, 0xe4                       ; sub ah,ah
    int 0x1a                            ; BIOS Timer: Get tick count → CX:DX
    sub dx,word [anim_tick_delay]
    cmp dx,0xa
    jc lab_11ab
    call silence_speaker                           ;undefined silence_speaker()
    mov di,word [death_draw_pos]
    mov si,0xe
    mov cx,0x1205
    mov byte [sprite_hidden],0x0
    call blit_to_cga                           ;undefined blit_to_cga()
    cmp byte [deduct_life],0x0
    jz lab_11e2
    cmp byte [lives_count],0x0
    jz lab_11e2
    dec byte [lives_count]
lab_11e2:
    ret

; --- restore_alley_buffer ---
restore_alley_buffer:
    mov ax,0xb800
    mov es,ax
    mov di,word [cat_draw_pos]
    mov si,alley_save_buf
    mov cx,word [buffer_size]
    call blit_to_cga                           ;undefined blit_to_cga()
    ret
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00


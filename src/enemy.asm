; --- decode_enemy_params ---
decode_enemy_params:
    db 0x2a, 0xff                       ; sub bh,bh
    db 0x8a, 0xda                       ; mov bl,dl
    and bl,0x3
    shl bl,0x1
    mov cx,word [bx + jump_spawn_x_table]
    db 0x8a, 0xda                       ; mov bl,dl
    shr bl,0x1
    shr bl,0x1
    and bl,0x3
    mov dl,byte [bx + jump_spawn_y_table]
    ret

; --- check_fish_collision ---
check_fish_collision:
    mov ax,[jump_x]
    mov dl,byte [jump_y]
    mov bx,word [cat_x]
    mov dh,byte [cat_y]
    mov si,0x20
    mov di,0x18
    mov cx,0xe0f
    call check_rect_collision                           ;undefined check_rect_collision()
    jnc lab_1b4b
    cmp byte [in_level_mode],0x1
    jnz lab_1b4a
    cmp byte [transitioning],0x0
    jnz lab_1b4a
    cmp byte [cat_y],0x60
    jnc lab_1b4a
    cmp byte [jump_anim_counter],0x5
    jc lab_1b4a
    cmp byte [jump_anim_counter],0x19
    jnc lab_1b4a
    mov byte [0x551],0x1
lab_1b4a:
    stc
lab_1b4b:
    ret

; --- check_trashcan_near ---
check_trashcan_near:
    mov al,[jump_spawn_param]
    cmp al,0x8
    jnc lab_1b78
    mov bx,0x2
    test al,0x4
    jz lab_1b5c
    shl bl,0x1
lab_1b5c:
    mov ax,word [bx + obj_x]
    db 0x05, 0x10, 0x00                 ; add ax,0x10
    cmp ax,word [jump_x]
    jc lab_1b78
    db 0x2d, 0x30, 0x00                 ; sub ax,0x30
    jnc lab_1b70
    db 0x2b, 0xc0                       ; sub ax,ax
lab_1b70:
    cmp ax,word [jump_x]
    ja lab_1b78
    stc
    ret
lab_1b78:
    clc
    ret

; --- check_dog_collision ---
check_dog_collision:
    cmp word [level_number],0x0
    jnz lab_1be1
    mov dl,byte [gravity_y]
    cmp dl,0x0
    jz lab_1be1
    mov cx,word [gravity_cur_dims]
    db 0x86, 0xcd                       ; xchg ch,cl
    mov si,0x10
    mov ax,[gravity_x]
    mov bx,word [cat_x]
    mov dh,byte [cat_y]
    mov di,0x18
    mov ch,0xe
    call check_rect_collision                           ;undefined check_rect_collision()
    jnc lab_1be2
    call restore_alley_buffer                           ;undefined restore_alley_buffer()
    call restore_gravity_bg                           ;undefined restore_gravity_bg()
    call enter_building                           ;undefined enter_building()
    cmp byte [dog_catch_flag],0x0
    jnz lab_1bdf
    mov byte [dog_catch_flag],0x1
    call handle_cat_death                           ;undefined handle_cat_death()
    mov dl,0x1
    cmp byte [gravity_drift_dir],0xff
    jz lab_1bcb
    mov dl,0xff
lab_1bcb:
    mov byte [gravity_drift_dir],dl
    mov word [gravity_h_speed],0x60
    mov byte [gravity_frame],0x1
    mov byte [at_platform],0x0
lab_1bdf:
    stc
    ret
lab_1be1:
    clc
lab_1be2:
    ret
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; --- level_transition ---
; Level transition effect. Clears the CGA palette, handles post-level-7
; special animations (love scene completion), draws the alley scene or
; level background with a wipe effect, then restores the palette.
; Called both when entering and exiting a level.
level_transition:
    db 0x2b, 0xdb                       ; sub bx,bx
    mov ah,0xb
    int byte 0x10
    cmp word [0x6],0x7
    jnz short lab_1c12
    cmp byte [0x553],0x0
    jz short lab_1c12
    call run_victory_sequence
    mov word [0x579],0x98
    mov byte [0x57b],0x5f
lab_1c12:
    mov ax,0xb800
    mov es,ax
    cld
    mov word [wipe_fill_pattern],0x0
    call animate_screen_wipe
    call silence_speaker
    call set_palette
    cmp word [0x4],0x0
    jnz short lab_1c49
    cmp byte [0x553],0x0
    jz short lab_1c46
    cmp word [0x6],0x7
    jnz short lab_1c41
    call play_victory_march
    jmp short lab_1c49
lab_1c41:
    call handle_level_complete
    jmp short lab_1c49
lab_1c46:
    call show_level_result
lab_1c49:
    cmp word [0x4],0x7
    jz short lab_1c5a
    mov ax,0xaaaa
    cmp word [0x4],0x2
    jnz short lab_1c5d
lab_1c5a:
    mov ax,0x5555
lab_1c5d:
    mov [wipe_fill_pattern],ax
    call animate_screen_wipe
    call silence_speaker
    ret
animate_screen_wipe:
    call wipe_sound_start
    mov word [wipe_width],0x1
    mov byte [wipe_height],0x8
    mov cx,[0x579]
    mov dl,[0x57b]
    add cx,0xc
    db 0x81, 0xe1, 0xf0, 0xff           ; and cx,0xfff0
    add dl,0x8
    mov byte [wipe_edge_flags],0x0
lab_1c8c:
    call play_wipe_note
    mov [wipe_rect_x],cx
    mov [wipe_rect_y],dl
    call calc_cga_addr
    db 0x8b, 0xf8                       ; mov di,ax
    mov bl,[wipe_height]
lab_1ca0:
    mov ax,[wipe_fill_pattern]
    mov cx,[wipe_width]
    db 0xd1, 0xe9                       ; shr cx,0x0
    db 0xd1, 0xe9                       ; shr cx,0x0
    db 0xd1, 0xe9                       ; shr cx,0x0
    rep stosw
    mov cx,[wipe_width]
    db 0xd1, 0xe9                       ; shr cx,0x0
    db 0xd1, 0xe9                       ; shr cx,0x0
    and cx,0xfe
    db 0x2b, 0xf9                       ; sub di,cx
    xor di,0x2000
    test di,0x2000
    jnz short lab_1cca
    add di,0x50
lab_1cca:
    dec bl
    jnz short lab_1ca0
    cmp byte [wipe_edge_flags],0xf
    jnz short lab_1cd6
    ret
lab_1cd6:
    add word [wipe_width],0x20
    add byte [wipe_height],0x10
    mov cx,[wipe_rect_x]
    mov dl,[wipe_rect_y]
    sub cx,0x10
    jnb short lab_1cf4
    db 0x2b, 0xc9                       ; sub cx,cx
    or byte [wipe_edge_flags],0x1
lab_1cf4:
    mov ax,[wipe_width]
    db 0x03, 0xc1                       ; add ax,cx
    cmp ax,0x140
    jb short lab_1d0b
    mov ax,0x140
    db 0x2b, 0xc1                       ; sub ax,cx
    mov [wipe_width],ax
    or byte [wipe_edge_flags],0x2
lab_1d0b:
    sub dl,0x8
    jnb short lab_1d17
    db 0x2a, 0xd2                       ; sub dl,dl
    or byte [wipe_edge_flags],0x4
lab_1d17:
    mov al,[wipe_height]
    db 0x02, 0xc2                       ; add al,dl
    jb short lab_1d22
    cmp al,0xc8
    jb short lab_1d2e
lab_1d22:
    mov al,0xc8
    db 0x2a, 0xc2                       ; sub al,dl
    mov [wipe_height],al
    or byte [wipe_edge_flags],0x8
lab_1d2e:
    jmp near lab_1c8c

; --- set_palette ---
; Sets the CGA/EGA color palette based on the current level number.
; On standard CGA: uses INT 10h/AH=0Bh to select a palette from the
;   per-level table at DS:0x1853.
; On PCjr (rom_id=0xFD): sets 3 individual EGA palette registers using
;   per-level color tables at DS:0x183B, 0x1843, 0x184B.
; Always resets background/border color to black via INT 10h/AH=0Bh.
set_palette:
    cmp byte [rom_id],0xfd
    jz lab_1d48
    mov ah,0xb
    mov bh,0x1
    mov si,word [level_number]
    mov bl,byte [si + cga_palette_table]
    int 0x10                            ; BIOS Video: Set CGA palette
    jmp short lab_1d67
lab_1d48:
    mov si,word [level_number]
    mov bl,0x1
    mov bh,byte [si + pcjr_palette_1]
    call set_ega_palette                           ;undefined set_ega_palette()
    mov bl,0x2
    mov bh,byte [si + pcjr_palette_2]
    call set_ega_palette                           ;undefined set_ega_palette()
    mov bl,0x3
    mov bh,byte [si + pcjr_palette_3]
    call set_ega_palette                           ;undefined set_ega_palette()
lab_1d67:
    mov ah,0xb
    db 0x2b, 0xdb                       ; sub bx,bx
    int 0x10                            ; BIOS Video: Set background/border color
    ret

; --- set_ega_palette ---
set_ega_palette:
    mov ax,0x1000
    push si
    int 0x10                            ; BIOS Video: Set/get palette regs (EGA/VGA)
    pop si
    ret
show_level_result:
    cmp word [0x6],0x7
    jnz short lab_1d81
    call love_scene_outro
    ret
lab_1d81:
    call init_result_melody
    mov ax,0x185b
    cmp byte [0x552],0x0
    jz short lab_1dc6
    mov bx,[game_timer]
    add word [game_timer],0x2
    db 0x81, 0xe3, 0x06, 0x00           ; and bx,0x6
    mov ax,[bx+result_sprite_table]
    cmp byte [lives_count],0x0
    jz short lab_1daa
    dec byte [lives_count]
lab_1daa:
    cmp byte [0x552],0xdd
    jnz short lab_1dc6
    cmp word [0x8],0x0
    jz short lab_1dc6
    cmp byte [lives_count],0x1
    jb short lab_1dc6
    call show_extra_life
    call silence_speaker
    ret
lab_1dc6:
    mov [result_sprite_ptr],ax
    mov word [result_dissolve_mask],0x8080
    mov byte [result_frame_counter],0x1c
lab_1dd4:
    call draw_result_frame
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    mov [result_last_tick],dx
lab_1ddf:
    call play_result_note
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    cmp dx,[result_last_tick]
    jz short lab_1ddf
    cmp byte [result_frame_counter],0x14
    ja short lab_1e02
    db 0x2a, 0xff                       ; sub bh,bh
    mov bl,[result_frame_counter]
    and bl,0x6
    mov ax,[bx+result_mask_table]
    jmp short lab_1e0a
lab_1e02:
    mov ax,[result_dissolve_mask]
    stc
    db 0xd0, 0xd8                       ; rcr al,0x0
    db 0x8a, 0xe0                       ; mov ah,al
lab_1e0a:
    mov [result_dissolve_mask],ax
    dec byte [result_frame_counter]
    jnz short lab_1dd4
    call silence_speaker
    ret
draw_result_frame:
    cld
    push ds
    pop es
    mov si,[result_sprite_ptr]
    mov di,0xe
    mov cx,0x60
lab_1e24:
    lodsw
    and ax,[result_dissolve_mask]
    stosw
    loop short lab_1e24
    mov ax,0xb800
    mov es,ax
    mov si,0xe
    mov di,0xed0
    mov cx,0xc08
    call blit_to_cga
    ret
    db 0x00, 0x00

; --- init_sound ---
; Resets enemy/chase sound state. Clears enemy_active and enemy_chasing flags,
; reinitializes the chase sound generator.
init_sound:
    mov byte [enemy_chasing],0x0
    mov word [enemy_tick_counter],0x0
    mov byte [enemy_approach_timer],0x0
    mov byte [enemy_exit_timer],0x0
    mov byte [enemy_active],0x0
    mov byte [enemy_y_pos],0xb1
    call init_chase_sound                           ;undefined init_chase_sound()
    ret

; --- update_enemies ---
; Per-frame enemy update. Handles enemy spawning, movement, chasing AI,
; and collision detection with the cat. Rate-limited by BIOS tick counter.
; Sets [enemy_active] when an enemy is on screen.
update_enemies:
    db 0x2a, 0xe4                       ; sub ah,ah
    int 0x1a                            ; BIOS Timer: Get tick count → CX:DX
    db 0x8b, 0xca                       ; mov cx,dx
    sub dx,word [enemy_last_tick]
    mov ax,[enemy_tick_counter]
    db 0x25, 0x01, 0x00                 ; and ax,0x1
    db 0x05, 0x01, 0x00                 ; add ax,0x1
    db 0x3b, 0xd0                       ; cmp dx,ax
    jnc lab_1e7b
lab_1e7a:
    ret
lab_1e7b:
    call check_vsync                           ;undefined check_vsync()
    jz lab_1e7a
    mov word [enemy_last_tick],cx
    inc word [enemy_tick_counter]
    cmp byte [enemy_exit_timer],0x0
    jz lab_1ee2
    dec byte [enemy_exit_timer]
    jnz lab_1ec9
    call silence_speaker                           ;undefined silence_speaker()
    cmp byte [enemy_active],0x0
    jz lab_1ec2
    cmp word [level_number],0x0
    jz lab_1eb7
    mov byte [object_hit],0xdd
    mov word [cat_x],0xa0
    mov byte [cat_y],0x60
    ret
lab_1eb7:
    cmp byte [lives_count],0x0
    jz lab_1ec2
    dec byte [lives_count]
lab_1ec2:
    call erase_enemy                           ;undefined erase_enemy()
    call init_sound                           ;undefined init_sound()
    ret
lab_1ec9:
    call update_enemy_sprite                           ;undefined update_enemy_sprite()
    mov ax,0x104
    sub al,byte [enemy_exit_timer]
    cmp byte [enemy_dir],0xff
    jz lab_1edc
    mov ah,0xff
lab_1edc:
    call update_enemy_viewport                           ;undefined update_enemy_viewport()
    jmp near lab_1ffb
lab_1ee2:
    cmp byte [enemy_active],0x0
    jz lab_1f0c
    mov dl,byte [enemy_active]
    cmp word [enemy_chase_delay],0x0
    jz lab_1f02
    dec word [enemy_chase_delay]
    call random                           ;undefined random()
    and dl,0x1
    jnz lab_1f02
    mov dl,0xff
lab_1f02:
    mov byte [enemy_dir],dl
    mov ax,[enemy_x]
    jmp near lab_1fab
lab_1f0c:
    cmp byte [enemy_chasing],0x0
    jnz lab_1f75
    cmp byte [enemy_approach_timer],0x0
    jnz lab_1f57
    cmp byte [fall_hit],0x0
    jnz lab_1f3d
    cmp byte [cat_y],0xb4
    jc lab_1f3c
    cmp byte [0x558],0x0
    jnz lab_1f3c
    call random                           ;undefined random()
    mov bx,word [difficulty_level]
    cmp dl,byte [bx + enemy_spawn_chance]
    jc lab_1f3d
lab_1f3c:
    ret
lab_1f3d:
    mov al,0x1
    mov word [walk_note_index],0x0
    cmp word [cat_x],0xa0
    jnc lab_1f4f
    mov al,0xff
lab_1f4f:
    mov [enemy_dir],al
    mov byte [enemy_approach_timer],0x4
lab_1f57:
    dec byte [enemy_approach_timer]
    jnz lab_1f65
    mov byte [enemy_chasing],0x1
    jmp short lab_1f75
    db 0x90
lab_1f65:
    call update_enemy_sprite                           ;undefined update_enemy_sprite()
    mov al,[enemy_approach_timer]
    mov ah,byte [enemy_dir]
    call update_enemy_viewport                           ;undefined update_enemy_viewport()
    jmp near lab_1ffb
lab_1f75:
    mov byte [fall_hit],0x0
    mov ax,[enemy_x]
    cmp byte [cat_y],0xb4
    jc lab_1fab
    cmp byte [0x558],0x0
    jnz lab_1fab
    call random                           ;undefined random()
    mov bx,word [difficulty_level]
    cmp dl,byte [bx + enemy_chase_chance]
    ja lab_1fab
    cmp ax,word [cat_x]
    ja lab_1fa6
    mov byte [enemy_dir],0x1
    jmp short lab_1fab
    db 0x90
lab_1fa6:
    mov byte [enemy_dir],0xff
lab_1fab:
    cmp byte [enemy_dir],0x1
    jc lab_1fef
    jz lab_1fe2
    db 0x2d, 0x08, 0x00                 ; sub ax,0x8
    jnc lab_1fef
    db 0x2b, 0xc0                       ; sub ax,ax
lab_1fbb:
    cmp byte [enemy_active],0x0
    jz lab_1fcc
    cmp word [enemy_chase_delay],0x0
    jnz lab_1fef
    jmp short lab_1fda
    db 0x90
lab_1fcc:
    cmp byte [cat_y],0xb4
    jc lab_1fda
    cmp byte [0x558],0x0
    jz lab_1fef
lab_1fda:
    mov byte [enemy_exit_timer],0x4
    jmp short lab_1fef
    db 0x90
lab_1fe2:
    db 0x05, 0x08, 0x00                 ; add ax,0x8
    cmp ax,0x11e
    jc lab_1fef
    mov ax,0x11e
    jmp short lab_1fbb
lab_1fef:
    mov [enemy_x],ax
    call update_enemy_sprite                           ;undefined update_enemy_sprite()
    mov word [enemy_sprite_dims],0xf04
lab_1ffb:
    mov cx,word [enemy_x]
    mov dl,byte [enemy_y_pos]
    call calc_cga_addr                           ;undefined calc_cga_addr()
    mov [enemy_next_addr],ax
    cmp byte [enemy_approach_timer],0x3
    jz lab_2013
    call erase_enemy                           ;undefined erase_enemy()
lab_2013:
    call check_enemy_activate                           ;undefined check_enemy_activate()
    jc lab_2021
    mov ax,[enemy_next_addr]
    mov [enemy_draw_addr],ax
    call draw_enemy                           ;undefined draw_enemy()
lab_2021:
    ret

; --- update_enemy_sprite ---
update_enemy_sprite:
    db 0x2a, 0xff                       ; sub bh,bh
    cmp byte [enemy_active],0x0
    jz lab_203b
    inc byte [enemy_anim_frame]
    mov bl,byte [enemy_anim_frame]
    and bl,0x6
    or bl,0x8
    jnz lab_2051
lab_203b:
    add byte [enemy_anim_frame],0x2
    mov bl,byte [enemy_anim_frame]
    and bl,0x2
    cmp byte [enemy_dir],0x1
    jnz lab_2051
    or bl,0x4
lab_2051:
    mov ax,word [bx + enemy_sprite_table]
    mov [enemy_sprite_ptr],ax
    ret

; --- update_enemy_viewport ---
update_enemy_viewport:
    mov cx,0xf04
    db 0x2a, 0xc8                       ; sub cl,al
    mov word [enemy_sprite_dims],cx
    cmp ah,0xff
    jz lab_2078
    db 0x2a, 0xe4                       ; sub ah,ah
    shl al,0x1
    add word [enemy_sprite_ptr],ax
    mov word [enemy_x],0x0
    jmp short lab_2086
    db 0x90
lab_2078:
    db 0x2a, 0xe4                       ; sub ah,ah
    shl al,0x1
    shl al,0x1
    shl al,0x1
    add ax,0x120
    mov [enemy_x],ax
lab_2086:
    push ds
    pop es
    mov si,word [enemy_sprite_ptr]
    mov di,0xe
    mov al,0x4
    call copy_with_stride                           ;undefined copy_with_stride()
    mov word [enemy_sprite_ptr],0xe
    ret

; --- draw_enemy ---
draw_enemy:
    mov cx,word [enemy_sprite_dims]
    mov word [enemy_erase_dims],cx
    mov ax,0xb800
    cmp byte [enemy_active],0x0
    jnz lab_20be
    mov es,ax
    mov di,word [enemy_draw_addr]
    mov si,word [enemy_sprite_ptr]
    mov bp,enemy_save_buf
    call blit_transparent                           ;undefined blit_transparent()
    ret
lab_20be:
    push ds
    mov ds,ax
    pop es
    push es
    push ds
    mov si,word [es:0x1cbd]
    mov di,enemy_save_buf
    call save_from_cga                           ;undefined save_from_cga()
    pop es
    pop ds
    mov si,word [enemy_sprite_ptr]
    mov di,word [enemy_draw_addr]
    mov cx,word [enemy_sprite_dims]
    call blit_to_cga                           ;undefined blit_to_cga()
    ret

; --- erase_enemy ---
erase_enemy:
    mov ax,0xb800
    mov es,ax
    mov di,word [enemy_draw_addr]
    mov si,enemy_save_buf
    mov cx,word [enemy_erase_dims]
    call blit_to_cga                           ;undefined blit_to_cga()
    ret

; --- check_enemy_activate ---
check_enemy_activate:
    cmp byte [enemy_active],0x0
    jnz lab_2134
    mov al,[enemy_chasing]
    or al,byte [enemy_approach_timer]
    or al,byte [enemy_exit_timer]
    jz lab_2134
    cmp byte [cat_y],0xa3
    jc lab_2134
    cmp byte [0x558],0x0
    jnz lab_2134
    mov ax,[enemy_x]
    db 0x05, 0x20, 0x00                 ; add ax,0x20
    cmp ax,word [cat_x]
    jc lab_2134
    db 0x2d, 0x38, 0x00                 ; sub ax,0x38
    jnc lab_212a
    db 0x2b, 0xc0                       ; sub ax,ax
lab_212a:
    cmp ax,word [cat_x]
    ja lab_2134
    call activate_enemy_chase                           ;undefined activate_enemy_chase()
    ret
lab_2134:
    clc
    ret

; --- activate_enemy_chase ---
activate_enemy_chase:
    cmp word [level_number],0x6
    jnz lab_2149
    mov al,[cat_y]
    mov [enemy_y_pos],al
    mov ax,[cat_x]
    mov [enemy_x],ax
lab_2149:
    mov ax,[enemy_x]
    add ax,word [cat_x]
    shr ax,0x1
    cmp ax,0x118
    jc lab_215a
    mov ax,0x117
lab_215a:
    mov [enemy_x],ax
    mov bl,0x1
    cmp ax,0xa0
    ja lab_216e
    mov bl,0xff
    mov dx,0xa1
    db 0x2b, 0xd0                       ; sub dx,ax
    jmp short lab_2173
    db 0x90
lab_216e:
    sub ax,0x9f
    db 0x8b, 0xd0                       ; mov dx,ax
lab_2173:
    mov byte [enemy_active],bl
    mov byte [enemy_chasing],0x1
    mov byte [enemy_exit_timer],0x0
    mov cl,0x3
    shr dx,cl
    mov word [enemy_chase_delay],dx
    cmp word [level_number],0x6
    jnz lab_21bd
    call restore_alley_buffer                           ;undefined restore_alley_buffer()
    mov al,[enemy_active]
    push ax
    mov byte [enemy_active],0x0
    mov word [enemy_sprite_dims],0xf04
    mov ax,[enemy_sprite_table]
    mov [enemy_sprite_ptr],ax
    mov cx,word [enemy_x]
    mov dl,byte [enemy_y_pos]
    call calc_cga_addr                           ;undefined calc_cga_addr()
    mov [enemy_draw_addr],ax
    call draw_enemy                           ;undefined draw_enemy()
    pop ax
    mov [enemy_active],al
lab_21bd:
    call erase_enemy                           ;undefined erase_enemy()
    call restore_alley_buffer                           ;undefined restore_alley_buffer()
    mov ax,0x0
    cmp word [cat_x],0xa0
    jnc lab_21d1
    mov ax,0x122
lab_21d1:
    mov [cat_x],ax
    cmp word [level_number],0x0
    jnz lab_21de
    call setup_alley                           ;undefined setup_alley()
lab_21de:
    stc
    ret
check_enemy_object_hit:
    mov al,[enemy_chasing]
    or al,[enemy_approach_timer]
    or al,[enemy_exit_timer]
    jz short lab_2209
    mov ax,[thrown_obj_x]
    mov dl,[thrown_obj_y]
    mov si,0x10
    mov bx,[enemy_x]
    mov dh,[enemy_y_pos]
    mov di,0x20
    mov cx,0xf1e
    call check_rect_collision
    ret
lab_2209:
    clc
    ret
    db 0x00, 0x00, 0x00, 0x00, 0x00


; --- pick_random_target ---
pick_random_target:
    mov bx,word [difficulty_level]
    mov cl,byte [bx + floor_door_count]
lab_15d8:
    call random                           ;undefined random()
    and dl,0x7
    db 0x3a, 0xd1                       ; cmp dl,cl
    ja lab_15d8
    add dl,byte [bx + floor_first_door]
    cmp dl,byte [last_target_door]
    jz lab_15d8
    mov byte [last_target_door],dl
    db 0x8a, 0xda                       ; mov bl,dl
    mov cl,byte [bx + door_position_table]
    mov dl,0x88
    test cl,0x80
    jnz lab_15ff
    mov dl,0x90
lab_15ff:
    db 0x81, 0xe1, 0x7f, 0x00           ; and cx,0x7f
    shl cx,0x1
    shl cx,0x1
    ret

; --- check_level_collision ---
check_level_collision:
    cmp word [level_number],0x7
    jnz lab_1613
    call check_stairs_collision                           ;undefined check_stairs_collision()
    ret
lab_1613:
    cmp word [level_number],0x0
    jz lab_161e
    call check_level_platform                           ;undefined check_level_platform()
    ret
lab_161e:
    mov al,[cat_y]
    and al,0xf8
    cmp al,0x60
    jz lab_1630
    call check_door_position                           ;undefined check_door_position()
    jc lab_1656
    call check_window_landing                           ;undefined check_window_landing()
    ret
lab_1630:
    cmp byte [game_mode],0x2
    jnc lab_1655
    mov [cat_y],al
    add al,0x32
    mov [cat_y_bottom],al
    cmp byte [game_mode],0x1
    jz lab_1653
    mov byte [game_mode],0x1
    db 0x2a, 0xe4                       ; sub ah,ah
    int 0x1a                            ; BIOS Timer: Get tick count → CX:DX
    mov word [0x556],dx
lab_1653:
    stc
    ret
lab_1655:
    clc
lab_1656:
    ret

; --- check_door_position ---
check_door_position:
    mov cl,byte [cat_y]
    add cl,0x2
    and cl,0xf8
    mov bx,word [difficulty_level]
    mov bl,byte [bx + floor_first_door]
lab_1669:
    mov al,byte [bx + door_position_table]
    cmp al,0x0
    jnz lab_1678
    mov byte [door_contact],0x0
    clc
    ret
lab_1678:
    inc bx
    mov ch,0x88
    test al,0x80
    jnz lab_1681
    mov ch,0x90
lab_1681:
    db 0x3a, 0xcd                       ; cmp cl,ch
    jnz lab_1669
    db 0x25, 0x7f, 0x00                 ; and ax,0x7f
    shl ax,0x1
    shl ax,0x1
    mov dx,word [cat_x]
    db 0x81, 0xe2, 0xf8, 0xff           ; and dx,0xfff8
    db 0x3b, 0xd0                       ; cmp dx,ax
    jc lab_1669
    mov dx,word [cat_x]
    sub dx,0xf
    db 0x81, 0xe2, 0xf8, 0xff           ; and dx,0xfff8
    db 0x3b, 0xd0                       ; cmp dx,ax
    ja lab_1669
    sub ch,0x2
    mov byte [cat_y],ch
    add ch,0x32
    mov byte [cat_y_bottom],ch
    cmp byte [door_contact],0x0
    jnz lab_16c4
    mov byte [door_contact],0x1
    call play_hit_sound                           ;undefined play_hit_sound()
lab_16c4:
    stc
    ret

; --- check_level_platform ---
check_level_platform:
    mov byte [l3_platform_id],0x0
    cmp byte [in_level_mode],0x1
    jnz lab_16fc
    mov ax,[entrance_x]
    db 0x2d, 0x04, 0x00                 ; sub ax,0x4
    mov dl,byte [entrance_y]
    sub dl,0x8
    mov si,0xc
    mov bx,word [cat_x]
    mov dh,byte [cat_y]
    mov di,0x18
    mov cx,0xe10
    call check_rect_collision                           ;undefined check_rect_collision()
    jnc lab_16fc
    mov byte [0x551],0x1
    clc
    ret
lab_16fc:
    cmp word [level_number],0x3
    jnz lab_170e
    call check_fence_collision                           ;undefined check_fence_collision()
    jnc lab_170e
    mov byte [at_platform],0x1
    ret
lab_170e:
    mov cl,byte [cat_y]
    and cl,0xf8
    mov bx,word [level_number]
    shl bx,0x1
    mov bx,word [bx + level_platform_index]
lab_171f:
    mov ch,byte [bx + platform_y_table]
    cmp ch,0x0
    jnz lab_172a
    clc
    ret
lab_172a:
    mov al,byte [bx + platform_type_table]
    mov [platform_cur_type],al
    shl bl,0x1
    mov ax,word [bx + platform_width_table]
    mov [platform_cur_width],ax
    mov ax,word [bx + platform_x_left]
    shr bl,0x1
    inc bx
    db 0x3a, 0xcd                       ; cmp cl,ch
    jnz lab_171f
    mov dx,word [cat_x]
    db 0x81, 0xe2, 0xf8, 0xff           ; and dx,0xfff8
    db 0x3b, 0xd0                       ; cmp dx,ax
    jc lab_171f
    mov dx,word [cat_x]
    sub dx,word [platform_cur_width]
    jnc lab_175d
    db 0x2b, 0xd2                       ; sub dx,dx
lab_175d:
    db 0x81, 0xe2, 0xfc, 0xff           ; and dx,0xfffc
    db 0x3b, 0xd0                       ; cmp dx,ax
    ja lab_171f
    mov byte [cat_y],ch
    add ch,0x32
    mov byte [cat_y_bottom],ch
    mov al,[platform_cur_type]
    mov [at_platform],al
    cmp al,0x0
    jz lab_1780
    db 0x81, 0x26, 0x79, 0x05, 0xfc, 0xff ; and word [cat_x],0xfffc
lab_1780:
    cmp word [level_number],0x4
    jnz lab_1797
    dec bx
    sub bx,0x27
    jc lab_1797
    cmp bx,0x10
    jnc lab_1797
    inc bx
    mov byte [l3_platform_id],bl
lab_1797:
    stc
    ret

; --- pixel_to_bitmask ---
pixel_to_bitmask:
    mov cl,0x3
    shr bx,cl
    db 0x8a, 0xeb                       ; mov ch,bl
    mov cl,0x3
    shr bx,cl
    db 0x8a, 0xcd                       ; mov cl,ch
    and cl,0x7
    mov ch,0x80
    shr ch,cl
    ret

; --- check_window_landing ---
check_window_landing:
    mov dl,byte [cat_y]
    and dl,0xf8
    db 0x2b, 0xdb                       ; sub bx,bx
    cmp dl,0x8
    jz lab_17c9
    inc bl
    cmp dl,0x28
    jz lab_17c9
    inc bl
    cmp dl,0x48
    jnz lab_1810
lab_17c9:
    mov ax,[cat_x]
    cmp bx,word [current_floor]
    jnz lab_17fc
    cmp byte [window_column],0x3
    ja lab_17fc
    cmp bl,0x1
    jz lab_17ee
    mov cx,0x4
    sub cl,byte [window_column]
    shl cl,0x1
    shl cl,0x1
    db 0x03, 0xc1                       ; add ax,cx
    jmp short lab_17fc
    db 0x90
lab_17ee:
    db 0x2a, 0xed                       ; sub ch,ch
    mov cl,byte [window_column]
    inc cl
    shl cl,0x1
    shl cl,0x1
    db 0x2b, 0xc1                       ; sub ax,cx
lab_17fc:
    mov bl,byte [bx + window_row_offset]
    db 0x8b, 0xf3                       ; mov si,bx
    db 0x8b, 0xd8                       ; mov bx,ax
    add bx,0xa
    call pixel_to_bitmask                           ;undefined pixel_to_bitmask()
    test byte [bx + si + 0x1016],ch
    jnz lab_1812
lab_1810:
    clc
    ret
lab_1812:
    mov byte [cat_y],dl
    add dl,0x32
    mov byte [cat_y_bottom],dl
    db 0x81, 0x26, 0x79, 0x05, 0xf8, 0xff ; and word [cat_x],0xfff8
    mov byte [at_platform],0x1
    stc
    ret
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00

; --- init_player ---
; Resets player physics state for a new level or respawn.
; Clears gravity, jump counters, and related state variables.
; No inputs or outputs.
init_player:
    mov byte [jump_anim_counter],0x0
    mov byte [gravity_y],0x0
    mov byte [idle_aggro_flag],0x0
    mov byte [deduct_life],0x0
    mov word [jump_toss_delay],0x9
    ret

; --- apply_cat_gravity ---
; Per-frame update for gravity-affected projectiles (objects thrown at the cat).
; Rate-limited to one update per BIOS tick. When [gravity_y] != 0, moves the
; projectile along its trajectory (applying horizontal drift from [0x1674]),
; draws its sprite, and checks collision with the dog (level 4).
; When the projectile reaches its target height, clears gravity state and
; restores the background.
apply_cat_gravity:
    cmp byte [gravity_y],0x0
    jz lab_185c
    db 0x2a, 0xe4                       ; sub ah,ah
    int 0x1a                            ; BIOS Timer: Get tick count → CX:DX
    cmp dx,word [gravity_last_tick]
    jnz lab_185d
lab_185c:
    ret
lab_185d:
    mov word [gravity_last_tick],dx
    cmp byte [idle_aggro_flag],0x0
    jz lab_187f
    mov ax,[gravity_x]
    db 0x25, 0xf8, 0xff                 ; and ax,0xfff8
    mov bx,word [cat_x]
    db 0x81, 0xe3, 0xf8, 0xff           ; and bx,0xfff8
    db 0x3b, 0xc3                       ; cmp ax,bx
    jnz lab_187f
    mov byte [gravity_drift_dir],0x0
lab_187f:
    inc byte [gravity_frame]
    cmp word [gravity_h_speed],0x1
    ja lab_188e
    dec word [gravity_h_speed]
lab_188e:
    mov ax,[gravity_x]
    mov dx,word [gravity_h_speed]
    mov cl,0x3
    shr dl,cl
    cmp byte [gravity_drift_dir],0x1
    jc lab_18b5
    jnz lab_18af
    db 0x03, 0xc2                       ; add ax,dx
    cmp ax,0x12f
    jc lab_18b5
    mov ax,0x12e
    jmp short lab_18b5
    db 0x90
lab_18af:
    db 0x2b, 0xc2                       ; sub ax,dx
    jnc lab_18b5
    db 0x2b, 0xc0                       ; sub ax,ax
lab_18b5:
    mov [gravity_x],ax
    mov bx,word [gravity_cur_dims]
    mov al,[gravity_frame]
    shr al,0x1
    add al,byte [gravity_y]
    db 0x8a, 0xd0                       ; mov dl,al
    sub al,byte [gravity_target_height]
    jc lab_18e1
    db 0x2a, 0xf8                       ; sub bh,al
    jz lab_18d3
    jnc lab_18e1
lab_18d3:
    mov byte [gravity_y],0x0
    mov byte [deduct_life],0x0
    call restore_gravity_bg                           ;undefined restore_gravity_bg()
lab_18e0:
    ret
lab_18e1:
    mov byte [gravity_y],dl
    mov cx,word [gravity_x]
    mov word [gravity_save_dims],bx
    call calc_cga_addr                           ;undefined calc_cga_addr()
    mov [gravity_cga_addr],ax
    cmp byte [gravity_frame],0x2
    jz lab_18fd
    call restore_gravity_bg                           ;undefined restore_gravity_bg()
lab_18fd:
    call check_dog_collision                           ;undefined check_dog_collision()
    jc lab_18e0
    mov di,word [gravity_cga_addr]
    mov word [gravity_prev_cga],di
    mov cx,word [gravity_save_dims]
    mov word [gravity_restore_dims],cx
    mov ax,0xb800
    mov es,ax
    mov si,word [gravity_cur_sprite]
    mov bp,gravity_save_buf
    call blit_transparent                           ;undefined blit_transparent()
    ret

; --- restore_gravity_bg ---
restore_gravity_bg:
    mov ax,0xb800
    mov es,ax
    mov di,word [gravity_prev_cga]
    mov si,gravity_save_buf
    mov cx,word [gravity_restore_dims]
    call blit_to_cga                           ;undefined blit_to_cga()
    ret

; --- update_cat_jump ---
; Per-frame handler for indoor level enemy spawning and jump arcs.
; Manages the lifecycle of enemies that leap from ledges toward the cat:
;   - Randomly spawns new enemies (higher frequency when cat is idle too long)
;   - Animates the enemy through a parabolic jump arc
;   - On landing near cat: initiates a gravity toss (fish/object thrown at cat)
;   - Checks collision via check_fish_collision and check_trashcan_near
; Rate-limited by a countdown timer [0x166A].
update_cat_jump:
    dec byte [jump_tick_delay]
    jz lab_193d
lab_193c:
    ret
lab_193d:
    mov byte [jump_tick_delay],0xd
    call check_vsync                           ;undefined check_vsync()
    jnz lab_193c
    cmp byte [jump_anim_counter],0x0
    jz lab_1951
    call check_fish_collision                           ;undefined check_fish_collision()
lab_1951:
    cmp byte [gravity_y],0x0
    jnz lab_193c
    cmp byte [jump_anim_counter],0x0
    jnz lab_19cd
    cmp byte [cat_y],0x60
    ja lab_193c
    mov byte [idle_aggro_flag],0x0
    cmp byte [game_mode],0x1
    jnz lab_198a
    cmp byte [0x418],0x0
    jnz lab_198a
    db 0x2a, 0xe4                       ; sub ah,ah
    int 0x1a                            ; BIOS Timer: Get tick count → CX:DX
    sub dx,word [0x556]
    cmp dx,0x48
    jc lab_198a
    inc byte [idle_aggro_flag]
lab_198a:
    call random                           ;undefined random()
    cmp byte [idle_aggro_flag],0x0
    jz lab_199a
    and dl,0x3
    jmp short lab_19a2
    db 0x90
lab_199a:
    and dl,0xf
    cmp dl,0xc
    jnc lab_193c
lab_19a2:
    mov byte [jump_spawn_param],dl
    call decode_enemy_params                           ;undefined decode_enemy_params()
    mov word [jump_x],cx
    mov byte [jump_y],dl
    call check_fish_collision                           ;undefined check_fish_collision()
    jc lab_198a
    mov byte [jump_anim_counter],0x1d
    mov bx,word [difficulty_level]
    shl bl,0x1
    mov ax,word [bx + jump_pause_by_diff]
    mov [jump_toss_delay],ax
    mov byte [jump_toss_remaining],0x1
lab_19cd:
    call check_fish_collision                           ;undefined check_fish_collision()
    jc lab_19e0
    mov byte [cycle_active],0x0
    call check_trashcan_near                           ;undefined check_trashcan_near()
    jnc lab_19e1
    inc byte [cycle_active]
lab_19e0:
    ret
lab_19e1:
    cmp byte [jump_anim_counter],0x10
    jnz lab_19f0
    db 0x2a, 0xe4                       ; sub ah,ah
    int 0x1a                            ; BIOS Timer: Get tick count → CX:DX
    mov word [jump_toss_tick],dx
lab_19f0:
    cmp byte [jump_anim_counter],0xf
    jnz lab_1a76
    db 0x2a, 0xe4                       ; sub ah,ah
    int 0x1a                            ; BIOS Timer: Get tick count → CX:DX
    sub dx,word [jump_toss_tick]
    cmp dx,word [jump_toss_delay]
    jnc lab_1a76
    cmp byte [jump_toss_remaining],0x0
    jz lab_1a75
    cmp byte [gravity_y],0x0
    jnz lab_1a75
    cmp byte [0x418],0x0
    jnz lab_1a75
    dec byte [jump_toss_remaining]
    mov byte [deduct_life],0x1
    mov al,[jump_y]
    mov [gravity_y],al
    call random                           ;undefined random()
    db 0x81, 0xe2, 0x0f, 0x00           ; and dx,0xf
    add dx,word [jump_x]
    mov word [gravity_x],dx
    mov al,0x1
    cmp dx,word [cat_x]
    jc lab_1a42
    mov al,0xff
lab_1a42:
    mov [gravity_drift_dir],al
    call random                           ;undefined random()
    db 0x8a, 0xda                       ; mov bl,dl
    db 0x81, 0xe3, 0x06, 0x00           ; and bx,0x6
    mov ax,word [bx + gravity_sprite_ptrs]
    mov [gravity_cur_sprite],ax
    mov ax,word [bx + gravity_sprite_dims_tbl]
    mov [gravity_cur_dims],ax
    shr bl,0x1
    mov al,byte [bx + gravity_height_table]
    mov [gravity_target_height],al
    mov word [gravity_h_speed],0x20
    mov byte [gravity_frame],0x1
    mov byte [dog_catch_flag],0x0
lab_1a75:
    ret
lab_1a76:
    dec byte [jump_anim_counter]
    mov cx,word [jump_x]
    mov dl,byte [jump_y]
    cmp byte [jump_anim_counter],0xe
    jbe lab_1a93
    add dl,byte [jump_anim_counter]
    sub dl,0xe
    jmp short lab_1a9a
    db 0x90
lab_1a93:
    add dl,0xe
    sub dl,byte [jump_anim_counter]
lab_1a9a:
    mov byte [jump_draw_y],dl
    call calc_cga_addr                           ;undefined calc_cga_addr()
    db 0x8b, 0xf8                       ; mov di,ax
    mov ax,0xb800
    mov es,ax
    cld
    mov cx,0x4
    cmp byte [jump_anim_counter],0xe
    jbe lab_1ad7
    cmp byte [0x418],0x0
    jz lab_1ad2
    mov al,[jump_draw_y]
    sub al,byte [jump_y]
    db 0x2a, 0xe4                       ; sub ah,ah
    mov cl,0x3
    shl ax,cl
    add ax,jump_land_sprite_data
    db 0x8b, 0xf0                       ; mov si,ax
    mov cx,0x4
    rep movsw
    ret
lab_1ad2:
    db 0x2b, 0xc0                       ; sub ax,ax
    rep stosw
    ret
lab_1ad7:
    mov al,[jump_draw_y]
    sub al,byte [jump_y]
    mov ah,0xa
    mul ah
    add ax,jump_land_sprites
    db 0x8b, 0xf0                       ; mov si,ax
    rep movsw
    ret


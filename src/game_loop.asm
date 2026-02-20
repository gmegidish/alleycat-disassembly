; --- setup_alley ---
; Sets up the alley (outdoor) scene. Positions the cat at the left or right
; edge based on current cat_x, initializes scroll direction, clears all
; game state flags (death, hit, caught, transition), and resets window state.
setup_alley:
    mov cx,0x0
    mov ah,0x1
    cmp word [cat_x],0xa0
    jc lab_071f
    mov cx,0x128
    mov ah,0xff
lab_071f:
    mov byte [scroll_direction],ah
    mov byte [entry_steps],0x3
    mov byte [entry_delay],0xc
    mov dl,0xb4
    mov word [cat_x],cx
    mov byte [cat_y],dl
    mov byte [cat_y_bottom],0xe6
    call calc_cga_addr                           ;undefined calc_cga_addr()
    mov [cat_draw_pos],ax
    mov word [0x561],0xb03
    call save_alley_buffer                           ;undefined save_alley_buffer()
    mov byte [in_level_mode],0x0
    mov word [scroll_speed],0x2
    mov byte [anim_counter],0x1
    mov byte [transition_timer],0x0
    mov byte [game_mode],0x0
    mov byte [at_platform],0x0
    mov byte [transitioning],0x0
    mov byte [sprite_hidden],0x0
    mov byte [input_horizontal],0x0
    mov byte [input_vertical],0x0
    mov byte [cat_died],0x0
    mov byte [auto_walk],0x0
    mov byte [object_hit],0x0
    mov word [level_complete],0x0
    mov byte [cat_caught],0x0
    mov byte [door_contact],0x0
    call reset_window_state                           ;undefined reset_window_state()
    ret

; --- setup_level ---
; Configures the alley scene for the current level. If level_number == 0,
; uses saved_cat_x/y for position; otherwise looks up position from
; per-level tables. Draws the alley background and foreground.
setup_level:
    mov bx,word [level_number]
    cmp bx,0x0
    jnz lab_07b5
    mov cx,word [saved_cat_x]
    mov dl,byte [saved_cat_y]
    jmp short lab_07bf
    db 0x90
lab_07b5:
    mov dl,byte [bx + 0x5e9]
    shl bl,0x1
    mov cx,word [bx + 0x5d9]
lab_07bf:
    mov word [cat_x],cx
    mov byte [cat_y],dl
    db 0x8a, 0xc2                       ; mov al,dl
    add al,0x32
    mov [cat_y_bottom],al
    call calc_cga_addr                           ;undefined calc_cga_addr()
    mov [cat_draw_pos],ax
    mov ax,[0xfb2]
    mov [vert_sprite_data],ax
    mov ax,[0xfbe]
    mov [vert_sprite_dims],ax
    mov [0x561],ax
    call save_alley_buffer                           ;undefined save_alley_buffer()
    mov byte [in_level_mode],0x1
    mov byte [scroll_direction],0x0
    mov byte [anim_counter],0x1
    mov byte [anim_step],0x40
    mov al,0xa
    cmp word [level_number],0x7
    jnz lab_0805
    db 0x2a, 0xc0                       ; sub al,al
lab_0805:
    mov [transition_timer],al
    mov byte [game_mode],0x0
    mov byte [at_platform],0x0
    mov byte [transitioning],0x0
    mov byte [sprite_hidden],0x0
    mov byte [input_horizontal],0x0
    mov byte [input_vertical],0x0
    mov byte [cat_died],0x0
    mov byte [auto_walk],0x0
    mov byte [object_hit],0x0
    mov word [level_complete],0x0
    mov byte [cat_caught],0x0
    mov byte [door_contact],0x0
    call reset_window_state                           ;undefined reset_window_state()
    cmp word [level_number],0x2
    jnz lab_0871
    mov byte [anim_counter],0x10
    mov word [speed_ramp],0x10
    db 0x2a, 0xe4                       ; sub ah,ah
    int 0x1a                            ; BIOS Timer: Get tick count → CX:DX
    mov word [level2_tick],dx
    mov byte [immune_flag],0x0
    mov byte [level2_rise],0x5
    mov byte [meow_timer],0x1
lab_0871:
    ret
start_auto_walk:
    mov word [0x592a],0x400
    cmp byte [auto_walk],0x0
    jz short lab_0880
    ret
lab_0880:
    mov byte [anim_counter],0x8
    mov dl,0xff
    mov al,[cat_y]
    cmp al,[entrance_y]
    jnb short lab_0892
    mov dl,0x1
lab_0892:
    mov [in_level_mode],dl
    mov ax,[cat_x]
    sub ax,[entrance_x]
    mov dl,0xff
    ja short lab_08a5
    mov dl,0x1
    not ax
lab_08a5:
    mov [scroll_direction],dl
    cmp ah,0x0
    jz short lab_08b1
    mov ax,0xff
lab_08b1:
    not al
    cmp al,0x30
    jnb short lab_08b9
    mov al,0x30
lab_08b9:
    db 0x8a, 0xd8                       ; mov bl,al
    db 0xd0, 0xeb                       ; shr bl,0x0
    db 0xd0, 0xeb                       ; shr bl,0x0
    db 0x2a, 0xc3                       ; sub al,bl
    mov [anim_step],al
    mov cl,0x5
    shr al,cl
    mov [scroll_speed],ax
    mov byte [at_platform],0x0
    mov byte [0x39e0],0x0
    mov byte [anim_accumulator],0x1
    mov byte [transition_timer],0x10
    mov byte [auto_walk],0x1
    ret

; --- update_animation ---
; Per-frame animation tick. Handles cat walking/scrolling animation,
; sprite frame cycling, and screen transitions. Rate-limited by BIOS
; tick counter. Halves animation speed on PCjr (rom_id == 0xFD).
update_animation:
    db 0x2a, 0xe4                       ; sub ah,ah
    int 0x1a                            ; BIOS Timer: Get tick count → CX:DX
    cmp dx,word [anim_last_tick]
    jnz lab_08fd
    cmp word [pcjr_delay],0x0
    jz lab_08fc
    dec word [pcjr_delay]
    jz lab_090c
lab_08fc:
    ret
lab_08fd:
    mov ax,0x20
    cmp byte [rom_id],0xfd
    jnz lab_0909
    shr ax,0x1
lab_0909:
    mov [pcjr_delay],ax
lab_090c:
    cmp word [level_number],0x2
    jz lab_091d
    mov cl,byte [in_level_mode]
    or cl,byte [scroll_direction]
    jnz lab_0926
lab_091d:
    push dx
    push ax
    call check_vsync                           ;undefined check_vsync()
    pop ax
    pop dx
    jz lab_08fc
lab_0926:
    mov word [anim_last_tick],dx
    mov [anim_tick_delay],ax
    cmp word [level_number],0x4
    jnz lab_093b
    cmp byte [0x39e1],0x0
    jnz lab_08fc
lab_093b:
    cmp word [level_number],0x6
    jnz lab_0949
    cmp byte [0x44bd],0x0
    jnz lab_08fc
lab_0949:
    cmp word [level_number],0x2
    jz lab_0953
    jmp near lab_0bac
lab_0953:
    mov si,word [difficulty_level]
    shl si,0x1
    mov ax,[anim_last_tick]
    sub ax,word [level2_tick]
    cmp ax,word [si + 0x589]
    jc lab_09d6
    cmp ax,word [si + 0x599]
    jc lab_0971
    mov byte [object_hit],0x1
lab_0971:
    dec byte [meow_timer]
    jnz lab_09b9
    call play_meow_sound                           ;undefined play_meow_sound()
    mov byte [meow_timer],0x6
    mov al,[level2_rise]
    cmp byte [cat_y],0xb3
    jc lab_0992
    cmp al,0xc8
    jnc lab_0992
    add al,0x1e
    mov [level2_rise],al
lab_0992:
    mov dl,byte [cat_y]
    db 0x2a, 0xd0                       ; sub dl,al
    jnc lab_099c
    db 0x2a, 0xd2                       ; sub dl,dl
lab_099c:
    mov cx,word [cat_x]
    and dl,0xf8
    call calc_cga_addr                           ;undefined calc_cga_addr()
    db 0x8b, 0xf8                       ; mov di,ax
    mov si,0x64e
    mov ax,0xb800
    mov es,ax
    mov bp,0xe
    mov cx,0x503
    call blit_masked                           ;undefined blit_masked()
lab_09b9:
    mov byte [scroll_direction],0x0
    mov byte [in_level_mode],0x1
    mov byte [immune_flag],0x1
    mov byte [anim_counter],0x20
    db 0x2b, 0xdb                       ; sub bx,bx
    mov ah,0xb
    int 0x10                            ; BIOS Video: Set background/border color
    jmp near lab_0a86
lab_09d6:
    mov si,word [difficulty_level]
    shl si,0x1
    db 0x2b, 0xdb                       ; sub bx,bx
    cmp ax,word [si + 0x5a9]
    jc lab_09f6
    inc bl
    cmp ax,word [si + 0x5b9]
    jc lab_09f6
    mov bl,0x5
    cmp ax,word [si + 0x5c9]
    jc lab_09f6
    dec bl
lab_09f6:
    mov ah,0xb
    int 0x10                            ; BIOS Video: Set background/border color
    mov al,[scroll_direction]
    mov [prev_scroll_dir],al
    mov al,[in_level_mode]
    mov [prev_vert_dir],al
    mov al,[input_horizontal]
    cmp al,0x0
    jnz lab_0a1a
    cmp word [speed_ramp],0x10
    jc lab_0a2e
    dec word [speed_ramp]
    jmp short lab_0a37
lab_0a1a:
    cmp al,byte [scroll_direction]
    jnz lab_0a2e
    cmp word [speed_ramp],0x30
    jnc lab_0a37
    add word [speed_ramp],0x3
    jmp short lab_0a37
lab_0a2e:
    mov [scroll_direction],al
    mov word [speed_ramp],0x20
lab_0a37:
    mov ax,[speed_ramp]
    mov cl,0x3
    shr ax,cl
    mov bx,word [difficulty_level]
    shl bl,0x1
    cmp ax,word [bx + 0x66c]
    jbe lab_0a4e
    mov ax,word [bx + 0x66c]
lab_0a4e:
    mov [scroll_speed],ax
    call update_scroll                           ;undefined update_scroll()
    mov al,[input_vertical]
    cmp al,0x0
    jnz lab_0a6a
    not al
    cmp byte [anim_counter],0x10
    jc lab_0a7e
    dec byte [anim_counter]
    jmp short lab_0a86
lab_0a6a:
    cmp al,byte [in_level_mode]
    jnz lab_0a7e
    cmp byte [anim_counter],0x40
    jnc lab_0a86
    add byte [anim_counter],0x4
    jmp short lab_0a86
lab_0a7e:
    mov [in_level_mode],al
    mov byte [anim_counter],0x20
lab_0a86:
    mov si,word [difficulty_level]
    mov dl,byte [cat_y]
    mov cl,0x4
    mov bl,byte [anim_counter]
    shr bl,cl
    cmp bl,byte [si + 0x67c]
    jbe lab_0aa0
    mov bl,byte [si + 0x67c]
lab_0aa0:
    mov al,[in_level_mode]
    cmp al,0x1
    jc lab_0ace
    jnz lab_0ab4
    db 0x02, 0xd3                       ; add dl,bl
    cmp dl,0xb4
    jc lab_0ace
    mov dl,0xb3
    jmp short lab_0ace
lab_0ab4:
    db 0x2a, 0xd3                       ; sub dl,bl
    jc lab_0abd
    cmp dl,0x3
    ja lab_0ace
lab_0abd:
    mov ax,[0x9b8]
    cmp ax,word [cat_sprite_data]
    jnz lab_0acc
    mov ax,[anim_last_tick]
    mov [level2_tick],ax
lab_0acc:
    mov dl,0x2
lab_0ace:
    mov byte [cat_y],dl
    mov cx,word [cat_x]
    call calc_cga_addr                           ;undefined calc_cga_addr()
    mov [cat_screen_pos],ax
    cmp byte [immune_flag],0x0
    jz lab_0ae9
    mov bx,0x10
    jmp short lab_0b64
    db 0x90
lab_0ae9:
    mov al,[scroll_direction]
    cmp al,byte [prev_scroll_dir]
    jnz lab_0afb
    mov al,[in_level_mode]
    cmp al,byte [prev_vert_dir]
    jz lab_0b00
lab_0afb:
    mov bx,0x18
    jmp short lab_0b64
lab_0b00:
    inc word [walk_frame]
    mov bx,word [walk_frame]
    mov al,[input_horizontal]
    or al,byte [input_vertical]
    jnz lab_0b13
    shr bl,0x1
lab_0b13:
    cmp byte [cat_y],0xb3
    jc lab_0b21
    cmp byte [in_level_mode],0x1
    jz lab_0b3c
lab_0b21:
    cmp byte [cat_y],0x4
    ja lab_0b2f
    cmp byte [input_vertical],0x0
    jnz lab_0b53
lab_0b2f:
    mov al,[anim_counter]
    db 0x2a, 0xe4                       ; sub ah,ah
    shr ax,0x1
    cmp ax,word [speed_ramp]
    jnc lab_0b53
lab_0b3c:
    cmp byte [scroll_direction],0x0
    jz lab_0b53
    db 0x81, 0xe3, 0x06, 0x00           ; and bx,0x6
    cmp byte [scroll_direction],0x1
    jz lab_0b64
    or bl,0x8
    jmp short lab_0b64
lab_0b53:
    db 0x81, 0xe3, 0x02, 0x00           ; and bx,0x2
    or bl,0x10
    cmp byte [in_level_mode],0x1
    jnz lab_0b64
    add bl,0x4
lab_0b64:
    mov ax,word [bx + 0x9a6]
    mov [cat_sprite_data],ax
    mov ax,word [bx + 0x9c0]
    mov [cat_sprite_dims],ax
    mov al,0x30
    mov cx,0x2bc
    cmp byte [rom_id],0xfd
    jc lab_0b97
    jz lab_0b85
    mov al,0x8
    mov cx,0x3e8
lab_0b85:
    cmp byte [cat_y],al
    ja lab_0b97
lab_0b8b:
    call check_vsync                           ;undefined check_vsync()
    jnz lab_0b8b
lab_0b90:
    call check_vsync                           ;undefined check_vsync()
    jz lab_0b90
lab_0b95:
    loop lab_0b95
lab_0b97:
    call restore_alley_buffer                           ;undefined restore_alley_buffer()
    mov ax,[cat_screen_pos]
    mov [cat_draw_pos],ax
    call draw_alley_foreground                           ;undefined draw_alley_foreground()
    call check_level_objects                           ;undefined check_level_objects()
    jnc lab_0bab
    call draw_alley_foreground                           ;undefined draw_alley_foreground()
lab_0bab:
    ret
lab_0bac:
    call check_dog_collision                           ;undefined check_dog_collision()
    jnc lab_0bb2
lab_0bb1:
    ret
lab_0bb2:
    cmp byte [enemy_active],0x0
    jnz lab_0bb1
    cmp byte [entry_steps],0x0
    jz lab_0c1c
    cmp byte [entry_delay],0x0
    jz lab_0bd3
    cmp byte [enemy_chasing],0x0
    jnz lab_0bd2
    dec byte [entry_delay]
lab_0bd2:
    ret
lab_0bd3:
    dec byte [entry_steps]
    jnz lab_0be5
    mov word [scroll_speed],0x8
    call update_scroll                           ;undefined update_scroll()
    jmp short lab_0c1c
    db 0x90
lab_0be5:
    call update_walk_frame                           ;undefined update_walk_frame()
    mov word [cat_sprite_data],bx
    mov al,[entry_steps]
    mov ah,byte [scroll_direction]
    call update_viewport                           ;undefined update_viewport()
    cmp byte [entry_steps],0x2
    jz lab_0c00
    call restore_alley_buffer                           ;undefined restore_alley_buffer()
lab_0c00:
    call check_dog_collision                           ;undefined check_dog_collision()
    jc lab_0c1b
    call check_enemy_activate                           ;undefined check_enemy_activate()
    jc lab_0c1b
    mov dl,byte [cat_y]
    mov cx,word [cat_x]
    call calc_cga_addr                           ;undefined calc_cga_addr()
    mov [cat_draw_pos],ax
    call draw_alley_foreground                           ;undefined draw_alley_foreground()
lab_0c1b:
    ret
lab_0c1c:
    cmp byte [at_platform],0x1
    jc lab_0c6a
    jnz lab_0c5f
    inc byte [at_platform]
    mov word [scroll_speed],0x6
    mov dl,byte [cat_y]
    mov cx,word [cat_x]
    call calc_cga_addr                           ;undefined calc_cga_addr()
    mov [cat_screen_pos],ax
    call restore_alley_buffer                           ;undefined restore_alley_buffer()
    call check_dog_collision                           ;undefined check_dog_collision()
    jc lab_0c66
    call check_enemy_activate                           ;undefined check_enemy_activate()
    jc lab_0c66
    mov ax,[cat_screen_pos]
    mov [cat_draw_pos],ax
    mov word [cat_sprite_dims],0xe03
    mov word [cat_sprite_data],0x9da
    call draw_alley_foreground                           ;undefined draw_alley_foreground()
lab_0c5f:
    cmp byte [input_vertical],0x0
    jnz lab_0c67
lab_0c66:
    ret
lab_0c67:
    jmp near lab_0e78
lab_0c6a:
    cmp byte [in_level_mode],0x0
    jnz lab_0c74
    jmp near lab_0e23
lab_0c74:
    call update_scroll                           ;undefined update_scroll()
    jnc lab_0c90
    mov byte [scroll_direction],0x0
    mov byte [anim_counter],0x2
    mov byte [in_level_mode],0x1
    mov byte [transition_timer],0x0
    jmp short lab_0cc1
    db 0x90
lab_0c90:
    mov al,[anim_step]
    sub byte [anim_accumulator],al
    jnc lab_0cc1
    cmp byte [in_level_mode],0x1
    jz lab_0cb6
    cmp byte [anim_counter],0x1
    jbe lab_0cae
    dec byte [anim_counter]
    jmp short lab_0cc1
    db 0x90
lab_0cae:
    mov byte [in_level_mode],0x1
    jmp short lab_0cc1
    db 0x90
lab_0cb6:
    cmp byte [anim_counter],0x4
    jnc lab_0cc1
    inc byte [anim_counter]
lab_0cc1:
    cmp byte [transitioning],0x0
    jnz lab_0ce7
    cmp byte [transition_timer],0x0
    jz lab_0cd5
    dec byte [transition_timer]
    jnz lab_0ce7
lab_0cd5:
    cmp byte [in_level_mode],0x1
    jnz lab_0ce7
    call check_level_collision                           ;undefined check_level_collision()
    jnc lab_0ce7
    mov al,[cat_y_bottom]
    jmp short lab_0d29
    db 0x90
lab_0ce7:
    mov al,[cat_y_bottom]
    cmp byte [in_level_mode],0x1
    jz lab_0d06
    sub al,byte [anim_counter]
    jnc lab_0d4f
    db 0x2a, 0xc0                       ; sub al,al
    mov byte [in_level_mode],0x1
    mov byte [anim_counter],0x1
    jmp short lab_0d4f
    db 0x90
lab_0d06:
    add al,byte [anim_counter]
    cmp al,0xe6
    jbe lab_0d4f
    cmp word [level_number],0x7
    jnz lab_0d22
    cmp al,0xf8
    jc lab_0d4f
    mov al,0xf8
    mov byte [cat_died],0x1
    jmp short lab_0d4f
lab_0d22:
    mov al,0xe6
    mov byte [game_mode],0x0
lab_0d29:
    mov byte [in_level_mode],0x0
    mov byte [auto_walk],0x0
    mov word [scroll_speed],0x2
    mov byte [transition_timer],0x0
    mov byte [transitioning],0x0
    cmp byte [at_platform],0x0
    jz lab_0d4f
    push ax
    call play_crash_sound                           ;undefined play_crash_sound()
    pop ax
lab_0d4f:
    mov [cat_y_bottom],al
    sub al,0x32
    jnc lab_0d58
    db 0x2a, 0xc0                       ; sub al,al
lab_0d58:
    mov [cat_y],al
    mov dl,byte [cat_y]
    mov cx,word [cat_x]
    call calc_cga_addr                           ;undefined calc_cga_addr()
    mov [cat_screen_pos],ax
    cmp byte [sprite_hidden],0x0
    jnz lab_0d73
    call restore_alley_buffer                           ;undefined restore_alley_buffer()
lab_0d73:
    call check_dog_collision                           ;undefined check_dog_collision()
    jc lab_0dc4
    call check_enemy_activate                           ;undefined check_enemy_activate()
    jc lab_0dc4
    mov ax,[cat_screen_pos]
    mov [cat_draw_pos],ax
    cmp byte [auto_walk],0x0
    jz lab_0da1
    add word [recoil_frame],0x2
    mov bx,word [recoil_frame]
    db 0x81, 0xe3, 0x0e, 0x00           ; and bx,0xe
    mov ax,word [bx + 0xfc2]
    mov bx,word [bx + 0xfd2]
    jmp short lab_0da8
lab_0da1:
    mov ax,[vert_sprite_data]
    mov bx,word [vert_sprite_dims]
lab_0da8:
    mov [cat_sprite_data],ax
    mov word [cat_sprite_dims],bx
    mov al,0x32
    sub al,byte [cat_y_bottom]
    jz lab_0dde
    jc lab_0dde
    mov cx,0x168
lab_0dbc:
    loop lab_0dbc
    db 0x2a, 0xf8                       ; sub bh,al
    jz lab_0dc4
    jnc lab_0dca
lab_0dc4:
    mov byte [sprite_hidden],0x1
    ret
lab_0dca:
    mov word [cat_sprite_dims],bx
    db 0x8a, 0xe3                       ; mov ah,bl
    shl ah,0x1
    mul ah
    add ax,word [vert_sprite_data]
    mov [cat_sprite_data],ax
    jmp short lab_0e1f
    db 0x90
lab_0dde:
    cmp word [level_number],0x7
    jnz lab_0dee
    mov al,[cat_y]
    sub al,0xbb
    jc lab_0e1f
    jnc lab_0dfc
lab_0dee:
    cmp byte [game_mode],0x2
    jnz lab_0e1f
    mov al,[cat_y]
    sub al,0x5e
    jc lab_0e1f
lab_0dfc:
    db 0x2a, 0xf8                       ; sub bh,al
    jz lab_0e02
    jnc lab_0e16
lab_0e02:
    cmp word [level_number],0x7
    jnz lab_0e0f
    mov byte [cat_died],0x1
    ret
lab_0e0f:
    call setup_alley                           ;undefined setup_alley()
    call play_hiss_sound                           ;undefined play_hiss_sound()
    ret
lab_0e16:
    mov word [cat_sprite_dims],bx
    mov byte [anim_counter],0x2
lab_0e1f:
    call draw_alley_foreground                           ;undefined draw_alley_foreground()
    ret
lab_0e23:
    cmp word [level_number],0x7
    jz lab_0e31
    cmp byte [cat_y],0xb4
    jnc lab_0e78
lab_0e31:
    call check_level_collision                           ;undefined check_level_collision()
    jc lab_0e43
    mov byte [scroll_direction],0x0
    mov byte [in_level_mode],0x1
    jmp short lab_0eb1
    db 0x90
lab_0e43:
    cmp word [level_number],0x0
    jnz lab_0e78
    call check_jump_collision                           ;undefined check_jump_collision()
    jc lab_0e56
    mov byte [jump_hit],0x0
    jmp short lab_0e78
lab_0e56:
    cmp byte [jump_hit],0x0
    jnz lab_0e60
    call play_death_melody                           ;undefined play_death_melody()
lab_0e60:
    mov byte [input_vertical],0x1
    mov byte [jump_hit],0x1
    call random                           ;undefined random()
    and dl,0x1
    jnz lab_0e74
    mov dl,0xff
lab_0e74:
    mov byte [input_horizontal],dl
lab_0e78:
    mov al,[scroll_direction]
    mov [prev_scroll_dir],al
    mov al,[input_horizontal]
    mov [scroll_direction],al
    mov al,[input_vertical]
    mov [in_level_mode],al
    cmp al,0x0
    jnz lab_0e91
    jmp near lab_0f34
lab_0e91:
    cmp byte [in_level_mode],0x1
    jnz lab_0ec9
    cmp byte [cat_y],0xb4
    jc lab_0eb1
    mov byte [in_level_mode],0x0
    mov byte [auto_walk],0x0
    mov byte [input_vertical],0x0
    jmp near lab_0f34
lab_0eb1:
    mov ah,0x1
    mov al,0x20
    mov byte [transition_timer],0x8
    cmp byte [game_mode],0x1
    jnz lab_0ef1
    mov byte [game_mode],0x0
    jmp short lab_0ef1
    db 0x90
lab_0ec9:
    mov byte [transition_timer],0x0
    mov ax,[scroll_speed]
    db 0x8a, 0xd8                       ; mov bl,al
    cmp al,0x2
    jbe lab_0ed9
    sub al,0x2
lab_0ed9:
    mov [scroll_speed],ax
    mov ah,0x8
    db 0x8a, 0xc3                       ; mov al,bl
    xor al,0xf
    mov cl,0x4
    shl al,cl
    cmp byte [game_mode],0x1
    jnz lab_0ef1
    inc byte [game_mode]
lab_0ef1:
    mov [anim_step],al
    mov byte [anim_counter],ah
    mov byte [anim_accumulator],0x1
    mov byte [at_platform],0x0
    mov bl,byte [scroll_direction]
    inc bl
    shl bl,0x1
    cmp byte [in_level_mode],0xff
    jz lab_0f14
    add bl,0x6
lab_0f14:
    db 0x2a, 0xff                       ; sub bh,bh
    mov ax,word [bx + 0xfaa]
    mov [vert_sprite_data],ax
    mov ax,word [bx + 0xfb6]
    mov [vert_sprite_dims],ax
    mov byte [0x39e0],0x0
    cmp byte [door_contact],0x0
    jz lab_0f33
    call play_catch_sound                           ;undefined play_catch_sound()
lab_0f33:
    ret
lab_0f34:
    cmp word [level_number],0x0
    jz lab_0f45
    cmp word [level_number],0x7
    jz lab_0f45
    call update_footprint                           ;undefined update_footprint()
lab_0f45:
    call update_scroll                           ;undefined update_scroll()
    mov dl,byte [cat_y]
    mov cx,word [cat_x]
    call calc_cga_addr                           ;undefined calc_cga_addr()
    mov [cat_screen_pos],ax
    mov al,[scroll_direction]
    or al,byte [in_level_mode]
    jnz lab_0f63
    call spawn_window_event                           ;undefined spawn_window_event()
    ret
lab_0f63:
    call update_walk_frame                           ;undefined update_walk_frame()
    mov word [cat_sprite_data],bx
    call restore_alley_buffer                           ;undefined restore_alley_buffer()
    call check_dog_collision                           ;undefined check_dog_collision()
    jc lab_0f86
    call check_enemy_activate                           ;undefined check_enemy_activate()
    jc lab_0f86
    mov ax,[cat_screen_pos]
    mov [cat_draw_pos],ax
    mov word [cat_sprite_dims],0xb03
    call draw_alley_foreground                           ;undefined draw_alley_foreground()
lab_0f86:
    ret


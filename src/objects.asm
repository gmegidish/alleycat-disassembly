; --- reset_jump ---
; Clears the falling-object animation counter, stopping any active fall.
; No inputs or outputs.
reset_jump:
    mov byte [fall_counter],0x0
    ret

; --- animate_falling ---
; Per-frame update for falling objects (items dropped from ledges).
; Rate-limited to one update per BIOS tick. Picks a random target position,
; animates the object through a parabolic arc, and checks collision with the
; cat via check_jump_collision. Sets [fall_hit] if the cat is hit.
animate_falling:
    db 0x2a, 0xe4                       ; sub ah,ah
    int 0x1a                            ; BIOS Timer: Get tick count → CX:DX
    cmp dx,word [fall_last_tick]
    jnz lab_2221
lab_2220:
    ret
lab_2221:
    db 0x8b, 0xca                       ; mov cx,dx
    call check_vsync                           ;undefined check_vsync()
    jz lab_2220
    mov word [fall_last_tick],cx
    call check_jump_collision                           ;undefined check_jump_collision()
    jc lab_2220
    cmp byte [fall_counter],0x0
    jnz lab_226d
    cmp byte [cat_y],0x86
    jz lab_224e
    cmp byte [cat_y],0x8e
    jz lab_224e
    call random                           ;undefined random()
    cmp dl,0x5
    ja lab_2220
lab_224e:
    call pick_random_target                           ;undefined pick_random_target()
    add dl,0x3
    mov byte [fall_target_y],dl
    call random                           ;undefined random()
    db 0x81, 0xe2, 0x07, 0x00           ; and dx,0x7
    db 0x03, 0xca                       ; add cx,dx
    add cx,0x6
    mov word [fall_target_x],cx
    mov byte [fall_counter],0x1b
lab_226d:
    dec byte [fall_counter]
    mov cx,word [fall_target_x]
    mov dl,byte [fall_target_y]
    cmp byte [fall_counter],0xd
    jbe lab_2291
    add dl,byte [fall_counter]
    sub dl,0xf
    mov bx,0x1b02
    sub bh,byte [fall_counter]
    jmp short lab_229f
    db 0x90
lab_2291:
    add dl,0xc
    sub dl,byte [fall_counter]
    mov bx,0x2
    add bh,byte [fall_counter]
lab_229f:
    mov word [fall_sprite_dims],bx
    mov byte [fall_cur_y],dl
    call calc_cga_addr                           ;undefined calc_cga_addr()
    mov [fall_cga_addr],ax
    call erase_jump_sprite                           ;undefined erase_jump_sprite()
    call check_jump_collision                           ;undefined check_jump_collision()
    jc lab_22bc
    cmp byte [fall_counter],0x0
    jnz lab_22bd
lab_22bc:
    ret
lab_22bd:
    mov ax,0xb800
    mov es,ax
    mov di,word [fall_cga_addr]
    mov si,fall_sprite
    mov word [fall_draw_pos],di
    mov cx,word [fall_sprite_dims]
    mov word [fall_save_dims],cx
    mov bp,fall_save_buf
    call blit_transparent                           ;undefined blit_transparent()
    ret

; --- erase_jump_sprite ---
erase_jump_sprite:
    cmp byte [fall_counter],0x1a
    jz lab_22f6
    mov ax,0xb800
    mov es,ax
    mov di,word [fall_draw_pos]
    mov si,fall_save_buf
    mov cx,word [fall_save_dims]
    call blit_to_cga                           ;undefined blit_to_cga()
lab_22f6:
    ret

; --- check_jump_collision ---
check_jump_collision:
    cmp byte [fall_counter],0x0
    jnz lab_2300
    clc
    ret
lab_2300:
    mov cx,word [fall_sprite_dims]
    db 0x86, 0xe9                       ; xchg cl,ch
    mov ax,[fall_target_x]
    mov dl,byte [fall_cur_y]
    mov si,0x10
    mov bx,word [cat_x]
    mov dh,byte [cat_y]
    mov di,0x18
    mov ch,0xe
    call check_rect_collision                           ;undefined check_rect_collision()
    jnc lab_2327
    mov byte [fall_hit],0x1
lab_2327:
    ret
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00

; --- init_objects ---
; Initializes 3 cycling enemy objects (rats/spiders that patrol horizontally).
; Sets starting x-positions based on which side of the screen the cat is on:
;   cat_x <= 0xA0: objects start at x=0, moving right
;   cat_x >  0xA0: objects start at x=0x12C, moving left
; Clears all animation and hit state for the 3 object slots.
init_objects:
    mov word [obj_slot],0x0
    db 0x2b, 0xc0                       ; sub ax,ax
    mov dl,0x1
    cmp word [cat_x],0xa0
    ja lab_2347
    mov ax,0x12c
    mov dl,0xff
lab_2347:
    mov [obj_x],ax
    mov [obj_x + 2],ax
    mov [obj_x + 4],ax
    mov byte [obj_dir],dl
    mov byte [obj_dir + 1],dl
    mov byte [obj_dir + 2],dl
    mov byte [obj_hidden],0x1
    mov byte [obj_hidden + 1],0x1
    mov byte [obj_hidden + 2],0x1
    mov byte [obj_hit],0x0
    mov byte [obj_hit + 1],0x0
    mov byte [obj_hit + 2],0x0
    ret

; --- cycle_animations ---
; Per-frame update for the 3 cycling patrol objects in the alley.
; Rate-limited to one update per BIOS tick. Round-robins through the 3 object
; slots. For each active object: applies movement AI (chases cat when on same
; floor, otherwise random direction), updates position, draws/erases sprites,
; and checks collision with the cat and gravity objects.
; On cat collision: triggers knockback animation, awards score, plays tone.
cycle_animations:
    db 0x2a, 0xe4                       ; sub ah,ah
    int 0x1a                            ; BIOS Timer: Get tick count → CX:DX
    cmp dx,word [obj_last_tick]
    jnz lab_2386
lab_2385:
    ret
lab_2386:
    mov word [obj_last_tick],dx
    cmp byte [transitioning],0x0
    jnz lab_2385
    mov bx,word [obj_slot]
    inc bx
    cmp bx,0x3
    jc lab_239e
    mov bx,0x0
lab_239e:
    mov word [obj_slot],bx
    call check_cycle_gravity_hit                           ;undefined check_cycle_gravity_hit()
    jc lab_2385
    call check_cycle_cat_collision                           ;undefined check_cycle_cat_collision()
    jc lab_2385
    mov bx,word [obj_slot]
    cmp byte [bx + obj_hit],0x0
    jz lab_23eb
    db 0x2a, 0xe4                       ; sub ah,ah
    int 0x1a                            ; BIOS Timer: Get tick count → CX:DX
    mov bx,word [obj_slot]
    shl bl,0x1
    sub dx,word [bx + obj_hit_tick]
    cmp dx,0x36
    jc lab_2385
    mov dl,0x1
    mov ax,0x0
    cmp word [cat_x],0xa0
    ja lab_23dc
    mov ax,0x12c
    mov dl,0xff
lab_23dc:
    mov word [bx + obj_x],ax
    shr bl,0x1
    mov byte [bx + obj_hit],0x0
    mov byte [bx + obj_dir],dl
lab_23eb:
    mov dl,byte [bx + obj_dir]
    mov byte [bx + obj_prev_dir],dl
    cmp byte [cycle_active],0x0
    jz lab_2403
    mov word [obj_speed],0xc
    jmp short lab_2418
    db 0x90
lab_2403:
    mov ax,0x8
    cmp byte [cat_y],0x60
    jbe lab_240f
    shr al,0x1
lab_240f:
    mov [obj_speed],ax
    cmp bx,word [current_floor]
    jnz lab_2425
lab_2418:
    cmp byte [bx + obj_dir],0x0
    jnz lab_2425
    call random                           ;undefined random()
    jmp short lab_248a
    db 0x90
lab_2425:
    cmp byte [at_platform],0x0
    jz lab_2466
    mov al,byte [bx + obj_y]
    cmp al,byte [cat_y]
    ja lab_2466
    add al,0x10
    cmp al,byte [cat_y]
    jc lab_2466
    call random                           ;undefined random()
    mov si,word [difficulty_level]
    cmp dl,byte [si + obj_chase_table]
    ja lab_2466
    mov word [obj_speed],0xc
    mov al,0x1
    shl bl,0x1
    mov cx,word [bx + obj_x]
    shr bl,0x1
    cmp cx,word [cat_x]
    jc lab_2463
    mov al,0xff
lab_2463:
    jmp short lab_2492
    db 0x90
lab_2466:
    mov cl,0x18
    cmp byte [cat_y],0x60
    jbe lab_247a
    mov cl,0x28
    cmp byte [bx + obj_dir],0x0
    jnz lab_247a
    mov cl,0x10
lab_247a:
    call random                           ;undefined random()
    db 0x3a, 0xd1                       ; cmp dl,cl
    ja lab_2496
    mov al,0x0
    cmp byte [bx + obj_dir],0x0
    jnz lab_2492
lab_248a:
    db 0x8a, 0xc2                       ; mov al,dl
    and al,0x1
    jnz lab_2492
    mov al,0xff
lab_2492:
    mov byte [bx + obj_dir],al
lab_2496:
    mov dl,byte [bx + obj_dir]
    shl bl,0x1
    mov ax,word [bx + obj_x]
    cmp dl,0x1
    jc lab_24c2
    jnz lab_24b8
    add ax,word [obj_speed]
    cmp ax,0x12f
    jc lab_24c2
    mov ax,0x12e
    mov dl,0xff
    jmp short lab_24c2
    db 0x90
lab_24b8:
    sub ax,word [obj_speed]
    jnc lab_24c2
    db 0x2b, 0xc0                       ; sub ax,ax
    mov dl,0x1
lab_24c2:
    mov word [bx + obj_x],ax
    shr bl,0x1
    mov byte [bx + obj_dir],dl
    mov dl,byte [bx + obj_y]
    db 0x8b, 0xc8                       ; mov cx,ax
    call calc_cga_addr                           ;undefined calc_cga_addr()
    mov [obj_cga_tmp],ax
    mov bx,word [obj_slot]
    cmp byte [bx + obj_hidden],0x0
    jnz lab_24f0
    mov al,byte [bx + obj_dir]
    or al,byte [bx + obj_prev_dir]
    jz lab_24f0
    call erase_cycle_sprite                           ;undefined erase_cycle_sprite()
lab_24f0:
    call check_cycle_gravity_hit                           ;undefined check_cycle_gravity_hit()
    jc lab_24fa
    call check_cycle_cat_collision                           ;undefined check_cycle_cat_collision()
    jnc lab_24fb
lab_24fa:
    ret
lab_24fb:
    mov bx,word [obj_slot]
    mov byte [bx + obj_hidden],0x0
    cmp byte [bx + obj_dir],0x0
    jnz lab_2518
    cmp byte [bx + obj_prev_dir],0x0
    jz lab_254c
    mov si,cycle_idle_sprite
    jmp short lab_2533
    db 0x90
lab_2518:
    mov si,cycle_walk_sprite
    inc byte [bx + obj_anim_toggle]
    test byte [bx + obj_anim_toggle],0x1
    jnz lab_2529
    add si,0x20
lab_2529:
    cmp byte [bx + obj_dir],0x1
    jz lab_2533
    add si,0x40
lab_2533:
    shl bl,0x1
    mov di,word [obj_cga_tmp]
    mov word [bx + obj_draw_pos],di
    mov ax,0xb800
    mov es,ax
    mov bp,word [bx + obj_save_buf]
    mov cx,0x802
    call blit_masked                           ;undefined blit_masked()
lab_254c:
    ret

; --- erase_cycle_sprite ---
erase_cycle_sprite:
    mov bx,word [obj_slot]
    shl bl,0x1
    mov ax,0xb800
    mov es,ax
    mov di,word [bx + obj_draw_pos]
    mov si,word [bx + obj_save_buf]
    mov cx,0x802
    call blit_to_cga                           ;undefined blit_to_cga()
    ret

; --- check_cycle_cat_collision ---
check_cycle_cat_collision:
    mov bx,word [obj_slot]
    mov dl,byte [bx + obj_y]
    shl bl,0x1
    mov ax,word [bx + obj_x]
    mov si,0x10
    mov bx,word [cat_x]
    mov dh,byte [cat_y]
    mov di,0x18
    mov cx,0xe08
    call check_rect_collision                           ;undefined check_rect_collision()
    jc lab_258e
    jmp near lab_265d
lab_258e:
    mov bx,word [obj_slot]
    cmp byte [bx + obj_hit],0x0
    jnz lab_260c
    cmp byte [cat_y_bottom],0x26
    jc lab_260c
    cmp byte [at_platform],0x0
    jz lab_260e
    mov byte [at_platform],0x0
    mov byte [transition_timer],0x11
    mov byte [in_level_mode],0x1
    mov byte [scroll_direction],0x0
    mov bx,word [obj_slot]
    shl bl,0x1
    mov di,word [bx + obj_draw_pos]
    cmp word [bx + obj_x],0x10
    jc lab_25cf
    sub di,0x4
lab_25cf:
    mov word [obj_collision_pos],di
    mov ax,0xb800
    mov es,ax
    mov si,collision_sprite
    mov bp,0xe
    mov cx,0x806
    call blit_transparent                           ;undefined blit_transparent()
    db 0x2a, 0xe4                       ; sub ah,ah
    int 0x1a                            ; BIOS Timer: Get tick count → CX:DX
    mov word [obj_last_tick],dx
lab_25ec:
    call play_random_noise                           ;undefined play_random_noise()
    db 0x2a, 0xe4                       ; sub ah,ah
    int 0x1a                            ; BIOS Timer: Get tick count → CX:DX
    sub dx,word [obj_last_tick]
    cmp dx,0x8
    jc lab_25ec
    call silence_speaker                           ;undefined silence_speaker()
    mov di,word [obj_collision_pos]
    mov si,0xe
    mov cx,0x806
    call blit_to_cga                           ;undefined blit_to_cga()
lab_260c:
    stc
    ret
lab_260e:
    db 0x2a, 0xe4                       ; sub ah,ah
    int 0x1a                            ; BIOS Timer: Get tick count → CX:DX
    mov bx,word [obj_slot]
    mov byte [bx + obj_hit],0x1
    mov byte [bx + obj_dir],0x1
    shl bl,0x1
    mov word [bx + obj_hit_tick],dx
    call restore_alley_buffer                           ;undefined restore_alley_buffer()
    mov bx,word [obj_slot]
    shl bl,0x1
    mov si,word [bx + obj_hit_sprite]
    mov di,word [bx + obj_draw_pos]
    mov ax,0xb800
    mov es,ax
    mov bp,0xe
    mov cx,0x802
    call blit_transparent                           ;undefined blit_transparent()
    call save_alley_buffer                           ;undefined save_alley_buffer()
    mov bx,word [obj_slot]
    mov al,byte [bx + obj_score]
    call add_score                           ;undefined add_score()
    mov ax,0x3e8
    mov bx,0x2ee
    call start_tone                           ;undefined start_tone()
    stc
lab_265d:
    ret

; --- check_cycle_gravity_hit ---
check_cycle_gravity_hit:
    cmp byte [gravity_y],0x0
    jnz lab_2667
    clc
    ret
lab_2667:
    mov bx,word [obj_slot]
    mov dl,byte [bx + obj_y]
    shl bl,0x1
    mov ax,word [bx + obj_x]
    mov si,0x10
    db 0x8b, 0xfe                       ; mov di,si
    mov bx,word [gravity_x]
    mov dh,byte [gravity_y]
    mov cx,0xc08
    call check_rect_collision                           ;undefined check_rect_collision()
    ret
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00


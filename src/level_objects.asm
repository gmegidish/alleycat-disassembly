; --- check_rect_collision ---
; AABB overlap test between two rectangles.
; Input:
;   AX = rect A x position (word)
;   DL = rect A y position (byte)
;   SI = rect A width
;   CL = rect A height
;   BX = rect B x position (word)
;   DH = rect B y position (byte)
;   DI = rect B width
;   CH = rect B height
; Output:
;   CF = 1 if collision (rectangles overlap), 0 if no collision
check_rect_collision:
    db 0x03, 0xc6                       ; add ax,si
    db 0x3b, 0xc3                       ; cmp ax,bx
    jc lab_2e4f                         ; if A.right < B.x → no overlap
    db 0x2b, 0xc6                       ; sub ax,si
    db 0x2b, 0xc7                       ; sub ax,di
    jnc lab_2e37                        ; clamp (A.x - B.width) to 0
    db 0x2b, 0xc0                       ; sub ax,ax
lab_2e37:
    db 0x3b, 0xc3                       ; cmp ax,bx
    ja lab_2e4f                         ; if A.x - B.width > B.x → no overlap
    db 0x02, 0xd1                       ; add dl,cl
    db 0x3a, 0xd6                       ; cmp dl,dh
    jc lab_2e4f                         ; if A.bottom < B.y → no overlap
    db 0x2a, 0xd1                       ; sub dl,cl
    db 0x2a, 0xd5                       ; sub dl,ch
    jnc lab_2e49                        ; clamp (A.y - B.height) to 0
    db 0x2a, 0xd2                       ; sub dl,dl
lab_2e49:
    db 0x3a, 0xd6                       ; cmp dl,dh
    ja lab_2e4f                         ; if A.y - B.height > B.y → no overlap
    stc                                 ; collision detected
    ret
lab_2e4f:
    clc                                 ; no collision
    ret
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
spawn_thrown_object:
    cmp word [l7_obj_spawn_slot],0x8
    jb short lab_2e68
lab_2e67:
    ret
lab_2e68:
    cmp byte [0x69a],0x0
    jnz short lab_2e67
    mov word [l7_obj_closest_row],0xffff
    mov byte [l7_obj_closest_dist],0xff
    mov cx,0x7
lab_2e7d:
    db 0x8b, 0xd9                       ; mov bx,cx
    dec bx
    mov al,[0x57b]
    sub al,[bx+window_row_y_table]
    jnb short lab_2e8b
    not al
lab_2e8b:
    cmp al,[l7_obj_closest_dist]
    ja short lab_2e98
    mov [l7_obj_closest_dist],al
    mov [l7_obj_closest_row],bx
lab_2e98:
    loop short lab_2e7d
    db 0x81, 0x3e, 0x92, 0x2e, 0xff, 0xff ; cmp word [0x2e92],0xffff
    jnz short lab_2ea8
    mov word [l7_obj_closest_row],0x0
lab_2ea8:
    mov bx,[l7_obj_spawn_slot]
    mov si,[l7_obj_closest_row]
    mov al,[si+window_row_y_table]
    mov [bx+l7_obj_y],al
    mov [l7_obj_cur_y],al
    mov ax,[0x579]
    db 0xd0, 0xe3                       ; shl bl,0x0
    cmp ax,0x108
    jb short lab_2ec8
    mov ax,0x107
lab_2ec8:
    and ax,0xffc
    mov [bx+l7_obj_x],ax
    mov [l7_obj_cur_x],ax
    mov cx,0x8
lab_2ed5:
    db 0x8b, 0xd9                       ; mov bx,cx
    dec bx
    cmp bx,[l7_obj_spawn_slot]
    jz short lab_2f07
    cmp byte [bx+l7_obj_active],0x0
    jz short lab_2f07
    push cx
    mov dl,[bx+l7_obj_y]
    db 0xd0, 0xe3                       ; shl bl,0x0
    mov ax,[bx+l7_obj_x]
    mov bx,[l7_obj_cur_x]
    mov dh,[l7_obj_cur_y]
    mov si,0x18
    db 0x8b, 0xfe                       ; mov di,si
    mov cx,0xf0f
    call check_rect_collision
    pop cx
    jnb short lab_2f07
    ret
lab_2f07:
    loop short lab_2ed5
    call restore_alley_buffer
    cmp byte [cupid_active],0x0
    jz short lab_2f16
    call erase_cupid
lab_2f16:
    mov bx,[l7_obj_spawn_slot]
    mov [l7_obj_last_picked],bx
    mov byte [bx+l7_obj_active],0x1
    mov dl,[bx+l7_obj_y]
    db 0xd0, 0xe3                       ; shl bl,0x0
    mov cx,[bx+l7_obj_x]
    call calc_cga_addr
    db 0x8b, 0xf8                       ; mov di,ax
    mov si,l7_obj_sprite
    mov ax,0xb800
    mov es,ax
    mov cx,0xf03
    call blit_to_cga
    mov word [l7_obj_spawn_slot],0xffff
    db 0x2b, 0xdb                       ; sub bx,bx
    mov ah,0xb
    int byte 0x10
    call check_l7_all_objects
    cmp byte [cupid_active],0x0
    jz short lab_2f59
    call draw_cupid
lab_2f59:
    call draw_alley_foreground
    mov ax,0x3e8
    mov bx,0x4a5
    call start_tone
    ret
tick_level_thrown_objects:
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    cmp dx,[l7_obj_last_tick]
    jnz short lab_2f71
    ret
lab_2f71:
    mov [l7_obj_last_tick],dx
    cmp word [l7_obj_spawn_slot],0x8
    jb short lab_2fac
    mov cx,0x8
lab_2f7f:
    db 0x8b, 0xd9                       ; mov bx,cx
    dec bx
    cmp byte [bx+l7_obj_active],0x0
    jz short lab_2faa
    push cx
    mov dl,[bx+l7_obj_y]
    db 0xd0, 0xe3                       ; shl bl,0x0
    mov ax,[bx+l7_obj_x]
    mov si,0x18
    db 0x8b, 0xfe                       ; mov di,si
    mov bx,[0x579]
    mov dh,[0x57b]
    mov cx,0xe0f
    call check_rect_collision
    pop cx
    jb short lab_2fb3
lab_2faa:
    loop short lab_2f7f
lab_2fac:
    mov word [l7_obj_last_picked],0xffff
lab_2fb2:
    ret
lab_2fb3:
    db 0x8b, 0xd9                       ; mov bx,cx
    dec bx
    cmp bx,[l7_obj_last_picked]
    jz short lab_2fb2
    push bx
    call restore_alley_buffer
    cmp byte [cupid_active],0x0
    jz short lab_2fca
    call erase_cupid
lab_2fca:
    pop bx
    mov byte [bx+l7_obj_active],0x0
    mov dl,[bx+l7_obj_y]
    mov [l7_obj_spawn_slot],bx
    db 0xd0, 0xe3                       ; shl bl,0x0
    mov cx,[bx+l7_obj_x]
    call calc_cga_addr
    db 0x8b, 0xf8                       ; mov di,ax
    mov si,l7_obj_erase_sprite
    mov ax,0xb800
    mov es,ax
    mov cx,0xf03
    call blit_to_cga
    cmp byte [cupid_active],0x0
    jz short lab_2ffb
    call draw_cupid
lab_2ffb:
    call draw_alley_foreground
    mov bx,0x1
    mov ah,0xb
    int byte 0x10
    mov ax,0x3e8
    mov bx,0x349
    call start_tone
    ret
draw_love_scene_bg:
    db 0x2b, 0xc0                       ; sub ax,ax
    mov bx,l7_bg_block_list
    call draw_block_list
    mov byte [l7_obj_draw_y],0xbf
    mov word [l7_obj_row_index],0x0
lab_3022:
    mov word [l7_obj_draw_x],0x20
lab_3028:
    db 0x2b, 0xdb                       ; sub bx,bx
    cmp byte [l7_obj_draw_y],0xbf
    jz short lab_3039
    call random
    db 0x8a, 0xda                       ; mov bl,dl
    and bl,0x2
lab_3039:
    mov cx,[l7_obj_draw_x]
    mov dl,[l7_obj_draw_y]
    push bx
    call draw_bg_tile
    pop bx
    mov si,[l7_obj_row_index]
    mov ax,[l7_obj_draw_x]
    mov cl,0x4
    shr ax,cl
    db 0x2d, 0x02, 0x00                 ; sub ax,0x2
    jnb short lab_3058
    db 0x2b, 0xc0                       ; sub ax,ax
lab_3058:
    db 0x3d, 0x12, 0x00                 ; cmp ax,0x12
    jb short lab_3060
    mov ax,0x11
lab_3060:
    mov dl,[si+window_row_col_offset]
    db 0x2a, 0xf6                       ; sub dh,dh
    db 0x03, 0xc2                       ; add ax,dx
    db 0x8b, 0xf0                       ; mov si,ax
    mov [si+window_open_state],bl
    add word [l7_obj_draw_x],0x10
    cmp word [l7_obj_draw_x],0x111
    jb short lab_3028
    inc word [l7_obj_row_index]
    sub byte [l7_obj_draw_y],0x18
    cmp byte [l7_obj_draw_y],0x2f
    jnb short lab_3022
    mov ax,0xffff
    mov [l7_obj_spawn_slot],ax
    mov [l7_obj_last_picked],ax
    db 0x2b, 0xc0                       ; sub ax,ax
    mov [l7_obj_active],ax
    mov [l7_obj_active_2],ax
    mov [l7_obj_active_4],ax
    mov [l7_obj_active_6],ax
    mov cx,[0x414]
    cmp cx,0x0
    jnz short lab_30b0
    inc cx
    mov [0x414],cx
lab_30b0:
    cmp cx,0x8
    jbe short lab_30b8
    mov cx,0x8
lab_30b8:
    db 0x8b, 0xd9                       ; mov bx,cx
    dec bx
    mov byte [bx+l7_obj_active],0x1
    mov dl,0xb0
    mov [bx+l7_obj_y],dl
    push cx
    db 0xd0, 0xe3                       ; shl bl,0x0
    mov cx,[bx+l7_obj_init_x_table]
    mov [bx+l7_obj_x],cx
    call calc_cga_addr
    db 0x8b, 0xf8                       ; mov di,ax
    mov si,l7_obj_sprite
    mov cx,0xf03
    call blit_to_cga
    pop cx
    loop short lab_30b8
    ret
draw_bg_tile:
    push bx
    call calc_cga_addr
    db 0x8b, 0xf8                       ; mov di,ax
    mov ax,0xb800
    mov es,ax
    pop bx
    mov si,[bx+l7_bg_tile_ptrs]
    mov cx,0x802
    call blit_to_cga
    ret

; --- check_stairs_collision ---
check_stairs_collision:
    mov al,[cat_y]
    sub al,0x5
    and al,0xf8
    mov cx,0x7
lab_3104:
    db 0x8b, 0xd9                       ; mov bx,cx
    dec bx
    cmp al,byte [bx + window_row_y_table]
    jz lab_3111
    loop lab_3104
    jmp short lab_314d
lab_3111:
    db 0x8a, 0xe8                       ; mov ch,al
    mov ax,[cat_x]
    db 0x05, 0x07, 0x00                 ; add ax,0x7
    mov cl,0x4
    shr ax,cl
    db 0x2d, 0x02, 0x00                 ; sub ax,0x2
    jnc lab_3124
    db 0x2b, 0xc0                       ; sub ax,ax
lab_3124:
    db 0x3d, 0x12, 0x00                 ; cmp ax,0x12
    jc lab_312c
    mov ax,0x11
lab_312c:
    mov dl,byte [bx + window_row_col_offset]
    db 0x2a, 0xf6                       ; sub dh,dh
    db 0x03, 0xc2                       ; add ax,dx
    db 0x8b, 0xf0                       ; mov si,ax
    cmp byte [si + window_open_state],0x0
    jnz lab_314d
    add ch,0x5
    mov byte [cat_y],ch
    add ch,0x32
    mov byte [cat_y_bottom],ch
    stc
    ret
lab_314d:
    clc
    ret
    db 0x00
; --- lab_3150 ---
; Thrown objects tick handler. Rate-limited per level (timing from table
; at 0x32F2 indexed by level_number). Spawns and updates thrown objects
; (shoes, bottles, etc.) that fall from windows in alley/level scenes.
tick_thrown_objects:
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    mov bx,[0x4]
    db 0xd0, 0xe3                       ; shl bl,0x0
    mov cx,[bx+dat_32f2]
    db 0x8b, 0xc2                       ; mov ax,dx
    sub ax,[dat_328c]
    db 0x3b, 0xc1                       ; cmp ax,cx
    jnb short lab_3169
lab_3168:
    ret
lab_3169:
    mov [dat_328c],dx
    call check_thrown_cat_hit
    jb short lab_3168
    call check_enemy_object_hit
    jb short lab_3168
    inc byte [dat_32ea]
    call random
    mov al,[dat_32ea]
    db 0x22, 0xc2                       ; and al,dl
    xor [dat_32eb],al
    mov ax,[thrown_obj_x]
    sub ax,[0x579]
    mov dl,0xff
    jnb short lab_3196
    not ax
    mov dl,0x1
lab_3196:
    mov [dat_32ed],dl
    mov bl,[thrown_obj_y]
    add bl,0x14
    sub bl,[0x57b]
    mov dl,0xff
    jnb short lab_31ad
    not bl
    mov dl,0x1
lab_31ad:
    mov [dat_32ee],dl
    db 0xd1, 0xe8                       ; shr ax,0x0
    db 0xd1, 0xe8                       ; shr ax,0x0
    db 0xd0, 0xeb                       ; shr bl,0x0
    db 0x02, 0xc3                       ; add al,bl
    mov [dat_32ec],al
    mov bx,[dat_328a]
    cmp bx,0x27
    jb short lab_31cc
    mov bx,0x26
    mov [dat_328a],bx
lab_31cc:
    cmp byte [bx+l1_bg_sprite],0x0
    jnz short lab_324b
    dec word [dat_328a]
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    sub dx,[0x410]
    mov cl,0x3
    shr dx,cl
    mov al,[dat_32ec]
    db 0x2a, 0xc2                       ; sub al,dl
    jnb short lab_31ec
    db 0x2a, 0xc0                       ; sub al,al
lab_31ec:
    cmp al,[dat_32eb]
    jb short lab_3212
    mov byte [dat_3281],0x1
    call random
    cmp dl,0x0
    jz short lab_320b
    cmp dl,0x7
    ja short lab_320f
    and dl,0x1
    jnz short lab_320b
    mov dl,0xff
lab_320b:
    mov [dat_3280],dl
lab_320f:
    jmp near lab_32ac
lab_3212:
    mov al,[dat_32eb]
    and al,0x2f
    jnz short lab_3238
    call random
    and dl,0x1
    jnz short lab_3223
    mov dl,0xff
lab_3223:
    mov [dat_3280],dl
    call random
    and dl,0x1
    jnz short lab_3231
    mov dl,0xff
lab_3231:
    mov [dat_3281],dl
    jmp short lab_32ac
    nop
lab_3238:
    and al,0x7
    jnz short lab_32ac
    mov al,[dat_32ed]
    mov [dat_3280],al
    mov al,[dat_32ee]
    mov [dat_3281],al
    jmp short lab_32ac
    nop
lab_324b:
    mov byte [dat_3281],0x1
    db 0x8b, 0xc3                       ; mov ax,bx
    mov cl,0x3
    shl ax,cl
    cmp [thrown_obj_x],ax
    jz short lab_3269
    mov dl,0x1
    jb short lab_3262
    mov dl,0xff
lab_3262:
    mov [dat_3280],dl
    jmp short lab_32ac
    nop
lab_3269:
    mov byte [dat_3280],0x0
    cmp byte [thrown_obj_y],0xa5
    jnz short lab_32ac
    mov byte [dat_3281],0x0
    cmp word [dat_327a],0x6
    jz short lab_3288
    cmp word [dat_327a],0x12
    jnz short lab_32ac
lab_3288:
    push bx
    mov si,l1_sprite_data
    mov di,[dat_3282]
    mov cx,0x1e02
    mov ax,0xb800
    mov es,ax
    call blit_to_cga
    pop bx
    dec byte [bx+l1_bg_sprite]
    mov al,[bx+l1_bg_sprite]
    call draw_footprint_tile
    mov byte [dat_3286],0x1
lab_32ac:
    mov cx,[thrown_obj_x]
    mov dl,[thrown_obj_y]
    mov [dat_32ef],cx
    mov [dat_32f1],dl
    cmp byte [dat_3280],0x1
    jb short lab_32da
    jnz short lab_32d3
    add cx,0x8
    cmp cx,0x131
    jb short lab_32da
    mov cx,0x130
    jmp short lab_32da
lab_32d3:
    sub cx,0x8
    jnb short lab_32da
    db 0x2b, 0xc9                       ; sub cx,cx
lab_32da:
    db 0x81, 0xe1, 0xf8, 0xff           ; and cx,0xfff8
    mov [thrown_obj_x],cx
    cmp byte [dat_3281],0x1
    jb short lab_32fe
    jnz short lab_32f7
    add dl,0x2
    cmp dl,0xa6
    jb short lab_32fe
    mov dl,0xa5
    jmp short lab_32fe
lab_32f7:
    sub dl,0x2
    jnb short lab_32fe
    db 0x2a, 0xd2                       ; sub dl,dl
lab_32fe:
    mov [thrown_obj_y],dl
    call calc_cga_addr
    mov [dat_3284],ax
    call check_thrown_cat_hit
    jnb short lab_3328
lab_330d:
    mov byte [dat_3280],0x0
    mov byte [dat_3281],0x0
    mov cx,[dat_32ef]
    mov [thrown_obj_x],cx
    mov dl,[dat_32f1]
    mov [thrown_obj_y],dl
    ret
lab_3328:
    call check_enemy_object_hit
    jb short lab_330d
    call erase_thrown_sprite
    add word [dat_327a],0x2
    call draw_thrown_sprite
    ret
draw_thrown_sprite:
    mov bx,[dat_327a]
    mov ax,[bx+dat_3260]
    db 0x3d, 0x00, 0x00                 ; cmp ax,0x0
    jnz short lab_334b
    mov [dat_327a],ax
    jmp short draw_thrown_sprite
lab_334b:
    db 0x8b, 0xf0                       ; mov si,ax
    mov di,[dat_3284]
    mov [dat_3282],di
    mov bp,l1_sprite_data
    mov ax,0xb800
    mov es,ax
    mov cx,0x1e02
    mov byte [dat_3286],0x0
    cld
    mov [dat_3289],ch
    db 0x2a, 0xed                       ; sub ch,ch
    mov [dat_3287],cx
lab_3370:
    mov cx,[dat_3287]
lab_3374:
    mov bx,[es:di]
    mov [ds:bp+0x0],bx
    lodsw
    db 0x0b, 0xc3                       ; or ax,bx
    stosw
    add bp,0x2
    loop short lab_3374
    sub di,[dat_3287]
    sub di,[dat_3287]
    xor di,0x2000
    test di,0x2000
    jnz short lab_3399
    add di,0x50
lab_3399:
    dec byte [dat_3289]
    jnz short lab_3370
    ret
erase_thrown_sprite:
    cmp byte [dat_3286],0x0
    jnz short lab_33b9
    mov ax,0xb800
    mov es,ax
    mov si,l1_sprite_data
    mov di,[dat_3282]
    mov cx,0x1e02
    call blit_to_cga
lab_33b9:
    ret
check_thrown_cat_hit:
    cmp byte [enemy_active],0x0
    jnz short lab_3403
    cmp word [0x4],0x6
    jnz short lab_33d3
    cmp byte [dat_44bd],0x0
    jz short lab_33d3
    call check_thrown_near_cat
    ret
lab_33d3:
    mov ax,[thrown_obj_x]
    mov dl,[thrown_obj_y]
    mov si,0x10
    mov bx,[0x579]
    mov dh,[0x57b]
    mov di,0x18
    mov cx,0xe1e
    call check_rect_collision
    jnb short lab_3403
    cmp word [0x4],0x4
    jnz short lab_33fe
    cmp byte [l3_door_anim_frame],0x0
    jnz short lab_3401
lab_33fe:
    call start_auto_walk
lab_3401:
    stc
    ret
lab_3403:
    clc
    ret
; --- lab_3405 ---
; Initializes the thrown objects subsystem. Zeros the object slots,
; resets spawn timers and positions. Called at the start of each level.
init_thrown_objects:
    cld
    db 0x2b, 0xc0                       ; sub ax,ax
    push ds
    pop es
    mov di,l1_bg_sprite
    mov cx,0x14
    rep stosw
    mov word [dat_32b6],0xff
    mov word [dat_327a],0x0
    mov word [thrown_obj_x],0x0
    mov byte [thrown_obj_y],0xa0
    mov byte [dat_3286],0x1
    mov byte [dat_3280],0x0
    mov byte [dat_3281],0x0
    call random
    mov [dat_32eb],dl
    mov byte [dat_32ea],0x6c
    ret

; --- update_footprint ---
update_footprint:
    cmp byte [cat_y],0xb4
    jc lab_347e
    cmp byte [scroll_direction],0x0
    jz lab_347e
    mov ax,[cat_x]
    db 0x05, 0x0c, 0x00                 ; add ax,0xc
    mov cl,0x3
    shr ax,cl
    db 0x3d, 0x27, 0x00                 ; cmp ax,0x27
    ja lab_347e
    cmp ax,word [dat_32b6]
    jz lab_347e
    mov [dat_32b6],ax
    db 0x8b, 0xd8                       ; mov bx,ax
    mov al,byte [bx + l1_bg_sprite]
    cmp al,0x4
    jnc lab_347e
    inc al
    mov byte [bx + l1_bg_sprite],al
    call draw_footprint_tile                           ;undefined draw_footprint_tile()
lab_347e:
    ret

; --- draw_footprint_tile ---
draw_footprint_tile:
    mov ah,0xa
    mul ah
    add ax,l1_obj_sprites
    db 0x8b, 0xf0                       ; mov si,ax
    db 0x8b, 0xfb                       ; mov di,bx
    shl di,0x1
    add di,dat_1e00
    mov ax,0xb800
    mov es,ax
    mov cx,0x501
    call blit_to_cga                           ;undefined blit_to_cga()
    ret
    db 0x00, 0x00, 0x00, 0x00

; --- check_level_objects ---
check_level_objects:
    mov word [dat_3511],0x0
    mov byte [dat_351b],0x0
lab_34ab:
    mov bx,word [dat_3511]
    cmp byte [bx + l2_obj_active],0x0
    jz lab_34b9
lab_34b6:
    jmp near lab_35ad
lab_34b9:
    db 0x8b, 0xf3                       ; mov si,bx
    shl si,0x1
    mov ax,word [si + l2_obj_x]
    mov dl,byte [bx + l2_obj_y]
    mov di,0x0
    cmp bx,0xc
    jc lab_34d0
    mov di,0x2
lab_34d0:
    mov si,word [di + dat_3513]
    mov cx,word [di + dat_3517]
    mov bx,word [cat_x]
    mov dh,byte [cat_y]
    mov di,0x18
    mov ch,0xe
    call check_rect_collision                           ;undefined check_rect_collision()
    jnc lab_34b6
    mov bx,word [dat_3511]
    cmp bx,0xc
    jc lab_356f
    cmp byte [cat_caught],0x0
    jnz lab_356f
    cmp byte [immune_flag],0x0
    jnz lab_356f
    mov byte [object_hit],0x1
    mov cx,word [cat_x]
    sub cx,0x8
    jnc lab_3511
    db 0x2b, 0xc9                       ; sub cx,cx
lab_3511:
    cmp cx,0x117
    jc lab_351a
    mov cx,0x116
lab_351a:
    mov dl,byte [cat_y]
    cmp dl,0xb5
    jc lab_3525
    mov dl,0xb4
lab_3525:
    call calc_cga_addr                           ;undefined calc_cga_addr()
    db 0x8b, 0xf8                       ; mov di,ax
    mov si,l1_anim_sprite_c
    mov ax,0xb800
    mov es,ax
    mov cx,0x1205
    call blit_to_cga                           ;undefined blit_to_cga()
    call reset_noise                           ;undefined reset_noise()
    db 0x2a, 0xe4                       ; sub ah,ah
    int 0x1a                            ; BIOS Timer: Get tick count → CX:DX
    mov word [dat_3509],dx
lab_3543:
    push dx
lab_3544:
    call update_noise                           ;undefined update_noise()
    call check_vsync                           ;undefined check_vsync()
    jz lab_3544
    call update_noise                           ;undefined update_noise()
    pop dx
    mov bx,0x1
    test dl,0x1
    jnz lab_355a
    mov bl,0xf
lab_355a:
    mov ah,0xb
    int 0x10                            ; BIOS Video: Set background/border color
    call update_noise                           ;undefined update_noise()
    db 0x2a, 0xe4                       ; sub ah,ah
    int 0x1a                            ; BIOS Timer: Get tick count → CX:DX
    sub dx,word [dat_3509]
    cmp dx,0xd
    jc lab_3543
    ret
lab_356f:
    inc byte [dat_351b]
    mov ax,0x5dc
    mov bx,0x425
    call start_tone                           ;undefined start_tone()
    cmp byte [dat_351b],0x1
    jnz lab_3586
    call restore_alley_buffer                           ;undefined restore_alley_buffer()
lab_3586:
    mov bx,word [dat_3511]
    call erase_level_object                           ;undefined erase_level_object()
    mov bx,word [dat_3511]
    mov byte [bx + l2_obj_active],0x1
    cmp bx,0xc
    jnc lab_35ad
    dec byte [dat_3410]
    jnz lab_35ad
    cmp byte [immune_flag],0x0
    jnz lab_35ad
    mov byte [cat_caught],0x1
lab_35ad:
    inc word [dat_3511]
    cmp word [dat_3511],0x18
    jnc lab_35bb
    jmp near lab_34ab
lab_35bb:
    cmp byte [dat_351b],0x0
    jz lab_35c7
    call reset_caught_objects                           ;undefined reset_caught_objects()
    stc
    ret
lab_35c7:
    clc
    ret
init_level2_objects:
    mov word [l2_anim_toggle],0x0
    mov word [dat_3415],0x0
    mov byte [dat_3410],0xc
    mov cx,0x18
lab_35dd:
    db 0x8b, 0xd9                       ; mov bx,cx
    dec bx
    mov byte [bx+l2_obj_hit],0x1
    mov byte [bx+l2_obj_active],0x0
    mov al,[bx+l2_obj_init_y]
    mov [bx+l2_obj_y],al
    mov byte [bx+dat_342f],0x1
    call random
    and dl,0x1
    jnz short lab_3601
    not dl
lab_3601:
    mov [bx+dat_3417],dl
    db 0xd1, 0xe3                       ; shl bx,0x0
    call random
    db 0x2a, 0xf6                       ; sub dh,dh
    mov [bx+l2_obj_x],dx
    loop short lab_35dd
    mov bx,[0x8]
    mov cl,[bx+dat_351c]
    db 0x2a, 0xed                       ; sub ch,ch
lab_361c:
    call random
    and dl,0xf
    cmp dl,0xc
    jnb short lab_361c
    db 0x8a, 0xda                       ; mov bl,dl
    add bl,0xc
    db 0x2a, 0xff                       ; sub bh,bh
    cmp byte [bx+l2_obj_active],0x0
    jnz short lab_361c
    mov byte [bx+l2_obj_active],0x1
    loop short lab_361c
    ret

; --- reset_caught_objects ---
reset_caught_objects:
    mov cx,0xc
lab_3640:
    db 0x8b, 0xd9                       ; mov bx,cx
    add bx,0xb
    cmp byte [bx + l2_obj_active],0x0
    jz lab_3672
    db 0x2b, 0xc0                       ; sub ax,ax
    mov dl,0x1
    mov byte [bx + l2_obj_active],al
    cmp word [cat_x],0xa0
    ja lab_3661
    mov ax,0x12e
    mov dl,0xff
lab_3661:
    mov byte [bx + dat_3417],dl
    shl bl,0x1
    mov word [bx + l2_obj_x],ax
    dec byte [dat_351b]
    jnz reset_caught_objects
    ret
lab_3672:
    loop lab_3640
    ret
update_level2_objects:
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    cmp dx,[dat_3509]
    jnz short lab_3680
lab_367f:
    ret
lab_3680:
    mov [dat_350b],dx
    inc word [dat_3415]
    mov bx,[dat_3415]
    cmp bx,0x18
    jb short lab_36a4
    db 0x2b, 0xdb                       ; sub bx,bx
    mov [dat_3415],bx
    db 0x81, 0x36, 0x11, 0x34, 0x0c, 0x00 ; xor word [0x3411],0xc
    add word [dat_3413],0x8
    jmp short lab_36b7
lab_36a4:
    cmp bx,0xc
    jnz short lab_36bd
    cmp byte [0x697],0xfd
    jnz short lab_36b7
    cmp byte [0x57b],0x30
    jb short lab_36bd
lab_36b7:
    mov ax,[dat_350b]
    mov [dat_3509],ax
lab_36bd:
    db 0x8b, 0xf3                       ; mov si,bx
    db 0xd1, 0xe6                       ; shl si,0x0
    cmp byte [bx+l2_obj_active],0x0
    jnz short lab_367f
    call random
    cmp dl,0x10
    ja short lab_36e9
    and dl,0x1
    jnz short lab_36d7
    not dl
lab_36d7:
    mov [bx+dat_3417],dl
    call random
    and dl,0x1
    jnz short lab_36e5
    not dl
lab_36e5:
    mov [bx+dat_342f],dl
lab_36e9:
    mov cx,0x4
    cmp bx,0xc
    jb short lab_36f3
    db 0xd0, 0xe9                       ; shr cl,0x0
lab_36f3:
    mov ax,[si+l2_obj_x]
    cmp byte [bx+dat_3417],0x1
    jz short lab_370b
    db 0x2b, 0xc1                       ; sub ax,cx
    jnb short lab_371a
    db 0x2b, 0xc0                       ; sub ax,ax
    mov byte [bx+dat_3417],0x1
    jmp short lab_371a
lab_370b:
    db 0x03, 0xc1                       ; add ax,cx
    cmp ax,0x12f
    jb short lab_371a
    mov ax,0x12e
    mov byte [bx+dat_3417],0xff
lab_371a:
    mov [si+l2_obj_x],ax
    mov al,[bx+l2_obj_y]
    cmp byte [bx+dat_342f],0x1
    jz short lab_373c
    dec al
    cmp al,[bx+l2_obj_init_y]
    jnb short lab_3750
    mov al,[bx+l2_obj_init_y]
    mov byte [bx+dat_342f],0x1
    jmp short lab_3750
lab_373c:
    inc al
    mov dl,[bx+l2_obj_init_y]
    add dl,0x18
    db 0x3a, 0xc2                       ; cmp al,dl
    jbe short lab_3750
    db 0x8a, 0xc2                       ; mov al,dl
    mov byte [bx+dat_342f],0xff
lab_3750:
    mov [bx+l2_obj_y],al
    db 0x8a, 0xd0                       ; mov dl,al
    mov cx,[si+l2_obj_x]
    call calc_cga_addr
    mov [l2_obj_cur_addr],ax
    mov bx,[dat_3415]
    call erase_level_object
    mov bx,[dat_3415]
    db 0x8b, 0xf3                       ; mov si,bx
    db 0xd1, 0xe6                       ; shl si,0x0
    mov di,[l2_obj_cur_addr]
    mov [si+l2_obj_cga_addr],di
    mov byte [bx+l2_obj_hit],0x0
    mov ax,0xb800
    mov es,ax
    cmp bx,0xc
    jb short lab_379f
    db 0x8b, 0xf3                       ; mov si,bx
    mov cl,0x3
    shl si,cl
    add si,[dat_3413]
    db 0x81, 0xe6, 0x18, 0x00           ; and si,0x18
    add si,l1_anim_sprite_b
    mov cx,0x202
    call blit_to_cga
    ret
lab_379f:
    mov si,[l2_anim_toggle]
    test bl,0x1
    jnz short lab_37ac
    db 0x81, 0xf6, 0x0c, 0x00           ; xor si,0xc
lab_37ac:
    cmp byte [bx+dat_3417],0x1
    jz short lab_37b6
    add si,0x18
lab_37b6:
    add si,l1_anim_sprite_a
    mov cx,0x601
    call blit_to_cga
    ret

; --- erase_level_object ---
erase_level_object:
    cmp byte [bx + l2_obj_hit],0x0
    jnz lab_37e4
    shl bx,0x1
    mov si,dat_3404
    mov di,word [bx + l2_obj_cga_addr]
    mov ax,0xb800
    mov es,ax
    mov cx,0x601
    cmp bx,0x18
    jc lab_37e1
    mov cx,0x202
lab_37e1:
    call blit_to_cga                           ;undefined blit_to_cga()
lab_37e4:
    ret
animate_level2_blocks:
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    db 0x8b, 0xc2                       ; mov ax,dx
    sub ax,[dat_350f]
    db 0x3d, 0x08, 0x00                 ; cmp ax,0x8
    jb short lab_384a
    inc word [dat_350d]
    mov bx,[dat_350d]
    cmp bx,0x28
    jb short lab_380b
    db 0x2b, 0xdb                       ; sub bx,bx
    mov [dat_350d],bx
    mov [dat_350f],dx
lab_380b:
    db 0x8b, 0xfb                       ; mov di,bx
    db 0xd1, 0xe7                       ; shl di,0x0
    cmp byte [0x57b],0x7
    ja short lab_3829
    mov ax,[0x579]
    mov cl,0x2
    shr ax,cl
    inc ax
    db 0x2b, 0xc7                       ; sub ax,di
    jnb short lab_3824
    not ax
lab_3824:
    db 0x3d, 0x04, 0x00                 ; cmp ax,0x4
    jb short lab_384a
lab_3829:
    add di,0xa0
    mov al,[bx+level2_block_types]
    add al,0x8
    mov [bx+level2_block_types],al
    db 0x25, 0x18, 0x00                 ; and ax,0x18
    add ax,level2_bar_sprites
    db 0x8b, 0xf0                       ; mov si,ax
    mov ax,0xb800
    mov es,ax
    mov cx,0x401
    call blit_to_cga
lab_384a:
    ret
    add [bx+si],al
    add [bx+si],al
    db 0x00
update_entrance_anim:
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    db 0x8b, 0xc2                       ; mov ax,dx
    sub ax,[dat_35da]
    db 0x3d, 0x06, 0x00                 ; cmp ax,0x6
    jnb short lab_3860
    ret
lab_3860:
    mov [dat_35da],dx
    add word [dat_35d8],0x2
    mov bx,[dat_35d8]
    db 0x81, 0xe3, 0x06, 0x00           ; and bx,0x6
    mov si,[bx+dat_35d0]
    mov di,enemy_sprite_table_hi
    mov ax,0xb800
    mov es,ax
    mov cx,0xa02
    call blit_to_cga
    mov ax,0xe4
    mov dl,0x8a
    mov si,0x10
    mov bx,[0x579]
    mov dh,[0x57b]
    mov di,0x18
    mov cx,0xe0a
    call check_rect_collision
    jnb short lab_38a3
    mov byte [level_complete],0x1
lab_38a3:
    ret
    add [bx+si],al
    add [bx+si],al
    add [bx+si],al
    add [bx+si],al
    add [bx+si],al
    add [bx+si],al
handle_level_complete:
    cmp word [0x6],0x7
    jnz short lab_38ba
    jmp short lab_38d3
    nop
lab_38ba:
    inc word [0x414]
    mov byte [0x418],0x1
    mov dx,0xaaaa
    call mask_score_tiles
    db 0x2b, 0xc0                       ; sub ax,ax
    mov byte [dat_369f],0x0
    call animate_score_bar
lab_38d3:
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    cmp word [0x6],0x7
    jnz short lab_38ef
    sub dx,[0x412]
    mov ax,0x2a30
    db 0x2b, 0xc2                       ; sub ax,dx
    jnb short lab_38eb
    db 0x2b, 0xc0                       ; sub ax,ax
lab_38eb:
    db 0xd1, 0xe8                       ; shr ax,0x0
    jmp short lab_390e
lab_38ef:
    sub dx,[0x410]
    mov ax,0x546
    cmp word [0x6],0x6
    jnz short lab_38ff
    db 0xd1, 0xe0                       ; shl ax,0x0
lab_38ff:
    db 0x2b, 0xc2                       ; sub ax,dx
    jnb short lab_3905
    db 0x2b, 0xc0                       ; sub ax,ax
lab_3905:
    cmp word [0x6],0x6
    jz short lab_390e
    db 0xd1, 0xe0                       ; shl ax,0x0
lab_390e:
    mov [dat_3697],ax
    call binary_to_bcd
    mov bx,[0x6]
    db 0xd0, 0xe3                       ; shl bl,0x0
    mov si,[bx+dat_36cc]
    mov di,dat_368d
    call add_bcd_scores
    cmp word [0x6],0x7
    jnz short lab_396e
    mov bx,[0x8]
    db 0xd0, 0xe3                       ; shl bl,0x0
    db 0x8b, 0xc3                       ; mov ax,bx
    mov cx,[bx+dat_36dc]
    cmp word [l7_obj_spawn_slot],0x8
    jnb short lab_3943
    db 0xd1, 0xe1                       ; shl cx,0x0
    db 0x05, 0x10, 0x00                 ; add ax,0x10
lab_3943:
    mov [dat_370c],ax
lab_3946:
    mov si,dat_368d
    mov di,dat_1f82
    push cx
    call add_bcd_scores
    pop cx
    loop short lab_3946
    call save_score_regions
    mov byte [dat_369e],0x38
    mov byte [dat_3699],0x1
    mov word [dat_3722],0x44
    call print_bonus_score
    call print_level7_bonus
    jmp short lab_39a7
lab_396e:
    mov si,dat_368d
    mov di,dat_1f82
    call add_bcd_scores
    mov byte [dat_3699],0x2
    mov word [dat_3722],0x1e
    mov dx,0xffff
    call mask_score_tiles
    mov ax,0xa8c
    sub ax,[dat_3697]
    mov cl,0x4
    shr ax,cl
    and al,0xf0
    mov [dat_369e],al
    mov ah,0x28
    mul ah
    mov byte [dat_369f],0x1
    call animate_score_bar
    call print_bonus_score
lab_39a7:
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    mov [dat_3695],dx
lab_39af:
    cmp word [0x6],0x7
    jnz short lab_39bb
    call play_victory_note
    jmp short lab_39be
lab_39bb:
    call play_level_note
lab_39be:
    call flash_score_color
    sub dx,[dat_3695]
    cmp dx,[dat_3722]
    jb short lab_39af
    db 0x2b, 0xdb                       ; sub bx,bx
    mov ah,0xb
    int byte 0x10
    cmp word [0x6],0x7
    jz short lab_39dc
    call silence_speaker
    ret
lab_39dc:
    mov ax,0xb800
    mov es,ax
    mov si,0xe
    mov di,0x8e4
    mov cx,0x804
    call blit_to_cga
    mov si,0x4e
    mov di,0xc94
    mov cx,0x814
    call blit_to_cga
    ret
save_score_regions:
    push ds
    pop es
    mov ax,0xb800
    mov ds,ax
    mov cx,0x804
    mov di,0xe
    mov si,0x8e4
    call save_from_cga
    mov cx,0x814
    mov di,0x4e
    mov si,0xc94
    call save_from_cga
    push es
    pop ds
    ret
flash_score_color:
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    push dx
lab_3a21:
    call check_vsync
    jz short lab_3a21
    pop dx
    push dx
    db 0x2b, 0xdb                       ; sub bx,bx
    test dx,0x4
    jnz short lab_3a34
    mov bl,[dat_3699]
lab_3a34:
    mov ah,0xb
    int byte 0x10
    pop dx
    ret
print_bonus_score:
    mov ah,0x2
    mov dh,[dat_369e]
    mov cl,0x3
    shr dh,cl
    mov dl,0x12
    db 0x2a, 0xff                       ; sub bh,bh
    int byte 0x10
    mov word [dat_36a0],0x3
lab_3a50:
    mov bx,[dat_36a0]
    mov al,[bx+dat_368d]
    add al,0x30
    mov ah,0xe
    mov bl,0x3
    int byte 0x10
    inc word [dat_36a0]
    cmp word [dat_36a0],0x7
    jb short lab_3a50
    ret
print_level7_bonus:
    mov ah,0x2
    mov dl,0xa
    db 0x8a, 0xf2                       ; mov dh,dl
    db 0x2b, 0xdb                       ; sub bx,bx
    int byte 0x10
    mov bx,[dat_370c]
    mov ax,[bx+dat_36ec]
    mov [dat_3720],ax
    db 0x2b, 0xdb                       ; sub bx,bx
lab_3a83:
    mov ah,0xe
    mov al,[bx+dat_370e]
    push bx
    mov bl,0x3
    int byte 0x10
    pop bx
    inc bx
    cmp bx,0x14
    jb short lab_3a83
    ret
mask_score_tiles:
    cld
reloc_8:
    mov ax,DATA_SEG_PARA                ; relocated: ES = data segment
    mov es,ax
    mov di,0xe
    mov si,dat_35e0
    mov cx,0x1e
lab_3aa5:
    lodsw
    db 0x23, 0xc2                       ; and ax,dx
    stosw
    loop short lab_3aa5
    ret
animate_score_bar:
    mov [dat_369a],ax
    mov ax,0xb800
    mov es,ax
    call init_level_melody
    mov ax,0x1b80
lab_3aba:
    mov bx,dat_361c
    mov [dat_369c],ax
    call draw_block_list
    cmp byte [dat_369f],0x0
    jz short lab_3ae2
    call play_melody_step
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    mov [dat_3695],dx
lab_3ad5:
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    sub dx,[dat_3695]
    cmp dx,0x2
    jb short lab_3ad5
lab_3ae2:
    mov ax,[dat_369c]
    sub ax,0x280
    jb short lab_3af0
    cmp ax,[dat_369a]
    jnb short lab_3aba
lab_3af0:
    call silence_speaker
    ret
binary_to_bcd:
    mov [dat_368b],ax
    db 0x2b, 0xc0                       ; sub ax,ax
    mov [dat_368d],ax
    mov [dat_368f],ax
    mov [dat_3691],ax
    mov [dat_3693],ax
    mov bx,dat_3684
    mov dx,0x1000
lab_3b0b:
    test [dat_368b],dx
    jz short lab_3b19
    db 0x8b, 0xf3                       ; mov si,bx
    mov di,dat_368d
    call add_bcd_scores
lab_3b19:
    sub bx,0x7
    db 0xd1, 0xea                       ; shr dx,0x0
    jnb short lab_3b0b
    ret
    add [bx+si],al
    add [bx+si],al
    add [bx+si],al
    add [bx+si],al
    add [bx+si],al
    add [bx+si],al
    add [bx+si],al
    db 0x00
init_level3_doors:
    mov byte [dat_37af],0x3
    mov ax,0x1
    mov [dat_37b0],ax
    mov [dat_37b2],ax
    mov [dat_37b4],ax
    ret
update_level3_doors:
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    cmp dx,[dat_37b8]
    jnz short lab_3b4d
    ret
lab_3b4d:
    mov [dat_37b8],dx
    mov word [dat_37b6],0x4
lab_3b57:
    mov bx,[dat_37b6]
    cmp word [bx+dat_37b0],0x0
    jz short lab_3b9b
    mov ax,[bx+dat_37a3]
    mov dl,0x18
    mov si,0x10
    mov bx,[0x579]
    mov dh,[0x57b]
    mov di,0x18
    mov cx,0xe10
    call check_rect_collision
    jnb short lab_3b9b
    mov ax,0xc00
    mov bx,0x8fd
    call start_tone
    call restore_alley_buffer
    call erase_level3_enemy
    mov bx,[dat_37b6]
    call close_level3_door
    call save_alley_buffer
    call draw_level3_enemy
    ret
lab_3b9b:
    sub word [dat_37b6],0x2
    jnb short lab_3b57
    ret
close_level3_door:
    mov word [bx+dat_37b0],0x0
    push ds
    pop es
    cld
    mov ax,0xaaaa
    mov di,0xe
    db 0x8b, 0xf7                       ; mov si,di
    mov cx,0x20
    rep stosw
    mov di,[bx+dat_37a9]
    mov ax,0xb800
    mov es,ax
    mov cx,0x1002
    call blit_to_cga
    dec byte [dat_37af]
    jnz short lab_3bda
    cmp byte [0x552],0x0
    jnz short lab_3bda
    mov byte [0x553],0x1
lab_3bda:
    ret
draw_level3_bg:
    mov ax,0xb800
    mov es,ax
    mov word [dat_37a0],0x66a
    mov cx,0x10
lab_3be9:
    db 0x2b, 0xc0                       ; sub ax,ax
    db 0x8b, 0xd8                       ; mov bx,ax
lab_3bed:
    mov [dat_37a2],al
    db 0x2a, 0xe4                       ; sub ah,ah
    add ax,dat_3730
    db 0x8b, 0xf0                       ; mov si,ax
    mov di,[dat_37a0]
    db 0x03, 0xfb                       ; add di,bx
    push cx
    mov cx,0x801
    push bx
    call blit_to_cga
    pop bx
    pop cx
    add bx,0x2
    cmp bx,0x1e
    jb short lab_3c1e
    jnz short lab_3c15
    mov al,0x20
    jmp short lab_3bed
lab_3c15:
    add word [dat_37a0],0x140
    loop short lab_3be9
    ret
lab_3c1e:
    cmp byte [dat_37a2],0x50
    jz short lab_3c36
    test cl,0x1
    jnz short lab_3c36
    call random
    cmp dl,0x40
    jb short lab_3c36
    mov al,0x10
    jmp short lab_3bed
lab_3c36:
    call random
    db 0x8a, 0xc2                       ; mov al,dl
    db 0x2a, 0xc3                       ; sub al,bl
    and al,0x30
    add al,0x30
    jmp short lab_3bed

; --- check_fence_collision ---
check_fence_collision:
    mov ax,[cat_x]
    db 0x25, 0xfc, 0xff                 ; and ax,0xfffc
    cmp ax,0xa4
    jc lab_3c7f
    cmp ax,0x118
    ja lab_3c7f
    mov dl,byte [cat_y]
    sub dl,0x2
    and dl,0xf8
    test dl,0x8
    jz lab_3c7f
    cmp dl,0x28
    jc lab_3c7f
    cmp dl,0xa0
    ja lab_3c7f
    mov [cat_x],ax
    add dl,0x2
    mov byte [cat_y],dl
    add dl,0x32
    mov byte [cat_y_bottom],dl
    stc
    ret
lab_3c7f:
    clc
    ret
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
init_level3_enemy:
    mov byte [dat_3966],0x8
    mov byte [dat_396a],0x1
    mov byte [dat_3967],0x0
    mov byte [dat_396d],0x2
    mov word [dat_3964],0x118
    mov word [l3_door_toggle],0x0
    ret
update_level3_enemy:
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    db 0x8b, 0xc2                       ; mov ax,dx
    sub ax,[dat_39c8]
    db 0x3d, 0x02, 0x00                 ; cmp ax,0x2
    jnb short lab_3cc1
lab_3cc0:
    ret
lab_3cc1:
    mov [dat_39c8],dx
    call check_l3_enemy_thrown
    jb short lab_3cc0
    call check_l3_enemy_cat
    jnb short lab_3cd2
    jmp near lab_3d90
lab_3cd2:
    mov bx,[0x8]
    db 0xd0, 0xe3                       ; shl bl,0x0
    mov ax,[bx+dat_39cc]
    mov [dat_39c6],ax
    mov ax,[dat_3964]
    mov [dat_39c3],ax
    mov dl,[dat_3966]
    mov [dat_39c5],dl
    cmp dl,0x8
    jnz short lab_3d25
    db 0x25, 0xf8, 0xff                 ; and ax,0xfff8
    mov dx,[0x579]
    db 0x81, 0xe2, 0xf8, 0xff           ; and dx,0xfff8
    db 0x3b, 0xc2                       ; cmp ax,dx
    jnz short lab_3d0d
    mov byte [dat_3967],0x1
    mov byte [dat_396e],0x1
    jmp short lab_3d25
lab_3d0d:
    mov ax,[dat_3964]
    jb short lab_3d1c
    sub ax,[dat_39c6]
    jnb short lab_3d20
    db 0x2b, 0xc0                       ; sub ax,ax
    jmp short lab_3d20
lab_3d1c:
    add ax,[dat_39c6]
lab_3d20:
    mov [dat_3964],ax
    jmp short lab_3d79
lab_3d25:
    mov al,[dat_3966]
    inc byte [dat_396e]
    mov dl,[dat_396e]
    db 0xd0, 0xea                       ; shr dl,0x0
    db 0xd0, 0xea                       ; shr dl,0x0
    and dl,0x3
    add dl,0x2
    cmp byte [dat_3967],0x1
    jz short lab_3d52
    db 0x2a, 0xc2                       ; sub al,dl
    jb short lab_3d49
    cmp al,0x9
    jnb short lab_3d76
lab_3d49:
    mov al,0x8
    mov byte [dat_3967],0x0
    jmp short lab_3d76
lab_3d52:
    db 0x02, 0xc2                       ; add al,dl
    cmp al,[0x57b]
    ja short lab_3d71
    mov bx,[dat_3964]
    sub bx,[0x579]
    jnb short lab_3d66
    not bx
lab_3d66:
    cmp bx,0x30
    ja short lab_3d71
    cmp al,0xa0
    jb short lab_3d76
    mov al,0x9f
lab_3d71:
    mov byte [dat_3967],0xff
lab_3d76:
    mov [dat_3966],al
lab_3d79:
    call check_l3_enemy_thrown
    jnb short lab_3d8b
    mov ax,[dat_39c3]
    mov [dat_3964],ax
    mov al,[dat_39c5]
    mov [dat_3966],al
    ret
lab_3d8b:
    call check_l3_enemy_cat
    jnb short lab_3dee
lab_3d90:
    cmp byte [0x553],0x0
    jz short lab_3d98
    ret
lab_3d98:
    mov cx,[0x579]
    sub cx,0xc
    jnb short lab_3da3
    db 0x2b, 0xc9                       ; sub cx,cx
lab_3da3:
    cmp cx,0x10f
    jb short lab_3dac
    mov cx,0x10e
lab_3dac:
    mov dl,[0x57b]
    sub dl,0x4
    jnb short lab_3db7
    db 0x2a, 0xd2                       ; sub dl,dl
lab_3db7:
    call calc_cga_addr
    db 0x8b, 0xf8                       ; mov di,ax
    mov ax,0xb800
    mov es,ax
    mov si,dat_37c0
    mov bp,0xe
    mov cx,0x1506
    call blit_transparent
    call init_buzz_sound
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    mov [dat_39c8],dx
lab_3dd8:
    call update_buzz_sound
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    sub dx,[dat_39c8]
    cmp dx,0x9
    jb short lab_3dd8
    mov byte [0x552],0x1
    ret
lab_3dee:
    mov cx,[dat_3964]
    mov dl,[dat_3966]
    call calc_cga_addr
    mov [dat_39ca],ax
    call erase_level3_enemy
    dec byte [dat_396d]
    jnz short lab_3e10
    mov byte [dat_396d],0x2
    db 0x81, 0x36, 0x6b, 0x39, 0x54, 0x00 ; xor word [0x396b],0x54
lab_3e10:
    call draw_level3_enemy
    ret
draw_level3_enemy:
    mov ax,0xb800
    mov es,ax
    mov di,[dat_39ca]
    mov [dat_3968],di
    mov bp,dat_396f
    mov byte [dat_396a],0x0
    mov si,[l3_door_toggle]
    add si,dat_38bc
    mov cx,0xe03
    call blit_transparent
    ret
erase_level3_enemy:
    mov ax,0xb800
    mov es,ax
    cmp byte [dat_396a],0x0
    jnz short lab_3e51
    mov di,[dat_3968]
    mov si,dat_396f
    mov cx,0xe03
    call blit_to_cga
lab_3e51:
    ret
check_l3_enemy_thrown:
    mov ax,[dat_3964]
    mov dl,[dat_3966]
    mov si,0x18
    mov bx,[thrown_obj_x]
    mov dh,[thrown_obj_y]
    mov di,0x10
    mov cx,0x1e0e
    call check_rect_collision
    ret
check_l3_enemy_cat:
    mov ax,[dat_3964]
    mov dl,[dat_3966]
    mov si,0x18
    db 0x8b, 0xfe                       ; mov di,si
    mov bx,[0x579]
    mov dh,[0x57b]
    mov cx,0xe0e
    call check_rect_collision
    ret
    add [bx+si],al
    add [bx+si],al
    add [bx+si],al
    db 0x00
update_level4_state:
    cmp byte [l3_door_anim_frame],0x0
    jz short lab_3ea4
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    cmp dx,[l4_last_tick]
    jz short lab_3eb9
    jmp near lab_3f35
lab_3ea4:
    cmp byte [0x584],0x0
    jnz short lab_3eb9
    cmp byte [0x69a],0x0
    jnz short lab_3eb9
    cmp byte [l3_platform_id],0x0
    jnz short lab_3eba
lab_3eb9:
    ret
lab_3eba:
    call check_l4_thrown_collision
    jb short lab_3eb9
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    db 0x8b, 0xc2                       ; mov ax,dx
    sub ax,[dat_3d18]
    db 0x3d, 0x0c, 0x00                 ; cmp ax,0xc
    jb short lab_3eb9
    mov [dat_3d18],dx
    mov byte [0x55c],0x0
    mov bl,[l3_platform_id]
    dec bl
    db 0x2a, 0xff                       ; sub bh,bh
    db 0x8b, 0xf3                       ; mov si,bx
    mov cl,0x2
    shl si,cl
    mov ax,[si+dat_3c5a]
    mov [l3_door_cga_1],ax
    db 0x2b, 0xc0                       ; sub ax,ax
    cmp bl,0x3
    jnb short lab_3ef5
    mov al,0x80
lab_3ef5:
    mov [l3_door_cga_2],ax
    mov bl,[bx+dat_3ce3]
    db 0x8b, 0xf3                       ; mov si,bx
    mov cl,0x2
    shl si,cl
    mov ax,[si+dat_3c5a]
    mov [l3_door_cga_3],ax
    db 0x2b, 0xc0                       ; sub ax,ax
    cmp bl,0x3
    jnb short lab_3f12
    mov al,0x80
lab_3f12:
    mov [l3_door_sprite_base],ax
    mov al,[bx+l4_platform_offset]
    mov [l4_obj_cur_y],al
    db 0xd0, 0xe3                       ; shl bl,0x0
    mov ax,[bx+l4_obj_x_table]
    db 0x05, 0x08, 0x00                 ; add ax,0x8
    mov [l4_obj_cur_x],ax
    call restore_alley_buffer
    mov byte [l3_door_anim_frame],0xe
    mov byte [0x69a],0x10
lab_3f35:
    cmp byte [enemy_chasing],0x0
    jnz short lab_3f3f
    call erase_thrown_sprite
lab_3f3f:
    sub byte [l3_door_anim_frame],0x2
    db 0x2a, 0xff                       ; sub bh,bh
    mov bl,[l3_door_anim_frame]
    cmp bl,0x8
    jb short lab_3f58
    mov di,[l3_door_cga_1]
    mov ax,[l3_door_cga_2]
    jmp short lab_3f70
lab_3f58:
    mov di,[l3_door_cga_3]
    mov al,[l4_obj_cur_y]
    mov [0x57b],al
    add al,0x32
    mov [0x57c],al
    mov ax,[l4_obj_cur_x]
    mov [0x579],ax
    mov ax,[l3_door_sprite_base]
lab_3f70:
    add ax,[bx+l4_anim_offset_table]
    db 0x8b, 0xf0                       ; mov si,ax
    mov ax,0xb800
    mov es,ax
    mov cx,0x1002
    call blit_to_cga
    cmp byte [enemy_chasing],0x0
    jnz short lab_3f8b
    call draw_thrown_sprite
lab_3f8b:
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    mov [l4_last_tick],dx
    cmp byte [l3_door_anim_frame],0x0
    jnz short lab_3f9d
    call save_cat_background
lab_3f9d:
    ret
init_level4_bg:
    mov ax,0xb800
    mov es,ax
    mov byte [l3_platform_id],0x0
    mov byte [l3_door_anim_frame],0x0
    mov word [dat_3cbf],0x506
    mov word [dat_3cc1],0x0
lab_3fb9:
    mov bx,[dat_3cc1]
    mov cl,[bx+dat_3cae]
    db 0x2b, 0xdb                       ; sub bx,bx
    db 0x8a, 0xeb                       ; mov ch,bl
lab_3fc5:
    mov si,dat_3aea
    call random
    cmp dl,0x30
    ja short lab_3fdb
    mov si,dat_3af8
    test dl,0x4
    jnz short lab_3fdb
    mov si,dat_3b02
lab_3fdb:
    mov di,[dat_3cbf]
    db 0x03, 0xfb                       ; add di,bx
    push cx
    push bx
    mov cx,0x801
    call blit_to_cga
    pop bx
    pop cx
    add bx,0x2
    loop short lab_3fc5
    add word [dat_3cbf],0x140
    inc word [dat_3cc1]
    cmp word [dat_3cc1],0x11
    jb short lab_3fb9
    mov bx,dat_3c22
    db 0x2b, 0xc0                       ; sub ax,ax
    call draw_block_list
    mov bx,dat_3c3e
    db 0x2b, 0xc0                       ; sub ax,ax
    call draw_block_list
    mov bx,dat_3c9a
    db 0x2b, 0xc0                       ; sub ax,ax
    call draw_block_list
    mov bx,dat_3c56
    db 0x2b, 0xc0                       ; sub ax,ax
    call draw_block_list
    mov si,dat_3caa
    mov di,0x8ec
    mov cx,0x102
    mov bp,0xe
    call blit_masked
    db 0x2b, 0xf6                       ; sub si,si
    mov bx,[0x8]
    mov cl,0x3
    db 0x22, 0xd9                       ; and bl,cl
    shl bl,cl
lab_403c:
    mov al,[bx+dat_3cc3]
    db 0x8a, 0xe0                       ; mov ah,al
    mov cl,0x4
    shr al,cl
    mov [si+dat_3ce3],al
    mov byte [si+dat_3cf3],0x0
    and ah,0xf
    mov [si+dat_3ce4],ah
    mov byte [si+dat_3cf4],0x0
    add si,0x2
    inc bx
    cmp si,0x10
    jb short lab_403c
    ret
check_l4_thrown_collision:
    mov ax,[thrown_obj_x]
    mov dl,[thrown_obj_y]
    mov si,0x10
    mov bx,[0x579]
    mov dh,[0x57b]
    mov di,0x18
    mov cx,0xe1e
    call check_rect_collision
    ret
    add [bx+si],al
    add [bx+si],al
    add [bx+si],al
    add [bx+si],al
    add [bx+si],al
    add [bx+si],al
    add [bx+si],al
    db 0x00
init_level4_objects:
    mov cx,0x4
lab_4093:
    db 0x8b, 0xd9                       ; mov bx,cx
    dec bx
    db 0x8b, 0xf3                       ; mov si,bx
    db 0xd1, 0xe6                       ; shl si,0x0
    mov byte [bx+l5_obj_active],0x1
    mov byte [bx+l5_obj_hit],0x0
    call randomize_l4_pos
    call random
    and dl,0xf
    add dl,0x14
    mov [bx+l5_obj_anim],dl
    loop short lab_4093
    mov word [l5_obj_index],0x0
    mov byte [l5_obj_count],0x4
    ret
update_level4_anim:
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    cmp dx,[l5_last_tick]
    jnz short lab_40cd
lab_40cc:
    ret
lab_40cd:
    inc word [l5_obj_index]
    mov bx,[l5_obj_index]
    cmp bx,0x2
    jbe short lab_40e5
    cmp bx,0x4
    jb short lab_40e9
    db 0x2b, 0xdb                       ; sub bx,bx
    mov [l5_obj_index],bx
lab_40e5:
    mov [l5_last_tick],dx
lab_40e9:
    db 0x8b, 0xf3                       ; mov si,bx
    db 0xd1, 0xe6                       ; shl si,0x0
    cmp byte [bx+l5_obj_hit],0x0
    jnz short lab_40cc
    call check_l4_obj_cat
    jnb short lab_40fc
    jmp short lab_4124
    nop
lab_40fc:
    call check_l4_obj_thrown
    jb short lab_40cc
    cmp byte [bx+l5_obj_anim],0x0
    jnz short lab_4118
    call randomize_l4_pos
    call random
    and dl,0x7
    add dl,0x14
    mov [bx+l5_obj_anim],dl
lab_4118:
    dec byte [bx+l5_obj_anim]
    call check_l4_obj_cat
    jb short lab_4124
    jmp short lab_4181
    nop
lab_4124:
    cmp byte [bx+l5_obj_active],0x0
    jnz short lab_4132
    cmp byte [bx+l5_obj_anim],0x14
    jb short lab_4133
lab_4132:
    ret
lab_4133:
    call restore_alley_buffer
    call erase_level4_sprite
    mov bx,[l5_obj_index]
    mov byte [bx+l5_obj_hit],0x1
    call save_alley_buffer
    mov byte [0x55c],0x0
    dec byte [l5_obj_count]
    jnz short lab_4155
    mov byte [0x553],0x1
lab_4155:
    mov al,0x4
    sub al,[l5_obj_count]
    mov cl,0x2
    shl al,cl
    db 0x2a, 0xe4                       ; sub ah,ah
    db 0x05, 0x51, 0x00                 ; add ax,0x51
    db 0x8b, 0xf8                       ; mov di,ax
    mov bp,0xe
    mov si,dat_3d20
    mov ax,0xb800
    mov es,ax
    mov cx,0xc02
    call blit_masked
    mov ax,0x3e8
    mov bx,0x2ee
    call start_tone
    ret
lab_4181:
    call calc_l4_obj_pos
    mov di,[0x8]
    db 0xd1, 0xe7                       ; shl di,0x0
    mov bp,[di+l5_save_buf_ptrs]
    call check_l4_proximity
    jnb short lab_41b0
    cmp byte [bx+l5_obj_anim],0x2
    jb short lab_41b0
    mov al,0x1
    cmp byte [bx+l5_obj_anim],0x11
    jbe short lab_41ac
    cmp byte [bx+l5_obj_anim],0x14
    jnb short lab_41b0
    dec al
lab_41ac:
    mov [bx+l5_obj_anim],al
lab_41b0:
    mov al,[bx+l5_obj_anim]
    cmp al,0x1
    jbe short lab_41d8
    cmp al,0x12
    jb short lab_41f8
    mov al,0x1
    cmp word [si+l5_obj_frame],0x3
    jnb short lab_41c7
    mov al,0x3
lab_41c7:
    add [bx+l5_obj_y_pos],al
    cmp byte [bx+l5_obj_anim],0x13
    jb short lab_41f3
    jz short lab_41ee
    db 0x2b, 0xc0                       ; sub ax,ax
    jmp short lab_4204
lab_41d8:
    mov al,0x1
    cmp word [si+l5_obj_frame],0x3
    jnb short lab_41e3
    mov al,0x3
lab_41e3:
    add [bx+l5_obj_y_pos],al
    cmp byte [bx+l5_obj_anim],0x1
    jnb short lab_41f3
lab_41ee:
    mov ax,0x3db0
    jmp short lab_4204
lab_41f3:
    mov ax,0x3d80
    jmp short lab_4204
lab_41f8:
    db 0xd0, 0xe0                       ; shl al,0x0
    db 0x8b, 0xf8                       ; mov di,ax
    db 0x81, 0xe7, 0x02, 0x00           ; and di,0x2
    mov ax,[di+dat_3de0]
lab_4204:
    mov [l5_obj_sprite_ptr],ax
    mov dl,[bx+l5_obj_y_pos]
    mov cx,[si+l5_obj_dims]
    call calc_cga_addr
    mov [dat_3de4],ax
    call erase_level4_sprite
    mov bx,[l5_obj_index]
    db 0x8b, 0xf3                       ; mov si,bx
    db 0xd1, 0xe6                       ; shl si,0x0
    call check_l4_obj_thrown
    jnb short lab_4226
    ret
lab_4226:
    cmp word [l5_obj_sprite_ptr],0x0
    jnz short lab_4233
    mov byte [bx+l5_obj_active],0x1
    ret
lab_4233:
    mov byte [bx+l5_obj_active],0x0
    mov di,[dat_3de4]
    mov [si+l5_obj_cga_addr],di
    mov ax,0xb800
    mov es,ax
    mov bp,[si+l5_obj_save_buf]
    mov cx,0xc02
    mov si,[l5_obj_sprite_ptr]
    call blit_masked
    ret
erase_level4_sprite:
    mov bx,[l5_obj_index]
    db 0x8b, 0xf3                       ; mov si,bx
    db 0xd1, 0xe6                       ; shl si,0x0
    cmp byte [bx+l5_obj_active],0x0
    jnz short lab_4276
    mov di,[si+l5_obj_cga_addr]
    mov cx,0xc02
    mov si,[si+l5_obj_save_buf]
    mov ax,0xb800
    mov es,ax
    call blit_to_cga
lab_4276:
    ret
randomize_l4_pos:
    mov byte [l5_anim_delay],0x20
lab_427c:
    call random
    db 0x81, 0xe2, 0x0f, 0x00           ; and dx,0xf
    db 0x2b, 0xff                       ; sub di,di
lab_4285:
    db 0x3b, 0xfe                       ; cmp di,si
    jz short lab_428f
    cmp dx,[di+l5_obj_frame]
    jz short lab_427c
lab_428f:
    add di,0x2
    cmp di,0x8
    jb short lab_4285
    mov [si+l5_obj_frame],dx
    call calc_l4_obj_pos
    cmp byte [l5_anim_delay],0x0
    jz short lab_42b3
    mov bp,0x32
    call check_l4_proximity
    jnb short lab_42b3
    dec byte [l5_anim_delay]
    jmp short lab_427c
lab_42b3:
    ret
calc_l4_obj_pos:
    mov di,[si+l5_obj_frame]
    mov al,[di+l4_platform_offset]
    mov dl,0xa
    cmp di,0x3
    jnb short lab_42c5
    db 0x2a, 0xd2                       ; sub dl,dl
lab_42c5:
    db 0x2a, 0xc2                       ; sub al,dl
    add al,0x3
    mov [bx+l5_obj_y_pos],al
    db 0xd1, 0xe7                       ; shl di,0x0
    mov ax,[di+l4_obj_x_table]
    db 0x05, 0x08, 0x00                 ; add ax,0x8
    mov [si+l5_obj_dims],ax
    ret
check_l4_obj_cat:
    push si
    push bx
    mov ax,[si+l5_obj_dims]
    mov dl,[bx+l5_obj_y_pos]
    mov si,0x10
    mov bx,[0x579]
    mov dh,[0x57b]
    mov di,0x18
    mov cx,0xe0c
    call check_rect_collision
    pop bx
    pop si
    ret
check_l4_obj_thrown:
    push si
    push bx
    mov ax,[si+l5_obj_dims]
    mov dl,[bx+l5_obj_y_pos]
    mov si,0x10
    mov bx,[thrown_obj_x]
    mov dh,[thrown_obj_y]
    db 0x8b, 0xfe                       ; mov di,si
    mov cx,0x1e0c
    call check_rect_collision
    pop bx
    pop si
    ret
check_l4_proximity:
    mov ax,[si+l5_obj_dims]
    sub ax,[0x579]
    jnb short lab_4328
    not ax
lab_4328:
    mov dl,[bx+l5_obj_y_pos]
    sub dl,[0x57b]
    jnb short lab_4334
    not dl
lab_4334:
    db 0x2a, 0xf6                       ; sub dh,dh
    db 0x03, 0xc2                       ; add ax,dx
    db 0x3b, 0xc5                       ; cmp ax,bp
    jb short lab_433e
    clc
    ret
lab_433e:
    stc
    ret
update_level5_anim:
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    cmp dx,[dat_40b5]
    jnz short lab_434b
lab_434a:
    ret
lab_434b:
    inc byte [dat_40ff]
    test byte [dat_40ff],0x3
    jz short lab_435a
    mov [dat_40b5],dx
lab_435a:
    cmp byte [dat_40aa],0xa4
    jb short lab_434a
    call check_l5_cat_catch
    call check_l5_thrown
    jb short lab_434a
    call random
    cmp dl,0x30
    ja short lab_439c
    call calc_l5_direction
    mov si,[0x8]
    db 0xd1, 0xe6                       ; shl si,0x0
    mov ax,[si+dat_40ce]
    cmp [dat_40cc],ax
    ja short lab_439c
    call play_random_chirp
    mov word [dat_40c8],0xff
    mov al,[dat_40ca]
    mov [dat_40b7],al
    mov al,[dat_40cb]
    mov [dat_40b8],al
    jmp near lab_442e
lab_439c:
    cmp word [dat_40c8],0xa
    ja short lab_43b1
    call random
    cmp dl,0x6
    ja short lab_43b4
    mov word [dat_40c8],0xff
lab_43b1:
    jmp short lab_4402
    nop
lab_43b4:
    mov bx,[dat_40c8]
    db 0x8b, 0xf3                       ; mov si,bx
    db 0xd1, 0xe6                       ; shl si,0x0
    db 0x2a, 0xd2                       ; sub dl,dl
    mov ax,[dat_40b2]
    and ax,0xffc
    cmp ax,[si+dat_40de]
    jz short lab_43d0
    inc dl
    jb short lab_43d0
    mov dl,0xff
lab_43d0:
    mov [dat_40b7],dl
    db 0x2a, 0xd2                       ; sub dl,dl
    mov al,[dat_40b4]
    and al,0xfe
    cmp al,[bx+dat_40f4]
    jz short lab_43e7
    inc dl
    jb short lab_43e7
    mov dl,0xff
lab_43e7:
    mov [dat_40b8],dl
    or dl,[dat_40b7]
    jnz short lab_442e
    call random
    cmp dl,0x10
    ja short lab_442e
    mov word [dat_40c8],0xff
    call play_random_chirp
lab_4402:
    call random
    cmp dl,0x30
    ja short lab_4423
    and dl,0x1
    jnz short lab_4411
    mov dl,0xff
lab_4411:
    mov [dat_40b7],dl
    call random
    and dl,0x1
    jnz short lab_441f
    mov dl,0xff
lab_441f:
    mov [dat_40b8],dl
lab_4423:
    call random
    and dx,0xff
    mov [dat_40c8],dx
lab_442e:
    mov al,[dat_40b4]
    cmp byte [dat_40b8],0x1
    jb short lab_4459
    jnz short lab_4449
    add al,0x2
    cmp al,0xa8
    jb short lab_4456
    mov al,0xa7
    mov byte [dat_40b8],0xff
    jmp short lab_4456
lab_4449:
    sub al,0x2
    cmp al,0x30
    jnb short lab_4456
    mov al,0x30
    mov byte [dat_40b8],0x1
lab_4456:
    mov [dat_40b4],al
lab_4459:
    mov ax,[dat_40b2]
    cmp byte [dat_40b7],0x1
    jb short lab_4486
    jnz short lab_4477
    db 0x05, 0x04, 0x00                 ; add ax,0x4
    cmp ax,0x136
    jb short lab_4483
    mov ax,0x135
    mov byte [dat_40b7],0xff
    jmp short lab_4483
lab_4477:
    db 0x2d, 0x04, 0x00                 ; sub ax,0x4
    jnb short lab_4483
    db 0x2b, 0xc0                       ; sub ax,ax
    mov byte [dat_40b7],0x1
lab_4483:
    mov [dat_40b2],ax
lab_4486:
    call check_l5_cat_catch
    mov cx,[dat_40b2]
    mov dl,[dat_40b4]
    call calc_cga_addr
    mov [dat_40bc],ax
    mov ax,0xb800
    mov es,ax
    cmp byte [dat_40b9],0x0
    jnz short lab_44b0
    mov si,dat_3f2c
    mov di,[dat_40ba]
    mov cx,0x501
    call blit_to_cga
lab_44b0:
    call check_l5_thrown
    jb short lab_44e6
    mov byte [dat_40b9],0x0
    add word [dat_40be],0x2
    mov bx,[dat_40be]
    db 0x81, 0xe3, 0x06, 0x00           ; and bx,0x6
    mov si,[bx+dat_40c0]
    cmp byte [dat_40b7],0xff
    jnz short lab_44d5
    add si,0x1e
lab_44d5:
    mov di,[dat_40bc]
    mov [dat_40ba],di
    mov bp,dat_3f2c
    mov cx,0x501
    call blit_transparent
lab_44e6:
    ret
check_l5_landing:
    cmp byte [0x571],0x0
    jnz short lab_44f9
    mov al,[0x57b]
    and al,0xf8
    cmp al,0x88
    jnz short lab_44f9
    stc
    ret
lab_44f9:
    clc
    ret
calc_l5_direction:
    mov ax,[dat_40b2]
    mov dl,0x1
    sub ax,[0x579]
    jnb short lab_450a
    not ax
    mov dl,0xff
lab_450a:
    mov [dat_40ca],dl
    mov [dat_40cc],ax
    mov al,[dat_40b4]
    mov dl,0x1
    sub al,[0x57b]
    jnb short lab_4520
    not al
    mov dl,0xff
lab_4520:
    mov [dat_40cb],dl
    db 0x2a, 0xe4                       ; sub ah,ah
    db 0xd1, 0xe0                       ; shl ax,0x0
    add [dat_40cc],ax
    ret
check_l5_cat_catch:
    mov ax,[dat_40b2]
    mov dl,[dat_40b4]
    mov si,0x8
    mov bx,[0x579]
    mov dh,[0x57b]
    mov di,0x18
    mov cx,0xe05
    call check_rect_collision
    jnb short lab_4556
    cmp byte [0x552],0x0
    jnz short lab_4556
    mov byte [0x553],0x1
lab_4556:
    ret
check_l5_thrown:
    mov ax,[dat_40b2]
    mov dl,[dat_40b4]
    mov si,0x8
    mov bx,[thrown_obj_x]
    mov dh,[thrown_obj_y]
    mov di,0x10
    mov cx,0x1e05
    call check_rect_collision
    jnb short lab_4579
    mov byte [dat_40b8],0xff
lab_4579:
    ret
init_level5_objects:
    mov cx,0x90
    mov dl,0x86
    mov [dat_40a8],cx
    mov [dat_40aa],dl
    call calc_cga_addr
    mov [dat_40ab],ax
    call draw_l5_perch
    mov byte [dat_40af],0x0
    mov byte [dat_40b1],0x0
    mov byte [dat_40b9],0x1
    mov byte [dat_40b8],0x0
    mov word [dat_40c8],0xff
    ret
update_level5_objects:
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    cmp dx,[dat_40ad]
    jnz short lab_45b6
lab_45b5:
    ret
lab_45b6:
    mov [dat_40ad],dx
    cmp byte [dat_40aa],0xa4
    jnb short lab_45b5
    call check_l5_thrown_near
    jnb short lab_45d6
    call check_l5_landing
    jnb short lab_45b5
    mov byte [0x571],0x1
    mov byte [0x55b],0x10
    ret
lab_45d6:
    call check_l5_perch_hit
    jnb short lab_4649
    cmp byte [dat_40af],0x0
    jnz short lab_45fa
    mov al,[0x56e]
    cmp al,0x0
    jnz short lab_45f7
    inc al
    mov bx,[dat_40a8]
    cmp bx,[0x579]
    ja short lab_45f7
    mov al,0xff
lab_45f7:
    mov [dat_40b0],al
lab_45fa:
    mov byte [dat_40af],0x1
    mov cx,0x20
lab_4602:
    mov ax,[0x579]
    mov dl,0x1
    cmp byte [dat_40b0],0x1
    jnz short lab_4615
    db 0x2d, 0x08, 0x00                 ; sub ax,0x8
    mov dl,0xff
    jmp short lab_4618
lab_4615:
    db 0x05, 0x08, 0x00                 ; add ax,0x8
lab_4618:
    mov [0x579],ax
    mov [0x56e],dl
    mov al,[0x57b]
    cmp byte [0x571],0x1
    jb short lab_4639
    jnz short lab_462f
    sub al,0x3
    jmp short lab_4631
lab_462f:
    add al,0x3
lab_4631:
    mov [0x57b],al
    add al,0x32
    mov [0x57c],al
lab_4639:
    push cx
    call check_l5_perch_hit
    pop cx
    jnb short lab_4642
    loop short lab_4602
lab_4642:
    call restore_alley_buffer
    call save_cat_background
lab_4648:
    ret
lab_4649:
    cmp byte [dat_40b1],0x0
    jnz short lab_46a2
    cmp byte [dat_40af],0x0
    jz short lab_4648
    mov ax,[dat_40a8]
    cmp byte [dat_40b0],0x1
    jnz short lab_4666
    db 0x05, 0x08, 0x00                 ; add ax,0x8
    jmp short lab_4669
lab_4666:
    db 0x2d, 0x08, 0x00                 ; sub ax,0x8
lab_4669:
    mov [dat_40a8],ax
    call check_l5_perch_hit
    jnb short lab_4672
    ret
lab_4672:
    mov ax,0xc00
    mov bx,0xb54
    call start_tone
    mov byte [dat_40af],0x0
    mov cx,[dat_40a8]
    mov dl,[dat_40aa]
    call calc_cga_addr
    mov [dat_40ab],ax
    call erase_l5_perch
    call draw_l5_perch
    mov ax,[dat_40a8]
    db 0x3d, 0x78, 0x00                 ; cmp ax,0x78
    jb short lab_46a2
    cmp ax,0xa8
    ja short lab_46a2
    ret
lab_46a2:
    mov byte [dat_40b1],0x1
    cmp byte [enemy_chasing],0x0
    jz short lab_46be
    call check_l5_landing
    jnb short lab_46bd
    mov byte [0x571],0x1
    mov byte [0x55b],0x10
lab_46bd:
    ret
lab_46be:
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    cmp dx,[dat_40ad]
    jz short lab_46a2
    mov [dat_40ad],dx
    cmp byte [0x0],0x0
    jz short lab_46ec
    mov al,0xb6
    out byte 0x43,al
    mov al,[dat_40aa]
    db 0x2a, 0xe4                       ; sub ah,ah
    db 0xd1, 0xe0                       ; shl ax,0x0
    db 0xd1, 0xe0                       ; shl ax,0x0
    out byte 0x42,al
    db 0x8a, 0xc4                       ; mov al,ah
    out byte 0x42,al
    in al,byte 0x61
    or al,0x3
    out byte 0x61,al
lab_46ec:
    mov dl,[dat_40aa]
    cmp dl,0xa4
    jnb short lab_470e
    add dl,0x5
    mov [dat_40aa],dl
    mov cx,[dat_40a8]
    call calc_cga_addr
    mov [dat_40ab],ax
    call erase_l5_perch
    call draw_l5_perch
    jmp short lab_46be
lab_470e:
    call silence_speaker
    call erase_l5_perch
    mov bp,dat_401e
    dec word [dat_40a6]
    mov di,[dat_40a6]
    mov si,dat_3f36
    mov cx,0x1104
    call blit_masked
    mov ax,[dat_40a8]
    mov [dat_40b2],ax
    mov al,[dat_40aa]
    mov [dat_40b4],al
    call calc_l5_direction
    mov al,[dat_40ca]
    mov [dat_40b7],al
    ret
check_l5_perch_hit:
    mov ax,[dat_40a8]
    mov dl,[dat_40aa]
    mov si,0x18
    mov bx,[0x579]
    mov dh,[0x57b]
    db 0x8b, 0xfe                       ; mov di,si
    mov cx,0xe10
    call check_rect_collision
    ret
draw_l5_perch:
    mov ax,0xb800
    mov es,ax
    mov bp,dat_401e
    mov si,dat_3fbe
    mov di,[dat_40ab]
    mov [dat_40a6],di
    mov cx,0x1003
    call blit_masked
    ret
erase_l5_perch:
    mov ax,0xb800
    mov es,ax
    mov si,dat_401e
    mov di,[dat_40a6]
    mov cx,0x1003
    call blit_to_cga
    ret
check_l5_thrown_near:
    cmp byte [thrown_obj_y],0x66
    jb short lab_47a4
    mov ax,[dat_40a8]
    db 0x2d, 0x14, 0x00                 ; sub ax,0x14
    cmp ax,[thrown_obj_x]
    ja short lab_47a4
    db 0x05, 0x30, 0x00                 ; add ax,0x30
    cmp ax,[thrown_obj_x]
    jb short lab_47a4
    stc
    ret
lab_47a4:
    clc
    ret
    add [bx+si],al
    add [bx+si],al
    add [bx+si],al
    add [bx+si],al
    add [bx+si],al
check_thrown_near_cat:
    mov ax,[thrown_obj_x]
    mov dl,[thrown_obj_y]
    mov si,0x10
    mov bx,[0x579]
    sub bx,0x8
    jnb short lab_47c5
    db 0x2b, 0xdb                       ; sub bx,bx
lab_47c5:
    mov dh,[0x57b]
    add dh,0x3
    mov di,0x28
    mov cx,0xe1e
    call check_rect_collision
    ret
update_level6_timing:
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    db 0x8b, 0xc2                       ; mov ax,dx
    sub ax,[dat_44d7]
    mov si,[0x8]
    db 0xd1, 0xe6                       ; shl si,0x0
    cmp ax,[si+dat_44dc]
    ja short lab_47ed
lab_47ec:
    ret
lab_47ed:
    mov [dat_44d7],dx
    cmp byte [enemy_active],0x0
    jnz short lab_47ec
    mov byte [dat_44fc],0x0
    mov cx,0xc
lab_4800:
    db 0x8b, 0xd9                       ; mov bx,cx
    dec bx
    db 0xd0, 0xe3                       ; shl bl,0x0
    cmp word [bx+dat_4441],0x0
    jz short lab_487d
    mov ax,[bx+dat_43f9]
    cmp al,[0x57b]
    jnz short lab_485d
    mov ax,[bx+dat_43e1]
    sub ax,[0x579]
    jnb short lab_4822
    not ax
lab_4822:
    mov si,[0x8]
    db 0xd1, 0xe6                       ; shl si,0x0
    cmp ax,[si+dat_44ec]
    ja short lab_485d
    cmp word [bx+l6_obj_state],0x2
    jb short lab_484c
    mov ax,[bx+l6_obj_x]
    mov [dat_44da],ax
    call prepare_l6_erase
    call clear_l6_object
    call draw_thrown_sprite
    call draw_alley_foreground
    call activate_enemy_chase
    ret
lab_484c:
    inc word [bx+l6_obj_state]
    cmp word [bx+l6_obj_state],0x2
    jb short lab_4870
    inc byte [dat_44fc]
    jmp short lab_4870
lab_485d:
    cmp word [bx+l6_obj_state],0x0
    jz short lab_487d
    call random
    cmp dl,0x38
    ja short lab_4870
    dec word [bx+l6_obj_state]
lab_4870:
    push cx
    push bx
    call check_l6_proximity
    pop bx
    call draw_l6_alert
    call refresh_l6_display
    pop cx
lab_487d:
    loop short lab_488a
    cmp byte [dat_44fc],0x0
    jz short lab_4889
    call play_explosion_effect
lab_4889:
    ret
lab_488a:
    jmp near lab_4800
prepare_l6_erase:
    cmp byte [dat_44bd],0x0
    jz short lab_489d
    call erase_l6_tracker
    mov byte [dat_44bd],0x0
    ret
lab_489d:
    call restore_alley_buffer
    ret
clear_l6_object:
    push ds
    pop es
    cld
    mov di,0xe
    db 0x8b, 0xf7                       ; mov si,di
    mov ax,0xaaaa
    mov cx,0x41
    rep stosw
    mov ax,0xb800
    mov es,ax
    mov di,[dat_44da]
    mov cx,0xd05
    call blit_to_cga
    ret
refresh_l6_display:
    cmp byte [dat_44d9],0x0
    jz short lab_48d2
    cmp byte [dat_44bd],0x0
    jz short lab_48d3
    call draw_l6_tracker
lab_48d2:
    ret
lab_48d3:
    call draw_alley_foreground
    ret
check_l6_proximity:
    mov byte [dat_44d9],0x0
    mov ax,[bx+dat_43e1]
    mov dx,[bx+dat_43f9]
    db 0x2d, 0x14, 0x00                 ; sub ax,0x14
    mov si,0x28
    mov bx,[0x579]
    mov dh,[0x57b]
    mov cx,0xe06
    mov di,0x18
    call check_rect_collision
    jnb short lab_4915
    mov byte [dat_44d9],0x1
lab_4902:
    call check_vsync
    jz short lab_4902
    cmp byte [dat_44bd],0x0
    jz short lab_4912
    call erase_l6_tracker
    ret
lab_4912:
    call restore_alley_buffer
lab_4915:
    ret
draw_l6_alert:
    mov ax,[bx+l6_obj_x]
    mov si,[bx+l6_obj_state]
    db 0xd1, 0xe6                       ; shl si,0x0
    add si,dat_4100
    add ax,0xa7
    cmp word [bx+l6_obj_sprite_ptr],0x429c
    jz short lab_4935
    db 0x2d, 0x06, 0x00                 ; sub ax,0x6
    add si,0x6
lab_4935:
    db 0x8b, 0xf8                       ; mov di,ax
    mov ax,0xb800
    mov es,ax
    mov cx,0x101
    call blit_to_cga
    ret
update_level6_movement:
    cmp byte [enemy_active],0x0
    jnz short lab_4966
    cmp byte [dat_44be],0x0
    jz short lab_495c
    mov al,[dat_44be]
    mov [0x698],al
    mov byte [0x699],0x0
lab_495c:
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    cmp dx,[dat_44d3]
    jnz short lab_4967
lab_4966:
    ret
lab_4967:
    mov [dat_44d3],dx
    cmp byte [0x584],0x0
    jz short lab_4995
    cmp byte [dat_44bd],0x0
    jz short lab_4994
    call erase_l6_tracker
    call erase_thrown_sprite
    call save_alley_buffer
    call draw_thrown_sprite
    mov byte [dat_44bd],0x0
    mov byte [dat_43e0],0x1
    mov byte [dat_44be],0x0
lab_4994:
    ret
lab_4995:
    cmp byte [0x69a],0x0
    jz short lab_499f
    jmp short lab_49f9
    nop
lab_499f:
    mov ax,0xffff
    mov [dat_44c1],ax
    mov [dat_44bf],ax
    mov cx,0xc
    mov si,[0x579]
    mov dl,[0x57b]
    add dl,0x8
lab_49b6:
    db 0x8b, 0xd9                       ; mov bx,cx
    dec bx
    cmp byte [bx+dat_44c4],0x1
    jb short lab_49f0
    cmp dl,[bx+l6_obj_y]
    jnz short lab_49f0
    db 0x8b, 0xc6                       ; mov ax,si
    db 0xd0, 0xe3                       ; shl bl,0x0
    mov dh,0xff
    sub ax,[bx+l6_obj_dims]
    jnb short lab_49d6
    not ax
    mov dh,0x1
lab_49d6:
    cmp ax,[dat_44bf]
    ja short lab_49f0
    mov [dat_44bf],ax
    mov ax,[bx+dat_44a5]
    mov [dat_44d1],ax
    db 0xd0, 0xeb                       ; shr bl,0x0
    mov [dat_44c1],bx
    mov [dat_44c3],dh
lab_49f0:
    loop short lab_49b6
    cmp word [dat_44c1],0xc
    jb short lab_4a20
lab_49f9:
    cmp byte [dat_44bd],0x0
    jz short lab_4a0b
    call erase_l6_tracker
    call draw_alley_foreground
    mov byte [0x69a],0x10
lab_4a0b:
    mov byte [dat_44bd],0x0
    mov byte [dat_43e0],0x1
    mov byte [dat_44d0],0x0
    mov byte [dat_44be],0x0
    ret
lab_4a20:
    cmp word [dat_44bf],0x4
    jb short lab_4a4b
    cmp word [dat_44bf],0x8
    ja short lab_4a33
    mov byte [0x572],0x4
lab_4a33:
    mov al,[dat_44c3]
    mov [0x698],al
    mov [0x56e],al
    mov [dat_44be],al
    mov byte [0x699],0x0
    mov byte [0x571],0x0
    jmp short lab_49f9
lab_4a4b:
    mov byte [dat_44be],0x0
    cmp byte [dat_44bd],0x0
    jnz short lab_4a5d
    call restore_alley_buffer
    call save_alley_buffer
lab_4a5d:
    mov byte [dat_44bd],0x1
    db 0x2a, 0xc0                       ; sub al,al
    add byte [dat_44d0],0x30
    jnb short lab_4a6d
    inc al
lab_4a6d:
    mov [dat_44d5],al
    mov cx,[0x579]
    and cx,0xffc
    mov dl,[0x57b]
    add dl,0x3
    cmp word [dat_44d1],0x410c
    jz short lab_4a95
    add cx,0x8
    cmp cx,0x127
    jb short lab_4a9c
    mov cx,0x126
    jmp short lab_4a9c
lab_4a95:
    sub cx,0x8
    jnb short lab_4a9c
    db 0x2b, 0xc9                       ; sub cx,cx
lab_4a9c:
    call calc_cga_addr
    mov [dat_43dc],ax
lab_4aa2:
    call check_vsync
    jz short lab_4aa2
    call erase_l6_tracker
    cmp byte [dat_44d5],0x0
    jz short lab_4aff
    mov bx,[dat_44c1]
    cmp byte [bx+dat_44c4],0x0
    jz short lab_4aff
    dec byte [bx+dat_44c4]
    jnz short lab_4ae7
    push bx
    mov ax,0x8fd
    mov bx,0x723
    call start_tone
    pop bx
    mov byte [0x698],0x0
    mov byte [dat_44be],0x0
    mov byte [0x69a],0x10
    dec byte [dat_44d6]
    jnz short lab_4ae7
    mov byte [0x553],0x1
lab_4ae7:
    push bx
    call check_thrown_near_cat
    pop bx
    jnb short lab_4afc
    push bx
    call erase_thrown_sprite
    pop bx
    call draw_l6_tile
    call draw_thrown_sprite
    jmp short lab_4aff
    nop
lab_4afc:
    call draw_l6_tile
lab_4aff:
    call draw_l6_tracker
    ret
erase_l6_tracker:
    cmp byte [dat_43e0],0x0
    jnz short lab_4b1c
    mov di,[dat_43de]
    mov si,dat_43a0
    mov ax,0xb800
    mov es,ax
    mov cx,0xa03
    call blit_to_cga
lab_4b1c:
    ret
draw_l6_tracker:
    mov byte [dat_43e0],0x0
    mov ax,0xb800
    mov es,ax
    mov di,[dat_43dc]
    mov [dat_43de],di
    mov bp,dat_43a0
    mov si,[dat_44d1]
    cmp byte [dat_44d0],0x80
    jb short lab_4b40
    add si,0x3c
lab_4b40:
    mov cx,0xa03
    call blit_masked
    ret
init_level6_objects:
    push ds
    pop es
    db 0x2b, 0xc0                       ; sub ax,ax
    mov di,dat_4441
    mov cx,0xc
    rep stosw
    mov ax,0xb800
    mov es,ax
    mov bx,[0x8]
    mov cl,[bx+l6_obj_type]
    db 0x2a, 0xed                       ; sub ch,ch
lab_4b62:
    call random
    db 0x8a, 0xda                       ; mov bl,dl
    db 0x81, 0xe3, 0x1e, 0x00           ; and bx,0x1e
    cmp bl,0x18
    jnb short lab_4b62
    cmp word [bx+dat_4441],0x0
    jnz short lab_4b62
    mov word [bx+l6_obj_state],0x0
    mov word [bx+dat_4441],0x1
    push cx
    mov si,[bx+l6_obj_sprite_ptr]
    mov di,[bx+l6_obj_x]
    mov cx,0xd05
    call blit_to_cga
    pop cx
    loop short lab_4b62
    mov cx,0xc
lab_4b98:
    db 0x8b, 0xd9                       ; mov bx,cx
    dec bx
    mov si,[0x8]
    mov dl,[si+l6_obj_init_y_tbl]
    mov [bx+dat_44c4],dl
    push cx
    call draw_l6_tile
    pop cx
    loop short lab_4b98
    mov byte [dat_44d0],0x0
    mov byte [dat_44bd],0x0
    mov byte [dat_43e0],0x1
    mov byte [dat_44d6],0xc
    mov byte [dat_44be],0x0
    ret
draw_l6_tile:
    call calc_l6_addr
    db 0x8b, 0xf8                       ; mov di,ax
    mov al,[bx+dat_44c4]
    db 0x2a, 0xe4                       ; sub ah,ah
    mov cl,0x5
    shl ax,cl
    add ax,l5_sprite_table_base
    db 0x8b, 0xf0                       ; mov si,ax
    mov cx,0x802
    mov ax,0xb800
    mov es,ax
    call blit_to_cga
    ret
calc_l6_addr:
    push bx
    mov dl,[bx+l6_obj_y]
    db 0xd0, 0xe3                       ; shl bl,0x0
    mov cx,[bx+l6_obj_dims]
    call calc_cga_addr
    pop bx
    ret
    add [bx+si],al
    add [bx+si],al
    add [bx+si],al
    add [bx+si],al
level6_stubs:
    ret
    ret
    ret
    ret
    clc
    ret
    clc
    ret
    ret
    add [bx+si],al
    add [bx+si],al
    add [bx+si],al
    db 0x00
update_level7_objects:
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    cmp dx,[l7_heart_tick]
    jnz short lab_4c1b
    ret
lab_4c1b:
    inc word [l7_heart_index]
    mov bx,[l7_heart_index]
    cmp bx,0x1
    jz short lab_4c38
    cmp bx,0x4
    jz short lab_4c38
    cmp bx,0x7
    jb short lab_4c3c
    db 0x2b, 0xdb                       ; sub bx,bx
    mov [l7_heart_index],bx
lab_4c38:
    mov [l7_heart_tick],dx
lab_4c3c:
    call load_l7_slot
    call check_l7_cupid
    jnb short lab_4c45
lab_4c44:
    ret
lab_4c45:
    cmp word [l7_cat_last_tick],0x0
    jz short lab_4c8c
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    sub dx,[l7_cat_last_tick]
    mov bx,[0x8]
    db 0xd0, 0xe3                       ; shl bl,0x0
    mov ax,[bx+l7_heart_sprite_table]
    cmp word [l7_heart_index],0x0
    jnz short lab_4c67
    db 0xd1, 0xe0                       ; shl ax,0x0
lab_4c67:
    db 0x3b, 0xd0                       ; cmp dx,ax
    jb short lab_4c44
    mov word [l7_cat_last_tick],0x0
    mov byte [l7_cat_moving],0x1
    mov ax,0x24
    cmp word [0x579],0xa0
    ja short lab_4c84
    mov ax,0x108
lab_4c84:
    mov [l7_cat_x],ax
    mov byte [l7_cat_dir],0x0
lab_4c8c:
    call check_l7_cat_hit
    jnb short lab_4c99
    mov bx,[l7_heart_index]
    call save_l7_slot
    ret
lab_4c99:
    cmp byte [l7_cat_delay],0x0
    jz short lab_4cb8
    dec byte [l7_cat_delay]
    jnz short lab_4cb5
    mov dl,0x1
    cmp byte [l7_cat_dir],0xff
    jz short lab_4cb1
    mov dl,0xff
lab_4cb1:
    mov [l7_cat_dir],dl
lab_4cb5:
    jmp short lab_4d14
    nop
lab_4cb8:
    mov al,[l7_cat_y]
    cmp al,[0x57b]
    ja short lab_4d14
    cmp word [l7_heart_index],0x6
    jnz short lab_4ccf
    cmp byte [0x57b],0x28
    jb short lab_4cdc
lab_4ccf:
    call random
    mov bx,[0x8]
    cmp dl,[bx+l7_heart_y_table]
    ja short lab_4d14
lab_4cdc:
    db 0x2a, 0xd2                       ; sub dl,dl
    mov ax,[l7_cat_x]
    and ax,0xff8
    mov cx,[0x579]
    and cx,0xff8
    db 0x3b, 0xc1                       ; cmp ax,cx
    jz short lab_4cf6
    mov dl,0x1
    jb short lab_4cf6
    mov dl,0xff
lab_4cf6:
    mov [l7_cat_dir],dl
    cmp byte [0x57b],0x28
    jb short lab_4d14
    cmp word [l7_heart_index],0x6
    jnz short lab_4d14
    mov al,0x1
    cmp dl,0xff
    jz short lab_4d11
    mov al,0xff
lab_4d11:
    mov [l7_cat_dir],al
lab_4d14:
    mov word [l7_heart_speed],0x8
    cmp byte [l7_cat_delay],0x0
    jz short lab_4d27
    mov word [l7_heart_speed],0x4
lab_4d27:
    mov ax,[l7_cat_x]
    cmp byte [l7_cat_dir],0x1
    jnb short lab_4d46
    call random
    cmp dl,0x10
    ja short lab_4da1
    and dl,0x1
    jnz short lab_4d40
    mov dl,0xff
lab_4d40:
    mov [l7_cat_dir],dl
    jmp short lab_4da1
lab_4d46:
    jnz short lab_4d60
    add ax,[l7_heart_speed]
    cmp ax,0x10b
    jb short lab_4d78
    mov ax,0x10a
    mov byte [l7_cat_dir],0xff
    mov byte [l7_cat_delay],0x0
    jmp short lab_4d78
lab_4d60:
    sub ax,[l7_heart_speed]
    jb short lab_4d6b
    db 0x3d, 0x24, 0x00                 ; cmp ax,0x24
    ja short lab_4d78
lab_4d6b:
    mov ax,0x25
    mov byte [l7_cat_dir],0x1
    mov byte [l7_cat_delay],0x0
lab_4d78:
    mov [l7_cat_x],ax
    add word [l7_cat_anim_idx],0x2
    cmp word [l7_cat_anim_idx],0xc
    jb short lab_4d8d
    mov word [l7_cat_anim_idx],0x0
lab_4d8d:
    cmp byte [l7_cat_delay],0x0
    jnz short lab_4da1
    call random
    cmp dl,0x8
    ja short lab_4da1
    mov byte [l7_cat_dir],0x0
lab_4da1:
    mov cx,[l7_cat_x]
    mov dl,[l7_cat_y]
    call calc_cga_addr
    mov [l7_heart_cga_addr],ax
    call check_l7_cupid
    jnb short lab_4db5
    ret
lab_4db5:
    call check_l7_cat_hit
    jb short lab_4dc8
    call erase_l7_sprite
    call setup_l7_sprite
    mov byte [l7_heart_caught],0x0
    call check_l7_object_overlap
lab_4dc8:
    mov bx,[l7_heart_index]
    call save_l7_slot
    ret
check_l7_cat_hit:
    mov ax,[0x579]
    mov dl,[0x57b]
    mov si,0x18
    db 0x8b, 0xfe                       ; mov di,si
    mov bx,[l7_cat_x]
    mov dh,[l7_cat_y]
    mov cx,0xc0e
    call check_rect_collision
    jnb short lab_4e3d
    cmp word [l7_heart_index],0x6
    jnz short lab_4e00
    mov byte [0x553],0x1
    call restore_alley_buffer
    call erase_l7_sprite
    stc
    ret
lab_4e00:
    call restore_alley_buffer
    call erase_l7_sprite
    call draw_alley_foreground
    mov byte [0x55b],0x4
    mov byte [0x571],0x1
    mov byte [0x576],0x4
    mov byte [0x578],0x8
    mov byte [l7_cat_delay],0x4
    mov dl,0x1
    mov ax,[l7_cat_x]
    cmp ax,[0x579]
    ja short lab_4e2f
    mov dl,0xff
lab_4e2f:
    mov [l7_cat_dir],dl
    mov ax,0xce4
    mov bx,l5_sprite_ptr
    call start_tone
    stc
lab_4e3d:
    ret
check_l7_all_objects:
    mov byte [l7_heart_caught],0x1
    mov ax,[l7_heart_index]
    push ax
    mov word [l7_heart_index],0x0
lab_4e4d:
    mov bx,[l7_heart_index]
    call load_l7_slot
    cmp word [l7_cat_last_tick],0x0
    jnz short lab_4e65
    call check_l7_object_overlap
    mov bx,[l7_heart_index]
    call save_l7_slot
lab_4e65:
    inc word [l7_heart_index]
    cmp word [l7_heart_index],0x7
    jb short lab_4e4d
    pop ax
    mov [l7_heart_index],ax
    ret
check_l7_object_overlap:
    mov cx,0x8
lab_4e78:
    db 0x8b, 0xd9                       ; mov bx,cx
    dec bx
    cmp byte [bx+l7_obj_active],0x0
    jz short lab_4ea3
    push cx
    mov dl,[bx+l7_obj_y]
    db 0xd0, 0xe3                       ; shl bl,0x0
    mov ax,[bx+l7_obj_x]
    mov si,0x18
    db 0x8b, 0xfe                       ; mov di,si
    mov bx,[l7_cat_x]
    mov dh,[l7_cat_y]
    mov cx,0xc0f
    call check_rect_collision
    pop cx
    jb short lab_4ea6
lab_4ea3:
    loop short lab_4e78
    ret
lab_4ea6:
    push cx
    cmp byte [l7_heart_caught],0x0
    jnz short lab_4ebb
    call restore_alley_buffer
    cmp byte [cupid_active],0x0
    jz short lab_4ebb
    call erase_cupid
lab_4ebb:
    call erase_l7_sprite
    pop cx
    db 0x8b, 0xd9                       ; mov bx,cx
    dec bx
    mov byte [bx+l7_obj_active],0x0
    mov dl,[bx+l7_obj_y]
    db 0xd0, 0xe3                       ; shl bl,0x0
    mov cx,[bx+l7_obj_x]
    call calc_cga_addr
    db 0x8b, 0xf8                       ; mov di,ax
    mov si,l7_obj_erase_sprite
    mov ax,0xb800
    mov es,ax
    mov cx,0xf03
    call blit_to_cga
    cmp byte [l7_heart_caught],0x0
    jnz short lab_4ef8
    cmp byte [cupid_active],0x0
    jz short lab_4ef5
    call draw_cupid
lab_4ef5:
    call draw_alley_foreground
lab_4ef8:
    db 0x2b, 0xd2                       ; sub dx,dx
    cmp word [l7_heart_index],0x6
    jz short lab_4f0b
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    cmp dx,0x0
    jnz short lab_4f0b
    dec dx
lab_4f0b:
    mov [l7_cat_last_tick],dx
    ret
setup_l7_sprite:
    mov byte [l7_cat_moving],0x0
    mov si,dat_4500
    cmp byte [l7_cat_dir],0x0
    jz short lab_4f3e
    mov bx,[l7_cat_anim_idx]
    cmp byte [l7_cat_delay],0x0
    jz short lab_4f30
    and bl,0x2
    add bl,0xc
lab_4f30:
    cmp byte [l7_cat_dir],0xff
    jnz short lab_4f3a
    add bx,0x10
lab_4f3a:
    mov si,[bx+dat_4a60]
lab_4f3e:
    mov di,[l7_heart_cga_addr]
    mov [l7_cat_save_addr],di
    call draw_l7_sprite
    ret
erase_l7_sprite:
    cmp byte [l7_cat_moving],0x0
    jnz short lab_4f58
    mov di,[l7_cat_save_addr]
    call clear_l7_sprite
lab_4f58:
    ret
init_level7_objects:
    mov word [l7_heart_index],0x0
lab_4f5f:
    call random
    db 0x81, 0xe2, 0x7f, 0x00           ; and dx,0x7f
    add dx,0x60
    mov [l7_cat_x],dx
    mov byte [l7_cat_dir],0x0
    mov byte [l7_cat_moving],0x1
    mov word [l7_cat_anim_idx],0x0
    mov byte [l7_cat_delay],0x0
    db 0x2b, 0xd2                       ; sub dx,dx
    cmp word [l7_heart_index],0x0
    jnz short lab_4f95
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    cmp dx,0x0
    jnz short lab_4f95
    dec dx
lab_4f95:
    mov [l7_cat_last_tick],dx
    mov bx,[l7_heart_index]
    mov al,[bx+window_row_y_table]
    add al,0x3
    mov [l7_cat_y],al
    call save_l7_slot
    inc word [l7_heart_index]
    cmp word [l7_heart_index],0x7
    jb short lab_4f5f
    mov word [l7_heart_index],0x0
    ret
save_l7_slot:
    push ds
    pop es
    db 0xd0, 0xe3                       ; shl bl,0x0
    cld
    mov di,[bx+l7_save_buf_ptrs]
    mov si,l7_cat_x
    mov cx,0xc
    rep movsb
    ret
load_l7_slot:
    push ds
    pop es
    db 0xd0, 0xe3                       ; shl bl,0x0
    cld
    mov si,[bx+l7_save_buf_ptrs]
    mov di,l7_cat_x
    mov cx,0xc
    rep movsb
    ret
draw_l7_sprite:
    mov ax,0xb800
    mov es,ax
    cld
    mov dh,0xc
lab_4fe7:
    mov cx,0x3
lab_4fea:
    mov bx,[es:di]
    lodsw
    db 0x0b, 0xc3                       ; or ax,bx
    stosw
    loop short lab_4fea
    sub di,0x6
    xor di,0x2000
    test di,0x2000
    jnz short lab_5003
    add di,0x50
lab_5003:
    dec dh
    jnz short lab_4fe7
    ret
clear_l7_sprite:
    mov ax,0xb800
    mov es,ax
    cld
    mov dh,0xc
    mov ax,0x5555
lab_5013:
    mov cx,0x3
    rep stosw
    sub di,0x6
    xor di,0x2000
    test di,0x2000
    jnz short lab_5028
    add di,0x50
lab_5028:
    dec dh
    jnz short lab_5013
    ret
check_l7_cupid:
    cmp byte [cupid_active],0x0
    jnz short lab_5036
    clc
    ret
lab_5036:
    mov ax,[cupid_x]
    mov dl,[cupid_y]
    mov si,0x10
    mov bx,[l7_cat_x]
    mov dh,[l7_cat_y]
    mov di,0x18
    mov cx,0xc08
    call check_rect_collision
    ret
    add [bx+si],al
    add [bx+si],al
    add [bx+si],al
    add [bx+si],al
    add [bx+si],al
    add [bx+si],al
    add [bx+si],al
position_victory_cat:
    mov ax,0xb800
    mov es,ax
    mov ax,[0x579]
    cmp ax,0x117
    jb short lab_5070
    mov ax,0x116
lab_5070:
    db 0x2d, 0x10, 0x00                 ; sub ax,0x10
    jnb short lab_5077
    db 0x2b, 0xc0                       ; sub ax,ax
lab_5077:
    and ax,0xff0
    mov [0x579],ax
    mov byte [0x57b],0x14
    sub ax,0x80
    jnb short lab_5089
    not ax
lab_5089:
    mov cl,0x3
    shr ax,cl
    db 0x3d, 0x0d, 0x00                 ; cmp ax,0xd
    jbe short lab_5095
    mov ax,0xd
lab_5095:
    db 0x05, 0x02, 0x00                 ; add ax,0x2
    mov [l7_cupid_dx],ax
    mov word [l7_cupid_tick],0xa
lab_50a1:
    cmp word [l7_cupid_tick],0xa
    jz short lab_50ab
    call play_victory_note
lab_50ab:
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    mov [dat_4a80],dx
    mov ax,[0x579]
    db 0x8b, 0xc8                       ; mov cx,ax
    and cx,0xff0
    cmp cx,0x80
    jnz short lab_50c6
    db 0x8b, 0xc1                       ; mov ax,cx
    jmp short lab_50d2
lab_50c6:
    jb short lab_50ce
    sub ax,[l7_cupid_dx]
    jmp short lab_50d2
lab_50ce:
    add ax,[l7_cupid_dx]
lab_50d2:
    mov [0x579],ax
    cmp byte [0x57b],0x54
    jb short lab_50dd
    ret
lab_50dd:
    add byte [0x57b],0x8
    mov cx,[0x579]
    add cx,0x4
    mov dl,[0x57b]
    call calc_cga_addr
    db 0x8b, 0xf8                       ; mov di,ax
    mov [l7_cupid_cga_addr],di
    mov si,dat_4b8a
    mov bp,0xe
    mov cx,0x2007
    call blit_transparent
    mov di,[l7_cupid_cga_addr]
    add di,0xf3
    mov si,dat_4a82
    mov cx,0xd04
    call blit_to_cga
    cmp word [l7_cupid_tick],0xa
    jnz short lab_5120
    call play_swoop_sound
    call init_victory_melody
lab_5120:
    call play_victory_note
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    sub dx,[dat_4a80]
    cmp dx,[l7_cupid_tick]
    jb short lab_5120
    cmp word [l7_cupid_tick],0xa
    jnz short lab_5141
    call handle_level_complete
    db 0x2b, 0xdb                       ; sub bx,bx
    mov ah,0xb
    int byte 0x10
lab_5141:
    mov word [l7_cupid_tick],0x2
    jmp near lab_50a1
animate_victory_pairs:
    mov cx,0x3
lab_514d:
    mov bx,0x3
    db 0x2b, 0xd9                       ; sub bx,cx
    db 0xd1, 0xe3                       ; shl bx,0x0
    mov ax,[bx+l7_cupid_dx_tbl]
    mov [l7_cupid_dx],ax
    mov ax,[bx+l7_cupid_dy_tbl]
    mov [l7_cupid_dy],ax
    mov ax,[bx+l7_cupid_x_init_tbl]
    mov [l7_cupid_x_init],ax
    mov ax,[bx+l7_cupid_y_init_tbl]
    mov [l7_cupid_y_init],ax
    mov ax,[bx+l7_cupid_x_max_tbl]
    mov [l7_cupid_x_max],ax
    mov ax,[bx+l7_cupid_y_max_tbl]
    mov [l7_cupid_y_max],ax
    mov ax,[bx+l7_cupid_dims_tbl]
    mov [l7_cupid_dims],ax
    mov ax,[bx+l7_cupid_sprite_tbl]
    mov [l7_cupid_sprite_ptr],ax
    mov ax,[bx+l7_cupid_save_tbl]
    mov [l7_cupid_save_ptr],ax
    push cx
    call init_victory_wave
    pop cx
    loop short lab_514d
    ret
init_victory_wave:
    mov cx,0x8
    mov byte [l7_cupid_active],0x1
lab_51a3:
    push cx
    call play_victory_note
    pop cx
    db 0x8b, 0xd9                       ; mov bx,cx
    dec bx
    db 0xd1, 0xe3                       ; shl bx,0x0
    mov ax,[l7_cupid_x_init]
    mov [bx+l7_cupid_x],ax
    mov ax,[l7_cupid_y_init]
    mov [bx+l7_cupid_y],ax
    loop short lab_51a3
    mov ax,0xb800
    mov es,ax
    mov byte [l7_cupid_bounce_cnt],0x0
lab_51c7:
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    mov [dat_4a80],dx
    mov cx,0x8
lab_51d2:
    push cx
    call play_victory_note
    pop cx
    db 0x8b, 0xd9                       ; mov bx,cx
    dec bx
    db 0xd1, 0xe3                       ; shl bx,0x0
    push cx
    push bx
    cmp byte [l7_cupid_active],0x0
    jz short lab_51ea
    cmp cx,0x8
    jnz short lab_5205
lab_51ea:
    mov cx,[bx+l7_cupid_x]
    mov dx,[bx+l7_cupid_y]
    call calc_cga_addr
    db 0x8b, 0xf8                       ; mov di,ax
    mov si,[l7_cupid_sprite_ptr]
    mov bp,0xe
    mov cx,[l7_cupid_dims]
    call blit_transparent
lab_5205:
    pop bx
    pop cx
    call move_victory_object
    loop short lab_51d2
lab_520c:
    call play_victory_note
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    sub dx,[dat_4a80]
    cmp dx,[l7_cupid_save_ptr]
    jb short lab_520c
    mov byte [l7_cupid_active],0x0
    cmp byte [l7_cupid_bounce_cnt],0x0
    jz short lab_51c7
    ret
move_victory_object:
    mov ax,[bx+l7_cupid_x]
    cmp word [bx+l7_cupid_x_dir],0x1
    jb short lab_525a
    jnz short lab_524a
    add ax,[l7_cupid_dx]
    cmp ax,[l7_cupid_x_max]
    jbe short lab_5256
    mov ax,[l7_cupid_x_max]
    inc byte [l7_cupid_bounce_cnt]
    jmp short lab_5256
lab_524a:
    sub ax,[l7_cupid_dx]
    jnb short lab_5256
    db 0x2b, 0xc0                       ; sub ax,ax
    inc byte [l7_cupid_bounce_cnt]
lab_5256:
    mov [bx+l7_cupid_x],ax
lab_525a:
    mov ax,[bx+l7_cupid_y]
    cmp word [bx+l7_cupid_y_dir],0x1
    jb short lab_528a
    jnz short lab_527a
    add ax,[l7_cupid_dy]
    cmp ax,[l7_cupid_y_max]
    jbe short lab_5286
    mov ax,[l7_cupid_y_max]
    inc byte [l7_cupid_bounce_cnt]
    jmp short lab_5286
lab_527a:
    sub ax,[l7_cupid_dy]
    jnb short lab_5286
    db 0x2b, 0xc0                       ; sub ax,ax
    inc byte [l7_cupid_bounce_cnt]
lab_5286:
    mov [bx+l7_cupid_y],ax
lab_528a:
    ret
run_victory_sequence:
    call init_victory_melody
    cmp byte [0x697],0xfd
    jz short lab_529c
    mov ah,0xb
    mov bx,0x101
    int byte 0x10
lab_529c:
    call position_victory_cat
    call animate_victory_pairs
    call play_full_victory
    cmp byte [lives_count],0x9
    jnb short lab_52b0
    inc byte [lives_count]
lab_52b0:
    cmp word [0x8],0x7
    jnb short lab_52bb
    inc word [0x8]
lab_52bb:
    mov word [0x414],0x0
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    mov [0x412],dx
    call silence_speaker
    ret
    add [bx+si],al
    db 0x00
play_march_note:
    cmp byte [0x0],0x0
    jz short lab_5312
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    cmp dx,[l7_bg_anim_tick]
    jz short lab_5312
    mov [l7_bg_anim_tick],dx
    mov bx,[l7_bg_anim_idx]
    add word [l7_bg_anim_idx],0x2
    mov ax,[bx+l7_bg_sprite_seq]
    cmp ax,[l7_bg_cur_sprite]
    jnz short lab_52fc
    call silence_speaker
    ret
lab_52fc:
    mov [l7_bg_cur_sprite],ax
    mov al,0xb6
    out byte 0x43,al
    mov ax,[l7_bg_cur_sprite]
    out byte 0x42,al
    db 0x8a, 0xc4                       ; mov al,ah
    out byte 0x42,al
    in al,byte 0x61
    or al,0x3
    out byte 0x61,al
lab_5312:
    ret
play_victory_march:
    cmp word [0x8],0x2
    jb short lab_5367
    mov word [l7_bg_xor_flag],0x0
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    mov [l7_bg_last_tick_1],dx
    mov [l7_bg_last_tick_2],dx
    mov [l7_bg_anim_tick],dx
    mov word [l7_bg_anim_idx],0x0
    mov word [l7_bg_cur_sprite],0x0
lab_533c:
    call draw_march_frame
    db 0x81, 0x36, 0x16, 0x50, 0x02, 0x00 ; xor word [0x5016],0x2
lab_5345:
    call play_march_note
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    db 0x8b, 0xc2                       ; mov ax,dx
    sub ax,[l7_bg_last_tick_1]
    db 0x3d, 0x05, 0x00                 ; cmp ax,0x5
    jb short lab_5345
    mov [l7_bg_last_tick_1],dx
    sub dx,[l7_bg_last_tick_2]
    cmp dx,0x28
    jb short lab_533c
    call silence_speaker
lab_5367:
    ret
draw_march_frame:
    mov ax,0xb800
    mov es,ax
    mov bx,[0x8]
    db 0xd1, 0xe3                       ; shl bx,0x0
    mov ax,[bx+l7_bg_pattern_tbl]
    mov [l7_bg_sprite_idx],ax
lab_537a:
    mov bx,[l7_bg_sprite_idx]
    mov di,[bx]
    cmp di,0x0
    jnz short lab_5386
    ret
lab_5386:
    mov bx,[bx+0x2]
    xor bx,[l7_bg_xor_flag]
    db 0x81, 0xe3, 0x02, 0x00           ; and bx,0x2
    mov si,[bx+l7_bg_sprite_ptrs]
    mov cx,0x2304
    call blit_to_cga
    call play_march_note
    add word [l7_bg_sprite_idx],0x4
    jmp short lab_537a
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00


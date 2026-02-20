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
lab_2e60:
    cmp word [0x2e8d],0x8
    jb short lab_2e68
lab_2e67:
    ret
lab_2e68:
    cmp byte [0x69a],0x0
    jnz short lab_2e67
    mov word [0x2e92],0xffff
    mov byte [0x2e91],0xff
    mov cx,0x7
lab_2e7d:
    db 0x8b, 0xd9                       ; mov bx,cx
    dec bx
    mov al,[0x57b]
    sub al,[bx+0x2bd4]
    jnb short lab_2e8b
    not al
lab_2e8b:
    cmp al,[0x2e91]
    ja short lab_2e98
    mov [0x2e91],al
    mov [0x2e92],bx
lab_2e98:
    loop short lab_2e7d
    db 0x81, 0x3e, 0x92, 0x2e, 0xff, 0xff ; cmp word [0x2e92],0xffff
    jnz short lab_2ea8
    mov word [0x2e92],0x0
lab_2ea8:
    mov bx,[0x2e8d]
    mov si,[0x2e92]
    mov al,[si+0x2bd4]
    mov [bx+0x2b6a],al
    mov [0x2e98],al
    mov ax,[0x579]
    db 0xd0, 0xe3                       ; shl bl,0x0
    cmp ax,0x108
    jb short lab_2ec8
    mov ax,0x107
lab_2ec8:
    and ax,0xffc
    mov [bx+0x2b5a],ax
    mov [0x2e96],ax
    mov cx,0x8
lab_2ed5:
    db 0x8b, 0xd9                       ; mov bx,cx
    dec bx
    cmp bx,[0x2e8d]
    jz short lab_2f07
    cmp byte [bx+0x2b72],0x0
    jz short lab_2f07
    push cx
    mov dl,[bx+0x2b6a]
    db 0xd0, 0xe3                       ; shl bl,0x0
    mov ax,[bx+0x2b5a]
    mov bx,[0x2e96]
    mov dh,[0x2e98]
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
    cmp byte [0x70f2],0x0
    jz short lab_2f16
    call erase_cupid
lab_2f16:
    mov bx,[0x2e8d]
    mov [0x2e94],bx
    mov byte [bx+0x2b72],0x1
    mov dl,[bx+0x2b6a]
    db 0xd0, 0xe3                       ; shl bl,0x0
    mov cx,[bx+0x2b5a]
    call calc_cga_addr
    db 0x8b, 0xf8                       ; mov di,ax
    mov si,0x2af0
    mov ax,0xb800
    mov es,ax
    mov cx,0xf03
    call blit_to_cga
    mov word [0x2e8d],0xffff
    db 0x2b, 0xdb                       ; sub bx,bx
    mov ah,0xb
    int byte 0x10
    call lab_4e3e
    cmp byte [0x70f2],0x0
    jz short lab_2f59
    call draw_cupid
lab_2f59:
    call draw_alley_foreground
    mov ax,0x3e8
    mov bx,0x4a5
    call start_tone
    ret
lab_2f66:
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    cmp dx,[0x2e8f]
    jnz short lab_2f71
    ret
lab_2f71:
    mov [0x2e8f],dx
    cmp word [0x2e8d],0x8
    jb short lab_2fac
    mov cx,0x8
lab_2f7f:
    db 0x8b, 0xd9                       ; mov bx,cx
    dec bx
    cmp byte [bx+0x2b72],0x0
    jz short lab_2faa
    push cx
    mov dl,[bx+0x2b6a]
    db 0xd0, 0xe3                       ; shl bl,0x0
    mov ax,[bx+0x2b5a]
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
    mov word [0x2e94],0xffff
lab_2fb2:
    ret
lab_2fb3:
    db 0x8b, 0xd9                       ; mov bx,cx
    dec bx
    cmp bx,[0x2e94]
    jz short lab_2fb2
    push bx
    call restore_alley_buffer
    cmp byte [0x70f2],0x0
    jz short lab_2fca
    call erase_cupid
lab_2fca:
    pop bx
    mov byte [bx+0x2b72],0x0
    mov dl,[bx+0x2b6a]
    mov [0x2e8d],bx
    db 0xd0, 0xe3                       ; shl bl,0x0
    mov cx,[bx+0x2b5a]
    call calc_cga_addr
    db 0x8b, 0xf8                       ; mov di,ax
    mov si,0x2b7a
    mov ax,0xb800
    mov es,ax
    mov cx,0xf03
    call blit_to_cga
    cmp byte [0x70f2],0x0
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
lab_300f:
    db 0x2b, 0xc0                       ; sub ax,ax
    mov bx,0x2e24
    call draw_block_list
    mov byte [0x2e8a],0xbf
    mov word [0x2e8b],0x0
lab_3022:
    mov word [0x2e88],0x20
lab_3028:
    db 0x2b, 0xdb                       ; sub bx,bx
    cmp byte [0x2e8a],0xbf
    jz short lab_3039
    call random
    db 0x8a, 0xda                       ; mov bl,dl
    and bl,0x2
lab_3039:
    mov cx,[0x2e88]
    mov dl,[0x2e8a]
    push bx
    call lab_30e3
    pop bx
    mov si,[0x2e8b]
    mov ax,[0x2e88]
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
    mov dl,[si+0x2bdb]
    db 0x2a, 0xf6                       ; sub dh,dh
    db 0x03, 0xc2                       ; add ax,dx
    db 0x8b, 0xf0                       ; mov si,ax
    mov [si+0x2be2],bl
    add word [0x2e88],0x10
    cmp word [0x2e88],0x111
    jb short lab_3028
    inc word [0x2e8b]
    sub byte [0x2e8a],0x18
    cmp byte [0x2e8a],0x2f
    jnb short lab_3022
    mov ax,0xffff
    mov [0x2e8d],ax
    mov [0x2e94],ax
    db 0x2b, 0xc0                       ; sub ax,ax
    mov [0x2b72],ax
    mov [0x2b74],ax
    mov [0x2b76],ax
    mov [0x2b78],ax
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
    mov byte [bx+0x2b72],0x1
    mov dl,0xb0
    mov [bx+0x2b6a],dl
    push cx
    db 0xd0, 0xe3                       ; shl bl,0x0
    mov cx,[bx+0x2b4a]
    mov [bx+0x2b5a],cx
    call calc_cga_addr
    db 0x8b, 0xf8                       ; mov di,ax
    mov si,0x2af0
    mov cx,0xf03
    call blit_to_cga
    pop cx
    loop short lab_30b8
    ret
lab_30e3:
    push bx
    call calc_cga_addr
    db 0x8b, 0xf8                       ; mov di,ax
    mov ax,0xb800
    mov es,ax
    pop bx
    mov si,[bx+0x2e20]
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
    cmp al,byte [bx + 0x2bd4]
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
    mov dl,byte [bx + 0x2bdb]
    db 0x2a, 0xf6                       ; sub dh,dh
    db 0x03, 0xc2                       ; add ax,dx
    db 0x8b, 0xf0                       ; mov si,ax
    cmp byte [si + 0x2be2],0x0
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
lab_3150:
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    mov bx,[0x4]
    db 0xd0, 0xe3                       ; shl bl,0x0
    mov cx,[bx+0x32f2]
    db 0x8b, 0xc2                       ; mov ax,dx
    sub ax,[0x328c]
    db 0x3b, 0xc1                       ; cmp ax,cx
    jnb short lab_3169
lab_3168:
    ret
lab_3169:
    mov [0x328c],dx
    call lab_33ba
    jb short lab_3168
    call check_enemy_object_hit
    jb short lab_3168
    inc byte [0x32ea]
    call random
    mov al,[0x32ea]
    db 0x22, 0xc2                       ; and al,dl
    xor [0x32eb],al
    mov ax,[0x327d]
    sub ax,[0x579]
    mov dl,0xff
    jnb short lab_3196
    not ax
    mov dl,0x1
lab_3196:
    mov [0x32ed],dl
    mov bl,[0x327f]
    add bl,0x14
    sub bl,[0x57b]
    mov dl,0xff
    jnb short lab_31ad
    not bl
    mov dl,0x1
lab_31ad:
    mov [0x32ee],dl
    db 0xd1, 0xe8                       ; shr ax,0x0
    db 0xd1, 0xe8                       ; shr ax,0x0
    db 0xd0, 0xeb                       ; shr bl,0x0
    db 0x02, 0xc3                       ; add al,bl
    mov [0x32ec],al
    mov bx,[0x328a]
    cmp bx,0x27
    jb short lab_31cc
    mov bx,0x26
    mov [0x328a],bx
lab_31cc:
    cmp byte [bx+0x328e],0x0
    jnz short lab_324b
    dec word [0x328a]
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    sub dx,[0x410]
    mov cl,0x3
    shr dx,cl
    mov al,[0x32ec]
    db 0x2a, 0xc2                       ; sub al,dl
    jnb short lab_31ec
    db 0x2a, 0xc0                       ; sub al,al
lab_31ec:
    cmp al,[0x32eb]
    jb short lab_3212
    mov byte [0x3281],0x1
    call random
    cmp dl,0x0
    jz short lab_320b
    cmp dl,0x7
    ja short lab_320f
    and dl,0x1
    jnz short lab_320b
    mov dl,0xff
lab_320b:
    mov [0x3280],dl
lab_320f:
    jmp near lab_32ac
lab_3212:
    mov al,[0x32eb]
    and al,0x2f
    jnz short lab_3238
    call random
    and dl,0x1
    jnz short lab_3223
    mov dl,0xff
lab_3223:
    mov [0x3280],dl
    call random
    and dl,0x1
    jnz short lab_3231
    mov dl,0xff
lab_3231:
    mov [0x3281],dl
    jmp short lab_32ac
    nop
lab_3238:
    and al,0x7
    jnz short lab_32ac
    mov al,[0x32ed]
    mov [0x3280],al
    mov al,[0x32ee]
    mov [0x3281],al
    jmp short lab_32ac
    nop
lab_324b:
    mov byte [0x3281],0x1
    db 0x8b, 0xc3                       ; mov ax,bx
    mov cl,0x3
    shl ax,cl
    cmp [0x327d],ax
    jz short lab_3269
    mov dl,0x1
    jb short lab_3262
    mov dl,0xff
lab_3262:
    mov [0x3280],dl
    jmp short lab_32ac
    nop
lab_3269:
    mov byte [0x3280],0x0
    cmp byte [0x327f],0xa5
    jnz short lab_32ac
    mov byte [0x3281],0x0
    cmp word [0x327a],0x6
    jz short lab_3288
    cmp word [0x327a],0x12
    jnz short lab_32ac
lab_3288:
    push bx
    mov si,0x31e8
    mov di,[0x3282]
    mov cx,0x1e02
    mov ax,0xb800
    mov es,ax
    call blit_to_cga
    pop bx
    dec byte [bx+0x328e]
    mov al,[bx+0x328e]
    call draw_footprint_tile
    mov byte [0x3286],0x1
lab_32ac:
    mov cx,[0x327d]
    mov dl,[0x327f]
    mov [0x32ef],cx
    mov [0x32f1],dl
    cmp byte [0x3280],0x1
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
    mov [0x327d],cx
    cmp byte [0x3281],0x1
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
    mov [0x327f],dl
    call calc_cga_addr
    mov [0x3284],ax
    call lab_33ba
    jnb short lab_3328
lab_330d:
    mov byte [0x3280],0x0
    mov byte [0x3281],0x0
    mov cx,[0x32ef]
    mov [0x327d],cx
    mov dl,[0x32f1]
    mov [0x327f],dl
    ret
lab_3328:
    call check_enemy_object_hit
    jb short lab_330d
    call lab_33a0
    add word [0x327a],0x2
    call lab_3339
    ret
lab_3339:
    mov bx,[0x327a]
    mov ax,[bx+0x3260]
    db 0x3d, 0x00, 0x00                 ; cmp ax,0x0
    jnz short lab_334b
    mov [0x327a],ax
    jmp short lab_3339
lab_334b:
    db 0x8b, 0xf0                       ; mov si,ax
    mov di,[0x3284]
    mov [0x3282],di
    mov bp,0x31e8
    mov ax,0xb800
    mov es,ax
    mov cx,0x1e02
    mov byte [0x3286],0x0
    cld
    mov [0x3289],ch
    db 0x2a, 0xed                       ; sub ch,ch
    mov [0x3287],cx
lab_3370:
    mov cx,[0x3287]
lab_3374:
    mov bx,[es:di]
    mov [ds:bp+0x0],bx
    lodsw
    db 0x0b, 0xc3                       ; or ax,bx
    stosw
    add bp,0x2
    loop short lab_3374
    sub di,[0x3287]
    sub di,[0x3287]
    xor di,0x2000
    test di,0x2000
    jnz short lab_3399
    add di,0x50
lab_3399:
    dec byte [0x3289]
    jnz short lab_3370
    ret
lab_33a0:
    cmp byte [0x3286],0x0
    jnz short lab_33b9
    mov ax,0xb800
    mov es,ax
    mov si,0x31e8
    mov di,[0x3282]
    mov cx,0x1e02
    call blit_to_cga
lab_33b9:
    ret
lab_33ba:
    cmp byte [0x1cb8],0x0
    jnz short lab_3403
    cmp word [0x4],0x6
    jnz short lab_33d3
    cmp byte [0x44bd],0x0
    jz short lab_33d3
    call lab_47b0
    ret
lab_33d3:
    mov ax,[0x327d]
    mov dl,[0x327f]
    mov si,0x10
    mov bx,[0x579]
    mov dh,[0x57b]
    mov di,0x18
    mov cx,0xe1e
    call check_rect_collision
    jnb short lab_3403
    cmp word [0x4],0x4
    jnz short lab_33fe
    cmp byte [0x39e1],0x0
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
lab_3405:
    cld
    db 0x2b, 0xc0                       ; sub ax,ax
    push ds
    pop es
    mov di,0x328e
    mov cx,0x14
    rep stosw
    mov word [0x32b6],0xff
    mov word [0x327a],0x0
    mov word [0x327d],0x0
    mov byte [0x327f],0xa0
    mov byte [0x3286],0x1
    mov byte [0x3280],0x0
    mov byte [0x3281],0x0
    call random
    mov [0x32eb],dl
    mov byte [0x32ea],0x6c
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
    cmp ax,word [0x32b6]
    jz lab_347e
    mov [0x32b6],ax
    db 0x8b, 0xd8                       ; mov bx,ax
    mov al,byte [bx + 0x328e]
    cmp al,0x4
    jnc lab_347e
    inc al
    mov byte [bx + 0x328e],al
    call draw_footprint_tile                           ;undefined draw_footprint_tile()
lab_347e:
    ret

; --- draw_footprint_tile ---
draw_footprint_tile:
    mov ah,0xa
    mul ah
    add ax,0x32b8
    db 0x8b, 0xf0                       ; mov si,ax
    db 0x8b, 0xfb                       ; mov di,bx
    shl di,0x1
    add di,0x1e00
    mov ax,0xb800
    mov es,ax
    mov cx,0x501
    call blit_to_cga                           ;undefined blit_to_cga()
    ret
    db 0x00, 0x00, 0x00, 0x00

; --- check_level_objects ---
check_level_objects:
    mov word [0x3511],0x0
    mov byte [0x351b],0x0
lab_34ab:
    mov bx,word [0x3511]
    cmp byte [bx + 0x34a7],0x0
    jz lab_34b9
lab_34b6:
    jmp near lab_35ad
lab_34b9:
    db 0x8b, 0xf3                       ; mov si,bx
    shl si,0x1
    mov ax,word [si + 0x3447]
    mov dl,byte [bx + 0x3477]
    mov di,0x0
    cmp bx,0xc
    jc lab_34d0
    mov di,0x2
lab_34d0:
    mov si,word [di + 0x3513]
    mov cx,word [di + 0x3517]
    mov bx,word [cat_x]
    mov dh,byte [cat_y]
    mov di,0x18
    mov ch,0xe
    call check_rect_collision                           ;undefined check_rect_collision()
    jnc lab_34b6
    mov bx,word [0x3511]
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
    mov si,0x3350
    mov ax,0xb800
    mov es,ax
    mov cx,0x1205
    call blit_to_cga                           ;undefined blit_to_cga()
    call reset_noise                           ;undefined reset_noise()
    db 0x2a, 0xe4                       ; sub ah,ah
    int 0x1a                            ; BIOS Timer: Get tick count → CX:DX
    mov word [0x3509],dx
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
    sub dx,word [0x3509]
    cmp dx,0xd
    jc lab_3543
    ret
lab_356f:
    inc byte [0x351b]
    mov ax,0x5dc
    mov bx,0x425
    call start_tone                           ;undefined start_tone()
    cmp byte [0x351b],0x1
    jnz lab_3586
    call restore_alley_buffer                           ;undefined restore_alley_buffer()
lab_3586:
    mov bx,word [0x3511]
    call erase_level_object                           ;undefined erase_level_object()
    mov bx,word [0x3511]
    mov byte [bx + 0x34a7],0x1
    cmp bx,0xc
    jnc lab_35ad
    dec byte [0x3410]
    jnz lab_35ad
    cmp byte [immune_flag],0x0
    jnz lab_35ad
    mov byte [cat_caught],0x1
lab_35ad:
    inc word [0x3511]
    cmp word [0x3511],0x18
    jnc lab_35bb
    jmp near lab_34ab
lab_35bb:
    cmp byte [0x351b],0x0
    jz lab_35c7
    call reset_caught_objects                           ;undefined reset_caught_objects()
    stc
    ret
lab_35c7:
    clc
    ret
lab_35c9:
    mov word [0x3411],0x0
    mov word [0x3415],0x0
    mov byte [0x3410],0xc
    mov cx,0x18
lab_35dd:
    db 0x8b, 0xd9                       ; mov bx,cx
    dec bx
    mov byte [bx+0x348f],0x1
    mov byte [bx+0x34a7],0x0
    mov al,[bx+0x34f1]
    mov [bx+0x3477],al
    mov byte [bx+0x342f],0x1
    call random
    and dl,0x1
    jnz short lab_3601
    not dl
lab_3601:
    mov [bx+0x3417],dl
    db 0xd1, 0xe3                       ; shl bx,0x0
    call random
    db 0x2a, 0xf6                       ; sub dh,dh
    mov [bx+0x3447],dx
    loop short lab_35dd
    mov bx,[0x8]
    mov cl,[bx+0x351c]
    db 0x2a, 0xed                       ; sub ch,ch
lab_361c:
    call random
    and dl,0xf
    cmp dl,0xc
    jnb short lab_361c
    db 0x8a, 0xda                       ; mov bl,dl
    add bl,0xc
    db 0x2a, 0xff                       ; sub bh,bh
    cmp byte [bx+0x34a7],0x0
    jnz short lab_361c
    mov byte [bx+0x34a7],0x1
    loop short lab_361c
    ret

; --- reset_caught_objects ---
reset_caught_objects:
    mov cx,0xc
lab_3640:
    db 0x8b, 0xd9                       ; mov bx,cx
    add bx,0xb
    cmp byte [bx + 0x34a7],0x0
    jz lab_3672
    db 0x2b, 0xc0                       ; sub ax,ax
    mov dl,0x1
    mov byte [bx + 0x34a7],al
    cmp word [cat_x],0xa0
    ja lab_3661
    mov ax,0x12e
    mov dl,0xff
lab_3661:
    mov byte [bx + 0x3417],dl
    shl bl,0x1
    mov word [bx + 0x3447],ax
    dec byte [0x351b]
    jnz reset_caught_objects
    ret
lab_3672:
    loop lab_3640
    ret
lab_3675:
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    cmp dx,[0x3509]
    jnz short lab_3680
lab_367f:
    ret
lab_3680:
    mov [0x350b],dx
    inc word [0x3415]
    mov bx,[0x3415]
    cmp bx,0x18
    jb short lab_36a4
    db 0x2b, 0xdb                       ; sub bx,bx
    mov [0x3415],bx
    db 0x81, 0x36, 0x11, 0x34, 0x0c, 0x00 ; xor word [0x3411],0xc
    add word [0x3413],0x8
    jmp short lab_36b7
lab_36a4:
    cmp bx,0xc
    jnz short lab_36bd
    cmp byte [0x697],0xfd
    jnz short lab_36b7
    cmp byte [0x57b],0x30
    jb short lab_36bd
lab_36b7:
    mov ax,[0x350b]
    mov [0x3509],ax
lab_36bd:
    db 0x8b, 0xf3                       ; mov si,bx
    db 0xd1, 0xe6                       ; shl si,0x0
    cmp byte [bx+0x34a7],0x0
    jnz short lab_367f
    call random
    cmp dl,0x10
    ja short lab_36e9
    and dl,0x1
    jnz short lab_36d7
    not dl
lab_36d7:
    mov [bx+0x3417],dl
    call random
    and dl,0x1
    jnz short lab_36e5
    not dl
lab_36e5:
    mov [bx+0x342f],dl
lab_36e9:
    mov cx,0x4
    cmp bx,0xc
    jb short lab_36f3
    db 0xd0, 0xe9                       ; shr cl,0x0
lab_36f3:
    mov ax,[si+0x3447]
    cmp byte [bx+0x3417],0x1
    jz short lab_370b
    db 0x2b, 0xc1                       ; sub ax,cx
    jnb short lab_371a
    db 0x2b, 0xc0                       ; sub ax,ax
    mov byte [bx+0x3417],0x1
    jmp short lab_371a
lab_370b:
    db 0x03, 0xc1                       ; add ax,cx
    cmp ax,0x12f
    jb short lab_371a
    mov ax,0x12e
    mov byte [bx+0x3417],0xff
lab_371a:
    mov [si+0x3447],ax
    mov al,[bx+0x3477]
    cmp byte [bx+0x342f],0x1
    jz short lab_373c
    dec al
    cmp al,[bx+0x34f1]
    jnb short lab_3750
    mov al,[bx+0x34f1]
    mov byte [bx+0x342f],0x1
    jmp short lab_3750
lab_373c:
    inc al
    mov dl,[bx+0x34f1]
    add dl,0x18
    db 0x3a, 0xc2                       ; cmp al,dl
    jbe short lab_3750
    db 0x8a, 0xc2                       ; mov al,dl
    mov byte [bx+0x342f],0xff
lab_3750:
    mov [bx+0x3477],al
    db 0x8a, 0xd0                       ; mov dl,al
    mov cx,[si+0x3447]
    call calc_cga_addr
    mov [0x34ef],ax
    mov bx,[0x3415]
    call erase_level_object
    mov bx,[0x3415]
    db 0x8b, 0xf3                       ; mov si,bx
    db 0xd1, 0xe6                       ; shl si,0x0
    mov di,[0x34ef]
    mov [si+0x34bf],di
    mov byte [bx+0x348f],0x0
    mov ax,0xb800
    mov es,ax
    cmp bx,0xc
    jb short lab_379f
    db 0x8b, 0xf3                       ; mov si,bx
    mov cl,0x3
    shl si,cl
    add si,[0x3413]
    db 0x81, 0xe6, 0x18, 0x00           ; and si,0x18
    add si,0x3330
    mov cx,0x202
    call blit_to_cga
    ret
lab_379f:
    mov si,[0x3411]
    test bl,0x1
    jnz short lab_37ac
    db 0x81, 0xf6, 0x0c, 0x00           ; xor si,0xc
lab_37ac:
    cmp byte [bx+0x3417],0x1
    jz short lab_37b6
    add si,0x18
lab_37b6:
    add si,0x3300
    mov cx,0x601
    call blit_to_cga
    ret

; --- erase_level_object ---
erase_level_object:
    cmp byte [bx + 0x348f],0x0
    jnz lab_37e4
    shl bx,0x1
    mov si,0x3404
    mov di,word [bx + 0x34bf]
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
lab_37e5:
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    db 0x8b, 0xc2                       ; mov ax,dx
    sub ax,[0x350f]
    db 0x3d, 0x08, 0x00                 ; cmp ax,0x8
    jb short lab_384a
    inc word [0x350d]
    mov bx,[0x350d]
    cmp bx,0x28
    jb short lab_380b
    db 0x2b, 0xdb                       ; sub bx,bx
    mov [0x350d],bx
    mov [0x350f],dx
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
    mov al,[bx+0x2656]
    add al,0x8
    mov [bx+0x2656],al
    db 0x25, 0x18, 0x00                 ; and ax,0x18
    add ax,0x2020
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
lab_3850:
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    db 0x8b, 0xc2                       ; mov ax,dx
    sub ax,[0x35da]
    db 0x3d, 0x06, 0x00                 ; cmp ax,0x6
    jnb short lab_3860
    ret
lab_3860:
    mov [0x35da],dx
    add word [0x35d8],0x2
    mov bx,[0x35d8]
    db 0x81, 0xe3, 0x06, 0x00           ; and bx,0x6
    mov si,[bx+0x35d0]
    mov di,0x15c9
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
lab_38b0:
    cmp word [0x6],0x7
    jnz short lab_38ba
    jmp short lab_38d3
    nop
lab_38ba:
    inc word [0x414]
    mov byte [0x418],0x1
    mov dx,0xaaaa
    call lab_3a96
    db 0x2b, 0xc0                       ; sub ax,ax
    mov byte [0x369f],0x0
    call lab_3aac
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
    mov [0x3697],ax
    call lab_3af4
    mov bx,[0x6]
    db 0xd0, 0xe3                       ; shl bl,0x0
    mov si,[bx+0x36cc]
    mov di,0x368d
    call add_bcd_scores
    cmp word [0x6],0x7
    jnz short lab_396e
    mov bx,[0x8]
    db 0xd0, 0xe3                       ; shl bl,0x0
    db 0x8b, 0xc3                       ; mov ax,bx
    mov cx,[bx+0x36dc]
    cmp word [0x2e8d],0x8
    jnb short lab_3943
    db 0xd1, 0xe1                       ; shl cx,0x0
    db 0x05, 0x10, 0x00                 ; add ax,0x10
lab_3943:
    mov [0x370c],ax
lab_3946:
    mov si,0x368d
    mov di,0x1f82
    push cx
    call add_bcd_scores
    pop cx
    loop short lab_3946
    call lab_39fa
    mov byte [0x369e],0x38
    mov byte [0x3699],0x1
    mov word [0x3722],0x44
    call lab_3a3a
    call lab_3a6c
    jmp short lab_39a7
lab_396e:
    mov si,0x368d
    mov di,0x1f82
    call add_bcd_scores
    mov byte [0x3699],0x2
    mov word [0x3722],0x1e
    mov dx,0xffff
    call lab_3a96
    mov ax,0xa8c
    sub ax,[0x3697]
    mov cl,0x4
    shr ax,cl
    and al,0xf0
    mov [0x369e],al
    mov ah,0x28
    mul ah
    mov byte [0x369f],0x1
    call lab_3aac
    call lab_3a3a
lab_39a7:
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    mov [0x3695],dx
lab_39af:
    cmp word [0x6],0x7
    jnz short lab_39bb
    call play_victory_note
    jmp short lab_39be
lab_39bb:
    call play_level_note
lab_39be:
    call lab_3a1c
    sub dx,[0x3695]
    cmp dx,[0x3722]
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
lab_39fa:
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
lab_3a1c:
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
    mov bl,[0x3699]
lab_3a34:
    mov ah,0xb
    int byte 0x10
    pop dx
    ret
lab_3a3a:
    mov ah,0x2
    mov dh,[0x369e]
    mov cl,0x3
    shr dh,cl
    mov dl,0x12
    db 0x2a, 0xff                       ; sub bh,bh
    int byte 0x10
    mov word [0x36a0],0x3
lab_3a50:
    mov bx,[0x36a0]
    mov al,[bx+0x368d]
    add al,0x30
    mov ah,0xe
    mov bl,0x3
    int byte 0x10
    inc word [0x36a0]
    cmp word [0x36a0],0x7
    jb short lab_3a50
    ret
lab_3a6c:
    mov ah,0x2
    mov dl,0xa
    db 0x8a, 0xf2                       ; mov dh,dl
    db 0x2b, 0xdb                       ; sub bx,bx
    int byte 0x10
    mov bx,[0x370c]
    mov ax,[bx+0x36ec]
    mov [0x3720],ax
    db 0x2b, 0xdb                       ; sub bx,bx
lab_3a83:
    mov ah,0xe
    mov al,[bx+0x370e]
    push bx
    mov bl,0x3
    int byte 0x10
    pop bx
    inc bx
    cmp bx,0x14
    jb short lab_3a83
    ret
lab_3a96:
    cld
    mov ax,0x10
    mov es,ax
    mov di,0xe
    mov si,0x35e0
    mov cx,0x1e
lab_3aa5:
    lodsw
    db 0x23, 0xc2                       ; and ax,dx
    stosw
    loop short lab_3aa5
    ret
lab_3aac:
    mov [0x369a],ax
    mov ax,0xb800
    mov es,ax
    call init_level_melody
    mov ax,0x1b80
lab_3aba:
    mov bx,0x361c
    mov [0x369c],ax
    call draw_block_list
    cmp byte [0x369f],0x0
    jz short lab_3ae2
    call play_melody_step
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    mov [0x3695],dx
lab_3ad5:
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    sub dx,[0x3695]
    cmp dx,0x2
    jb short lab_3ad5
lab_3ae2:
    mov ax,[0x369c]
    sub ax,0x280
    jb short lab_3af0
    cmp ax,[0x369a]
    jnb short lab_3aba
lab_3af0:
    call silence_speaker
    ret
lab_3af4:
    mov [0x368b],ax
    db 0x2b, 0xc0                       ; sub ax,ax
    mov [0x368d],ax
    mov [0x368f],ax
    mov [0x3691],ax
    mov [0x3693],ax
    mov bx,0x3684
    mov dx,0x1000
lab_3b0b:
    test [0x368b],dx
    jz short lab_3b19
    db 0x8b, 0xf3                       ; mov si,bx
    mov di,0x368d
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
lab_3b30:
    mov byte [0x37af],0x3
    mov ax,0x1
    mov [0x37b0],ax
    mov [0x37b2],ax
    mov [0x37b4],ax
    ret
lab_3b42:
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    cmp dx,[0x37b8]
    jnz short lab_3b4d
    ret
lab_3b4d:
    mov [0x37b8],dx
    mov word [0x37b6],0x4
lab_3b57:
    mov bx,[0x37b6]
    cmp word [bx+0x37b0],0x0
    jz short lab_3b9b
    mov ax,[bx+0x37a3]
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
    call lab_3e38
    mov bx,[0x37b6]
    call lab_3ba3
    call save_alley_buffer
    call lab_3e14
    ret
lab_3b9b:
    sub word [0x37b6],0x2
    jnb short lab_3b57
    ret
lab_3ba3:
    mov word [bx+0x37b0],0x0
    push ds
    pop es
    cld
    mov ax,0xaaaa
    mov di,0xe
    db 0x8b, 0xf7                       ; mov si,di
    mov cx,0x20
    rep stosw
    mov di,[bx+0x37a9]
    mov ax,0xb800
    mov es,ax
    mov cx,0x1002
    call blit_to_cga
    dec byte [0x37af]
    jnz short lab_3bda
    cmp byte [0x552],0x0
    jnz short lab_3bda
    mov byte [0x553],0x1
lab_3bda:
    ret
lab_3bdb:
    mov ax,0xb800
    mov es,ax
    mov word [0x37a0],0x66a
    mov cx,0x10
lab_3be9:
    db 0x2b, 0xc0                       ; sub ax,ax
    db 0x8b, 0xd8                       ; mov bx,ax
lab_3bed:
    mov [0x37a2],al
    db 0x2a, 0xe4                       ; sub ah,ah
    add ax,0x3730
    db 0x8b, 0xf0                       ; mov si,ax
    mov di,[0x37a0]
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
    add word [0x37a0],0x140
    loop short lab_3be9
    ret
lab_3c1e:
    cmp byte [0x37a2],0x50
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
lab_3c90:
    mov byte [0x3966],0x8
    mov byte [0x396a],0x1
    mov byte [0x3967],0x0
    mov byte [0x396d],0x2
    mov word [0x3964],0x118
    mov word [0x396b],0x0
    ret
lab_3cb1:
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    db 0x8b, 0xc2                       ; mov ax,dx
    sub ax,[0x39c8]
    db 0x3d, 0x02, 0x00                 ; cmp ax,0x2
    jnb short lab_3cc1
lab_3cc0:
    ret
lab_3cc1:
    mov [0x39c8],dx
    call lab_3e52
    jb short lab_3cc0
    call lab_3e6e
    jnb short lab_3cd2
    jmp near lab_3d90
lab_3cd2:
    mov bx,[0x8]
    db 0xd0, 0xe3                       ; shl bl,0x0
    mov ax,[bx+0x39cc]
    mov [0x39c6],ax
    mov ax,[0x3964]
    mov [0x39c3],ax
    mov dl,[0x3966]
    mov [0x39c5],dl
    cmp dl,0x8
    jnz short lab_3d25
    db 0x25, 0xf8, 0xff                 ; and ax,0xfff8
    mov dx,[0x579]
    db 0x81, 0xe2, 0xf8, 0xff           ; and dx,0xfff8
    db 0x3b, 0xc2                       ; cmp ax,dx
    jnz short lab_3d0d
    mov byte [0x3967],0x1
    mov byte [0x396e],0x1
    jmp short lab_3d25
lab_3d0d:
    mov ax,[0x3964]
    jb short lab_3d1c
    sub ax,[0x39c6]
    jnb short lab_3d20
    db 0x2b, 0xc0                       ; sub ax,ax
    jmp short lab_3d20
lab_3d1c:
    add ax,[0x39c6]
lab_3d20:
    mov [0x3964],ax
    jmp short lab_3d79
lab_3d25:
    mov al,[0x3966]
    inc byte [0x396e]
    mov dl,[0x396e]
    db 0xd0, 0xea                       ; shr dl,0x0
    db 0xd0, 0xea                       ; shr dl,0x0
    and dl,0x3
    add dl,0x2
    cmp byte [0x3967],0x1
    jz short lab_3d52
    db 0x2a, 0xc2                       ; sub al,dl
    jb short lab_3d49
    cmp al,0x9
    jnb short lab_3d76
lab_3d49:
    mov al,0x8
    mov byte [0x3967],0x0
    jmp short lab_3d76
lab_3d52:
    db 0x02, 0xc2                       ; add al,dl
    cmp al,[0x57b]
    ja short lab_3d71
    mov bx,[0x3964]
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
    mov byte [0x3967],0xff
lab_3d76:
    mov [0x3966],al
lab_3d79:
    call lab_3e52
    jnb short lab_3d8b
    mov ax,[0x39c3]
    mov [0x3964],ax
    mov al,[0x39c5]
    mov [0x3966],al
    ret
lab_3d8b:
    call lab_3e6e
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
    mov si,0x37c0
    mov bp,0xe
    mov cx,0x1506
    call blit_transparent
    call init_buzz_sound
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    mov [0x39c8],dx
lab_3dd8:
    call update_buzz_sound
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    sub dx,[0x39c8]
    cmp dx,0x9
    jb short lab_3dd8
    mov byte [0x552],0x1
    ret
lab_3dee:
    mov cx,[0x3964]
    mov dl,[0x3966]
    call calc_cga_addr
    mov [0x39ca],ax
    call lab_3e38
    dec byte [0x396d]
    jnz short lab_3e10
    mov byte [0x396d],0x2
    db 0x81, 0x36, 0x6b, 0x39, 0x54, 0x00 ; xor word [0x396b],0x54
lab_3e10:
    call lab_3e14
    ret
lab_3e14:
    mov ax,0xb800
    mov es,ax
    mov di,[0x39ca]
    mov [0x3968],di
    mov bp,0x396f
    mov byte [0x396a],0x0
    mov si,[0x396b]
    add si,0x38bc
    mov cx,0xe03
    call blit_transparent
    ret
lab_3e38:
    mov ax,0xb800
    mov es,ax
    cmp byte [0x396a],0x0
    jnz short lab_3e51
    mov di,[0x3968]
    mov si,0x396f
    mov cx,0xe03
    call blit_to_cga
lab_3e51:
    ret
lab_3e52:
    mov ax,[0x3964]
    mov dl,[0x3966]
    mov si,0x18
    mov bx,[0x327d]
    mov dh,[0x327f]
    mov di,0x10
    mov cx,0x1e0e
    call check_rect_collision
    ret
lab_3e6e:
    mov ax,[0x3964]
    mov dl,[0x3966]
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
lab_3e90:
    cmp byte [0x39e1],0x0
    jz short lab_3ea4
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    cmp dx,[0x3d16]
    jz short lab_3eb9
    jmp near lab_3f35
lab_3ea4:
    cmp byte [0x584],0x0
    jnz short lab_3eb9
    cmp byte [0x69a],0x0
    jnz short lab_3eb9
    cmp byte [0x39e0],0x0
    jnz short lab_3eba
lab_3eb9:
    ret
lab_3eba:
    call lab_4065
    jb short lab_3eb9
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    db 0x8b, 0xc2                       ; mov ax,dx
    sub ax,[0x3d18]
    db 0x3d, 0x0c, 0x00                 ; cmp ax,0xc
    jb short lab_3eb9
    mov [0x3d18],dx
    mov byte [0x55c],0x0
    mov bl,[0x39e0]
    dec bl
    db 0x2a, 0xff                       ; sub bh,bh
    db 0x8b, 0xf3                       ; mov si,bx
    mov cl,0x2
    shl si,cl
    mov ax,[si+0x3c5a]
    mov [0x39e2],ax
    db 0x2b, 0xc0                       ; sub ax,ax
    cmp bl,0x3
    jnb short lab_3ef5
    mov al,0x80
lab_3ef5:
    mov [0x39e4],ax
    mov bl,[bx+0x3ce3]
    db 0x8b, 0xf3                       ; mov si,bx
    mov cl,0x2
    shl si,cl
    mov ax,[si+0x3c5a]
    mov [0x39e6],ax
    db 0x2b, 0xc0                       ; sub ax,ax
    cmp bl,0x3
    jnb short lab_3f12
    mov al,0x80
lab_3f12:
    mov [0x39e8],ax
    mov al,[bx+0x1050]
    mov [0x3d05],al
    db 0xd0, 0xe3                       ; shl bl,0x0
    mov ax,[bx+0x1137]
    db 0x05, 0x08, 0x00                 ; add ax,0x8
    mov [0x3d03],ax
    call restore_alley_buffer
    mov byte [0x39e1],0xe
    mov byte [0x69a],0x10
lab_3f35:
    cmp byte [0x1cbf],0x0
    jnz short lab_3f3f
    call lab_33a0
lab_3f3f:
    sub byte [0x39e1],0x2
    db 0x2a, 0xff                       ; sub bh,bh
    mov bl,[0x39e1]
    cmp bl,0x8
    jb short lab_3f58
    mov di,[0x39e2]
    mov ax,[0x39e4]
    jmp short lab_3f70
lab_3f58:
    mov di,[0x39e6]
    mov al,[0x3d05]
    mov [0x57b],al
    add al,0x32
    mov [0x57c],al
    mov ax,[0x3d03]
    mov [0x579],ax
    mov ax,[0x39e8]
lab_3f70:
    add ax,[bx+0x3d06]
    db 0x8b, 0xf0                       ; mov si,ax
    mov ax,0xb800
    mov es,ax
    mov cx,0x1002
    call blit_to_cga
    cmp byte [0x1cbf],0x0
    jnz short lab_3f8b
    call lab_3339
lab_3f8b:
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    mov [0x3d16],dx
    cmp byte [0x39e1],0x0
    jnz short lab_3f9d
    call save_cat_background
lab_3f9d:
    ret
lab_3f9e:
    mov ax,0xb800
    mov es,ax
    mov byte [0x39e0],0x0
    mov byte [0x39e1],0x0
    mov word [0x3cbf],0x506
    mov word [0x3cc1],0x0
lab_3fb9:
    mov bx,[0x3cc1]
    mov cl,[bx+0x3cae]
    db 0x2b, 0xdb                       ; sub bx,bx
    db 0x8a, 0xeb                       ; mov ch,bl
lab_3fc5:
    mov si,0x3aea
    call random
    cmp dl,0x30
    ja short lab_3fdb
    mov si,0x3af8
    test dl,0x4
    jnz short lab_3fdb
    mov si,0x3b02
lab_3fdb:
    mov di,[0x3cbf]
    db 0x03, 0xfb                       ; add di,bx
    push cx
    push bx
    mov cx,0x801
    call blit_to_cga
    pop bx
    pop cx
    add bx,0x2
    loop short lab_3fc5
    add word [0x3cbf],0x140
    inc word [0x3cc1]
    cmp word [0x3cc1],0x11
    jb short lab_3fb9
    mov bx,0x3c22
    db 0x2b, 0xc0                       ; sub ax,ax
    call draw_block_list
    mov bx,0x3c3e
    db 0x2b, 0xc0                       ; sub ax,ax
    call draw_block_list
    mov bx,0x3c9a
    db 0x2b, 0xc0                       ; sub ax,ax
    call draw_block_list
    mov bx,0x3c56
    db 0x2b, 0xc0                       ; sub ax,ax
    call draw_block_list
    mov si,0x3caa
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
    mov al,[bx+0x3cc3]
    db 0x8a, 0xe0                       ; mov ah,al
    mov cl,0x4
    shr al,cl
    mov [si+0x3ce3],al
    mov byte [si+0x3cf3],0x0
    and ah,0xf
    mov [si+0x3ce4],ah
    mov byte [si+0x3cf4],0x0
    add si,0x2
    inc bx
    cmp si,0x10
    jb short lab_403c
    ret
lab_4065:
    mov ax,[0x327d]
    mov dl,[0x327f]
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
lab_4090:
    mov cx,0x4
lab_4093:
    db 0x8b, 0xd9                       ; mov bx,cx
    dec bx
    db 0x8b, 0xf3                       ; mov si,bx
    db 0xd1, 0xe6                       ; shl si,0x0
    mov byte [bx+0x3eae],0x1
    mov byte [bx+0x3eb2],0x0
    call lab_4277
    call random
    and dl,0xf
    add dl,0x14
    mov [bx+0x3eb6],dl
    loop short lab_4093
    mov word [0x3eda],0x0
    mov byte [0x3ed8],0x4
    ret
lab_40c2:
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    cmp dx,[0x3edc]
    jnz short lab_40cd
lab_40cc:
    ret
lab_40cd:
    inc word [0x3eda]
    mov bx,[0x3eda]
    cmp bx,0x2
    jbe short lab_40e5
    cmp bx,0x4
    jb short lab_40e9
    db 0x2b, 0xdb                       ; sub bx,bx
    mov [0x3eda],bx
lab_40e5:
    mov [0x3edc],dx
lab_40e9:
    db 0x8b, 0xf3                       ; mov si,bx
    db 0xd1, 0xe6                       ; shl si,0x0
    cmp byte [bx+0x3eb2],0x0
    jnz short lab_40cc
    call lab_42db
    jnb short lab_40fc
    jmp short lab_4124
    nop
lab_40fc:
    call lab_42fc
    jb short lab_40cc
    cmp byte [bx+0x3eb6],0x0
    jnz short lab_4118
    call lab_4277
    call random
    and dl,0x7
    add dl,0x14
    mov [bx+0x3eb6],dl
lab_4118:
    dec byte [bx+0x3eb6]
    call lab_42db
    jb short lab_4124
    jmp short lab_4181
    nop
lab_4124:
    cmp byte [bx+0x3eae],0x0
    jnz short lab_4132
    cmp byte [bx+0x3eb6],0x14
    jb short lab_4133
lab_4132:
    ret
lab_4133:
    call restore_alley_buffer
    call lab_4254
    mov bx,[0x3eda]
    mov byte [bx+0x3eb2],0x1
    call save_alley_buffer
    mov byte [0x55c],0x0
    dec byte [0x3ed8]
    jnz short lab_4155
    mov byte [0x553],0x1
lab_4155:
    mov al,0x4
    sub al,[0x3ed8]
    mov cl,0x2
    shl al,cl
    db 0x2a, 0xe4                       ; sub ah,ah
    db 0x05, 0x51, 0x00                 ; add ax,0x51
    db 0x8b, 0xf8                       ; mov di,ax
    mov bp,0xe
    mov si,0x3d20
    mov ax,0xb800
    mov es,ax
    mov cx,0xc02
    call blit_masked
    mov ax,0x3e8
    mov bx,0x2ee
    call start_tone
    ret
lab_4181:
    call lab_42b4
    mov di,[0x8]
    db 0xd1, 0xe7                       ; shl di,0x0
    mov bp,[di+0x3ede]
    call lab_431c
    jnb short lab_41b0
    cmp byte [bx+0x3eb6],0x2
    jb short lab_41b0
    mov al,0x1
    cmp byte [bx+0x3eb6],0x11
    jbe short lab_41ac
    cmp byte [bx+0x3eb6],0x14
    jnb short lab_41b0
    dec al
lab_41ac:
    mov [bx+0x3eb6],al
lab_41b0:
    mov al,[bx+0x3eb6]
    cmp al,0x1
    jbe short lab_41d8
    cmp al,0x12
    jb short lab_41f8
    mov al,0x1
    cmp word [si+0x3eba],0x3
    jnb short lab_41c7
    mov al,0x3
lab_41c7:
    add [bx+0x3ed4],al
    cmp byte [bx+0x3eb6],0x13
    jb short lab_41f3
    jz short lab_41ee
    db 0x2b, 0xc0                       ; sub ax,ax
    jmp short lab_4204
lab_41d8:
    mov al,0x1
    cmp word [si+0x3eba],0x3
    jnb short lab_41e3
    mov al,0x3
lab_41e3:
    add [bx+0x3ed4],al
    cmp byte [bx+0x3eb6],0x1
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
    mov ax,[di+0x3de0]
lab_4204:
    mov [0x3eca],ax
    mov dl,[bx+0x3ed4]
    mov cx,[si+0x3ecc]
    call calc_cga_addr
    mov [0x3de4],ax
    call lab_4254
    mov bx,[0x3eda]
    db 0x8b, 0xf3                       ; mov si,bx
    db 0xd1, 0xe6                       ; shl si,0x0
    call lab_42fc
    jnb short lab_4226
    ret
lab_4226:
    cmp word [0x3eca],0x0
    jnz short lab_4233
    mov byte [bx+0x3eae],0x1
    ret
lab_4233:
    mov byte [bx+0x3eae],0x0
    mov di,[0x3de4]
    mov [si+0x3ea6],di
    mov ax,0xb800
    mov es,ax
    mov bp,[si+0x3ec2]
    mov cx,0xc02
    mov si,[0x3eca]
    call blit_masked
    ret
lab_4254:
    mov bx,[0x3eda]
    db 0x8b, 0xf3                       ; mov si,bx
    db 0xd1, 0xe6                       ; shl si,0x0
    cmp byte [bx+0x3eae],0x0
    jnz short lab_4276
    mov di,[si+0x3ea6]
    mov cx,0xc02
    mov si,[si+0x3ec2]
    mov ax,0xb800
    mov es,ax
    call blit_to_cga
lab_4276:
    ret
lab_4277:
    mov byte [0x3ed9],0x20
lab_427c:
    call random
    db 0x81, 0xe2, 0x0f, 0x00           ; and dx,0xf
    db 0x2b, 0xff                       ; sub di,di
lab_4285:
    db 0x3b, 0xfe                       ; cmp di,si
    jz short lab_428f
    cmp dx,[di+0x3eba]
    jz short lab_427c
lab_428f:
    add di,0x2
    cmp di,0x8
    jb short lab_4285
    mov [si+0x3eba],dx
    call lab_42b4
    cmp byte [0x3ed9],0x0
    jz short lab_42b3
    mov bp,0x32
    call lab_431c
    jnb short lab_42b3
    dec byte [0x3ed9]
    jmp short lab_427c
lab_42b3:
    ret
lab_42b4:
    mov di,[si+0x3eba]
    mov al,[di+0x1050]
    mov dl,0xa
    cmp di,0x3
    jnb short lab_42c5
    db 0x2a, 0xd2                       ; sub dl,dl
lab_42c5:
    db 0x2a, 0xc2                       ; sub al,dl
    add al,0x3
    mov [bx+0x3ed4],al
    db 0xd1, 0xe7                       ; shl di,0x0
    mov ax,[di+0x1137]
    db 0x05, 0x08, 0x00                 ; add ax,0x8
    mov [si+0x3ecc],ax
    ret
lab_42db:
    push si
    push bx
    mov ax,[si+0x3ecc]
    mov dl,[bx+0x3ed4]
    mov si,0x10
    mov bx,[0x579]
    mov dh,[0x57b]
    mov di,0x18
    mov cx,0xe0c
    call check_rect_collision
    pop bx
    pop si
    ret
lab_42fc:
    push si
    push bx
    mov ax,[si+0x3ecc]
    mov dl,[bx+0x3ed4]
    mov si,0x10
    mov bx,[0x327d]
    mov dh,[0x327f]
    db 0x8b, 0xfe                       ; mov di,si
    mov cx,0x1e0c
    call check_rect_collision
    pop bx
    pop si
    ret
lab_431c:
    mov ax,[si+0x3ecc]
    sub ax,[0x579]
    jnb short lab_4328
    not ax
lab_4328:
    mov dl,[bx+0x3ed4]
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
lab_4340:
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    cmp dx,[0x40b5]
    jnz short lab_434b
lab_434a:
    ret
lab_434b:
    inc byte [0x40ff]
    test byte [0x40ff],0x3
    jz short lab_435a
    mov [0x40b5],dx
lab_435a:
    cmp byte [0x40aa],0xa4
    jb short lab_434a
    call lab_452d
    call lab_4557
    jb short lab_434a
    call random
    cmp dl,0x30
    ja short lab_439c
    call lab_44fb
    mov si,[0x8]
    db 0xd1, 0xe6                       ; shl si,0x0
    mov ax,[si+0x40ce]
    cmp [0x40cc],ax
    ja short lab_439c
    call play_random_chirp
    mov word [0x40c8],0xff
    mov al,[0x40ca]
    mov [0x40b7],al
    mov al,[0x40cb]
    mov [0x40b8],al
    jmp near lab_442e
lab_439c:
    cmp word [0x40c8],0xa
    ja short lab_43b1
    call random
    cmp dl,0x6
    ja short lab_43b4
    mov word [0x40c8],0xff
lab_43b1:
    jmp short lab_4402
    nop
lab_43b4:
    mov bx,[0x40c8]
    db 0x8b, 0xf3                       ; mov si,bx
    db 0xd1, 0xe6                       ; shl si,0x0
    db 0x2a, 0xd2                       ; sub dl,dl
    mov ax,[0x40b2]
    and ax,0xffc
    cmp ax,[si+0x40de]
    jz short lab_43d0
    inc dl
    jb short lab_43d0
    mov dl,0xff
lab_43d0:
    mov [0x40b7],dl
    db 0x2a, 0xd2                       ; sub dl,dl
    mov al,[0x40b4]
    and al,0xfe
    cmp al,[bx+0x40f4]
    jz short lab_43e7
    inc dl
    jb short lab_43e7
    mov dl,0xff
lab_43e7:
    mov [0x40b8],dl
    or dl,[0x40b7]
    jnz short lab_442e
    call random
    cmp dl,0x10
    ja short lab_442e
    mov word [0x40c8],0xff
    call play_random_chirp
lab_4402:
    call random
    cmp dl,0x30
    ja short lab_4423
    and dl,0x1
    jnz short lab_4411
    mov dl,0xff
lab_4411:
    mov [0x40b7],dl
    call random
    and dl,0x1
    jnz short lab_441f
    mov dl,0xff
lab_441f:
    mov [0x40b8],dl
lab_4423:
    call random
    and dx,0xff
    mov [0x40c8],dx
lab_442e:
    mov al,[0x40b4]
    cmp byte [0x40b8],0x1
    jb short lab_4459
    jnz short lab_4449
    add al,0x2
    cmp al,0xa8
    jb short lab_4456
    mov al,0xa7
    mov byte [0x40b8],0xff
    jmp short lab_4456
lab_4449:
    sub al,0x2
    cmp al,0x30
    jnb short lab_4456
    mov al,0x30
    mov byte [0x40b8],0x1
lab_4456:
    mov [0x40b4],al
lab_4459:
    mov ax,[0x40b2]
    cmp byte [0x40b7],0x1
    jb short lab_4486
    jnz short lab_4477
    db 0x05, 0x04, 0x00                 ; add ax,0x4
    cmp ax,0x136
    jb short lab_4483
    mov ax,0x135
    mov byte [0x40b7],0xff
    jmp short lab_4483
lab_4477:
    db 0x2d, 0x04, 0x00                 ; sub ax,0x4
    jnb short lab_4483
    db 0x2b, 0xc0                       ; sub ax,ax
    mov byte [0x40b7],0x1
lab_4483:
    mov [0x40b2],ax
lab_4486:
    call lab_452d
    mov cx,[0x40b2]
    mov dl,[0x40b4]
    call calc_cga_addr
    mov [0x40bc],ax
    mov ax,0xb800
    mov es,ax
    cmp byte [0x40b9],0x0
    jnz short lab_44b0
    mov si,0x3f2c
    mov di,[0x40ba]
    mov cx,0x501
    call blit_to_cga
lab_44b0:
    call lab_4557
    jb short lab_44e6
    mov byte [0x40b9],0x0
    add word [0x40be],0x2
    mov bx,[0x40be]
    db 0x81, 0xe3, 0x06, 0x00           ; and bx,0x6
    mov si,[bx+0x40c0]
    cmp byte [0x40b7],0xff
    jnz short lab_44d5
    add si,0x1e
lab_44d5:
    mov di,[0x40bc]
    mov [0x40ba],di
    mov bp,0x3f2c
    mov cx,0x501
    call blit_transparent
lab_44e6:
    ret
lab_44e7:
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
lab_44fb:
    mov ax,[0x40b2]
    mov dl,0x1
    sub ax,[0x579]
    jnb short lab_450a
    not ax
    mov dl,0xff
lab_450a:
    mov [0x40ca],dl
    mov [0x40cc],ax
    mov al,[0x40b4]
    mov dl,0x1
    sub al,[0x57b]
    jnb short lab_4520
    not al
    mov dl,0xff
lab_4520:
    mov [0x40cb],dl
    db 0x2a, 0xe4                       ; sub ah,ah
    db 0xd1, 0xe0                       ; shl ax,0x0
    add [0x40cc],ax
    ret
lab_452d:
    mov ax,[0x40b2]
    mov dl,[0x40b4]
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
lab_4557:
    mov ax,[0x40b2]
    mov dl,[0x40b4]
    mov si,0x8
    mov bx,[0x327d]
    mov dh,[0x327f]
    mov di,0x10
    mov cx,0x1e05
    call check_rect_collision
    jnb short lab_4579
    mov byte [0x40b8],0xff
lab_4579:
    ret
lab_457a:
    mov cx,0x90
    mov dl,0x86
    mov [0x40a8],cx
    mov [0x40aa],dl
    call calc_cga_addr
    mov [0x40ab],ax
    call lab_4759
    mov byte [0x40af],0x0
    mov byte [0x40b1],0x0
    mov byte [0x40b9],0x1
    mov byte [0x40b8],0x0
    mov word [0x40c8],0xff
    ret
lab_45ab:
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    cmp dx,[0x40ad]
    jnz short lab_45b6
lab_45b5:
    ret
lab_45b6:
    mov [0x40ad],dx
    cmp byte [0x40aa],0xa4
    jnb short lab_45b5
    call lab_4786
    jnb short lab_45d6
    call lab_44e7
    jnb short lab_45b5
    mov byte [0x571],0x1
    mov byte [0x55b],0x10
    ret
lab_45d6:
    call lab_473e
    jnb short lab_4649
    cmp byte [0x40af],0x0
    jnz short lab_45fa
    mov al,[0x56e]
    cmp al,0x0
    jnz short lab_45f7
    inc al
    mov bx,[0x40a8]
    cmp bx,[0x579]
    ja short lab_45f7
    mov al,0xff
lab_45f7:
    mov [0x40b0],al
lab_45fa:
    mov byte [0x40af],0x1
    mov cx,0x20
lab_4602:
    mov ax,[0x579]
    mov dl,0x1
    cmp byte [0x40b0],0x1
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
    call lab_473e
    pop cx
    jnb short lab_4642
    loop short lab_4602
lab_4642:
    call restore_alley_buffer
    call save_cat_background
lab_4648:
    ret
lab_4649:
    cmp byte [0x40b1],0x0
    jnz short lab_46a2
    cmp byte [0x40af],0x0
    jz short lab_4648
    mov ax,[0x40a8]
    cmp byte [0x40b0],0x1
    jnz short lab_4666
    db 0x05, 0x08, 0x00                 ; add ax,0x8
    jmp short lab_4669
lab_4666:
    db 0x2d, 0x08, 0x00                 ; sub ax,0x8
lab_4669:
    mov [0x40a8],ax
    call lab_473e
    jnb short lab_4672
    ret
lab_4672:
    mov ax,0xc00
    mov bx,0xb54
    call start_tone
    mov byte [0x40af],0x0
    mov cx,[0x40a8]
    mov dl,[0x40aa]
    call calc_cga_addr
    mov [0x40ab],ax
    call lab_4773
    call lab_4759
    mov ax,[0x40a8]
    db 0x3d, 0x78, 0x00                 ; cmp ax,0x78
    jb short lab_46a2
    cmp ax,0xa8
    ja short lab_46a2
    ret
lab_46a2:
    mov byte [0x40b1],0x1
    cmp byte [0x1cbf],0x0
    jz short lab_46be
    call lab_44e7
    jnb short lab_46bd
    mov byte [0x571],0x1
    mov byte [0x55b],0x10
lab_46bd:
    ret
lab_46be:
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    cmp dx,[0x40ad]
    jz short lab_46a2
    mov [0x40ad],dx
    cmp byte [0x0],0x0
    jz short lab_46ec
    mov al,0xb6
    out byte 0x43,al
    mov al,[0x40aa]
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
    mov dl,[0x40aa]
    cmp dl,0xa4
    jnb short lab_470e
    add dl,0x5
    mov [0x40aa],dl
    mov cx,[0x40a8]
    call calc_cga_addr
    mov [0x40ab],ax
    call lab_4773
    call lab_4759
    jmp short lab_46be
lab_470e:
    call silence_speaker
    call lab_4773
    mov bp,0x401e
    dec word [0x40a6]
    mov di,[0x40a6]
    mov si,0x3f36
    mov cx,0x1104
    call blit_masked
    mov ax,[0x40a8]
    mov [0x40b2],ax
    mov al,[0x40aa]
    mov [0x40b4],al
    call lab_44fb
    mov al,[0x40ca]
    mov [0x40b7],al
    ret
lab_473e:
    mov ax,[0x40a8]
    mov dl,[0x40aa]
    mov si,0x18
    mov bx,[0x579]
    mov dh,[0x57b]
    db 0x8b, 0xfe                       ; mov di,si
    mov cx,0xe10
    call check_rect_collision
    ret
lab_4759:
    mov ax,0xb800
    mov es,ax
    mov bp,0x401e
    mov si,0x3fbe
    mov di,[0x40ab]
    mov [0x40a6],di
    mov cx,0x1003
    call blit_masked
    ret
lab_4773:
    mov ax,0xb800
    mov es,ax
    mov si,0x401e
    mov di,[0x40a6]
    mov cx,0x1003
    call blit_to_cga
    ret
lab_4786:
    cmp byte [0x327f],0x66
    jb short lab_47a4
    mov ax,[0x40a8]
    db 0x2d, 0x14, 0x00                 ; sub ax,0x14
    cmp ax,[0x327d]
    ja short lab_47a4
    db 0x05, 0x30, 0x00                 ; add ax,0x30
    cmp ax,[0x327d]
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
lab_47b0:
    mov ax,[0x327d]
    mov dl,[0x327f]
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
lab_47d6:
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    db 0x8b, 0xc2                       ; mov ax,dx
    sub ax,[0x44d7]
    mov si,[0x8]
    db 0xd1, 0xe6                       ; shl si,0x0
    cmp ax,[si+0x44dc]
    ja short lab_47ed
lab_47ec:
    ret
lab_47ed:
    mov [0x44d7],dx
    cmp byte [0x1cb8],0x0
    jnz short lab_47ec
    mov byte [0x44fc],0x0
    mov cx,0xc
lab_4800:
    db 0x8b, 0xd9                       ; mov bx,cx
    dec bx
    db 0xd0, 0xe3                       ; shl bl,0x0
    cmp word [bx+0x4441],0x0
    jz short lab_487d
    mov ax,[bx+0x43f9]
    cmp al,[0x57b]
    jnz short lab_485d
    mov ax,[bx+0x43e1]
    sub ax,[0x579]
    jnb short lab_4822
    not ax
lab_4822:
    mov si,[0x8]
    db 0xd1, 0xe6                       ; shl si,0x0
    cmp ax,[si+0x44ec]
    ja short lab_485d
    cmp word [bx+0x4459],0x2
    jb short lab_484c
    mov ax,[bx+0x4411]
    mov [0x44da],ax
    call lab_488d
    call lab_48a1
    call lab_3339
    call draw_alley_foreground
    call activate_enemy_chase
    ret
lab_484c:
    inc word [bx+0x4459]
    cmp word [bx+0x4459],0x2
    jb short lab_4870
    inc byte [0x44fc]
    jmp short lab_4870
lab_485d:
    cmp word [bx+0x4459],0x0
    jz short lab_487d
    call random
    cmp dl,0x38
    ja short lab_4870
    dec word [bx+0x4459]
lab_4870:
    push cx
    push bx
    call lab_48d7
    pop bx
    call lab_4916
    call lab_48c1
    pop cx
lab_487d:
    loop short lab_488a
    cmp byte [0x44fc],0x0
    jz short lab_4889
    call play_explosion_effect
lab_4889:
    ret
lab_488a:
    jmp near lab_4800
lab_488d:
    cmp byte [0x44bd],0x0
    jz short lab_489d
    call lab_4b03
    mov byte [0x44bd],0x0
    ret
lab_489d:
    call restore_alley_buffer
    ret
lab_48a1:
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
    mov di,[0x44da]
    mov cx,0xd05
    call blit_to_cga
    ret
lab_48c1:
    cmp byte [0x44d9],0x0
    jz short lab_48d2
    cmp byte [0x44bd],0x0
    jz short lab_48d3
    call lab_4b1d
lab_48d2:
    ret
lab_48d3:
    call draw_alley_foreground
    ret
lab_48d7:
    mov byte [0x44d9],0x0
    mov ax,[bx+0x43e1]
    mov dx,[bx+0x43f9]
    db 0x2d, 0x14, 0x00                 ; sub ax,0x14
    mov si,0x28
    mov bx,[0x579]
    mov dh,[0x57b]
    mov cx,0xe06
    mov di,0x18
    call check_rect_collision
    jnb short lab_4915
    mov byte [0x44d9],0x1
lab_4902:
    call check_vsync
    jz short lab_4902
    cmp byte [0x44bd],0x0
    jz short lab_4912
    call lab_4b03
    ret
lab_4912:
    call restore_alley_buffer
lab_4915:
    ret
lab_4916:
    mov ax,[bx+0x4411]
    mov si,[bx+0x4459]
    db 0xd1, 0xe6                       ; shl si,0x0
    add si,0x4100
    add ax,0xa7
    cmp word [bx+0x4429],0x429c
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
lab_4943:
    cmp byte [0x1cb8],0x0
    jnz short lab_4966
    cmp byte [0x44be],0x0
    jz short lab_495c
    mov al,[0x44be]
    mov [0x698],al
    mov byte [0x699],0x0
lab_495c:
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    cmp dx,[0x44d3]
    jnz short lab_4967
lab_4966:
    ret
lab_4967:
    mov [0x44d3],dx
    cmp byte [0x584],0x0
    jz short lab_4995
    cmp byte [0x44bd],0x0
    jz short lab_4994
    call lab_4b03
    call lab_33a0
    call save_alley_buffer
    call lab_3339
    mov byte [0x44bd],0x0
    mov byte [0x43e0],0x1
    mov byte [0x44be],0x0
lab_4994:
    ret
lab_4995:
    cmp byte [0x69a],0x0
    jz short lab_499f
    jmp short lab_49f9
    nop
lab_499f:
    mov ax,0xffff
    mov [0x44c1],ax
    mov [0x44bf],ax
    mov cx,0xc
    mov si,[0x579]
    mov dl,[0x57b]
    add dl,0x8
lab_49b6:
    db 0x8b, 0xd9                       ; mov bx,cx
    dec bx
    cmp byte [bx+0x44c4],0x1
    jb short lab_49f0
    cmp dl,[bx+0x4499]
    jnz short lab_49f0
    db 0x8b, 0xc6                       ; mov ax,si
    db 0xd0, 0xe3                       ; shl bl,0x0
    mov dh,0xff
    sub ax,[bx+0x4481]
    jnb short lab_49d6
    not ax
    mov dh,0x1
lab_49d6:
    cmp ax,[0x44bf]
    ja short lab_49f0
    mov [0x44bf],ax
    mov ax,[bx+0x44a5]
    mov [0x44d1],ax
    db 0xd0, 0xeb                       ; shr bl,0x0
    mov [0x44c1],bx
    mov [0x44c3],dh
lab_49f0:
    loop short lab_49b6
    cmp word [0x44c1],0xc
    jb short lab_4a20
lab_49f9:
    cmp byte [0x44bd],0x0
    jz short lab_4a0b
    call lab_4b03
    call draw_alley_foreground
    mov byte [0x69a],0x10
lab_4a0b:
    mov byte [0x44bd],0x0
    mov byte [0x43e0],0x1
    mov byte [0x44d0],0x0
    mov byte [0x44be],0x0
    ret
lab_4a20:
    cmp word [0x44bf],0x4
    jb short lab_4a4b
    cmp word [0x44bf],0x8
    ja short lab_4a33
    mov byte [0x572],0x4
lab_4a33:
    mov al,[0x44c3]
    mov [0x698],al
    mov [0x56e],al
    mov [0x44be],al
    mov byte [0x699],0x0
    mov byte [0x571],0x0
    jmp short lab_49f9
lab_4a4b:
    mov byte [0x44be],0x0
    cmp byte [0x44bd],0x0
    jnz short lab_4a5d
    call restore_alley_buffer
    call save_alley_buffer
lab_4a5d:
    mov byte [0x44bd],0x1
    db 0x2a, 0xc0                       ; sub al,al
    add byte [0x44d0],0x30
    jnb short lab_4a6d
    inc al
lab_4a6d:
    mov [0x44d5],al
    mov cx,[0x579]
    and cx,0xffc
    mov dl,[0x57b]
    add dl,0x3
    cmp word [0x44d1],0x410c
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
    mov [0x43dc],ax
lab_4aa2:
    call check_vsync
    jz short lab_4aa2
    call lab_4b03
    cmp byte [0x44d5],0x0
    jz short lab_4aff
    mov bx,[0x44c1]
    cmp byte [bx+0x44c4],0x0
    jz short lab_4aff
    dec byte [bx+0x44c4]
    jnz short lab_4ae7
    push bx
    mov ax,0x8fd
    mov bx,0x723
    call start_tone
    pop bx
    mov byte [0x698],0x0
    mov byte [0x44be],0x0
    mov byte [0x69a],0x10
    dec byte [0x44d6]
    jnz short lab_4ae7
    mov byte [0x553],0x1
lab_4ae7:
    push bx
    call lab_47b0
    pop bx
    jnb short lab_4afc
    push bx
    call lab_33a0
    pop bx
    call lab_4bc8
    call lab_3339
    jmp short lab_4aff
    nop
lab_4afc:
    call lab_4bc8
lab_4aff:
    call lab_4b1d
    ret
lab_4b03:
    cmp byte [0x43e0],0x0
    jnz short lab_4b1c
    mov di,[0x43de]
    mov si,0x43a0
    mov ax,0xb800
    mov es,ax
    mov cx,0xa03
    call blit_to_cga
lab_4b1c:
    ret
lab_4b1d:
    mov byte [0x43e0],0x0
    mov ax,0xb800
    mov es,ax
    mov di,[0x43dc]
    mov [0x43de],di
    mov bp,0x43a0
    mov si,[0x44d1]
    cmp byte [0x44d0],0x80
    jb short lab_4b40
    add si,0x3c
lab_4b40:
    mov cx,0xa03
    call blit_masked
    ret
lab_4b47:
    push ds
    pop es
    db 0x2b, 0xc0                       ; sub ax,ax
    mov di,0x4441
    mov cx,0xc
    rep stosw
    mov ax,0xb800
    mov es,ax
    mov bx,[0x8]
    mov cl,[bx+0x4471]
    db 0x2a, 0xed                       ; sub ch,ch
lab_4b62:
    call random
    db 0x8a, 0xda                       ; mov bl,dl
    db 0x81, 0xe3, 0x1e, 0x00           ; and bx,0x1e
    cmp bl,0x18
    jnb short lab_4b62
    cmp word [bx+0x4441],0x0
    jnz short lab_4b62
    mov word [bx+0x4459],0x0
    mov word [bx+0x4441],0x1
    push cx
    mov si,[bx+0x4429]
    mov di,[bx+0x4411]
    mov cx,0xd05
    call blit_to_cga
    pop cx
    loop short lab_4b62
    mov cx,0xc
lab_4b98:
    db 0x8b, 0xd9                       ; mov bx,cx
    dec bx
    mov si,[0x8]
    mov dl,[si+0x4479]
    mov [bx+0x44c4],dl
    push cx
    call lab_4bc8
    pop cx
    loop short lab_4b98
    mov byte [0x44d0],0x0
    mov byte [0x44bd],0x0
    mov byte [0x43e0],0x1
    mov byte [0x44d6],0xc
    mov byte [0x44be],0x0
    ret
lab_4bc8:
    call lab_4be8
    db 0x8b, 0xf8                       ; mov di,ax
    mov al,[bx+0x44c4]
    db 0x2a, 0xe4                       ; sub ah,ah
    mov cl,0x5
    shl ax,cl
    add ax,0x41fc
    db 0x8b, 0xf0                       ; mov si,ax
    mov cx,0x802
    mov ax,0xb800
    mov es,ax
    call blit_to_cga
    ret
lab_4be8:
    push bx
    mov dl,[bx+0x4499]
    db 0xd0, 0xe3                       ; shl bl,0x0
    mov cx,[bx+0x4481]
    call calc_cga_addr
    pop bx
    ret
    add [bx+si],al
    add [bx+si],al
    add [bx+si],al
    add [bx+si],al
lab_4c00:
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
lab_4c10:
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    cmp dx,[0x45b8]
    jnz short lab_4c1b
    ret
lab_4c1b:
    inc word [0x45b6]
    mov bx,[0x45b6]
    cmp bx,0x1
    jz short lab_4c38
    cmp bx,0x4
    jz short lab_4c38
    cmp bx,0x7
    jb short lab_4c3c
    db 0x2b, 0xdb                       ; sub bx,bx
    mov [0x45b6],bx
lab_4c38:
    mov [0x45b8],dx
lab_4c3c:
    call lab_4fcd
    call lab_502d
    jnb short lab_4c45
lab_4c44:
    ret
lab_4c45:
    cmp word [0x454f],0x0
    jz short lab_4c8c
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    sub dx,[0x454f]
    mov bx,[0x8]
    db 0xd0, 0xe3                       ; shl bl,0x0
    mov ax,[bx+0x45c7]
    cmp word [0x45b6],0x0
    jnz short lab_4c67
    db 0xd1, 0xe0                       ; shl ax,0x0
lab_4c67:
    db 0x3b, 0xd0                       ; cmp dx,ax
    jb short lab_4c44
    mov word [0x454f],0x0
    mov byte [0x454e],0x1
    mov ax,0x24
    cmp word [0x579],0xa0
    ja short lab_4c84
    mov ax,0x108
lab_4c84:
    mov [0x4548],ax
    mov byte [0x454a],0x0
lab_4c8c:
    call lab_4dd0
    jnb short lab_4c99
    mov bx,[0x45b6]
    call lab_4fbb
    ret
lab_4c99:
    cmp byte [0x4553],0x0
    jz short lab_4cb8
    dec byte [0x4553]
    jnz short lab_4cb5
    mov dl,0x1
    cmp byte [0x454a],0xff
    jz short lab_4cb1
    mov dl,0xff
lab_4cb1:
    mov [0x454a],dl
lab_4cb5:
    jmp short lab_4d14
    nop
lab_4cb8:
    mov al,[0x454b]
    cmp al,[0x57b]
    ja short lab_4d14
    cmp word [0x45b6],0x6
    jnz short lab_4ccf
    cmp byte [0x57b],0x28
    jb short lab_4cdc
lab_4ccf:
    call random
    mov bx,[0x8]
    cmp dl,[bx+0x45bf]
    ja short lab_4d14
lab_4cdc:
    db 0x2a, 0xd2                       ; sub dl,dl
    mov ax,[0x4548]
    and ax,0xff8
    mov cx,[0x579]
    and cx,0xff8
    db 0x3b, 0xc1                       ; cmp ax,cx
    jz short lab_4cf6
    mov dl,0x1
    jb short lab_4cf6
    mov dl,0xff
lab_4cf6:
    mov [0x454a],dl
    cmp byte [0x57b],0x28
    jb short lab_4d14
    cmp word [0x45b6],0x6
    jnz short lab_4d14
    mov al,0x1
    cmp dl,0xff
    jz short lab_4d11
    mov al,0xff
lab_4d11:
    mov [0x454a],al
lab_4d14:
    mov word [0x45bc],0x8
    cmp byte [0x4553],0x0
    jz short lab_4d27
    mov word [0x45bc],0x4
lab_4d27:
    mov ax,[0x4548]
    cmp byte [0x454a],0x1
    jnb short lab_4d46
    call random
    cmp dl,0x10
    ja short lab_4da1
    and dl,0x1
    jnz short lab_4d40
    mov dl,0xff
lab_4d40:
    mov [0x454a],dl
    jmp short lab_4da1
lab_4d46:
    jnz short lab_4d60
    add ax,[0x45bc]
    cmp ax,0x10b
    jb short lab_4d78
    mov ax,0x10a
    mov byte [0x454a],0xff
    mov byte [0x4553],0x0
    jmp short lab_4d78
lab_4d60:
    sub ax,[0x45bc]
    jb short lab_4d6b
    db 0x3d, 0x24, 0x00                 ; cmp ax,0x24
    ja short lab_4d78
lab_4d6b:
    mov ax,0x25
    mov byte [0x454a],0x1
    mov byte [0x4553],0x0
lab_4d78:
    mov [0x4548],ax
    add word [0x4551],0x2
    cmp word [0x4551],0xc
    jb short lab_4d8d
    mov word [0x4551],0x0
lab_4d8d:
    cmp byte [0x4553],0x0
    jnz short lab_4da1
    call random
    cmp dl,0x8
    ja short lab_4da1
    mov byte [0x454a],0x0
lab_4da1:
    mov cx,[0x4548]
    mov dl,[0x454b]
    call calc_cga_addr
    mov [0x45ba],ax
    call lab_502d
    jnb short lab_4db5
    ret
lab_4db5:
    call lab_4dd0
    jb short lab_4dc8
    call lab_4f4a
    call lab_4f10
    mov byte [0x45be],0x0
    call lab_4e75
lab_4dc8:
    mov bx,[0x45b6]
    call lab_4fbb
    ret
lab_4dd0:
    mov ax,[0x579]
    mov dl,[0x57b]
    mov si,0x18
    db 0x8b, 0xfe                       ; mov di,si
    mov bx,[0x4548]
    mov dh,[0x454b]
    mov cx,0xc0e
    call check_rect_collision
    jnb short lab_4e3d
    cmp word [0x45b6],0x6
    jnz short lab_4e00
    mov byte [0x553],0x1
    call restore_alley_buffer
    call lab_4f4a
    stc
    ret
lab_4e00:
    call restore_alley_buffer
    call lab_4f4a
    call draw_alley_foreground
    mov byte [0x55b],0x4
    mov byte [0x571],0x1
    mov byte [0x576],0x4
    mov byte [0x578],0x8
    mov byte [0x4553],0x4
    mov dl,0x1
    mov ax,[0x4548]
    cmp ax,[0x579]
    ja short lab_4e2f
    mov dl,0xff
lab_4e2f:
    mov [0x454a],dl
    mov ax,0xce4
    mov bx,0x123b
    call start_tone
    stc
lab_4e3d:
    ret
lab_4e3e:
    mov byte [0x45be],0x1
    mov ax,[0x45b6]
    push ax
    mov word [0x45b6],0x0
lab_4e4d:
    mov bx,[0x45b6]
    call lab_4fcd
    cmp word [0x454f],0x0
    jnz short lab_4e65
    call lab_4e75
    mov bx,[0x45b6]
    call lab_4fbb
lab_4e65:
    inc word [0x45b6]
    cmp word [0x45b6],0x7
    jb short lab_4e4d
    pop ax
    mov [0x45b6],ax
    ret
lab_4e75:
    mov cx,0x8
lab_4e78:
    db 0x8b, 0xd9                       ; mov bx,cx
    dec bx
    cmp byte [bx+0x2b72],0x0
    jz short lab_4ea3
    push cx
    mov dl,[bx+0x2b6a]
    db 0xd0, 0xe3                       ; shl bl,0x0
    mov ax,[bx+0x2b5a]
    mov si,0x18
    db 0x8b, 0xfe                       ; mov di,si
    mov bx,[0x4548]
    mov dh,[0x454b]
    mov cx,0xc0f
    call check_rect_collision
    pop cx
    jb short lab_4ea6
lab_4ea3:
    loop short lab_4e78
    ret
lab_4ea6:
    push cx
    cmp byte [0x45be],0x0
    jnz short lab_4ebb
    call restore_alley_buffer
    cmp byte [0x70f2],0x0
    jz short lab_4ebb
    call erase_cupid
lab_4ebb:
    call lab_4f4a
    pop cx
    db 0x8b, 0xd9                       ; mov bx,cx
    dec bx
    mov byte [bx+0x2b72],0x0
    mov dl,[bx+0x2b6a]
    db 0xd0, 0xe3                       ; shl bl,0x0
    mov cx,[bx+0x2b5a]
    call calc_cga_addr
    db 0x8b, 0xf8                       ; mov di,ax
    mov si,0x2b7a
    mov ax,0xb800
    mov es,ax
    mov cx,0xf03
    call blit_to_cga
    cmp byte [0x45be],0x0
    jnz short lab_4ef8
    cmp byte [0x70f2],0x0
    jz short lab_4ef5
    call draw_cupid
lab_4ef5:
    call draw_alley_foreground
lab_4ef8:
    db 0x2b, 0xd2                       ; sub dx,dx
    cmp word [0x45b6],0x6
    jz short lab_4f0b
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    cmp dx,0x0
    jnz short lab_4f0b
    dec dx
lab_4f0b:
    mov [0x454f],dx
    ret
lab_4f10:
    mov byte [0x454e],0x0
    mov si,0x4500
    cmp byte [0x454a],0x0
    jz short lab_4f3e
    mov bx,[0x4551]
    cmp byte [0x4553],0x0
    jz short lab_4f30
    and bl,0x2
    add bl,0xc
lab_4f30:
    cmp byte [0x454a],0xff
    jnz short lab_4f3a
    add bx,0x10
lab_4f3a:
    mov si,[bx+0x4a60]
lab_4f3e:
    mov di,[0x45ba]
    mov [0x454c],di
    call lab_4fdf
    ret
lab_4f4a:
    cmp byte [0x454e],0x0
    jnz short lab_4f58
    mov di,[0x454c]
    call lab_5008
lab_4f58:
    ret
lab_4f59:
    mov word [0x45b6],0x0
lab_4f5f:
    call random
    db 0x81, 0xe2, 0x7f, 0x00           ; and dx,0x7f
    add dx,0x60
    mov [0x4548],dx
    mov byte [0x454a],0x0
    mov byte [0x454e],0x1
    mov word [0x4551],0x0
    mov byte [0x4553],0x0
    db 0x2b, 0xd2                       ; sub dx,dx
    cmp word [0x45b6],0x0
    jnz short lab_4f95
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    cmp dx,0x0
    jnz short lab_4f95
    dec dx
lab_4f95:
    mov [0x454f],dx
    mov bx,[0x45b6]
    mov al,[bx+0x2bd4]
    add al,0x3
    mov [0x454b],al
    call lab_4fbb
    inc word [0x45b6]
    cmp word [0x45b6],0x7
    jb short lab_4f5f
    mov word [0x45b6],0x0
    ret
lab_4fbb:
    push ds
    pop es
    db 0xd0, 0xe3                       ; shl bl,0x0
    cld
    mov di,[bx+0x45a8]
    mov si,0x4548
    mov cx,0xc
    rep movsb
    ret
lab_4fcd:
    push ds
    pop es
    db 0xd0, 0xe3                       ; shl bl,0x0
    cld
    mov si,[bx+0x45a8]
    mov di,0x4548
    mov cx,0xc
    rep movsb
    ret
lab_4fdf:
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
lab_5008:
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
lab_502d:
    cmp byte [0x70f2],0x0
    jnz short lab_5036
    clc
    ret
lab_5036:
    mov ax,[0x70f3]
    mov dl,[0x70f5]
    mov si,0x10
    mov bx,[0x4548]
    mov dh,[0x454b]
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
lab_5060:
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
    mov [0x4d6a],ax
    mov word [0x4dd6],0xa
lab_50a1:
    cmp word [0x4dd6],0xa
    jz short lab_50ab
    call play_victory_note
lab_50ab:
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    mov [0x4a80],dx
    mov ax,[0x579]
    db 0x8b, 0xc8                       ; mov cx,ax
    and cx,0xff0
    cmp cx,0x80
    jnz short lab_50c6
    db 0x8b, 0xc1                       ; mov ax,cx
    jmp short lab_50d2
lab_50c6:
    jb short lab_50ce
    sub ax,[0x4d6a]
    jmp short lab_50d2
lab_50ce:
    add ax,[0x4d6a]
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
    mov [0x4dd8],di
    mov si,0x4b8a
    mov bp,0xe
    mov cx,0x2007
    call blit_transparent
    mov di,[0x4dd8]
    add di,0xf3
    mov si,0x4a82
    mov cx,0xd04
    call blit_to_cga
    cmp word [0x4dd6],0xa
    jnz short lab_5120
    call play_swoop_sound
    call init_victory_melody
lab_5120:
    call play_victory_note
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    sub dx,[0x4a80]
    cmp dx,[0x4dd6]
    jb short lab_5120
    cmp word [0x4dd6],0xa
    jnz short lab_5141
    call lab_38b0
    db 0x2b, 0xdb                       ; sub bx,bx
    mov ah,0xb
    int byte 0x10
lab_5141:
    mov word [0x4dd6],0x2
    jmp near lab_50a1
lab_514a:
    mov cx,0x3
lab_514d:
    mov bx,0x3
    db 0x2b, 0xd9                       ; sub bx,cx
    db 0xd1, 0xe3                       ; shl bx,0x0
    mov ax,[bx+0x4da4]
    mov [0x4d6a],ax
    mov ax,[bx+0x4daa]
    mov [0x4d6c],ax
    mov ax,[bx+0x4d98]
    mov [0x4dcc],ax
    mov ax,[bx+0x4d9e]
    mov [0x4dce],ax
    mov ax,[bx+0x4db0]
    mov [0x4dd0],ax
    mov ax,[bx+0x4db6]
    mov [0x4dd2],ax
    mov ax,[bx+0x4dbc]
    mov [0x4dd4],ax
    mov ax,[bx+0x4d92]
    mov [0x4dca],ax
    mov ax,[bx+0x4dc2]
    mov [0x4dc8],ax
    push cx
    call lab_519b
    pop cx
    loop short lab_514d
    ret
lab_519b:
    mov cx,0x8
    mov byte [0x4d91],0x1
lab_51a3:
    push cx
    call play_victory_note
    pop cx
    db 0x8b, 0xd9                       ; mov bx,cx
    dec bx
    db 0xd1, 0xe3                       ; shl bx,0x0
    mov ax,[0x4dcc]
    mov [bx+0x4d4a],ax
    mov ax,[0x4dce]
    mov [bx+0x4d5a],ax
    loop short lab_51a3
    mov ax,0xb800
    mov es,ax
    mov byte [0x4d6e],0x0
lab_51c7:
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    mov [0x4a80],dx
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
    cmp byte [0x4d91],0x0
    jz short lab_51ea
    cmp cx,0x8
    jnz short lab_5205
lab_51ea:
    mov cx,[bx+0x4d4a]
    mov dx,[bx+0x4d5a]
    call calc_cga_addr
    db 0x8b, 0xf8                       ; mov di,ax
    mov si,[0x4dca]
    mov bp,0xe
    mov cx,[0x4dd4]
    call blit_transparent
lab_5205:
    pop bx
    pop cx
    call lab_522a
    loop short lab_51d2
lab_520c:
    call play_victory_note
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    sub dx,[0x4a80]
    cmp dx,[0x4dc8]
    jb short lab_520c
    mov byte [0x4d91],0x0
    cmp byte [0x4d6e],0x0
    jz short lab_51c7
    ret
lab_522a:
    mov ax,[bx+0x4d4a]
    cmp word [bx+0x4d6f],0x1
    jb short lab_525a
    jnz short lab_524a
    add ax,[0x4d6a]
    cmp ax,[0x4dd0]
    jbe short lab_5256
    mov ax,[0x4dd0]
    inc byte [0x4d6e]
    jmp short lab_5256
lab_524a:
    sub ax,[0x4d6a]
    jnb short lab_5256
    db 0x2b, 0xc0                       ; sub ax,ax
    inc byte [0x4d6e]
lab_5256:
    mov [bx+0x4d4a],ax
lab_525a:
    mov ax,[bx+0x4d5a]
    cmp word [bx+0x4d7f],0x1
    jb short lab_528a
    jnz short lab_527a
    add ax,[0x4d6c]
    cmp ax,[0x4dd2]
    jbe short lab_5286
    mov ax,[0x4dd2]
    inc byte [0x4d6e]
    jmp short lab_5286
lab_527a:
    sub ax,[0x4d6c]
    jnb short lab_5286
    db 0x2b, 0xc0                       ; sub ax,ax
    inc byte [0x4d6e]
lab_5286:
    mov [bx+0x4d5a],ax
lab_528a:
    ret
lab_528b:
    call init_victory_melody
    cmp byte [0x697],0xfd
    jz short lab_529c
    mov ah,0xb
    mov bx,0x101
    int byte 0x10
lab_529c:
    call lab_5060
    call lab_514a
    call play_full_victory
    cmp byte [0x1f80],0x9
    jnb short lab_52b0
    inc byte [0x1f80]
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
lab_52d0:
    cmp byte [0x0],0x0
    jz short lab_5312
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    cmp dx,[0x52c4]
    jz short lab_5312
    mov [0x52c4],dx
    mov bx,[0x52c6]
    add word [0x52c6],0x2
    mov ax,[bx+0x52ca]
    cmp ax,[0x52c8]
    jnz short lab_52fc
    call silence_speaker
    ret
lab_52fc:
    mov [0x52c8],ax
    mov al,0xb6
    out byte 0x43,al
    mov ax,[0x52c8]
    out byte 0x42,al
    db 0x8a, 0xc4                       ; mov al,ah
    out byte 0x42,al
    in al,byte 0x61
    or al,0x3
    out byte 0x61,al
lab_5312:
    ret
lab_5313:
    cmp word [0x8],0x2
    jb short lab_5367
    mov word [0x5016],0x0
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    mov [0x52c0],dx
    mov [0x52c2],dx
    mov [0x52c4],dx
    mov word [0x52c6],0x0
    mov word [0x52c8],0x0
lab_533c:
    call lab_5368
    db 0x81, 0x36, 0x16, 0x50, 0x02, 0x00 ; xor word [0x5016],0x2
lab_5345:
    call lab_52d0
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    db 0x8b, 0xc2                       ; mov ax,dx
    sub ax,[0x52c0]
    db 0x3d, 0x05, 0x00                 ; cmp ax,0x5
    jb short lab_5345
    mov [0x52c0],dx
    sub dx,[0x52c2]
    cmp dx,0x28
    jb short lab_533c
    call silence_speaker
lab_5367:
    ret
lab_5368:
    mov ax,0xb800
    mov es,ax
    mov bx,[0x8]
    db 0xd1, 0xe3                       ; shl bx,0x0
    mov ax,[bx+0x52ae]
    mov [0x5010],ax
lab_537a:
    mov bx,[0x5010]
    mov di,[bx]
    cmp di,0x0
    jnz short lab_5386
    ret
lab_5386:
    mov bx,[bx+0x2]
    xor bx,[0x5016]
    db 0x81, 0xe3, 0x02, 0x00           ; and bx,0x2
    mov si,[bx+0x5012]
    mov cx,0x2304
    call blit_to_cga
    call lab_52d0
    add word [0x5010],0x4
    jmp short lab_537a
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00


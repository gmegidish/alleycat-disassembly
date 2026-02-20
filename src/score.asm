; --- update_high_score ---
; Copies current score to high score if current > high.
; Score is stored as 7 BCD digits at DS:0x1F82 (current) and DS:0x1F89 (high).
update_high_score:
    push ds
    pop es
    mov cx,0x7
    mov si,0x1f82
lab_2698:
    lodsb
    mov bx,0x7
    db 0x2b, 0xd9                       ; sub bx,cx
    cmp al,byte [bx + 0x1f89]
    loopz lab_2698
    ja lab_26a7
    ret
lab_26a7:
    mov si,0x1f82
    mov di,0x1f89
    mov cx,0x7
    rep movsb
    ret

; --- draw_lives ---
; Redraws the lives indicator on screen if it changed since last draw.
; Reads [lives_count], compares to [lives_display] cache. Blits sprite to CGA.
draw_lives:
    mov al,[lives_count]
    cmp al,byte [lives_display]
    jnz lab_26bd
    ret
lab_26bd:
    mov [lives_display],al
    db 0x2a, 0xe4                       ; sub ah,ah
    mov cl,0x4
    shl ax,cl
    add ax,0x2720
    db 0x8b, 0xf0                       ; mov si,ax
    mov ax,0xb800
    mov es,ax
    mov di,0x1260
    mov cx,0x801
    call blit_to_cga                           ;undefined blit_to_cga()
    ret

; --- clear_score ---
; Zeros the 7-digit current score buffer at DS:0x1F82.
clear_score:
    mov di,0x1f82
    call zero_score_buffer                           ;undefined zero_score_buffer()
    ret

; --- clear_high_score ---
; Zeros the 7-digit high score buffer at DS:0x1F89.
clear_high_score:
    mov di,0x1f89
    call zero_score_buffer                           ;undefined zero_score_buffer()
    ret

; --- zero_score_buffer ---
; Input: DI = pointer to 7-byte score buffer
; Fills the buffer with zeros.
zero_score_buffer:
    push ds
    pop es
    mov cx,0x7
    db 0x2a, 0xc0                       ; sub al,al
    rep stosb
    ret

; --- draw_score ---
; Renders the current score digits to CGA screen at offset 0x12CA.
draw_score:
    mov bx,0x1f89
    mov di,0x12ca
    call render_score_digits                           ;undefined render_score_digits()
    ret

; --- draw_high_score ---
; Renders the high score digits to CGA screen at offset 0x143C.
draw_high_score:
    mov bx,0x1f82
    mov di,0x143c
    call render_score_digits                           ;undefined render_score_digits()
    ret

; --- add_score ---
; Adds a BCD value to the current score using AAA (ASCII adjust after add).
; Input: AL = BCD digit to add to the ones place (carries propagate up)
add_score:
    mov cx,0x6
lab_2709:
    db 0x8b, 0xd9                       ; mov bx,cx
    mov ah,0x0
    add al,byte [bx + 0x1f81]
    aaa
    mov byte [bx + 0x1f81],al
    db 0x8a, 0xc4                       ; mov al,ah
    loop lab_2709
    call draw_high_score                           ;undefined draw_high_score()
    ret
add_bcd_scores:
    push cx
    push ax
    push bx
    clc
    pushf
    mov cx,0x7
lab_2726:
    popf
    db 0x8b, 0xd9                       ; mov bx,cx
    dec bx
    mov al,[bx+di]
    adc al,[bx+si]
    aaa
    mov [bx+di],al
    pushf
    loop short lab_2726
    popf
    pop bx
    pop ax
    pop cx
    ret

; --- render_score_digits ---
render_score_digits:
    mov ax,0xb800
    mov es,ax
    mov word [score_draw_pos],di
    mov word [score_buf_ptr],bx
    mov byte [score_digit_idx],0x0
lab_274b:
    mov bx,word [score_buf_ptr]
    mov al,byte [bx]
    db 0x2a, 0xe4                       ; sub ah,ah
    mov cl,0x4
    shl ax,cl
    add ax,0x2720
    db 0x8b, 0xf0                       ; mov si,ax
    mov di,word [score_draw_pos]
    mov cx,0x801
    call blit_to_cga                           ;undefined blit_to_cga()
    add word [score_draw_pos],0x2
    inc word [score_buf_ptr]
    inc byte [score_digit_idx]
    cmp byte [score_digit_idx],0x7
    jz lab_2788
    cmp byte [score_digit_idx],0x3
    jnz lab_274b
    add word [score_draw_pos],0x2
    jmp short lab_274b
lab_2788:
    ret
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; --- draw_level_background ---
; Draws the score bar and level background header.
; Behavior depends on [level_number]: level 2 draws random blocks,
; level 7 uses a special renderer, others draw standard score bar.
draw_level_background:
    mov ax,0xb800
    mov es,ax
    cmp word [level_number],0x2
    jnz short lab_27ee
    cld
    db 0x2b, 0xff                       ; sub di,di
    mov ax,0xaaaa
    mov cx,0x50
    rep stosw
    mov di,0x2000
    mov cx,0x50
    rep stosw
    mov word [block_count],0x0
lab_27b5:
    call random
    db 0x81, 0xe2, 0x18, 0x00           ; and dx,0x18
    cmp dl,[block_prev]
    jz short lab_27b5
    mov [block_prev],dl
    mov bx,[block_count]
    mov [bx+0x2656],dl
    add dx,0x2020
    db 0x8b, 0xf2                       ; mov si,dx
    db 0x8b, 0xfb                       ; mov di,bx
    db 0xd1, 0xe7                       ; shl di,0x0
    add di,0xa0
    mov cx,0x401
    call blit_to_cga
    inc word [block_count]
    cmp word [block_count],0x28
    jb short lab_27b5
    ret
lab_27ee:
    cmp word [level_number],0x7
    jnz short lab_27f9
    call draw_love_scene_bg
    ret
lab_27f9:
    cmp word [level_number],0x6
    jnz short lab_283e
    db 0x2b, 0xc0                       ; sub ax,ax
    call draw_level_border
    mov bx,0x2570
    mov ax,0x64a
    call draw_block_list
    mov word [entrance_x],0x48
    mov byte [entrance_y],0x38
    mov ax,0xdd2
    call draw_door_frame
    mov ax,0xdf6
    call draw_platform
    mov si,0x1fa0
    mov di,0x67e
    mov cx,0x1002
    call blit_to_cga
    mov bx,0x2344
    mov ax,0xb84
    call draw_block_list
    call init_level6_objects
    ret
lab_283e:
    cmp word [level_number],0x5
    jnz short lab_288d
    mov ax,0x640
    call draw_level_border
    mov bx,0x2570
    mov ax,0xcb6
    call draw_block_list
    mov word [entrance_x],0xf8
    mov byte [entrance_y],0x60
    mov ax,0x140e
    call draw_door_frame
    mov ax,0x1434
    call draw_platform
    mov ax,0x143e
    call draw_platform
    mov ax,0x16a0
    call draw_ledge
    mov bx,0x2344
    mov ax,0x1184
    call draw_block_list
    mov si,0x1fe0
    mov di,0xdd6
    mov cx,0x1002
    call blit_to_cga
    ret
lab_288d:
    cmp word [level_number],0x4
    jnz short lab_28be
    mov ax,0x640
    call draw_level_border
    mov bx,0x2570
    mov ax,0xcba
    call draw_block_list
    mov word [entrance_x],0x108
    mov byte [entrance_y],0x60
    mov ax,0x1439
    call draw_door_frame
    mov ax,0x16c0
    call draw_block_pair
    call init_level4_bg
    ret
lab_28be:
    cmp word [level_number],0x3
    jnz short lab_2909
    mov ax,0x640
    call draw_level_border
    mov bx,0x2570
    mov ax,0xc90
    call draw_block_list
    mov word [entrance_x],0x60
    mov byte [entrance_y],0x60
    mov ax,0x140c
    call draw_door_frame
    mov ax,0x1418
    call draw_platform
    mov bx,0x2344
    mov ax,0x1184
    call draw_block_list
    mov bx,0x2344
    mov ax,0x11a2
    call draw_block_list
    mov bx,0x2624
    db 0x2b, 0xc0                       ; sub ax,ax
    call draw_block_list
    call draw_level3_bg
    ret
lab_2909:
    mov ax,0x640
    call draw_level_border
    mov bx,0x2570
    mov ax,0xca0
    call draw_block_list
    mov word [entrance_x],0xa0
    mov byte [entrance_y],0x60
    mov ax,0x1406
    call draw_door_frame
    mov bx,0x2344
    mov ax,0x11c4
    call draw_block_list
    mov ax,0x1422
    call draw_platform
    mov ax,0x1690
    call draw_ledge
    mov ax,0x16b6
    call draw_block_pair
    ret
draw_block_pair:
    mov [draw_temp],ax
    mov bx,0x2384
    call draw_block_list
    mov ax,[draw_temp]
    mov bx,0x238c
    call draw_block_list
    ret
draw_door_frame:
    mov [draw_temp],ax
    mov si,0x8
lab_295e:
    mov ax,[draw_temp]
    mov bx,[si+0x2634]
    push si
    call draw_block_list
    pop si
    sub si,0x2
    jnz short lab_295e
    ret
draw_platform:
    mov [draw_temp],ax
    mov si,0xa
lab_2976:
    mov ax,[draw_temp]
    mov bx,[si+0x263c]
    push si
    call draw_block_list
    pop si
    sub si,0x2
    jnz short lab_2976
    ret
draw_ledge:
    mov [draw_temp],ax
    mov si,0x8
lab_298e:
    mov ax,[draw_temp]
    mov bx,[si+0x2646]
    push si
    call draw_block_list
    pop si
    sub si,0x2
    jnz short lab_298e
    ret
draw_level_border:
    mov [bar_base],ax
    mov bx,0x251c
    call draw_block_list
    db 0x2b, 0xc0                       ; sub ax,ax
    cld
    mov di,[bar_base]
    add di,0x284
    mov cx,0x24
    rep stosw
    mov di,[bar_base]
    add di,0x1184
    mov cx,0x24
    rep stosw
    mov di,[bar_base]
    add di,0x2284
    mov al,0x2a
    call draw_vertical_line
    mov di,[bar_base]
    add di,0x22cb
    mov al,0xa8
    call draw_vertical_line
    ret
draw_vertical_line:
    mov cx,0x5f
lab_29e4:
    mov [es:di],al
    xor di,0x2000
    test di,0x2000
    jnz short lab_29f4
    add di,0x50
lab_29f4:
    loop short lab_29e4
    ret
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00


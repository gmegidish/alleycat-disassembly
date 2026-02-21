; --- detect_video ---
; Checks for CGA-compatible video hardware via BIOS equipment list (INT 11h).
; If bits 4-5 indicate monochrome (0x30), skips CGA init.
; Otherwise, verifies CGA RAM at B800:0000 is readable/writable.
; If CGA RAM test fails, prints error message and halts.
; On success, prints startup message and sets CGA 320x200 4-color mode.
detect_video:
    int 0x11                            ; BIOS: Equipment list → AX (bits 4-5=video mode)
    and al,0x30
    cmp al,0x30
    jnz lab_5c95
    mov ax,0xb800
    mov ds,ax
    mov ax,0x55aa
    mov [sound_enabled],ax
    mov ax,[sound_enabled]
    cmp ax,0x55aa
    jnz lab_5c96
    mov si,0x60f0
    call print_startup_msg                           ;undefined print_startup_msg()
    mov ax,0x40
    mov ds,ax
    mov ax,[0x10]
    and al,0xcf
    or al,0x10
    mov [0x10],ax
    mov ax,0x4
    int 0x10                            ; BIOS Video: Set mode (CGA 320x200 4-color)
lab_5c95:
    ret
lab_5c96:
    mov si,0x6112
    call print_startup_msg                           ;undefined print_startup_msg()
lab_5c9c:
    jmp short lab_5c9c

; --- print_startup_msg ---
print_startup_msg:
reloc_9:
    mov ax,DATA_SEG_PARA                ; relocated: DS = data segment
    mov ds,ax
    call print_string                           ;undefined print_string()
    ret
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00

; --- show_title_screen ---
; Draws the full title screen: alley background, game logo, copyright text,
; author credits, and an animated icon. Sets up a cat that walks across the
; bottom of the screen (via move_title_cat). Plays the title music.
; Waits for a keypress or joystick button press, or times out to attract mode.
; Initializes score display and lives counter before returning.
show_title_screen:
    cld
    mov word [level_number],0x0
    call init_player                           ;undefined init_player()
    call init_objects                           ;undefined init_objects()
    call draw_alley_scene                           ;undefined draw_alley_scene()
    mov ax,0xb800
    mov es,ax
    mov si,0x6152
    mov cx,0x1d0b
    mov di,0xbd
    call blit_to_cga                           ;undefined blit_to_cga()
    mov si,0x63d0
    mov cx,0x160e
    mov di,0x69e
    call blit_to_cga                           ;undefined blit_to_cga()
    mov si,0x6638
    mov cx,0xc03
    mov di,0xa78
    call blit_to_cga                           ;undefined blit_to_cga()
    mov si,0x6680
    mov cx,0x80e
    mov di,0xca8
    call blit_to_cga                           ;undefined blit_to_cga()
    mov si,0x6760
    mov cx,0xb0c
    mov di,0x1d6e
    call blit_to_cga                           ;undefined blit_to_cga()
    mov si,0x6868
    mov cx,0x804
    mov di,0x1dec
    call blit_to_cga                           ;undefined blit_to_cga()
    mov word [0x6a8d],0x0
    call animate_title_icon                           ;undefined animate_title_icon()
    mov word [cat_x],0x0
    call setup_alley                           ;undefined setup_alley()
    mov byte [cat_y],0x60
    mov byte [cat_y_bottom],0x92
    call draw_score                           ;undefined draw_score()
    call draw_high_score                           ;undefined draw_high_score()
    mov byte [lives_count],0x9
    mov byte [lives_display],0xff
    call draw_lives                           ;undefined draw_lives()
    call init_sound                           ;undefined init_sound()
    mov byte [input_horizontal],0x0
    mov byte [input_vertical],0x0
    mov byte [0x6a8a],0x0
    mov ax,[keyboard_counter]
    mov [0x6150],ax
lab_5d54:
    db 0x2a, 0xe4                       ; sub ah,ah
    int 0x1a                            ; BIOS Timer: Get tick count → CX:DX
    mov word [0x6a8b],dx
    mov word [0x5322],dx
    mov word [0x6a93],dx
    sub dx,0x30
    mov word [0x6a88],dx
    mov word [0x5320],0x0
lab_5d71:
    db 0x2a, 0xe4                       ; sub ah,ah
    int 0x1a                            ; BIOS Timer: Get tick count → CX:DX
    db 0x8b, 0xc2                       ; mov ax,dx
    sub ax,word [0x6a93]
    db 0x3d, 0x24, 0x00                 ; cmp ax,0x24
    jc lab_5d89
    mov word [0x6a93],dx
    push dx
    call animate_title_icon                           ;undefined animate_title_icon()
    pop dx
lab_5d89:
    sub dx,word [0x6a8b]
    mov ax,[0x56da]
    cmp byte [0x41a],0x0
    jz lab_5da0
    db 0x05, 0x48, 0x00                 ; add ax,0x48
    db 0x3b, 0xd0                       ; cmp dx,ax
    jnc lab_5d54
    jmp short lab_5da7
lab_5da0:
    db 0x05, 0x06, 0x00                 ; add ax,0x6
    db 0x3b, 0xd0                       ; cmp dx,ax
    ja lab_5dd3
lab_5da7:
    call play_music_note                           ;undefined play_music_note()
    call move_title_cat                           ;undefined move_title_cat()
    cmp byte [use_joystick],0x0
    jz lab_5dca
    mov dx,0x201
    in al,dx                            ; Joystick: read button/axis status
    and al,0x10
    jz lab_5dc3
    mov byte [0x6a8a],0x1
    jmp short lab_5dca
lab_5dc3:
    cmp byte [0x6a8a],0x0
    jnz lab_5dd3
lab_5dca:
    mov ax,[0x6150]
    cmp ax,word [keyboard_counter]
    jz lab_5d71
lab_5dd3:
    ret

; --- move_title_cat ---
move_title_cat:
    cmp word [cat_x],0x20
    ja lab_5de2
    mov byte [input_horizontal],0x1
    jmp short lab_5e1c
lab_5de2:
    cmp word [cat_x],0x120
    jc lab_5df1
    mov byte [input_horizontal],0xff
    jmp short lab_5e1c
lab_5df1:
    db 0x2a, 0xe4                       ; sub ah,ah
    int 0x1a                            ; BIOS Timer: Get tick count → CX:DX
    db 0x8b, 0xc2                       ; mov ax,dx
    sub ax,word [0x6a88]
    db 0x3d, 0x12, 0x00                 ; cmp ax,0x12
    jc lab_5e1c
    mov word [0x6a88],dx
    call random                           ;undefined random()
    mov byte [input_horizontal],0x0
    cmp dl,0xa0
    ja lab_5e1c
    and dl,0x1
    jnz lab_5e18
    mov dl,0xff
lab_5e18:
    mov byte [input_horizontal],dl
lab_5e1c:
    call check_vsync                           ;undefined check_vsync()
    jz lab_5e2a
    mov word [scroll_speed],0x4
    call update_animation                           ;undefined update_animation()
lab_5e2a:
    ret

; --- print_string ---
print_string:
    lodsb
    cmp al,0x0
    jz lab_5e3a
    push si
    mov bl,0x2
    mov ah,0xe
    int 0x10                            ; BIOS Video: Teletype output (AL=char)
    pop si
    jmp short print_string
lab_5e3a:
    ret

; --- animate_title_icon ---
animate_title_icon:
    mov ax,0xb800
    mov es,ax
    add word [0x6a8d],0x2
    mov bx,word [0x6a8d]
    db 0x81, 0xe3, 0x02, 0x00           ; and bx,0x2
    mov si,word [bx + 0x6a8f]
    mov cx,0xc0a
    mov di,0x1d38
    call blit_to_cga                           ;undefined blit_to_cga()
    ret

; --- set_cursor ---
set_cursor:
    mov dl,0x0
    db 0x8a, 0xfa                       ; mov bh,dl
    mov ah,0x2
    int 0x10                            ; BIOS Video: Set cursor position (DH=row, DL=col)
    ret
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00

; --- show_pause_menu ---
show_pause_menu:
    call silence_speaker                           ;undefined silence_speaker()
    db 0x2a, 0xe4                       ; sub ah,ah
    int 0x1a                            ; BIOS Timer: Get tick count → CX:DX
    mov word [0x6dfc],dx
    mov word [0x6dfe],cx
    push ds
    push ds
    pop es
    mov ax,0xb800
    mov ds,ax
    mov si,0xdca
    mov di,0xe
    mov cx,0x1020
    call save_from_cga                           ;undefined save_from_cga()
    pop ds
    mov dx,0xb05
    mov bh,0x0
    mov ah,0x2
    int 0x10                            ; BIOS Video: Set cursor position (DH=row, DL=col)
    mov si,0x6d91
    cld
    call print_string                           ;undefined print_string()
    mov dx,0xc05
    mov bh,0x0
    mov ah,0x2
    int 0x10                            ; BIOS Video: Set cursor position (DH=row, DL=col)
    mov si,0x6db2
    cmp byte [use_joystick],0x0
    jz lab_5eba
    mov si,0x6dd3
lab_5eba:
    cld
    call print_string                           ;undefined print_string()
    call wait_for_input                           ;undefined wait_for_input()
    mov ax,0xb800
    mov es,ax
    mov si,0xe
    mov di,0xdca
    mov cx,0x1020
    call blit_to_cga                           ;undefined blit_to_cga()
    mov ah,0x1
    mov cx,word [0x6dfe]
    mov dx,word [0x6dfc]
    int 0x1a                            ; BIOS Timer: Set tick count from CX:DX
    mov ax,[keyboard_counter]
    mov [0x6e00],ax
    ret

; --- show_attract_mode ---
; Displays the attract/demo mode screens. Flow:
;   1. Wait for keypress or joystick to detect input device
;   2. Display difficulty selection (4 levels via keys 1-4 or joystick)
;   3. Show control instructions (keyboard or joystick, depending on selection)
;   4. Wait for final input before returning to title screen
; Sets [use_joystick] and [0x6DF8] (difficulty selection) as output.
show_attract_mode:
    call silence_speaker                           ;undefined silence_speaker()
lab_5ee8:
    call clear_cga                           ;undefined clear_cga()
    mov word [0x6d8f],0x0
    call display_text_line                           ;undefined display_text_line()
lab_5ef4:
    mov ax,[keyboard_counter]
lab_5ef7:
    cmp ax,word [keyboard_counter]
    jz lab_5ef7
    test byte [0x6c1],0x80
    jz lab_5f12
    test byte [0x6c2],0x80
    jnz lab_5ef4
    mov byte [use_joystick],0x0
    jmp short lab_5f1c
lab_5f12:
    call detect_joystick                           ;undefined detect_joystick()
    jc lab_5ee8
    mov byte [use_joystick],0x1
lab_5f1c:
    mov cx,0x5
lab_5f1f:
    push cx
    call display_text_line                           ;undefined display_text_line()
    pop cx
    loop lab_5f1f
lab_5f26:
    mov ax,[keyboard_counter]
lab_5f29:
    cmp ax,word [keyboard_counter]
    jz lab_5f29
    db 0x2b, 0xc0                       ; sub ax,ax
    test byte [0x6c3],0x80
    jz lab_5f50
    inc ax
    test byte [0x6c4],0x80
    jz lab_5f50
    inc ax
    test byte [0x6c5],0x80
    jz lab_5f50
    inc ax
    test byte [0x6c6],0x80
    jnz lab_5f26
lab_5f50:
    mov [0x6df8],ax
    mov cx,0x5
lab_5f56:
    push cx
    call display_text_line                           ;undefined display_text_line()
    pop cx
    loop lab_5f56
    cmp byte [use_joystick],0x0
    jz lab_5f7e
    mov word [0x6d8f],0x20
    call display_text_line                           ;undefined display_text_line()
    call display_text_line                           ;undefined display_text_line()
    mov word [0x6d8f],0x18
    call display_text_line                           ;undefined display_text_line()
    call display_text_line                           ;undefined display_text_line()
    jmp short lab_5f93
lab_5f7e:
    mov word [0x6d8f],0x1c
    call display_text_line                           ;undefined display_text_line()
    call display_text_line                           ;undefined display_text_line()
    mov word [0x6d8f],0x16
    call display_text_line                           ;undefined display_text_line()
lab_5f93:
    call wait_for_input                           ;undefined wait_for_input()
    ret

; --- wait_for_input ---
wait_for_input:
    cmp byte [use_joystick],0x0
    jz lab_5fa7
lab_5f9e:
    mov dx,0x201
    in al,dx                            ; Joystick: read button/axis status
    and al,0x10
    jnz lab_5f9e
    ret
lab_5fa7:
    mov ax,[keyboard_counter]
lab_5faa:
    cmp ax,word [keyboard_counter]
    jz lab_5faa
    ret

; --- display_text_line ---
display_text_line:
    mov bx,word [0x6d8f]
    mov dx,word [bx + 0x6d63]
    call set_cursor                           ;undefined set_cursor()
    mov bx,word [0x6d8f]
    add word [0x6d8f],0x2
    mov si,word [bx + 0x6d37]
    call print_string                           ;undefined print_string()
    ret

; --- clear_cga ---
clear_cga:
    cld
    mov ax,0xb800
    mov es,ax
    db 0x2b, 0xc0                       ; sub ax,ax
    db 0x8b, 0xf8                       ; mov di,ax
    mov cx,0xfa0
    rep stosw
    mov di,0x2000
    mov cx,0xfa0
    rep stosw
    ret

; --- detect_joystick ---
detect_joystick:
    int 0x11                            ; BIOS: Equipment list → AX (bits 4-5=video mode)
    test ax,0x1000
    jz lab_5ff6
    call test_joystick_axis                           ;undefined test_joystick_axis()
    jnc lab_600e
    call test_joystick_axis                           ;undefined test_joystick_axis()
    jnc lab_600e
lab_5ff6:
    mov word [0x6d8f],0x24
    mov cx,0x4
lab_5fff:
    call display_text_line                           ;undefined display_text_line()
    loop lab_5fff
    mov ax,[keyboard_counter]
lab_6007:
    cmp ax,word [keyboard_counter]
    jz lab_6007
    stc
lab_600e:
    ret

; --- test_joystick_axis ---
test_joystick_axis:
    mov dx,0x201
    out dx,al                           ; Joystick: trigger one-shot
    db 0x2a, 0xe4                       ; sub ah,ah
    int 0x1a                            ; BIOS Timer: Get tick count → CX:DX
    mov word [0x6dfa],dx
lab_601b:
    mov dx,0x201
    in al,dx                            ; Joystick: read button/axis status
    test al,0x3
    jnz lab_6025
    clc
    ret
lab_6025:
    db 0x2a, 0xe4                       ; sub ah,ah
    int 0x1a                            ; BIOS Timer: Get tick count → CX:DX
    sub dx,word [0x6dfa]
    cmp dx,0x12
    jc lab_601b
    stc
    ret
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; --- love_scene_outro ---
; Level 7 (love scene) exit animation. Clears a sprite buffer, then animates
; a descending wipe effect with sound (PIT channel 2 speaker tones).
; Draws the final love scene image at the bottom, plays a celebratory tone
; sequence, then silences the speaker and returns.
love_scene_outro:
    cld
    push ds
    pop es
    mov di,0xe
    mov cx,0x24
    db 0x2b, 0xc0                       ; sub ax,ax
    rep stosw
    mov word [0x6f24],0x25
    mov ax,0xb800
    mov es,ax
lab_6058:
    call check_vsync
    jz short lab_6058
    mov si,0xe
    mov di,[0x6f24]
    mov cx,0xc03
    call blit_to_cga
    add word [0x6f24],0x1e0
    mov si,0x6e10
    mov di,[0x6f24]
    mov cx,0xc03
    call blit_to_cga
lab_607d:
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    cmp dx,[0x6f26]
    jz short lab_607d
    mov [0x6f26],dx
    cmp byte [0x0],0x0
    jz short lab_60a7
    mov al,0xb6
    out byte 0x43,al
    mov ax,[0x6f24]
    db 0xd1, 0xe8                       ; shr ax,0x0
    out byte 0x42,al
    db 0x8a, 0xc4                       ; mov al,ah
    out byte 0x42,al
    in al,byte 0x61
    or al,0x3
    out byte 0x61,al
lab_60a7:
    cmp word [0x6f24],0x1a40
    jb short lab_6058
    mov si,0x6e58
    mov di,[0x6f24]
    mov cx,0x1106
    call blit_to_cga
lab_60bc:
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    cmp dx,[0x6f28]
    jz short lab_60bc
    mov [0x6f28],dx
    cmp byte [0x0],0x0
    jz short lab_60e6
    mov al,0xb6
    out byte 0x43,al
    mov ax,0xc00
    test dl,0x1
    jz short lab_60e0
    mov ax,0xb54
lab_60e0:
    out byte 0x42,al
    db 0x8a, 0xc4                       ; mov al,ah
    out byte 0x42,al
lab_60e6:
    sub dx,[0x6f26]
    cmp dx,0x12
    jb short lab_60bc
    call silence_speaker
    ret
    add [bx+si],al
    add [bx+si],al
    add [bx+si],al
    add [bx+si],al
    add [bx+si],al
    add [bx+si],al
    db 0x00
; --- reset_cupid ---
; Resets the level 7 flying enemy state. Clears the active flag so the next
; call to update_cupid can spawn a new enemy.
reset_cupid:
    mov byte [0x70f2],0x0
    ret
; --- update_cupid ---
; Per-frame update for the level 7 flying enemy (cupid arrows / hearts).
; Rate-limited to one update per BIOS tick. When no enemy is active,
; randomly spawns one from the left or right edge at a random height.
; Moves the enemy horizontally across the screen, checks collision with
; the cat (sets cat_died and triggers knockback on hit), and toggles
; window open/close state when the enemy passes over a window position.
update_cupid:
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    cmp dx,[0x70ee]
    jnz short lab_6111
    ret
lab_6111:
    mov [0x70ee],dx
    call check_cupid_collision
    jnb short lab_6129
    call restore_alley_buffer
    call erase_cupid
    call draw_alley_foreground
    mov byte [0x70f2],0x0
    ret
lab_6129:
    cmp byte [0x70f2],0x0
    jnz short lab_619e
lab_6130:
    call random
    db 0x8b, 0xda                       ; mov bx,dx
    db 0x81, 0xe3, 0x1f, 0x00           ; and bx,0x1f
    cmp bl,0x10
    jb short lab_6166
    sub bl,0x10
    cmp bl,0x9
    ja short lab_6130
    mov dl,0x1
    cmp bl,0x5
    jb short lab_614f
    mov dl,0xff
lab_614f:
    mov [0x70f6],dl
    mov byte [0x70f5],0x6
    db 0xd0, 0xe3                       ; shl bl,0x0
    mov ax,[bx+0x70b8]
    db 0x05, 0x04, 0x00                 ; add ax,0x4
    mov [0x70f3],ax
    jmp short lab_6188
lab_6166:
    mov ax,0xc
    mov dl,0x1
    test bl,0x8
    jz short lab_6175
    mov ax,0x120
    mov dl,0xff
lab_6175:
    mov [0x70f3],ax
    mov [0x70f6],dl
    and bl,0x7
    mov al,[bx+0x70b0]
    add al,0x8
    mov [0x70f5],al
lab_6188:
    mov byte [0x70f2],0x1
    mov byte [0x70f7],0x1
    mov word [0x70f0],0x0
    mov word [0x70ec],0xffff
lab_619e:
    cmp word [0x70f0],0xa0
    jnb short lab_61ab
    add word [0x70f0],0x4
lab_61ab:
    add byte [0x70f5],0x2
    cmp byte [0x70f5],0xbf
    ja short lab_61d4
    cmp byte [0x70f6],0x1
    jz short lab_61c7
    sub word [0x70f3],0x5
    jb short lab_61d4
    jmp short lab_61dd
lab_61c7:
    add word [0x70f3],0x5
    cmp word [0x70f3],0x12c
    jb short lab_61dd
lab_61d4:
    mov byte [0x70f2],0x0
    call erase_cupid
    ret
lab_61dd:
    mov cx,[0x70f3]
    mov dl,[0x70f5]
    call calc_cga_addr
    mov [0x70fa],ax
    call check_cupid_collision
    jb short lab_61d4
    call cupid_toggle_window
    call erase_cupid
    call draw_cupid
    ret
draw_cupid:
    mov ax,0xb800
    mov es,ax
    mov byte [0x70f7],0x0
    mov ax,[0x70f0]
    and ax,0x1e0
    add ax,0x6f30
    cmp byte [0x70f6],0xff
    jz short lab_6217
    add ax,0xc0
lab_6217:
    db 0x8b, 0xf0                       ; mov si,ax
    mov di,[0x70fa]
    mov [0x70f8],di
    mov bp,0x70cc
    mov cx,0x802
    call blit_transparent
    ret
erase_cupid:
    cmp byte [0x70f7],0x0
    jnz short lab_6244
    mov ax,0xb800
    mov es,ax
    mov si,0x70cc
    mov di,[0x70f8]
    mov cx,0x802
    call blit_to_cga
lab_6244:
    ret
cupid_toggle_window:
    mov al,[0x70f5]
    sub al,0x8
    and al,0xf8
    mov cx,0x7
lab_624f:
    db 0x8b, 0xd9                       ; mov bx,cx
    dec bx
    cmp al,[bx+0x2bd4]
    jz short lab_625b
    loop short lab_624f
lab_625a:
    ret
lab_625b:
    mov ax,[0x70f3]
    mov cl,0x4
    shr ax,cl
    db 0x2d, 0x02, 0x00                 ; sub ax,0x2
    jb short lab_625a
    db 0x3d, 0x10, 0x00                 ; cmp ax,0x10
    jnb short lab_625a
    db 0x8b, 0xf8                       ; mov di,ax
    mov dl,[bx+0x2bdb]
    db 0x2a, 0xf6                       ; sub dh,dh
    db 0x03, 0xc2                       ; add ax,dx
    cmp ax,[0x70ec]
    jz short lab_625a
    mov [0x70ec],ax
    db 0x8b, 0xf0                       ; mov si,ax
    xor byte [si+0x2be2],0x2
    mov al,[si+0x2be2]
    db 0x2a, 0xe4                       ; sub ah,ah
    db 0xd1, 0xe7                       ; shl di,0x0
    mov cx,[di+0x70fc]
    mov dl,[bx+0x7120]
    push ax
    push cx
    push dx
    call erase_cupid
    pop dx
    pop cx
    pop bx
    call draw_bg_tile
    call draw_cupid
    ret
check_cupid_collision:
    cmp byte [0x70f2],0x0
    jnz short lab_62af
    clc
    ret
lab_62af:
    mov ax,[0x70f3]
    mov dl,[0x70f5]
    mov si,0x10
    mov bx,[0x579]
    mov dh,[0x57b]
    mov di,0x18
    mov cx,0xe08
    call check_rect_collision
    jnb short lab_62ea
    mov byte [0x571],0x1
    mov byte [0x576],0x2
    mov byte [0x578],0x20
    mov byte [0x55b],0x8
    mov ax,0x91d
    mov bx,0xce4
    call start_tone
    stc
lab_62ea:
    ret

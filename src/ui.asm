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
    mov si,dat_60f0
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
    mov si,dat_6112
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
    mov si,dat_6152
    mov cx,0x1d0b
    mov di,0xbd
    call blit_to_cga                           ;undefined blit_to_cga()
    mov si,dat_63d0
    mov cx,0x160e
    mov di,0x69e
    call blit_to_cga                           ;undefined blit_to_cga()
    mov si,dat_6638
    mov cx,0xc03
    mov di,0xa78
    call blit_to_cga                           ;undefined blit_to_cga()
    mov si,dat_6680
    mov cx,0x80e
    mov di,0xca8
    call blit_to_cga                           ;undefined blit_to_cga()
    mov si,dat_6760
    mov cx,0xb0c
    mov di,dat_1d6e
    call blit_to_cga                           ;undefined blit_to_cga()
    mov si,dat_6868
    mov cx,0x804
    mov di,dat_1dec
    call blit_to_cga                           ;undefined blit_to_cga()
    mov word [attract_anim_idx],0x0
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
    mov byte [attract_key_pressed],0x0
    mov ax,[keyboard_counter]
    mov [attract_save_int],ax
lab_5d54:
    db 0x2a, 0xe4                       ; sub ah,ah
    int 0x1a                            ; BIOS Timer: Get tick count → CX:DX
    mov word [attract_last_tick],dx
    mov word [title_music_tick],dx
    mov word [attract_frame_tick],dx
    sub dx,0x30
    mov word [attract_start_tick],dx
    mov word [title_music_pos],0x0
lab_5d71:
    db 0x2a, 0xe4                       ; sub ah,ah
    int 0x1a                            ; BIOS Timer: Get tick count → CX:DX
    db 0x8b, 0xc2                       ; mov ax,dx
    sub ax,word [attract_frame_tick]
    db 0x3d, 0x24, 0x00                 ; cmp ax,0x24
    jc lab_5d89
    mov word [attract_frame_tick],dx
    push dx
    call animate_title_icon                           ;undefined animate_title_icon()
    pop dx
lab_5d89:
    sub dx,word [attract_last_tick]
    mov ax,[attract_timing]
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
    mov byte [attract_key_pressed],0x1
    jmp short lab_5dca
lab_5dc3:
    cmp byte [attract_key_pressed],0x0
    jnz lab_5dd3
lab_5dca:
    mov ax,[attract_save_int]
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
    sub ax,word [attract_start_tick]
    db 0x3d, 0x12, 0x00                 ; cmp ax,0x12
    jc lab_5e1c
    mov word [attract_start_tick],dx
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
    add word [attract_anim_idx],0x2
    mov bx,word [attract_anim_idx]
    db 0x81, 0xe3, 0x02, 0x00           ; and bx,0x2
    mov si,word [bx + attract_icon_ptrs]
    mov cx,0xc0a
    mov di,dat_1d38
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
    mov word [title_saved_cx],dx
    mov word [title_saved_dx],cx
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
    mov si,dat_6d91
    cld
    call print_string                           ;undefined print_string()
    mov dx,0xc05
    mov bh,0x0
    mov ah,0x2
    int 0x10                            ; BIOS Video: Set cursor position (DH=row, DL=col)
    mov si,dat_6db2
    cmp byte [use_joystick],0x0
    jz lab_5eba
    mov si,dat_6dd3
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
    mov cx,word [title_saved_dx]
    mov dx,word [title_saved_cx]
    int 0x1a                            ; BIOS Timer: Set tick count from CX:DX
    mov ax,[keyboard_counter]
    mov [pause_counter],ax
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
    mov word [title_joy_offset],0x0
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
    mov [difficulty_counter],ax
    mov cx,0x5
lab_5f56:
    push cx
    call display_text_line                           ;undefined display_text_line()
    pop cx
    loop lab_5f56
    cmp byte [use_joystick],0x0
    jz lab_5f7e
    mov word [title_joy_offset],0x20
    call display_text_line                           ;undefined display_text_line()
    call display_text_line                           ;undefined display_text_line()
    mov word [title_joy_offset],0x18
    call display_text_line                           ;undefined display_text_line()
    call display_text_line                           ;undefined display_text_line()
    jmp short lab_5f93
lab_5f7e:
    mov word [title_joy_offset],0x1c
    call display_text_line                           ;undefined display_text_line()
    call display_text_line                           ;undefined display_text_line()
    mov word [title_joy_offset],0x16
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
    mov bx,word [title_joy_offset]
    mov dx,word [bx + attract_icon_sprite_b]
    call set_cursor                           ;undefined set_cursor()
    mov bx,word [title_joy_offset]
    add word [title_joy_offset],0x2
    mov si,word [bx + attract_icon_sprite_a]
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
    mov di,cga_bank1_base
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
    mov word [title_joy_offset],0x24
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
    mov word [title_input_tick],dx
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
    sub dx,word [title_input_tick]
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
    mov word [title_scroll_pos],0x25
    mov ax,0xb800
    mov es,ax
lab_6058:
    call check_vsync
    jz short lab_6058
    mov si,0xe
    mov di,[title_scroll_pos]
    mov cx,0xc03
    call blit_to_cga
    add word [title_scroll_pos],0x1e0
    mov si,dat_6e10
    mov di,[title_scroll_pos]
    mov cx,0xc03
    call blit_to_cga
lab_607d:
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    cmp dx,[title_scroll_tick_1]
    jz short lab_607d
    mov [title_scroll_tick_1],dx
    cmp byte [0x0],0x0
    jz short lab_60a7
    mov al,0xb6
    out byte 0x43,al
    mov ax,[title_scroll_pos]
    db 0xd1, 0xe8                       ; shr ax,0x0
    out byte 0x42,al
    db 0x8a, 0xc4                       ; mov al,ah
    out byte 0x42,al
    in al,byte 0x61
    or al,0x3
    out byte 0x61,al
lab_60a7:
    cmp word [title_scroll_pos],0x1a40
    jb short lab_6058
    mov si,dat_6e58
    mov di,[title_scroll_pos]
    mov cx,0x1106
    call blit_to_cga
lab_60bc:
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    cmp dx,[title_scroll_tick_2]
    jz short lab_60bc
    mov [title_scroll_tick_2],dx
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
    sub dx,[title_scroll_tick_1]
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
    mov byte [cupid_active],0x0
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
    cmp dx,[cupid_anim_tick]
    jnz short lab_6111
    ret
lab_6111:
    mov [cupid_anim_tick],dx
    call check_cupid_collision
    jnb short lab_6129
    call restore_alley_buffer
    call erase_cupid
    call draw_alley_foreground
    mov byte [cupid_active],0x0
    ret
lab_6129:
    cmp byte [cupid_active],0x0
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
    mov [cupid_dir],dl
    mov byte [cupid_y],0x6
    db 0xd0, 0xe3                       ; shl bl,0x0
    mov ax,[bx+dat_70b8]
    db 0x05, 0x04, 0x00                 ; add ax,0x4
    mov [cupid_x],ax
    jmp short lab_6188
lab_6166:
    mov ax,0xc
    mov dl,0x1
    test bl,0x8
    jz short lab_6175
    mov ax,0x120
    mov dl,0xff
lab_6175:
    mov [cupid_x],ax
    mov [cupid_dir],dl
    and bl,0x7
    mov al,[bx+dat_70b0]
    add al,0x8
    mov [cupid_y],al
lab_6188:
    mov byte [cupid_active],0x1
    mov byte [cupid_drawn],0x1
    mov word [cupid_arrow_x],0x0
    mov word [cupid_prev_x],0xffff
lab_619e:
    cmp word [cupid_arrow_x],0xa0
    jnb short lab_61ab
    add word [cupid_arrow_x],0x4
lab_61ab:
    add byte [cupid_y],0x2
    cmp byte [cupid_y],0xbf
    ja short lab_61d4
    cmp byte [cupid_dir],0x1
    jz short lab_61c7
    sub word [cupid_x],0x5
    jb short lab_61d4
    jmp short lab_61dd
lab_61c7:
    add word [cupid_x],0x5
    cmp word [cupid_x],0x12c
    jb short lab_61dd
lab_61d4:
    mov byte [cupid_active],0x0
    call erase_cupid
    ret
lab_61dd:
    mov cx,[cupid_x]
    mov dl,[cupid_y]
    call calc_cga_addr
    mov [cupid_draw_addr],ax
    call check_cupid_collision
    jb short lab_61d4
    call cupid_toggle_window
    call erase_cupid
    call draw_cupid
    ret
draw_cupid:
    mov ax,0xb800
    mov es,ax
    mov byte [cupid_drawn],0x0
    mov ax,[cupid_arrow_x]
    and ax,0x1e0
    add ax,dat_6f30
    cmp byte [cupid_dir],0xff
    jz short lab_6217
    add ax,0xc0
lab_6217:
    db 0x8b, 0xf0                       ; mov si,ax
    mov di,[cupid_draw_addr]
    mov [cupid_erase_addr],di
    mov bp,dat_70cc
    mov cx,0x802
    call blit_transparent
    ret
erase_cupid:
    cmp byte [cupid_drawn],0x0
    jnz short lab_6244
    mov ax,0xb800
    mov es,ax
    mov si,dat_70cc
    mov di,[cupid_erase_addr]
    mov cx,0x802
    call blit_to_cga
lab_6244:
    ret
cupid_toggle_window:
    mov al,[cupid_y]
    sub al,0x8
    and al,0xf8
    mov cx,0x7
lab_624f:
    db 0x8b, 0xd9                       ; mov bx,cx
    dec bx
    cmp al,[bx+window_row_y_table]
    jz short lab_625b
    loop short lab_624f
lab_625a:
    ret
lab_625b:
    mov ax,[cupid_x]
    mov cl,0x4
    shr ax,cl
    db 0x2d, 0x02, 0x00                 ; sub ax,0x2
    jb short lab_625a
    db 0x3d, 0x10, 0x00                 ; cmp ax,0x10
    jnb short lab_625a
    db 0x8b, 0xf8                       ; mov di,ax
    mov dl,[bx+window_row_col_offset]
    db 0x2a, 0xf6                       ; sub dh,dh
    db 0x03, 0xc2                       ; add ax,dx
    cmp ax,[cupid_prev_x]
    jz short lab_625a
    mov [cupid_prev_x],ax
    db 0x8b, 0xf0                       ; mov si,ax
    xor byte [si+window_open_state],0x2
    mov al,[si+window_open_state]
    db 0x2a, 0xe4                       ; sub ah,ah
    db 0xd1, 0xe7                       ; shl di,0x0
    mov cx,[di+cupid_sprite_offset]
    mov dl,[bx+cupid_sprite_end]
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
    cmp byte [cupid_active],0x0
    jnz short lab_62af
    clc
    ret
lab_62af:
    mov ax,[cupid_x]
    mov dl,[cupid_y]
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

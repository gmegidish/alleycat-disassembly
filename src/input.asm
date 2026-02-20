; --- poll_joystick ---
; Reads the joystick position if [use_joystick] is set. Rate-limited to
; every 2 BIOS ticks. Translates joystick axes to input_horizontal/vertical.
poll_joystick:
    db 0x2a, 0xe4                       ; sub ah,ah
    int 0x1a                            ; BIOS Timer: Get tick count → CX:DX
    db 0x8b, 0xc2                       ; mov ax,dx
    sub ax,word [joy_last_tick]
    db 0x3d, 0x02, 0x00                 ; cmp ax,0x2
    jnc lab_1210
    ret
lab_1210:
    mov word [joy_last_tick],dx
    cmp byte [use_joystick],0x0
    jnz lab_122e
    call read_keyboard_dirs                           ;undefined read_keyboard_dirs()
    call read_pit_timer                           ;undefined read_pit_timer()
    db 0x8b, 0xd0                       ; mov dx,ax
lab_1223:
    call read_pit_timer                           ;undefined read_pit_timer()
    db 0x2b, 0xc2                       ; sub ax,dx
    cmp ax,0xf8ed
    jc lab_1223
    ret
lab_122e:
    mov dx,0x201
    in al,dx                            ; Joystick: read button/axis status
    and al,0x10
    mov [joy_button],al
    mov byte [joy_pending],0x3
    call read_pit_timer                           ;undefined read_pit_timer()
    mov [joy_timer],ax
    out dx,al                           ; Write to port [DX]
    mov cx,0x7d0
lab_1246:
    in al,dx                            ; Read from port [DX]
    test al,0x1
    jnz lab_125e
    test byte [joy_pending],0x1
    jz lab_125e
    and byte [joy_pending],0xfe
    call decode_joystick_axis                           ;undefined decode_joystick_axis()
    mov byte [input_horizontal],bl
lab_125e:
    test al,0x2
    jnz lab_1275
    test byte [joy_pending],0x2
    jz lab_1275
    and byte [joy_pending],0xfd
    call decode_joystick_axis                           ;undefined decode_joystick_axis()
    mov byte [input_vertical],bl
lab_1275:
    test byte [joy_pending],0x3
    jz lab_12a0
    call read_pit_timer                           ;undefined read_pit_timer()
    sub ax,word [joy_timer]
    cmp ax,0x1964
    loopnz lab_1246
    test byte [joy_pending],0x1
    jz lab_1294
    mov byte [input_horizontal],0xff
lab_1294:
    test byte [joy_pending],0x2
    jz lab_12a0
    mov byte [input_vertical],0xff
lab_12a0:
    ret

; --- decode_joystick_axis ---
decode_joystick_axis:
    push ax
    call read_pit_timer                           ;undefined read_pit_timer()
    sub ax,word [joy_timer]
    db 0x8b, 0xd8                       ; mov bx,ax
    pop ax
    cmp bx,0xf5e6
    jnc lab_12b5
    mov bl,0x1
    ret
lab_12b5:
    cmp bx,0xfafa
    jnc lab_12be
    db 0x2a, 0xdb                       ; sub bl,bl
    ret
lab_12be:
    mov bl,0xff
    ret

; --- read_keyboard_dirs ---
read_keyboard_dirs:
    mov al,[key_down]
    cmp byte [rom_id],0xfd
    jz lab_12d3
    and al,byte [key_mod2]
    and al,byte [key_mod3]
lab_12d3:
    xor al,0x80
    jz lab_12d9
    mov al,0x1
lab_12d9:
    mov [input_vertical],al
    mov al,[key_up]
    cmp byte [rom_id],0xfd
    jz lab_12ee
    and al,byte [key_mod1]
    and al,byte [key_mod4]
lab_12ee:
    xor al,0x80
    jz lab_12f7
    mov byte [input_vertical],0xff
lab_12f7:
    mov al,[key_right]
    cmp byte [rom_id],0xfd
    jz lab_1309
    and al,byte [key_mod1]
    and al,byte [key_mod2]
lab_1309:
    xor al,0x80
    jz lab_130f
    mov al,0x1
lab_130f:
    mov [input_horizontal],al
    mov al,[key_left]
    cmp byte [rom_id],0xfd
    jz lab_1324
    and al,byte [key_mod3]
    and al,byte [key_mod4]
lab_1324:
    xor al,0x80
    jz lab_132d
    mov byte [input_horizontal],0xff
lab_132d:
    mov al,[key_fire]
    mov cl,0x3
    shr al,cl
    mov [joy_button],al
    ret

; --- process_keyboard ---
; Scans the keyboard buffer and translates key presses into game actions.
; Sets input_horizontal/input_vertical for movement, handles pause (via
; show_pause_menu), sound toggle, restart_game, and show_attract flags.
process_keyboard:
    mov ax,[keyboard_counter]
    cmp ax,word [keyboard_prev]
    jz lab_1357
    mov [keyboard_prev],ax
    test byte [key_ctrl],0x80
    jnz lab_1358
    mov ax,[keyboard_counter]
    cmp ax,word [pause_counter]
    jz lab_1357
    call show_pause_menu                           ;undefined show_pause_menu()
lab_1357:
    ret
lab_1358:
    test byte [key_pause],0x80
    jz lab_1360
    ret
lab_1360:
    test byte [key_cheat],0x80
    jnz lab_136d
    mov byte [lives_count],0x9
    ret
lab_136d:
    test byte [key_fn],0x80
    jz lab_13a5
    test byte [key_demo],0x80
    jnz lab_1381
    mov byte [show_attract],0xff
    ret
lab_1381:
    test byte [key_restart],0x80
    jnz lab_138e
    mov byte [restart_game],0xff
    ret
lab_138e:
    test byte [key_sound],0x80
    jnz lab_13a4
    not byte [sound_enabled]
    cmp byte [sound_enabled],0x0
    jnz lab_13a3
    call silence_speaker                           ;undefined silence_speaker()
lab_13a3:
    ret
lab_13a4:
    ret
lab_13a5:
    call restore_handlers                           ;undefined restore_handlers()
    pop ax
    retf


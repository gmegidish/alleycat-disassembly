; --- play_music_note ---
play_music_note:
    cmp byte [sound_enabled],0x0
    jz lab_53f5
    db 0x2a, 0xe4                       ; sub ah,ah
    int 0x1a                            ; BIOS Timer: Get tick count → CX:DX
    cmp dx,word [0x5322]
    jz lab_53f5
    mov word [0x5322],dx
    mov bx,word [0x5320]
    mov bl,byte [bx + 0x538c]
    cmp bl,0x66
    jz lab_53dd
    db 0x2a, 0xff                       ; sub bh,bh
    inc word [0x5320]
    cmp bx,0x0
    jnz lab_53e1
lab_53dd:
    call silence_speaker                           ;undefined silence_speaker()
    ret
lab_53e1:
    mov al,0xb6
    out 0x43,al                         ; PIT: control word (Ch2 square wave (speaker))
    mov ax,word [bx + 0x5324]
    out 0x42,al                         ; PIT Ch2: speaker frequency data
    db 0x8a, 0xc4                       ; mov al,ah
    out 0x42,al                         ; PIT Ch2: speaker frequency data
    in al,0x61                          ; Read speaker/system status
    or al,0x3
    out 0x61,al                         ; Speaker control (bits 0-1: gate/enable)
lab_53f5:
    ret
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00

; --- render_sprites ---
; Draws decorative foreground sprites (clotheslines, trash cans, etc.) into
; the alley scene. Iterates through a position list indexed by difficulty level,
; picking random sprite variants from the sprite table. Blits each sprite
; to CGA video memory at the coordinates specified in the list.
render_sprites:
    mov ax,0xb800
    mov es,ax
    mov bx,word [difficulty_level]
    db 0x81, 0xe3, 0x07, 0x00           ; and bx,0x7
    shl bx,0x1
    db 0x8b, 0xc3                       ; mov ax,bx
    mov bx,word [bx + 0x5908]
    mov cl,0x3
    shl ax,cl
    mov [0x5918],ax
lab_541c:
    mov di,word [bx]
    db 0x81, 0xff, 0xff, 0xff           ; cmp di,0xffff
    jz lab_5447
    call random                           ;undefined random()
    db 0x81, 0xe2, 0x0e, 0x00           ; and dx,0xe
    add dx,word [0x5918]
    db 0x8b, 0xf2                       ; mov si,dx
    mov si,word [si + 0x5888]
    mov cx,word [si + 0x5858]
    mov si,word [si + 0x584c]
    push bx
    call blit_to_cga                           ;undefined blit_to_cga()
    pop bx
    add bx,0x2
    jmp short lab_541c
lab_5447:
    ret
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00

; --- init_chase_sound ---
init_chase_sound:
    mov byte [0x5b0f],0xc
    mov word [0x5b0c],0x1
    mov word [0x5b12],0x1ff
    mov word [0x5b0a],0xf
    mov byte [0x5b0e],0x1
    ret

; --- play_sound ---
; Main sound tick handler. Called once per frame. Processes the active sound
; effect or music note, driving the PC speaker via PIT channel 2.
; Checks [sound_enabled]; does nothing if sound is off.
play_sound:
    cmp byte [sound_enabled],0x0
    jz lab_54a5
    cmp byte [enemy_active],0x0
    jz lab_54f8
    db 0x2a, 0xe4                       ; sub ah,ah
    int 0x1a                            ; BIOS Timer: Get tick count → CX:DX
    cmp byte [0x5b0f],0x0
    jnz lab_54a6
    cmp dx,word [0x5b10]
    jz lab_54a5
    mov word [0x5b10],dx
    mov al,0xb6
    out 0x43,al                         ; PIT: control word (Ch2 square wave (speaker))
    mov ax,[0x5b12]
    and ax,0x1ff
    add ax,0xc8
    call set_speaker_freq                           ;undefined set_speaker_freq()
    sub word [0x5b12],0x4b
lab_54a5:
    ret
lab_54a6:
    cmp dx,word [0x5b10]
    jz lab_54b4
    mov word [0x5b10],dx
    dec byte [0x5b0f]
lab_54b4:
    dec byte [0x5b0e]
    jnz lab_54f7
    mov al,0x1
    cmp byte [rom_id],0xfd
    jz lab_54c5
    shl al,0x1
lab_54c5:
    mov [0x5b0e],al
    call random                           ;undefined random()
    cmp dl,0x4
    ja lab_54d4
    inc word [0x5b0c]
lab_54d4:
    test word [0x5b0c],0x1
    jz lab_54e1
    add word [0x5b0a],0x7
lab_54e1:
    mov al,0xb6
    out 0x43,al                         ; PIT: control word (Ch2 square wave (speaker))
    call random                           ;undefined random()
    db 0x8b, 0xc2                       ; mov ax,dx
    and ax,word [0x5b0a]
    and ax,0x1ff
    add ax,0x190
    call set_speaker_freq                           ;undefined set_speaker_freq()
lab_54f7:
    ret
lab_54f8:
    db 0x2a, 0xe4                       ; sub ah,ah
    int 0x1a                            ; BIOS Timer: Get tick count → CX:DX
    cmp byte [0x5920],0x0
    jz lab_5522
    cmp dx,word [0x5921]
    jz lab_5562
    mov word [0x5921],dx
    dec byte [0x5920]
    jz lab_551e
    mov al,0xb6
    out 0x43,al                         ; PIT: control word (Ch2 square wave (speaker))
    mov ax,[0x5923]
    call set_speaker_freq                           ;undefined set_speaker_freq()
    ret
lab_551e:
    call silence_speaker                           ;undefined silence_speaker()
    ret
lab_5522:
    cmp dx,word [0x5925]
    jz lab_5562
    mov si,0x3
    mov al,[enemy_chasing]
    or al,byte [0x5b07]
    jnz lab_5549
    mov si,0x1
    cmp word [level_number],0x0
    jnz lab_5549
    dec si
    cmp byte [gravity_y],0x0
    jz lab_5549
    mov si,0x2
lab_5549:
    db 0x8b, 0xfe                       ; mov di,si
    shl di,0x1
    mov al,[0x584]
    or al,byte [0x5b07]
    jnz lab_5563
    db 0x8b, 0xc2                       ; mov ax,dx
    sub ax,word [0x5925]
    cmp ax,word [di + 0x59f2]
    jnc lab_5563
lab_5562:
    ret
lab_5563:
    mov word [0x5925],dx
    cmp byte [enemy_chasing],0x0
    jnz lab_5579
    cmp byte [0x5b07],0x0
    jz lab_559e
    dec byte [0x5b07]
lab_5579:
    mov word [0x592e],0x1200
    mov bx,word [0x59ba]
    cmp bx,0x6
    jc lab_558e
    db 0x2b, 0xdb                       ; sub bx,bx
    mov word [0x59ba],bx
lab_558e:
    add word [0x59ba],0x2
    mov ax,word [bx + 0x5a44]
    mov [0x592a],ax
    call play_timed_tone                           ;undefined play_timed_tone()
    ret
lab_559e:
    cmp si,0x2
    jnz lab_55bb
    mov al,[gravity_y]
    db 0x2a, 0xe4                       ; sub ah,ah
    mov cl,0x4
    shl ax,cl
    add ax,0x200
    mov [0x592a],ax
    mov word [0x592e],0x1800
    jmp near lab_568d
lab_55bb:
    mov ax,word [di + 0x5a02]
    mov [0x592e],ax
    shr byte [0x5927],0x1
    jnc lab_5623
    mov word [0x592e],0x1000
    mov byte [0x5927],0x80
    inc byte [0x5928]
    mov al,[0x5928]
    and al,byte [si + 0x59fa]
    jnz lab_5616
    mov dl,byte [si + 0x5a0a]
    add byte [0x5929],dl
    call random                           ;undefined random()
    cmp dl,byte [si + 0x5a0c]
    ja lab_55f8
    and dl,0x7
    mov byte [0x592d],dl
lab_55f8:
    call random                           ;undefined random()
    and dx,0xff
    shl dx,0x1
    mov cl,0x1
    test dl,0x2
    jz lab_560e
    mov cl,0xff
    add dx,0x300
lab_560e:
    mov word [0x592a],dx
    mov byte [0x592c],cl
lab_5616:
    mov ah,byte [0x5929]
    and ah,byte [si + 0x59fc]
    db 0x0a, 0xc4                       ; or al,ah
    mov [0x5928],al
lab_5623:
    cmp byte [0x592c],0xff
    jz lab_5640
    add word [0x5a54],0x2
    mov bx,word [0x5a54]
    db 0x81, 0xe3, 0x0e, 0x00           ; and bx,0xe
    mov ax,word [bx + 0x5a44]
    mov [0x592a],ax
    jmp short lab_5653
lab_5640:
    cmp word [0x592a],0xc8
    ja lab_564e
    mov word [0x592a],0x500
lab_564e:
    sub word [0x592a],0x19
lab_5653:
    cmp byte [0x584],0x0
    jz lab_5667
    mov word [0x592e],0x2000
    mov byte [0x592c],0xff
    jnz lab_568d
lab_5667:
    mov bl,byte [0x5928]
    db 0x2a, 0xff                       ; sub bh,bh
    add bx,word [di + 0x59fe]
    mov al,byte [bx + 0x59c2]
    and al,byte [0x5927]
    jnz lab_568d
    cmp byte [0x592d],0x0
    jz lab_5690
    dec byte [0x592d]
    mov ax,word [di + 0x5a06]
    mov [0x592e],ax
lab_568d:
    call play_timed_tone                           ;undefined play_timed_tone()
lab_5690:
    ret
play_explosion_effect:
    call silence_speaker
    mov ah,0xb
    mov bx,0x4
    int byte 0x10
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    mov [0x5ae2],dx
    mov word [0x5ae4],0x0
    mov al,0x2
    cmp byte [0x697],0xfd
    jnz short lab_56b4
    db 0xd0, 0xe8                       ; shr al,0x0
lab_56b4:
    mov [0x5b06],al
lab_56b7:
    cmp byte [0x0],0x0
    jz short lab_56d8
    inc word [0x5ae4]
    mov bx,[0x5ae4]
    mov cl,[0x5b06]
    shr bx,cl
    db 0x81, 0xe3, 0x1f, 0x00           ; and bx,0x1f
    in al,byte 0x61
    xor al,[bx+0x5ae6]
    out byte 0x61,al
lab_56d8:
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    sub dx,[0x5ae2]
    cmp dx,0x2
    jb short lab_56b7
    mov ah,0xb
    db 0x2b, 0xdb                       ; sub bx,bx
    int byte 0x10
    mov byte [0x5b07],0xc
    call silence_speaker
    ret
init_buzz_sound:
    mov ax,0x200
    cmp byte [0x697],0xfd
    jnz short lab_5700
    db 0xd1, 0xe0                       ; shl ax,0x0
lab_5700:
    mov [0x5ad0],ax
    ret
update_buzz_sound:
    inc word [0x5ad0]
    mov bx,[0x5ad0]
    db 0x8b, 0xd3                       ; mov dx,bx
    mov cl,0x9
    shr dx,cl
    db 0x8a, 0xca                       ; mov cl,dl
    and cl,0xf
    shr bx,cl
    db 0x81, 0xe3, 0x0f, 0x00           ; and bx,0xf
    mov dl,[bx+0x5ad2]
    and dl,[0x0]
    in al,byte 0x61
    and al,0xfc
    db 0x0a, 0xc2                       ; or al,dl
    out byte 0x61,al
    ret
play_swoop_sound:
    mov word [0x5acb],0x1f4
lab_5734:
    call play_delayed_tone
    sub word [0x5acb],0x1e
    cmp word [0x5acb],0xc8
    ja short lab_5734
    mov word [0x5acb],0x1f4
lab_574a:
    call play_delayed_tone
    sub word [0x5acb],0x14
    cmp word [0x5acb],0x12c
    ja short lab_574a
lab_575a:
    call play_delayed_tone
    add word [0x5acb],0x1e
    cmp word [0x5acb],0x320
    jb short lab_575a
    call silence_speaker
    ret
play_delayed_tone:
    mov cx,0x1000
    cmp byte [0x697],0xfd
    jnz short lab_577a
    db 0xd1, 0xe9                       ; shr cx,0x0
lab_577a:
    loop short lab_577a
    cmp byte [0x0],0x0
    jz short lab_5796
    mov al,0xb6
    out byte 0x43,al
    mov ax,[0x5acb]
    out byte 0x42,al
    db 0x8a, 0xc4                       ; mov al,ah
    out byte 0x42,al
    in al,byte 0x61
    or al,0x3
    out byte 0x61,al
lab_5796:
    ret

; --- reset_noise ---
reset_noise:
    call silence_speaker                           ;undefined silence_speaker()
    mov byte [0x5acf],0x0
    mov word [0x5acd],0x8
    ret

; --- update_noise ---
update_noise:
    inc byte [0x5acf]
    db 0x2a, 0xd2                       ; sub dl,dl
    mov al,[0x5acf]
    and al,0x3f
    jnz lab_57b7
    inc word [0x5acd]
lab_57b7:
    mov bx,word [0x5acd]
    mov cl,0x2
    shr bx,cl
    and bl,0x1f
    db 0x3a, 0xc3                       ; cmp al,bl
    jc lab_57c8
    mov dl,0x2
lab_57c8:
    and dl,byte [sound_enabled]
    in al,0x61                          ; Read speaker/system status
    and al,0xfd
    db 0x0a, 0xc2                       ; or al,dl
    out 0x61,al                         ; Speaker control (bits 0-1: gate/enable)
    ret
init_result_melody:
    mov word [0x5a85],0x0
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    mov [0x5a83],dx
    ret
play_result_note:
    cmp byte [0x0],0x0
    jz short lab_5828
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    db 0x8b, 0xc2                       ; mov ax,dx
    sub ax,[0x5a83]
    db 0x3d, 0x02, 0x00                 ; cmp ax,0x2
    jb short lab_5828
    mov [0x5a83],dx
    mov bx,[0x5a85]
    add word [0x5a85],0x2
    cmp byte [0x552],0x0
    jz short lab_581b
    mov ax,[bx+0x5aa3]
    db 0x3d, 0x00, 0x00                 ; cmp ax,0x0
    jnz short lab_581f
    call silence_speaker
    ret
lab_581b:
    mov ax,[bx+0x5a87]
lab_581f:
    push ax
    mov al,0xb6
    out byte 0x43,al
    pop ax
    call set_speaker_freq
lab_5828:
    ret
init_level_melody:
    mov word [0x5a62],0x0
    mov byte [0x5a82],0x0
    ret
play_level_note:
    cmp byte [0x0],0x0
    jz short lab_5846
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    cmp dx,[0x5a80]
    jnz short lab_5847
lab_5846:
    ret
lab_5847:
    mov [0x5a80],dx
    inc byte [0x5a82]
    mov al,0xb6
    out byte 0x43,al
    mov bx,[0x5a62]
    test byte [0x5a82],0x1
    jnz short lab_5861
    add bx,0x2
lab_5861:
    mov ax,[bx+0x5a64]
    call set_speaker_freq
    ret
play_melody_step:
    cmp byte [0x0],0x0
    jz short lab_5888
    push bx
    push ax
    mov al,0xb6
    out byte 0x43,al
    mov bx,[0x5a62]
    add word [0x5a62],0x2
    mov ax,[bx+0x5a64]
    call set_speaker_freq
    pop ax
    pop bx
lab_5888:
    ret

; --- set_speaker_freq ---
set_speaker_freq:
    out 0x42,al                         ; PIT Ch2: speaker frequency data
    db 0x8a, 0xc4                       ; mov al,ah
    out 0x42,al                         ; PIT Ch2: speaker frequency data
    in al,0x61                          ; Read speaker/system status
    or al,0x3
    out 0x61,al                         ; Speaker control (bits 0-1: gate/enable)
    ret
wipe_sound_start:
    ret
play_wipe_note:
    cmp byte [0x0],0x0
    jz short lab_58bc
    push ax
    push cx
    push dx
    mov al,0xb6
    out byte 0x43,al
    mov bx,[0x5a56]
    db 0x81, 0xe3, 0x06, 0x00           ; and bx,0x6
    add word [0x5a56],0x2
    mov ax,[bx+0x5a5a]
    call set_speaker_freq
    pop dx
    pop cx
    pop ax
lab_58bc:
    ret

; --- init_music ---
; Resets the background music sequencer state. Sets initial tempo, position,
; and playback flags for the music engine.
init_music:
    mov byte [0x5927],0x80
    mov byte [0x5928],0x0
    mov byte [0x5929],0x0
    mov word [0x592a],0x500
    mov byte [0x592c],0xff
    mov byte [0x592d],0x0
    mov byte [0x5920],0x0
    mov byte [0x5b07],0x0
    mov word [0x5b08],0x0
    mov word [0x5b0c],0x1
    mov byte [0x5b0e],0x1
    ret

; --- play_catch_sound ---
play_catch_sound:
    cmp byte [enemy_chasing],0x0
    jnz lab_5908
    mov bx,0x390
    mov cx,0x1800
    call play_tone                           ;undefined play_tone()
lab_5908:
    mov byte [door_contact],0x0
    ret

; --- play_hit_sound ---
play_hit_sound:
    cmp byte [enemy_chasing],0x0
    jnz lab_591e
    mov bx,0x400
    mov cx,0x1800
    call play_tone                           ;undefined play_tone()
lab_591e:
    ret

; --- play_death_melody ---
play_death_melody:
    mov bx,0x7d0
    mov cx,0x1800
    call play_tone                           ;undefined play_tone()
    mov bx,0xa6e
    mov cx,0x1800
    call play_tone                           ;undefined play_tone()
    mov bx,0xdec
    mov cx,0x1800
    call play_tone                           ;undefined play_tone()
    ret

; --- start_tone ---
start_tone:
    cmp byte [sound_enabled],0x0
    jz lab_595c
    mov word [0x5923],bx
    push ax
    mov al,0xb6
    out 0x43,al                         ; PIT: control word (Ch2 square wave (speaker))
    pop ax
    call set_speaker_freq                           ;undefined set_speaker_freq()
    mov byte [0x5920],0x2
    db 0x2a, 0xe4                       ; sub ah,ah
    int 0x1a                            ; BIOS Timer: Get tick count → CX:DX
    mov word [0x5921],dx
lab_595c:
    ret
play_random_chirp:
    cmp byte [0x0],0x0
    jz short lab_597e
    cmp byte [0x5920],0x0
    jnz short lab_597e
    call random
    db 0x8b, 0xc2                       ; mov ax,dx
    db 0x25, 0x7f, 0x00                 ; and ax,0x7f
    add ax,0xaa
    db 0x8b, 0xd8                       ; mov bx,ax
    db 0x05, 0x1e, 0x00                 ; add ax,0x1e
    call start_tone
lab_597e:
    ret

; --- play_meow_sound ---
play_meow_sound:
    cmp byte [sound_enabled],0x0
    jz lab_59a2
    mov ax,0x1200
    mov bx,0x1312
    add ax,word [0x5b08]
    add bx,word [0x5b08]
    add word [0x5b08],0x15e
    call start_tone                           ;undefined start_tone()
    mov byte [0x5b07],0x18
lab_59a2:
    ret

; --- play_tone ---
play_tone:
    cmp byte [sound_enabled],0x0
    jz lab_59ca
    mov al,0xb6
    out 0x43,al                         ; PIT: control word (Ch2 square wave (speaker))
    db 0x8b, 0xc3                       ; mov ax,bx
    out 0x42,al                         ; PIT Ch2: speaker frequency data
    db 0x8a, 0xc4                       ; mov al,ah
    out 0x42,al                         ; PIT Ch2: speaker frequency data
    in al,0x61                          ; Read speaker/system status
    or al,0x3
    out 0x61,al                         ; Speaker control (bits 0-1: gate/enable)
    cmp byte [rom_id],0xfd
    jnz lab_59c5
    shr cx,0x1
lab_59c5:
    loop lab_59c5
    call silence_speaker                           ;undefined silence_speaker()
lab_59ca:
    ret

; --- play_hiss_sound ---
play_hiss_sound:
    in al,0x61                          ; Read speaker/system status
    and al,0xfe
    out 0x61,al                         ; Speaker control (bits 0-1: gate/enable)
    db 0x2a, 0xe4                       ; sub ah,ah
    int 0x1a                            ; BIOS Timer: Get tick count → CX:DX
    mov word [0x5a40],dx
    mov word [0x5a42],0x0
lab_59df:
    mov ax,[0x5a42]
    mov cl,0x6
    shr ax,cl
    jnz lab_59e9
    inc ax
lab_59e9:
    db 0x8b, 0xc8                       ; mov cx,ax
lab_59eb:
    push cx
    db 0x2a, 0xe4                       ; sub ah,ah
    int 0x1a                            ; BIOS Timer: Get tick count → CX:DX
    pop cx
    sub dx,word [0x5a40]
    cmp dx,0x2
    jc lab_59eb
    cmp dx,0x7
    jnc lab_5a18
    loop lab_59eb
    call random                           ;undefined random()
    and dl,0x2
    and dl,byte [sound_enabled]
    in al,0x61                          ; Read speaker/system status
    db 0x32, 0xc2                       ; xor al,dl
    out 0x61,al                         ; Speaker control (bits 0-1: gate/enable)
    add word [0x5a42],0x7
    jmp short lab_59df
lab_5a18:
    call silence_speaker                           ;undefined silence_speaker()
    ret

; --- play_falling_sound ---
play_falling_sound:
    cmp byte [sound_enabled],0x0
    jz lab_5a34
    call read_pit_timer                           ;undefined read_pit_timer()
    mov bx,word [0x5a16]
    db 0x2b, 0xd8                       ; sub bx,ax
    jc lab_5a35
    cmp bx,0x260
    ja lab_5a35
lab_5a34:
    ret
lab_5a35:
    mov [0x5a16],ax
    mov al,0xb6
    out 0x43,al                         ; PIT: control word (Ch2 square wave (speaker))
    inc word [0x5a18]
    mov bx,word [0x5a18]
    db 0x81, 0xe3, 0x1e, 0x00           ; and bx,0x1e
    mov ax,[0x5a3c]
    and ax,0x3ff
    cmp ax,0x180
    jc lab_5a59
    mov cx,0x180
    db 0x2b, 0xc8                       ; sub cx,ax
    xchg ax,cx
lab_5a59:
    shr ax,0x1
    shr ax,0x1
    add ax,word [bx + 0x5a1a]
    mov bx,0x1
    cmp byte [rom_id],0xfd
    jnz lab_5a6d
    shl bl,0x1
lab_5a6d:
    add word [0x5a3e],bx
    shl bx,0x1
    shl bx,0x1
    add word [0x5a3c],bx
    mov dx,word [0x5a3e]
    mov cl,0x3
    shr dx,cl
    db 0x03, 0xc2                       ; add ax,dx
    out 0x42,al                         ; PIT Ch2: speaker frequency data
    db 0x8a, 0xc4                       ; mov al,ah
    out 0x42,al                         ; PIT Ch2: speaker frequency data
    in al,0x61                          ; Read speaker/system status
    or al,0x3
    out 0x61,al                         ; Speaker control (bits 0-1: gate/enable)
    ret

; --- play_random_noise ---
play_random_noise:
    cmp byte [sound_enabled],0x0
    jz lab_5aa1
    db 0x2a, 0xe4                       ; sub ah,ah
    int 0x1a                            ; BIOS Timer: Get tick count → CX:DX
    cmp dx,word [0x5a14]
    jnz lab_5aa2
lab_5aa1:
    ret
lab_5aa2:
    mov word [0x5a14],dx
    mov al,0xb6
    out 0x43,al                         ; PIT: control word (Ch2 square wave (speaker))
    call random                           ;undefined random()
    db 0x8b, 0xc2                       ; mov ax,dx
    db 0x25, 0x70, 0x00                 ; and ax,0x70
    add ax,0x200
    out 0x42,al                         ; PIT Ch2: speaker frequency data
    db 0x8a, 0xc4                       ; mov al,ah
    out 0x42,al                         ; PIT Ch2: speaker frequency data
    in al,0x61                          ; Read speaker/system status
    or al,0x3
    out 0x61,al                         ; Speaker control (bits 0-1: gate/enable)
    ret

; --- play_crash_sound ---
play_crash_sound:
    mov word [0x5a12],0x338
    db 0x2a, 0xe4                       ; sub ah,ah
    int 0x1a                            ; BIOS Timer: Get tick count → CX:DX
    mov word [0x5a10],dx
    call read_pit_timer                           ;undefined read_pit_timer()
    mov [0x5a0e],ax
lab_5ad6:
    call read_pit_timer                           ;undefined read_pit_timer()
    db 0x8b, 0xd0                       ; mov dx,ax
    sub ax,word [0x5a0e]
    cmp ax,0x9c40
    jc lab_5b10
    mov word [0x5a0e],dx
    cmp byte [sound_enabled],0x0
    jz lab_5b10
    mov al,0xb6
    out 0x43,al                         ; PIT: control word (Ch2 square wave (speaker))
    call random                           ;undefined random()
    db 0x8b, 0xc2                       ; mov ax,dx
    and ax,0x7ff
    add ax,word [0x5a12]
    sub word [0x5a12],0x2
    out 0x42,al                         ; PIT Ch2: speaker frequency data
    db 0x8a, 0xc4                       ; mov al,ah
    out 0x42,al                         ; PIT Ch2: speaker frequency data
    in al,0x61                          ; Read speaker/system status
    or al,0x3
    out 0x61,al                         ; Speaker control (bits 0-1: gate/enable)
lab_5b10:
    db 0x2a, 0xe4                       ; sub ah,ah
    int 0x1a                            ; BIOS Timer: Get tick count → CX:DX
    sub dx,word [0x5a10]
    cmp dx,0x2
    jc lab_5ad6
    call silence_speaker                           ;undefined silence_speaker()
    ret

; --- silence_speaker ---
; Turns off the PC speaker by clearing the gate and enable bits (bits 0-1)
; of port 0x61.
silence_speaker:
    in al,0x61                          ; Read speaker/system status
    and al,0xfc
    out 0x61,al                         ; Speaker control (bits 0-1: gate/enable)
    ret

; --- play_timed_tone ---
play_timed_tone:
    mov al,0xb6
    out 0x43,al                         ; PIT: control word (Ch2 square wave (speaker))
    mov ax,[0x592a]
    out 0x42,al                         ; PIT Ch2: speaker frequency data
    db 0x8a, 0xc4                       ; mov al,ah
    out 0x42,al                         ; PIT Ch2: speaker frequency data
    in al,0x61                          ; Read speaker/system status
    or al,0x3
    out 0x61,al                         ; Speaker control (bits 0-1: gate/enable)
    call read_pit_timer                           ;undefined read_pit_timer()
    db 0x8b, 0xc8                       ; mov cx,ax
lab_5b40:
    call read_pit_timer                           ;undefined read_pit_timer()
    db 0x8b, 0xd1                       ; mov dx,cx
    db 0x2b, 0xd0                       ; sub dx,ax
    cmp dx,word [0x592e]
    jc lab_5b40
    in al,0x61                          ; Read speaker/system status
    and al,0xfc
    out 0x61,al                         ; Speaker control (bits 0-1: gate/enable)
    ret
init_victory_melody:
    mov word [0x59be],0x0
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    mov [0x59c0],dx
    ret
play_victory_note:
    cmp byte [0x0],0x0
    jz short lab_5b79
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    db 0x8b, 0xc2                       ; mov ax,dx
    sub ax,[0x59c0]
    db 0x3d, 0x02, 0x00                 ; cmp ax,0x2
    jnb short lab_5b7a
lab_5b79:
    ret
lab_5b7a:
    mov [0x59c0],dx
    mov bx,[0x59be]
    and bx,0xfe
    cmp bx,0x86
    jb short lab_5b92
    db 0x2b, 0xdb                       ; sub bx,bx
    mov [0x59be],bx
lab_5b92:
    add word [0x59be],0x2
    mov ax,[bx+0x5934]
    mov cx,[0x59bc]
    mov [0x59bc],ax
    db 0x3b, 0xc1                       ; cmp ax,cx
    jnz short lab_5baa
    call silence_speaker
    ret
lab_5baa:
    db 0x8b, 0xc8                       ; mov cx,ax
    mov al,0xb6
    out byte 0x43,al
    db 0x8b, 0xc1                       ; mov ax,cx
    out byte 0x42,al
    db 0x8a, 0xc4                       ; mov al,ah
    out byte 0x42,al
    in al,byte 0x61
    or al,0x3
    out byte 0x61,al
    ret
play_full_victory:
    cmp byte [0x0],0x0
    jz short lab_5bd0
    call play_victory_note
    cmp word [0x59be],0x7c
    jb short play_full_victory
lab_5bd0:
    ret
    add [bx+si],al
    add [bx+si],al
    add [bx+si],al
    add [bx+si],al
    add [bx+si],al
    add [bx+si],al
    add [bx+si],al
    db 0x00
show_extra_life:
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    mov [0x5f66],dx
    mov word [0x5f60],0x0
lab_5bee:
    mov ax,0xb800
    mov es,ax
    mov bx,[0x5f60]
    add word [0x5f60],0x2
    db 0x81, 0xe3, 0x02, 0x00           ; and bx,0x2
    mov si,[bx+0x5f62]
    mov di,0xa74
    mov cx,0x4404
    call blit_to_cga
lab_5c0d:
    call play_result_note
    db 0x2a, 0xe4                       ; sub ah,ah
    int byte 0x1a
    db 0x8b, 0xc2                       ; mov ax,dx
    sub ax,[0x5f66]
    db 0x3d, 0x04, 0x00                 ; cmp ax,0x4
    jb short lab_5c0d
    mov [0x5f66],dx
    cmp word [0x5f60],0x4
    jnz short lab_5c36
    mov si,0x5f68
    mov di,0x668
    mov cx,0x1004
    call blit_to_cga
lab_5c36:
    mov bx,[0x5f60]
    sub bx,0x8
    jb short lab_5c51
    cmp bx,0x6
    jnb short lab_5c51
    mov si,0x5fe8
    mov di,[bx+0x60e4]
    mov cx,0x1506
    call blit_to_cga
lab_5c51:
    cmp word [0x5f60],0x10
    jb short lab_5bee
    call silence_speaker
    ret
    db 0x00, 0x00, 0x00, 0x00


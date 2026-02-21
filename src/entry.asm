; --- entry ---
; Main entry point and game loop for Alley Cat.
;
; Structure:
;   1. One-time hardware init (video, ROM ID, interrupt handlers)
;   2. Title/attract screen loop
;   3. New game setup (lives, score, difficulty)
;   4. Alley game loop (walking, jumping, dodging obstacles)
;   5. On death: random level selection + dispatch via jump table
;   6. Per-level init + game loop (levels 1-7)
;   7. Level exit → return to alley
;
; Level map (names TBD unless confirmed):
;   0,1 → lab_03e2    3 → lab_0394 (has fence collision)
;     2 → lab_0459    4 → lab_0349 (has dog collision)
;     5 → lab_02fe    6 → lab_02aa
;     7 → lab_0260 (love scene - confirmed)
;
; Exit flags checked by level loops:
;   [cat_died]    (0x551)  - cat lost a life
;   [object_hit]  (0x552)  - hit by thrown object → back to alley
;   [cat_caught]  (0x553)  - caught by enemy → back to alley
;   [restart_game](0x41b)  - player pressed restart key
;   [show_attract](0x41c)  - timeout → show attract mode

; ===================== One-time initialization =====================
entry:
    push ds                             ; push DS:0000 as far-return address
    mov ax,0x0
    push ax
    call detect_video                           ;undefined detect_video()
reloc_1:
    mov ax,DATA_SEG_PARA                ; relocated: DS = data segment
    mov ds,ax
    call read_rom_id                           ;undefined read_rom_id()
    mov byte [video_mode],0x4
    mov word [difficulty_counter],0x0
    mov byte [use_joystick],0x0
    call install_handlers                           ;undefined install_handlers()
    call init_bios_data                           ;undefined init_bios_data()
    mov ax,[keyboard_counter]
    add ax,0x240
    mov [pause_screen_addr],ax
    mov ax,0x4
    int 0x10                            ; BIOS Video: Set mode (CGA 320x200 4-color)
    mov al,0x4                          ; mode 4 = CGA 320x200
    cmp byte [rom_id],0xfd              ; PCjr ROM?
    jz lab_003f
    mov al,0x6                          ; mode 6 = CGA 640x200 mono (non-PCjr)
lab_003f:
    mov [video_mode],al
    mov ah,0xb
    mov bx,0x101
    int 0x10                            ; BIOS Video: Set CGA palette (palette 1)
    mov word [round_counter],0x0
    mov word [level_number],0x0
    call set_palette                           ;undefined set_palette()
    cmp byte [rom_id],0xfd
    jz lab_0065
    mov dx,0x3d9
    mov al,0x20
    out dx,al                           ; CGA: color select (AL=20h)
lab_0065:
    call read_pit_counter                           ;undefined read_pit_counter()
    call clear_high_score                           ;undefined clear_high_score()
    call clear_score                           ;undefined clear_score()
    mov byte [attract_shown],0x0
    mov ax,0xffff
    mov [last_level],ax                 ; no previous level
    mov [prev_level],ax
    mov byte [sound_enabled],0xff       ; sound on

; ===================== Title screen / game over =====================
lab_0081:
    call update_high_score                           ;undefined update_high_score()
    mov word [difficulty_level],0x0
    mov word [level_number],0x0
    call set_palette                           ;undefined set_palette()
    call silence_speaker                           ;undefined silence_speaker()
    call show_title_screen                           ;undefined show_title_screen()
    call silence_speaker                           ;undefined silence_speaker()
    cmp byte [attract_shown],0x0
    jnz lab_00ae                        ; attract already shown → start game

; ===================== Attract mode (demo) =====================
lab_00a3:
    call silence_speaker                           ;undefined silence_speaker()
    call show_attract_mode                           ;undefined show_attract_mode()
    mov byte [attract_shown],0x1

; ===================== New game setup =====================
lab_00ae:
    mov ax,[difficulty_counter]
    mov [difficulty_level],ax
    mov byte [lives_count],0x3          ; 3 lives
    call clear_score                           ;undefined clear_score()
    mov word [level_number],0x0
    call set_palette                           ;undefined set_palette()
    call silence_speaker                           ;undefined silence_speaker()
    mov word [game_timer],0x0
    db 0x2a, 0xe4                       ; sub ah,ah
    int 0x1a                            ; BIOS Timer: Get tick count → CX:DX
    mov word [start_tick],dx
    mov word [elapsed_ticks],0x0
    mov byte [force_level7],0x0
    mov byte [start_in_level],0x0
    mov byte [show_attract],0x0
    mov byte [restart_game],0x0
    call silence_speaker                           ;undefined silence_speaker()

; ===================== Alley setup =====================
lab_00f3:
    cmp byte [lives_count],0x0          ; game over?
    jz lab_0081
    cmp byte [restart_game],0x0         ; player wants restart?
    jnz lab_00ae
    cmp byte [show_attract],0x0         ; timeout → attract?
    jnz lab_00a3
    call clear_screen                           ;undefined clear_screen()
    call render_sprites                           ;undefined render_sprites()
    mov byte [lives_display],0xff       ; force lives redraw
    call silence_speaker                           ;undefined silence_speaker()
    mov word [level_number],0x0
    cmp byte [start_in_level],0x0       ; returning from a level?
    jz lab_0137
    call setup_level                           ;undefined setup_level()
    mov byte [game_mode],0x2            ; level mode
    mov byte [anim_counter],0x1
    mov byte [anim_step],0x20
    jmp short lab_0140
lab_0137:
    mov word [cat_x],0x0                ; start at left edge
    call setup_alley                           ;undefined setup_alley()
lab_0140:
    call init_sound                           ;undefined init_sound()
    call init_player                           ;undefined init_player()
    call reset_jump                           ;undefined reset_jump()
    call init_objects                           ;undefined init_objects()
    call draw_score                           ;undefined draw_score()
    call draw_high_score                           ;undefined draw_high_score()
    call init_music                           ;undefined init_music()

; ===================== Alley game loop =====================
lab_0155:
    cmp byte [lives_count],0x0
    jnz lab_015f
    jmp near lab_0081                   ; game over
lab_015f:
    call process_keyboard                           ;undefined process_keyboard()
    cmp byte [show_attract],0x0
    jz lab_016c
    jmp near lab_00a3                   ; timeout → attract
lab_016c:
    cmp byte [restart_game],0x0
    jz lab_0176
    jmp near lab_00ae                   ; restart
lab_0176:
    call poll_joystick                           ;undefined poll_joystick()
    call update_animation                           ;undefined update_animation()
    call update_enemies                           ;undefined update_enemies()
    cmp byte [enemy_active],0x0
    jnz lab_0191
    inc byte [frame_counter]            ; no enemy → throttle: run physics
    test byte [frame_counter],0x3       ;   only every 4th frame
    jnz lab_0155
lab_0191:
    call play_sound                           ;undefined play_sound()
    call update_thrown_objects                           ;undefined update_thrown_objects()
    call update_cat_jump                           ;undefined update_cat_jump()
    call apply_cat_gravity                           ;undefined apply_cat_gravity()
    call animate_falling                           ;undefined animate_falling()
    call cycle_animations                           ;undefined cycle_animations()
    call draw_lives                           ;undefined draw_lives()
    cmp byte [cat_died],0x0
    jz lab_0155                         ; still alive → loop
    cmp byte [lives_count],0x0
    jnz lab_01b7
    jmp near lab_0081                   ; game over

; ===================== Death handler: save state + pick next level =====================
lab_01b7:
    db 0x2a, 0xe4                       ; sub ah,ah
    int 0x1a                            ; BIOS Timer: Get tick count → CX:DX
    mov word [game_tick],dx
    mov ax,[cat_x]
    mov [saved_cat_x],ax                ; save cat position for respawn
    mov al,[cat_y]
    mov [saved_cat_y],al
    mov byte [start_in_level],0x1
    cmp byte [force_level7],0x0         ; forced love scene?
    jz lab_01e5
    mov byte [force_level7],0x0
    mov word [level_number],0x7
    jmp short lab_0238                  ; → dispatch level 7
    db 0x90

; --- Random level selection ---
; ~62% chance: pick from difficulty table (biased by current difficulty)
; ~38% chance: pick uniformly from random table
; Avoids repeating the last 2 levels played.
lab_01e5:
    call random                           ;undefined random()
    test dl,0xa0                        ; ~62% chance bits 7 or 5 are set
    jz lab_020a                         ; → use random table
    mov bx,word [difficulty_level]
    db 0x81, 0xe3, 0x03, 0x00           ; and bx,0x3
    cmp bx,0x3                          ; difficulty 3 has no table
    jz lab_020a                         ; → use random table
    mov cl,0x2
    shl bx,cl                           ; bx = difficulty * 4
    db 0x81, 0xe2, 0x03, 0x00           ; and dx,0x3
    db 0x03, 0xda                       ; add bx,dx
    mov al,byte [bx + level_pool]      ; level_pool[difficulty*4 + rand&3]
    jmp short lab_021c
lab_020a:
    call random                           ;undefined random()
    db 0x81, 0xe2, 0x07, 0x00           ; and dx,0x7
    cmp dx,0x5                          ; reject 5,6,7 → uniform over 0..4
    jnc lab_020a
    db 0x8b, 0xda                       ; mov bx,dx
    mov al,byte [bx + level_pool_hard] ; level_pool_hard[rand % 5]
lab_021c:
    db 0x2a, 0xe4                       ; sub ah,ah
    cmp ax,word [last_level]            ; same as last level?
    jnz lab_022a
    cmp ax,word [prev_level]            ; same as the one before that?
    jz lab_01e5                         ; both match → re-roll

; --- Record chosen level and dispatch ---
lab_022a:
    mov [level_number],ax
    mov cx,word [last_level]
    mov word [prev_level],cx            ; shift history: prev = last
    mov [last_level],ax                 ;                last = new

; ===================== Level dispatch =====================
lab_0238:
    mov word [level_state],0x0
    mov bx,word [level_number]
    cmp bx,0x7
    jbe lab_0249
    db 0x2b, 0xdb                       ; sub bx,bx          ; clamp to 0
lab_0249:
    shl bx,0x1
    jmp word [cs:bx + 0x250]
    ; Jump table: level_number → handler
    dw 0x03e2                           ; -> lab_03e2         ; level 0
    dw 0x03e2                           ; -> lab_03e2         ; level 1 (same as 0)
    dw 0x0459                           ; -> lab_0459         ; level 2
    dw 0x0394                           ; -> lab_0394         ; level 3
    dw 0x0349                           ; -> lab_0349         ; level 4
    dw 0x02fe                           ; -> lab_02fe         ; level 5
    dw 0x02aa                           ; -> lab_02aa         ; level 6
    dw 0x0260                           ; -> lab_0260         ; level 7 (love scene)

; ===================== Level 7 (love scene) =====================
lab_0260:
    mov word [level_number],0x7
    call level_transition                       ; transition into level
    call draw_level_background                       ; draw score bar
    call setup_level
    call init_sound
    call init_thrown_objects                       ; init thrown objects state
    call reset_cupid                       ; init level 7 state
    call init_level7_objects                       ; init level 7 objects
    call init_music
lab_027e:
    call process_keyboard
    call poll_joystick
    call play_sound
    call update_animation
    call update_cupid                       ; update level 7 logic
    call tick_level_thrown_objects                    ; update thrown objects animation
    call spawn_thrown_object                       ; spawn thrown objects
    call update_level7_objects                       ; update level 7 objects
    mov al,[cat_died]
    or al,[cat_caught]
    or al,[show_attract]
    or al,[restart_game]
    jz short lab_027e
    jmp near lab_0427                   ; → level exit

; ===================== Level 6 =====================
lab_02aa:
    mov word [level_number],0x6
    call level_transition                       ; transition into level
    call draw_level_background                       ; draw score bar
    call level6_stubs                       ; init level 6 (stub/data)
    call setup_level
    call init_thrown_objects                       ; init thrown objects state
    call init_sound
    call init_music
lab_02c5:
    call process_keyboard
    call poll_joystick
    call play_sound
    call update_level6_movement                       ; update level 6 movement
    call update_level6_timing                       ; update level 6 timing
    call update_animation
    cmp byte [enemy_active],0x0
    jz short lab_02e3
    call update_enemies
    jmp short lab_02e6
lab_02e3:
    call tick_thrown_objects                       ; update thrown objects timing
lab_02e6:
    mov al,[cat_died]
    or al,[object_hit]
    or al,[cat_caught]
    or al,[restart_game]
    or al,[show_attract]
    jz short lab_02c5
    jmp near lab_0427                   ; → level exit

; ===================== Level 5 =====================
lab_02fe:
    mov word [level_number],0x5
    call level_transition                       ; transition into level
    call draw_level_background                       ; draw score bar
    call init_level5_objects                       ; init level 5 objects
    call setup_level
    call init_thrown_objects                       ; init thrown objects state
    call init_sound
    call init_music
lab_0319:
    call process_keyboard
    call poll_joystick
    call play_sound
    call update_level5_objects                       ; update level 5 objects
    call update_level5_anim                       ; update level 5 animation
    call update_animation
    call tick_thrown_objects                       ; update thrown objects timing
    call update_enemies
    mov al,[object_hit]
    or al,[cat_caught]
    or al,[cat_died]
    or al,[show_attract]
    or al,[restart_game]
    jz short lab_0319
    jmp near lab_0427                   ; → level exit

; ===================== Level 4 =====================
lab_0349:
    mov word [level_number],0x4
    call level_transition                       ; transition into level
    call draw_level_background                       ; draw score bar
    call setup_level
    call init_thrown_objects                       ; init thrown objects state
    call init_sound
    call init_level4_objects                       ; init level 4 objects
    call init_music
lab_0364:
    call process_keyboard
    call poll_joystick
    call play_sound
    call update_animation
    call update_level4_state                       ; update level 4 state
    call update_level4_anim                       ; update level 4 animation
    call tick_thrown_objects                       ; update thrown objects timing
    call update_enemies
    mov al,[object_hit]
    or al,[cat_caught]
    or al,[cat_died]
    or al,[show_attract]
    or al,[restart_game]
    jz short lab_0364
    jmp near lab_0427                   ; → level exit

; ===================== Level 3 =====================
lab_0394:
    mov word [level_number],0x3
    call level_transition                       ; transition into level
    call draw_level_background                       ; draw score bar
    call setup_level
    call init_thrown_objects                       ; init thrown objects state
    call init_sound
    call init_level3_doors                       ; init level 3 objects
    call init_level3_enemy                       ; init level 3 animation state
    call init_music
lab_03b2:
    call process_keyboard
    call poll_joystick
    call play_sound
    call update_animation
    call update_level3_enemy                       ; update level 3 animation
    call update_level3_doors                       ; update level 3 objects
    call tick_thrown_objects                       ; update thrown objects timing
    call update_enemies
    mov al,[object_hit]
    or al,[cat_caught]
    or al,[cat_died]
    or al,[show_attract]
    or al,[restart_game]
    jz short lab_03b2
    jmp short lab_0427                  ; → level exit
    nop

; ===================== Level 0/1 =====================
lab_03e2:
    mov word [level_number],0x1
    call level_transition                       ; transition into level
    call draw_level_background                       ; draw score bar
    call setup_level
    call init_thrown_objects                       ; init thrown objects state
    call init_sound
    call init_music
lab_03fa:
    call process_keyboard
    call poll_joystick
    call play_sound
    call update_animation
    call tick_thrown_objects                       ; update thrown objects timing
    call update_enemies
    call update_entrance_anim                       ; update level 0/1 animation
    cmp byte [level_complete],0x0      ; level complete? → level 2
    jnz short lab_0459
    mov al,[object_hit]
    or al,[cat_died]
    or al,[restart_game]
    or al,[show_attract]
    jz short lab_03fa

; ===================== Level exit handler =====================
lab_0427:
    cmp byte [restart_game],0x0
    jz short lab_0431
    jmp near lab_00ae                   ; → new game
lab_0431:
    cmp byte [show_attract],0x0
    jz short lab_043b
    jmp near lab_00a3                   ; → attract mode
lab_043b:
    cmp byte [object_hit],0x0
    jz short lab_0447
    mov byte [start_in_level],0x0      ; respawn in alley
lab_0447:
    mov ax,[level_number]
    mov [level_state],ax                ; save last level played
    mov word [level_number],0x0         ; back to alley
    call level_transition                       ; transition out of level
    jmp near lab_00f3                   ; → alley setup

; ===================== Level 2 (entered from level 0/1 on completion) =====================
lab_0459:
    mov word [level_number],0x2
    call level_transition                       ; transition into level
    call draw_level_background                       ; draw score bar
    call init_level2_objects             ; init level 2 objects
    call setup_level
    mov byte [enemy_chasing],0x0
    mov byte [enemy_active],0x0
    call init_music
lab_0478:
    call process_keyboard
    call poll_joystick
    call play_sound
    call update_animation
    call update_level2_objects           ; update level 2 objects
    call animate_level2_blocks           ; update level 2 animation
    mov al,[object_hit]
    or al,[cat_caught]
    or al,[show_attract]
    or al,[restart_game]
    jz short lab_0478
    jmp short lab_0427                  ; → level exit
    db 0x00, 0x00, 0x00


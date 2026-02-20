# AlleyCat Reverse Engineering - Progress

## Goal
Convert Ghidra disassembly of AlleyCat (1984 DOS game, 55KB) to NASM-compilable assembly.

## Binary Structure (from MZ header)
- **File size**: 55,067 bytes
- **MZ header**: 512 bytes (32 paragraphs)
- **Load image**: 54,555 bytes
- **Relocations**: 9 (all in CS segment 0x0723)
- **Entry point**: CS:IP = 0x0723:0x0000
- **Stack**: SS:SP = 0x0000:0x0100 (256 bytes, likely re-initialized at startup)

## Ghidra Segment Mapping
| Ghidra Segment | Segment Addr | Role | Load Image Offset | Lines |
|---|---|---|---|---|
| CODE_0 | 0x1000 | Stack/BSS (256 bytes) | 0x0000 | 1-257 |
| CODE_1 | 0x1010 | Data segment (DS) | 0x0100 | 258-28439 |
| CODE_2 | 0x1723 | Code segment (CS) | 0x7230 | 28440-47000+ |
| HEADER | - | MZ header bytes | file offset 0 | 47000+ |

- **Ghidra load base**: 0x1000
- **DS** = 0x1010 (set in entry() at line 28450-28451)
- **CS** = 0x1723 (entry point segment)
- **Total functions**: 132

## Address Translation
- Ghidra addr `CODE_2:1723:XXXX` → file offset `0x200 + 0x7230 + XXXX`
- Ghidra addr `CODE_1:1010:XXXX` → file offset `0x200 + 0x0100 + XXXX`
- Data references like `DAT_1010_XXXX` → DS-relative offset `XXXX`

## Approach
1. **Phase 1**: Parse Ghidra listing, extract all code instructions and data
2. **Phase 2**: Convert to NASM syntax (MZ EXE format first)
3. **Phase 3**: Try .COM conversion (everything fits in ~54KB + PSP = ~55KB < 64KB)

## Key Findings

### Code Section (CODE_2: 0x1723)
- **18,251 lines** (28445-46695), offset range 0x0000-0x62EA
- **132 functions**, all near calls (no far calls)
- **1 RETF** at 0x13A9 (otherwise all near RET)
- **1 indirect jump**: `JMP word ptr CS:[BX+0x250]` (jump table dispatch)
- **~12,814 raw data bytes** (`??`) embedded in code segment (lookup/dispatch tables)
- **No INT 21h** - game uses INT 10h (video), INT 1Ah (timer), INT 11h (equipment)
- **Entry function** (FUN_1723_5c60): detects video hardware, sets CGA mode 4

### Data Section (CODE_1: 0x1010)
- **~29KB** from offset 0x0000 to 0x712F
- First 0x422 bytes are mostly zeros (BSS-like)
- First non-zero data at offset 0x0422 (lookup table values)
- Contains embedded bitmap/sprite data (0xAA, 0xFF patterns = CGA pixel data)
- Word-size data with `undefined2`, byte-size with `undefined1`
- No `undefined4` or larger types found

### Relocations (9 total, all in CS=0x0723)
| # | Offset:Segment | Purpose |
|---|---|---|
| 1 | 0x0009:0x0723 | In entry(), MOV AX,0x0 (patched to data segment) |
| 2-9 | Various:0x0723 | Segment references in code |

## Approach: Raw Byte Extraction + NASM
Since the Ghidra listing embeds raw hex bytes in every line, the most reliable approach is:
1. **Extract raw bytes from cat.exe** (skip 512-byte MZ header)
2. **For data section**: emit as `db` directives with labels from Ghidra
3. **For code section**: convert Ghidra mnemonics to NASM syntax with labels
4. **Verify**: assemble with NASM and compare byte-for-byte

## Status
- [x] Analyzed MZ header
- [x] Identified segments and entry point
- [x] Counted functions (132)
- [x] Surveyed all Ghidra line format patterns
- [x] Analyzed data section structure
- [x] Analyzed code section edge cases
- [x] Write Python parser for Ghidra → NASM conversion (`ghidra2nasm.py`)
- [x] Extract data section with labels (47 labels, 26 game strings annotated)
- [x] Convert code section instructions (4,223 instructions, 132 functions, 506 labels)
- [x] Handle embedded data in code section (12,814 raw data bytes)
- [x] Assemble with NASM and verify byte-exact match (**IDENTICAL!**)
- [x] Convert `db` to real NASM mnemonics with iterative verification
  - **3,918 instructions** → real NASM mnemonics
  - **305 instructions** → kept as `db` (1 unconvertible, 304 encoding mismatches)
  - **30 size ambiguities** pre-detected (accumulator-specific, sign-ext imm8, etc.)
  - **274 same-size encoding diffs** caught via byte comparison (opcode direction, etc.)
  - Converged in **1 iteration** after pre-detection
- [x] Name all 132 functions (96 renamed from `fun_XXXX`, 36 already named)
- [x] Name 47 data variables (EQU labels + inline address replacements)
- [ ] Consider .COM file conversion (all fits in ~54KB < 64KB)

## Current Approach
Hybrid: real NASM mnemonics for 93% of instructions (3,918/4,223), `db` fallback
for the remaining 7% where NASM encodes differently than the original assembler.
Data labels defined as EQU constants. Iterative verification ensures byte-exact match.

## Named Functions (96 of 132)

All `fun_XXXX` placeholders have been replaced with meaningful names. The remaining
36 functions already had names from Ghidra or were named during initial conversion.

### Drawing Primitives
| Original | Name | Purpose |
|---|---|---|
| fun_13d8 | check_vsync | Wait for CGA vertical sync |
| fun_13b7 | read_pit_timer | Read PIT channel 0 counter |
| fun_5e2b | print_string | Print null-terminated string via INT 10h |
| fun_5e5b | set_cursor | Set BIOS cursor position |
| fun_5fcd | clear_cga | Clear CGA framebuffer |
| fun_2cb0 | calc_cga_addr | Calculate CGA interlaced address from (CX,DL) |
| fun_2d9d | blit_to_cga | Blit sprite data to CGA memory |
| fun_2dca | save_from_cga | Save CGA region to buffer |
| fun_2d35 | blit_masked | Blit sprite with AND mask |
| fun_2ccc | blit_transparent | Blit sprite with transparency (XOR) |
| fun_2d70 | copy_with_stride | Copy data with interlace stride |

### Sound System
| Original | Name | Purpose |
|---|---|---|
| fun_5889 | set_speaker_freq | Set PIT channel 2 frequency |
| fun_59a3 | play_tone | Play tone for CX loop cycles |
| fun_593b | start_tone | Start async tone with timer |
| fun_5797 | reset_noise | Initialize noise generator |
| fun_57a6 | update_noise | Update noise waveform |
| fun_597f | play_meow_sound | Cat meow sound effect |
| fun_59cb | play_hiss_sound | Cat hiss sound effect |
| fun_53b0 | play_music_note | Play note from music sequence table |
| fun_5450 | init_chase_sound | Initialize chase sound parameters |
| fun_58f8 | play_catch_sound | Sound when catching object |
| fun_590e | play_hit_sound | Sound on hit/impact |
| fun_591f | play_death_melody | 3-tone descending death melody |
| fun_5a1c | play_falling_sound | Modulated falling sound |
| fun_5a90 | play_random_noise | Random frequency noise burst |
| fun_5ac2 | play_crash_sound | Crash/impact with decay |
| fun_5b28 | play_timed_tone | Play tone with PIT-timed duration |

### Input Handling
| Original | Name | Purpose |
|---|---|---|
| fun_12c1 | read_keyboard_dirs | Read keyboard arrow key state |
| fun_12a1 | decode_joystick_axis | Decode joystick axis to direction |
| fun_5f97 | wait_for_input | Wait for keypress or joystick |
| fun_5fb1 | display_text_line | Display text line with input wait |
| fun_5fe5 | detect_joystick | Detect joystick hardware |
| fun_600f | test_joystick_axis | Test single joystick axis |
| fun_5e70 | show_pause_menu | Show pause menu overlay |

### Alley Scene Drawing
| Original | Name | Purpose |
|---|---|---|
| fun_2a30 | draw_alley_scene | Draw full alley background |
| fun_2a68 | draw_difficulty_icon | Draw difficulty indicator |
| fun_2a80 | init_alley_objects | Initialize alley object positions |
| fun_2ac6 | draw_object_row | Draw row of alley objects |
| fun_2b24 | draw_block_list | Draw block list for alley |
| fun_2b71 | draw_window_strip | Draw window strip on building |
| fun_2b8b | draw_all_windows | Draw all window strips |
| fun_2b9e | draw_alley_details | Draw alley detail elements |
| fun_2c3d | draw_building | Draw single building |
| fun_2c84 | draw_all_buildings | Draw all buildings in alley |

### Alley Game Logic
| Original | Name | Purpose |
|---|---|---|
| fun_0658 | check_throw_range | Check if thrown object in range |
| fun_0633 | rotate_throw_bits | Rotate throw direction bits |
| fun_067d | generate_throw_object | Generate object thrown from window |
| fun_06de | generate_throw_pattern | Generate throw pattern sequence |
| fun_0700 | reset_window_state | Reset window throw state |
| fun_0fc9 | update_scroll | Update alley scroll position |
| fun_1020 | update_walk_frame | Update cat walk animation frame |
| fun_1069 | spawn_window_event | Spawn event from window |
| fun_10dd | enter_building | Start building/level transition |
| fun_1124 | save_alley_buffer | Save alley screen region |
| fun_1145 | draw_alley_foreground | Draw alley foreground sprites |
| fun_1166 | handle_cat_death | Handle cat death sequence |
| fun_11e3 | restore_alley_buffer | Restore saved alley region |
| fun_0f87 | update_viewport | Update viewport/camera position |
| fun_17ad | check_window_landing | Check if cat lands on window ledge |

### Enemy System
| Original | Name | Purpose |
|---|---|---|
| fun_1d6e | set_ega_palette | Set EGA palette registers |
| fun_2022 | update_enemy_sprite | Update enemy sprite frame |
| fun_2059 | update_enemy_viewport | Update enemy viewport position |
| fun_209b | draw_enemy | Draw enemy sprite to CGA |
| fun_20e1 | erase_enemy | Erase enemy from screen |
| fun_20f5 | check_enemy_activate | Check if enemy should activate |
| fun_2136 | activate_enemy_chase | Activate enemy chase mode |
| fun_1aea | decode_enemy_params | Decode enemy parameters from data |
| fun_1b05 | check_fish_collision | Check collision with fish object |
| fun_1b4c | check_trashcan_near | Check if near trashcan |
| fun_1b7a | check_dog_collision | Check collision with dog enemy |
| fun_15d0 | pick_random_target | Pick random target position |

### Level Collision & Objects
| Original | Name | Purpose |
|---|---|---|
| fun_1608 | check_level_collision | Check level-specific collision |
| fun_1657 | check_door_position | Check if at door position |
| fun_16c6 | check_level_platform | Check level platform collision |
| fun_1799 | pixel_to_bitmask | Convert pixel position to bitmask |
| fun_2e29 | check_rect_collision | AABB rectangle collision test |
| fun_30fa | check_stairs_collision | Check staircase collision |
| fun_3445 | update_footprint | Update ground footprint graphics |
| fun_347f | draw_footprint_tile | Draw single footprint tile |
| fun_34a0 | check_level_objects | Main level object collision loop |
| fun_363d | reset_caught_objects | Reset caught level objects |
| fun_37c1 | erase_level_object | Erase level object from CGA |
| fun_3c43 | check_fence_collision | Level 3 fence collision check |

### Gravity & Animation Objects
| Original | Name | Purpose |
|---|---|---|
| fun_1922 | restore_gravity_bg | Restore CGA behind gravity object |
| fun_22dc | erase_jump_sprite | Erase jump object from screen |
| fun_22f7 | check_jump_collision | Jump object vs cat collision |
| fun_254d | erase_cycle_sprite | Erase cycling object sprite |
| fun_2567 | check_cycle_cat_collision | Cycling object vs cat collision |
| fun_265e | check_cycle_gravity_hit | Cycling object vs gravity collision |

### Score System
| Original | Name | Purpose |
|---|---|---|
| fun_26e8 | zero_score_buffer | Zero 7-byte score buffer |
| fun_2706 | add_score | BCD addition to score |
| fun_2739 | render_score_digits | Render 7 BCD digits to CGA |

### System & Title Screen
| Original | Name | Purpose |
|---|---|---|
| fun_147f | restore_handlers | Restore original interrupt handlers |
| fun_5c9e | print_startup_msg | Print startup/error message |
| fun_5dd4 | move_title_cat | AI-controlled title screen cat |
| fun_5e3b | animate_title_icon | Animate title screen cat icon |

## Named Variables (47 total)

All frequently-used data addresses replaced with meaningful names via EQU constants.

### Core Game State
| Address | Name | Type | Purpose |
|---|---|---|---|
| 0x0000 | sound_enabled | byte | Sound on/off (0xFF=on, 0=off) |
| 0x0001 | saved_cat_x | word | Backup of cat_x for respawn |
| 0x0003 | saved_cat_y | byte | Backup of cat_y for respawn |
| 0x0004 | level_number | word | Current level (0-7, 7=love) |
| 0x0006 | level_state | word | Level sub-state counter |
| 0x0008 | difficulty_level | word | Current difficulty tier |
| 0x0550 | game_mode | byte | Mode (0=alley, 2=level) |
| 0x0551 | cat_died | byte | Cat death flag |
| 0x1f80 | lives_count | byte | Remaining lives |
| 0x1f81 | lives_display | byte | Lives display cache (redraw opt) |
| 0x6df8 | difficulty_counter | word | Difficulty progression counter |

### Cat Position & Movement
| Address | Name | Type | Purpose |
|---|---|---|---|
| 0x0579 | cat_x | word | Cat horizontal position (pixels) |
| 0x057b | cat_y | byte | Cat vertical position (row) |
| 0x057c | cat_y_bottom | byte | Cat bottom edge (cat_y + 0x32) |
| 0x056e | scroll_direction | byte | Scroll/walk direction |
| 0x0572 | scroll_speed | word | Scroll/walk speed |
| 0x0563 | cat_screen_pos | word | Cat CGA screen address |
| 0x0565 | cat_sprite_dims | word | Cat sprite dimensions (rows:cols) |

### Cat State Flags
| Address | Name | Type | Purpose |
|---|---|---|---|
| 0x0571 | in_level_mode | byte | Inside building flag |
| 0x055a | transitioning | byte | Transition active flag |
| 0x055b | transition_timer | byte | Transition countdown |
| 0x055c | at_platform | byte | On window ledge flag |
| 0x0552 | object_hit | byte | Object collision flag |
| 0x0553 | cat_caught | byte | Cat caught flag |
| 0x05f3 | immune_flag | byte | Immunity during transitions |

### Animation
| Address | Name | Type | Purpose |
|---|---|---|---|
| 0x0576 | anim_counter | byte | Animation frame counter |
| 0x0577 | anim_accumulator | byte | Animation sub-frame accumulator |
| 0x0578 | anim_step | byte | Animation step size |

### Window/Floor Tracking
| Address | Name | Type | Purpose |
|---|---|---|---|
| 0x0525 | window_column | byte | Window column index (0-3) |
| 0x052f | current_floor | word | Current floor index (0-2) |

### Gravity Object
| Address | Name | Type | Purpose |
|---|---|---|---|
| 0x1671 | gravity_x | word | Gravity object X position |
| 0x1673 | gravity_y | byte | Gravity object Y position |

### Enemy
| Address | Name | Type | Purpose |
|---|---|---|---|
| 0x1cb8 | enemy_active | byte | Enemy present on screen |
| 0x1cbf | enemy_chasing | byte | Enemy in chase mode |
| 0x1cc6 | enemy_x | word | Enemy X position |
| 0x1cd0 | enemy_dir | byte | Enemy direction (1/0xFF) |

### Input
| Address | Name | Type | Purpose |
|---|---|---|---|
| 0x0698 | input_horizontal | byte | H-axis input (1=right, 0xFF=left) |
| 0x0699 | input_vertical | byte | V-axis input |
| 0x0693 | keyboard_counter | word | Keyboard state counter |
| 0x069b | use_joystick | byte | Joystick active flag |

### Timers & Game Loop
| Address | Name | Type | Purpose |
|---|---|---|---|
| 0x040f | frame_counter | byte | Frame skip counter (& 0x3) |
| 0x0410 | game_tick | word | BIOS tick for game timing |
| 0x0412 | start_tick | word | Tick count at game start |
| 0x0414 | elapsed_ticks | word | Elapsed time counter |
| 0x0416 | round_counter | word | Round/stage counter |
| 0x1c30 | game_timer | word | Total game time tracker |

### Flow Control Flags
| Address | Name | Type | Purpose |
|---|---|---|---|
| 0x0418 | force_level7 | byte | Force love level selection |
| 0x0419 | start_in_level | byte | Start in level (vs alley) |
| 0x041a | attract_shown | byte | Attract mode shown flag |
| 0x041b | restart_game | byte | Restart game flag |
| 0x041c | show_attract | byte | Go to attract mode flag |
| 0x041d | last_input | word | Last input state (debounce) |
| 0x041f | prev_input | word | Previous input (debounce) |

### Hardware
| Address | Name | Type | Purpose |
|---|---|---|---|
| 0x0690 | video_mode | byte | CGA video mode (4 or 6) |
| 0x0697 | rom_id | byte | PCjr detection (0xFD=PCjr) |

### Encoding Mismatches (why some instructions stay as `db`)
NASM picks the shortest encoding; the original 1984 assembler sometimes used longer forms:
- **Size differences** (30): accumulator-specific opcodes shorter than r/m form,
  sign-extended imm8 shorter than imm16, MOV AL/AX with direct address, etc.
- **Same-size differences** (274): opcode direction bit (MOV reg,reg has two encodings),
  accumulator-specific vs sign-extended imm8 (both 3 bytes, different opcodes)

## Call-Target Label Renaming (Phase 2)

After the initial 132 function renames (`fun_XXXX` → meaningful names), a second pass
renamed `lab_XXXX` labels that are call targets (subroutine entry points within files).

| File | Labels Renamed | Status |
|---|---|---|
| game_loop.asm | ~20 | Done |
| hardware.asm | ~15 | Done |
| alley.asm | ~25 | Done |
| alley_drawing.asm | ~10 | Done |
| ui.asm | ~30 | Done |
| score.asm | ~15 | Done |
| enemy.asm | ~20 | Done |
| sound.asm | ~17 | Done |
| level_objects.asm | 87 | Done |
| level_physics.asm | - | Pending |

## Variable Naming Progress

Systematic replacement of raw hex addresses (`[0xNNNN]`) with named EQU constants.

| File | Status |
|---|---|
| entry.asm | Done (0 raw refs) |
| game_loop.asm | Done |
| score.asm | Done |
| input.asm | Done |
| throw.asm | Done |
| cga.asm | Done |
| alley.asm | Done |
| alley_drawing.asm | Done |
| objects.asm | Done |
| level_physics.asm | Remaining |
| ui.asm | Remaining |
| enemy.asm | Remaining |
| sound.asm | Remaining |
| level_objects.asm | Remaining |
| hardware.asm | Remaining |

## Bugs Found & Fixed
1. **Backslash line continuation**: NASM treats `\` at end of line as continuation.
   ASCII sidebar in `db` comments ending with 0x5C (`\`) caused next `db` line to be
   swallowed. Fix: exclude `\` from ASCII sidebar display.
2. **Truncated addresses**: Ghidra truncates long addresses as `0x1...`. Fixed by
   extracting actual address from raw instruction bytes.
3. **`=>` annotation stripping**: Greedy regex ate second operand. Fixed with `[^,\]]*`.
4. **MZ header padding**: Extra bytes between fields; fixed by emitting raw binary header.

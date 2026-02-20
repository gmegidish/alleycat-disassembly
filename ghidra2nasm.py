#!/usr/bin/env python3
"""Convert Ghidra listing of AlleyCat to NASM-compilable assembly.

Reads:
  - cat.exe (original binary for raw bytes)
  - cat.txt (Ghidra disassembly for labels, instructions, structure)

Outputs:
  - cat.asm (NASM source that assembles to byte-exact replica)

Iteratively converts instructions to NASM mnemonics, automatically
reverting any that produce different bytes than the original.
"""

import re
import sys
import os
import subprocess
import struct
from collections import OrderedDict

# === Constants from MZ header analysis ===
MZ_HEADER_SIZE = 0x200      # 512 bytes (32 paragraphs)
STACK_SIZE = 0x100           # 256 bytes (first part of load image)
DATA_FILE_OFFSET = 0x300     # MZ header + stack = file offset of data
CODE_FILE_OFFSET = 0x7430    # MZ header + stack + data = file offset of code
DATA_SEG_LOAD_OFFSET = 0x100 # data starts 0x100 into load image
CODE_SEG_LOAD_OFFSET = 0x7230 # code starts 0x7230 into load image
DATA_SIZE = 0x7130           # 28,976 bytes
GHIDRA_CS = 0x1723
GHIDRA_DS = 0x1010


def read_binary(filename):
    """Read the original binary and return bytes."""
    with open(filename, 'rb') as f:
        return f.read()


def parse_ghidra_listing(filename):
    """Parse Ghidra listing for labels, functions, and instruction info."""
    data_labels = {}       # ds_offset -> label_name
    data_strings = {}      # ds_offset -> string text (from ds directives)
    code_labels = {}       # cs_offset -> label_name
    functions = {}         # cs_offset -> function_name
    code_instructions = [] # (cs_offset, raw_bytes_hex, mnemonic, operands)
    code_data_bytes = []   # (cs_offset, byte_hex) - raw ?? data in code section

    with open(filename, 'r') as f:
        for line_raw in f:
            line = line_raw.rstrip('\n\r')
            stripped = line.strip()
            if not stripped:
                continue

            # --- Data labels: DAT_1010_XXXX ---
            m = re.match(r'(DAT_1010_([0-9a-fA-F]{4})):', stripped)
            if m:
                name = 'dat_' + m.group(2).lower()
                offset = int(m.group(2), 16)
                data_labels[offset] = name
                continue

            # --- Code labels: LAB_1723_XXXX ---
            m = re.match(r'(LAB_1723_([0-9a-fA-F]{4})):', stripped)
            if m:
                name = 'lab_' + m.group(2).lower()
                offset = int(m.group(2), 16)
                code_labels[offset] = name
                continue

            # --- Function definitions ---
            m = re.match(r';undefined (FUN_1723_([0-9a-fA-F]{4}))\(\)', stripped)
            if m:
                name = 'fun_' + m.group(2).lower()
                offset = int(m.group(2), 16)
                functions[offset] = name
                continue

            # --- entry() function ---
            if stripped == ';undefined entry()':
                functions[0x0000] = 'entry'
                continue

            # --- CODE_2 data bytes (??) ---
            m = re.match(
                r'CODE_2:1723:([0-9a-fA-F]{4})([0-9a-fA-F]+)\s+'
                r'(\?\?)\s+([0-9a-fA-F]+)h',
                stripped
            )
            if m:
                offset = int(m.group(1), 16)
                raw_hex = m.group(2)
                code_data_bytes.append((offset, raw_hex))
                continue

            # --- CODE_2 instruction lines ---
            m = re.match(
                r'CODE_2:1723:([0-9a-fA-F]{4})([0-9a-fA-F]+)\s+'
                r'([A-Z][A-Z0-9.]+)\s*(.*)',
                stripped
            )
            if m:
                offset = int(m.group(1), 16)
                raw_hex = m.group(2)
                mnemonic = m.group(3).strip()
                operands = m.group(4).strip()
                # Strip trailing comments: ;= value, ;undefined, etc.
                operands = re.sub(r'\s*;[=\s].*$', '', operands).strip()
                code_instructions.append((offset, raw_hex, mnemonic, operands))
                continue

            # --- Data string definitions: ds "text" ---
            m = re.match(
                r'CODE_1:1010:([0-9a-fA-F]{4})[0-9a-fA-F]+\.{3}\s+'
                r'ds\s+"(.*)',
                stripped
            )
            if m:
                offset = int(m.group(1), 16)
                text = m.group(2).rstrip('"').rstrip('.')
                data_strings[offset] = text
                continue

    return (data_labels, data_strings, code_labels, functions,
            code_instructions, code_data_bytes)


def reconstruct_address_from_bytes(raw_hex, operands):
    """For truncated addresses like 0x1..., extract actual addr from raw bytes."""
    if '0x1...' not in operands:
        return operands
    raw = bytes.fromhex(raw_hex)
    if len(raw) >= 2:
        addr = raw[-2] | (raw[-1] << 8)
        return operands.replace('0x1...', f'0x{addr:04x}]')
    return operands


def convert_operand_to_nasm(operand, raw_hex=''):
    """Convert a single Ghidra operand to NASM syntax."""
    if not operand:
        return ''

    s = operand

    # Fix truncated addresses from raw bytes
    if '...' in s and raw_hex:
        s = reconstruct_address_from_bytes(raw_hex, s)

    # Remove Ghidra annotations: =>anything (greedy to end or next comma)
    s = re.sub(r'=>[^,\]]*', '', s)

    # Remove trailing whitespace after annotation removal
    s = s.strip()
    if s.endswith(','):
        s = s[:-1].strip()

    # Convert CODE_1:DAT_1010_XXXX references to dat_XXXX
    s = re.sub(r'\[CODE_1:DAT_1010_([0-9a-fA-F]{4})\]',
               lambda m: '[dat_' + m.group(1).lower() + ']', s)

    # Convert standalone CODE_1:DAT_1010_XXXX (without brackets)
    s = re.sub(r'CODE_1:DAT_1010_([0-9a-fA-F]{4})',
               lambda m: 'dat_' + m.group(1).lower(), s)

    # Convert FUN_1723_XXXX to fun_XXXX
    s = re.sub(r'FUN_1723_([0-9a-fA-F]{4})',
               lambda m: 'fun_' + m.group(1).lower(), s)

    # Convert LAB_1723_XXXX to lab_XXXX
    s = re.sub(r'LAB_1723_([0-9a-fA-F]{4})',
               lambda m: 'lab_' + m.group(1).lower(), s)

    # Convert DAT_1010_XXXX (standalone, not in brackets)
    s = re.sub(r'DAT_1010_([0-9a-fA-F]{4})',
               lambda m: 'dat_' + m.group(1).lower(), s)

    # Convert CODE_0:DAT_1000_XXXX references (stack/BSS area)
    s = re.sub(r'CODE_0:DAT_1000_[0-9a-fA-F]+', '', s)

    return s


def convert_instruction_to_nasm(mnemonic, operands, raw_hex=''):
    """Convert Ghidra mnemonic + operands to NASM instruction string.
    Returns None if conversion fails (caller should emit db fallback)."""
    mn = mnemonic.upper()

    # Handle REP prefix on string ops: MOVSB.REP -> rep movsb
    if '.' in mn:
        parts = mn.split('.')
        base_mn = parts[0].lower()
        prefix = parts[1].lower()
        if prefix == 'rep':
            return f'rep {base_mn}'
        elif prefix == 'repnz':
            return f'repne {base_mn}'
        elif prefix == 'repz':
            return f'repe {base_mn}'
        else:
            return f'{prefix} {base_mn}'

    mn_lower = mn.lower()

    # No-operand instructions
    if mn_lower in ('ret', 'retf', 'nop', 'cld', 'std', 'cli', 'sti',
                     'pushf', 'popf', 'cbw', 'cwd', 'xlat', 'sahf', 'lahf',
                     'movsb', 'movsw', 'stosb', 'stosw', 'lodsb', 'lodsw',
                     'cmpsb', 'cmpsw', 'scasb', 'scasw', 'aaa', 'aas',
                     'daa', 'das', 'hlt', 'iret', 'into', 'aad', 'aam'):
        return mn_lower

    # Convert operands
    ops = convert_operand_to_nasm(operands, raw_hex)

    # Remove Ghidra-style "byte ptr" -> NASM "byte"
    ops = ops.replace('byte ptr ', 'byte ')
    ops = ops.replace('word ptr ', 'word ')
    ops = ops.replace('dword ptr ', 'dword ')

    # Handle segment overrides in memory operands
    ops = re.sub(r'([A-Z]{2}):\[', lambda m: '[' + m.group(1).lower() + ':', ops)
    ops = re.sub(r'CS:\[', '[cs:', ops)
    ops = re.sub(r'DS:\[', '[ds:', ops)
    ops = re.sub(r'ES:\[', '[es:', ops)
    ops = re.sub(r'SS:\[', '[ss:', ops)

    # String ops with explicit operands (NASM doesn't need them)
    if mn_lower in ('lodsb', 'lodsw', 'stosb', 'stosw', 'movsb', 'movsw'):
        return mn_lower

    result = f'{mn_lower} {ops}'.strip()

    # Lowercase register names
    for reg in ['AX', 'BX', 'CX', 'DX', 'SI', 'DI', 'SP', 'BP',
                'AL', 'AH', 'BL', 'BH', 'CL', 'CH', 'DL', 'DH',
                'DS', 'ES', 'CS', 'SS']:
        result = re.sub(r'\b' + reg + r'\b', reg.lower(), result)

    # JMP: force near/short based on original encoding
    if mn_lower == 'jmp' and raw_hex:
        first_byte = int(raw_hex[:2], 16)
        if first_byte == 0xe9:
            result = result.replace('jmp ', 'jmp near ', 1)
        elif first_byte == 0xeb:
            result = result.replace('jmp ', 'jmp short ', 1)

    # Validation: if result still has suspicious patterns, return None
    if '=>' in result or '...' in result or 'CODE_' in result or 'DAT_' in result:
        return None

    return result


def build_instruction_map(code_instructions):
    """Build mapping of cs_offset -> (end_offset, nasm_str, raw_hex, mnemonic, operands)."""
    instr_map = {}
    for (offset, raw_hex, mnemonic, operands) in sorted(code_instructions, key=lambda x: x[0]):
        byte_count = len(raw_hex) // 2
        end_offset = offset + byte_count
        nasm_str = convert_instruction_to_nasm(mnemonic, operands, raw_hex)
        instr_map[offset] = (end_offset, nasm_str, raw_hex, mnemonic, operands)
    return instr_map


def detect_size_ambiguities(instr_map):
    """Find instructions where NASM would produce a shorter encoding than original.

    The original 8086 assembler sometimes uses longer r/m forms where shorter
    accumulator-specific or register-specific forms exist. NASM always picks
    the shortest encoding, causing size mismatches.
    """
    ambiguous = set()
    for cs_off, (end_off, nasm_str, raw_hex, mn, ops) in instr_map.items():
        if nasm_str is None:
            continue
        raw = bytes.fromhex(raw_hex)
        if len(raw) < 2:
            continue
        opcode = raw[0]
        modrm = raw[1]

        # ALU byte ops with AL via r/m form: 80 [C0-C7] imm → 04/0C/.../3C imm
        if opcode == 0x80 and (modrm & 0xC7) == 0xC0:
            ambiguous.add(cs_off)

        # ALU word ops via r/m form with imm16 (opcode 81):
        #   a) with AX: 81 [C0/C8/D0/D8/E0/E8/F0/F8] imm16 → 05/0D/.../3D imm16
        #   b) any reg, imm16 fits in signed byte → 83 form (1 byte shorter)
        if opcode == 0x81 and len(raw) >= 4:
            if (modrm & 0xC7) == 0xC0:
                ambiguous.add(cs_off)
            imm16 = raw[-2] | (raw[-1] << 8)
            if imm16 <= 0x7F or imm16 >= 0xFF80:
                ambiguous.add(cs_off)

        # TEST AL via r/m form: F6 C0 imm → A8 imm
        if opcode == 0xF6 and modrm == 0xC0:
            ambiguous.add(cs_off)

        # TEST AX via r/m form: F7 C0 imm16 → A9 imm16
        if opcode == 0xF7 and modrm == 0xC0:
            ambiguous.add(cs_off)

        # MOV AL/AX, [disp16] via r/m form: 8A/8B 06 disp → A0/A1 disp
        # MOV [disp16], AL/AX via r/m form: 88/89 06 disp → A2/A3 disp
        if opcode in (0x88, 0x89, 0x8A, 0x8B) and modrm == 0x06:
            ambiguous.add(cs_off)

        # INC/DEC reg16 via r/m form: FF C0-CF → 40-4F
        if opcode == 0xFF and 0xC0 <= modrm <= 0xCF:
            ambiguous.add(cs_off)

        # PUSH reg16 via r/m form: FF F0-F7 → 50-57
        if opcode == 0xFF and 0xF0 <= modrm <= 0xF7:
            ambiguous.add(cs_off)

        # POP reg16 via r/m form: 8F C0-C7 → 58-5F
        if opcode == 0x8F and (modrm & 0xF8) == 0xC0:
            ambiguous.add(cs_off)

        # MOV reg, imm via r/m form: C6 [C0-C7] imm → B0-B7 imm
        if opcode == 0xC6 and (modrm & 0xC0) == 0xC0:
            ambiguous.add(cs_off)

        # MOV reg16, imm16 via r/m form: C7 [C0-C7] imm → B8-BF imm
        if opcode == 0xC7 and (modrm & 0xC0) == 0xC0:
            ambiguous.add(cs_off)

        # XCHG AX, reg via r/m form: 87 [mod=11, one reg=AX] → 90+r
        if opcode == 0x87 and (modrm & 0xC0) == 0xC0:
            if (modrm & 0x07) == 0x00 or (modrm & 0x38) == 0x00:
                ambiguous.add(cs_off)

    return ambiguous


# === IO Annotation Support ===

# Video modes for INT 10h AH=00h
VIDEO_MODES = {
    0x00: '40x25 text B&W', 0x01: '40x25 text color',
    0x02: '80x25 text B&W', 0x03: '80x25 text color',
    0x04: 'CGA 320x200 4-color', 0x05: 'CGA 320x200 4-color (no burst)',
    0x06: 'CGA 640x200 2-color',
}

# INT 10h subfunctions (by AH value)
INT10H_DESC = {
    0x00: 'Set video mode',
    0x02: 'Set cursor position (DH=row, DL=col)',
    0x0B: 'Set palette',
    0x0E: 'Teletype output (AL=char)',
    0x0F: 'Get video mode',
    0x10: 'Set/get palette regs (EGA/VGA)',
}

# INT 1Ah subfunctions (by AH value)
INT1AH_DESC = {
    0x00: 'Get tick count → CX:DX',
    0x01: 'Set tick count from CX:DX',
}

# PIT control word byte descriptions
PIT_CTRL_DESC = {
    0x00: 'latch counter 0',
    0xB6: 'Ch2 square wave (speaker)',
}


def track_registers(regs, instr_text):
    """Update tracked register state based on an instruction string."""
    if not instr_text:
        return
    s = instr_text.strip()

    # mov reg, immediate
    m = re.match(r'mov\s+(ax|ah|al|bx|bh|bl|dx|dh|dl),\s*0x([0-9a-fA-F]+)$', s)
    if m:
        reg, val = m.group(1), int(m.group(2), 16)
        regs[reg] = val
        if reg == 'ax':
            regs['ah'] = (val >> 8) & 0xFF
            regs['al'] = val & 0xFF
        elif reg == 'bx':
            regs['bh'] = (val >> 8) & 0xFF
            regs['bl'] = val & 0xFF
        elif reg == 'dx':
            regs['dh'] = (val >> 8) & 0xFF
            regs['dl'] = val & 0xFF
        return

    # xor/sub reg,reg → 0
    m = re.match(r'(?:xor|sub)\s+(ax|ah|al|bx|bh|bl|dx|dh|dl),\s*\1$', s)
    if m:
        reg = m.group(1)
        regs[reg] = 0
        if reg == 'ax': regs['ah'] = regs['al'] = 0
        if reg == 'bx': regs['bh'] = regs['bl'] = 0
        if reg == 'dx': regs['dh'] = regs['dl'] = 0
        return

    # call / ret / retf → clear everything
    if s.startswith('call ') or s in ('ret', 'retf'):
        regs.clear()
        return

    # int → clear return registers
    if s.startswith('int '):
        for r in ('ax', 'ah', 'al', 'bx', 'bh', 'bl',
                   'dx', 'dh', 'dl', 'cx', 'ch', 'cl'):
            regs.pop(r, None)
        return

    # For other instructions, invalidate any tracked register in destination
    parts = s.split(',', 1)
    if parts:
        dest = parts[0]
        if not any(dest.startswith(x) for x in ('cmp ', 'test ', 'push ', 'out ')):
            for reg in list(regs.keys()):
                if re.search(r'\b' + reg + r'\b', dest):
                    del regs[reg]


def get_io_annotation(instr_text, regs):
    """Generate descriptive annotation for INT/OUT/IN instructions.
    Returns annotation string or None."""
    if not instr_text:
        return None
    s = instr_text.strip()

    # --- INT instructions ---
    m = re.match(r'int\s+0x([0-9a-fA-F]+)', s)
    if m:
        int_num = int(m.group(1), 16)

        if int_num == 0x11:
            return 'BIOS: Equipment list → AX (bits 4-5=video mode)'

        if int_num == 0x10:
            ah = regs.get('ah')
            if ah is None and 'ax' in regs:
                ah = (regs['ax'] >> 8) & 0xFF
            al = regs.get('al')
            if al is None and 'ax' in regs:
                al = regs['ax'] & 0xFF
            if ah == 0x00:
                mode = VIDEO_MODES.get(al, f'{al:02X}h' if al is not None else '?')
                return f'BIOS Video: Set mode ({mode})'
            if ah == 0x0B:
                bh = regs.get('bh')
                if bh is None and 'bx' in regs:
                    bh = (regs['bx'] >> 8) & 0xFF
                if bh == 0x00:
                    return 'BIOS Video: Set background/border color'
                elif bh == 0x01:
                    bl = regs.get('bl')
                    if bl is None and 'bx' in regs:
                        bl = regs['bx'] & 0xFF
                    pal = f' (palette {bl})' if bl is not None else ''
                    return f'BIOS Video: Set CGA palette{pal}'
                return 'BIOS Video: Set palette'
            desc = INT10H_DESC.get(ah)
            if desc:
                return f'BIOS Video: {desc}'
            if ah is not None:
                return f'BIOS Video: AH={ah:02X}h'
            return 'BIOS Video'

        if int_num == 0x1A:
            ah = regs.get('ah')
            desc = INT1AH_DESC.get(ah)
            if desc:
                return f'BIOS Timer: {desc}'
            if ah is not None:
                return f'BIOS Timer: AH={ah:02X}h'
            return 'BIOS Timer'

    # --- OUT port, AL (immediate port) ---
    m = re.match(r'out\s+0x([0-9a-fA-F]+),\s*al', s)
    if m:
        port = int(m.group(1), 16)
        return _port_annotation(port, 'out', regs)

    # --- OUT DX, AL ---
    if re.match(r'out\s+dx,\s*al', s):
        dx = regs.get('dx')
        if dx is not None:
            return _port_annotation(dx, 'out', regs)
        return 'Write to port [DX]'

    # --- IN AL, port (immediate port) ---
    m = re.match(r'in\s+al,\s*0x([0-9a-fA-F]+)', s)
    if m:
        port = int(m.group(1), 16)
        return _port_annotation(port, 'in', regs)

    # --- IN AL, DX ---
    if re.match(r'in\s+al,\s*dx', s):
        dx = regs.get('dx')
        if dx is not None:
            return _port_annotation(dx, 'in', regs)
        return 'Read from port [DX]'

    return None


def _port_annotation(port, direction, regs):
    """Generate annotation for a specific I/O port access."""
    al = regs.get('al')

    if port == 0x40:
        return 'PIT Ch0: read counter value'
    if port == 0x42:
        if direction == 'out':
            return 'PIT Ch2: speaker frequency data'
        return 'PIT Ch2: read counter'
    if port == 0x43:
        if direction == 'out':
            desc = PIT_CTRL_DESC.get(al)
            if desc:
                return f'PIT: control word ({desc})'
            return 'PIT: control word'
        return 'PIT: read control'
    if port == 0x61:
        if direction == 'out':
            return 'Speaker control (bits 0-1: gate/enable)'
        return 'Read speaker/system status'
    if port == 0x201:
        if direction == 'out':
            return 'Joystick: trigger one-shot'
        return 'Joystick: read button/axis status'
    if port == 0x3D9:
        if direction == 'out':
            if al is not None:
                return f'CGA: color select (AL={al:02X}h)'
            return 'CGA: color select register'
        return 'CGA: read color select'
    if port == 0x3DA:
        if direction == 'in':
            return 'CGA: read status (bit3=vsync)'
        return 'CGA: mode control'

    return f'Port {port:04X}h: {"write" if direction == "out" else "read"}'


def collect_dat_references(instr_map):
    """Collect all dat_XXXX offsets referenced in converted instructions."""
    refs = set()
    for offset, (end_off, nasm_str, raw_hex, mn, ops) in instr_map.items():
        if nasm_str:
            for m in re.finditer(r'dat_([0-9a-f]{4})', nasm_str):
                refs.add(int(m.group(1), 16))
    return refs


def find_instruction_for_cs_offset(cs_off, instr_map):
    """Find the instruction start offset that contains the given CS offset."""
    for start, (end, _, _, _, _) in instr_map.items():
        if start <= cs_off < end:
            return start
    return None


def find_mismatch_instructions(exe_bytes, rebuilt_bytes, instr_map):
    """Find CS offsets of instructions that produced wrong bytes."""
    bad_offsets = set()

    if len(rebuilt_bytes) == len(exe_bytes):
        # Same size: find ALL mismatching instructions
        for i in range(len(exe_bytes)):
            if rebuilt_bytes[i] != exe_bytes[i]:
                if i >= CODE_FILE_OFFSET:
                    cs_off = i - CODE_FILE_OFFSET
                    start = find_instruction_for_cs_offset(cs_off, instr_map)
                    if start is not None:
                        bad_offsets.add(start)
                else:
                    # Mismatch outside code section - shouldn't happen
                    print(f"  WARNING: mismatch at file offset 0x{i:04x} (not in code section)")
    else:
        # Different size: find first mismatch only (cascade makes rest unreliable)
        min_len = min(len(rebuilt_bytes), len(exe_bytes))
        for i in range(min_len):
            if rebuilt_bytes[i] != exe_bytes[i]:
                if i >= CODE_FILE_OFFSET:
                    cs_off = i - CODE_FILE_OFFSET
                    start = find_instruction_for_cs_offset(cs_off, instr_map)
                    if start is not None:
                        bad_offsets.add(start)
                break
        if not bad_offsets:
            # Sizes differ but no byte mismatch found in common range
            # The shorter file is missing bytes at the end
            print(f"  Size mismatch: expected {len(exe_bytes)}, got {len(rebuilt_bytes)} "
                  f"(diff: {len(rebuilt_bytes) - len(exe_bytes)})")
    return bad_offsets


def handle_nasm_error(error_text, asm_file, instr_map, line_to_cs):
    """Parse NASM error, find the responsible instruction, return its CS offset."""
    # NASM errors look like: cat_tmp.asm:1234: error: ...
    m = re.search(r':(\d+):\s*error:', error_text)
    if m:
        line_num = int(m.group(1))
        if line_num in line_to_cs:
            return {line_to_cs[line_num]}
    return set()


def generate_nasm(exe_bytes, data_labels, data_strings, code_labels,
                  functions, code_instructions, code_data_bytes, output_file,
                  instr_map=None, force_db_offsets=None):
    """Generate the NASM assembly file.

    When force_db_offsets is None: all-db mode (original behavior).
    When force_db_offsets is a set: mnemonic mode, with those offsets forced to db.

    Returns line_to_cs: dict mapping line numbers to CS offsets (for mnemonic lines).
    """
    use_mnemonics = force_db_offsets is not None
    if force_db_offsets is None:
        force_db_offsets = set()
    if instr_map is None:
        instr_map = build_instruction_map(code_instructions)

    # Merge code labels
    all_code_labels = {}
    all_code_labels.update(code_labels)
    all_code_labels.update(functions)

    code_size = len(exe_bytes) - CODE_FILE_OFFSET
    code_bytes = exe_bytes[CODE_FILE_OFFSET:]
    data_bytes = exe_bytes[DATA_FILE_OFFSET:CODE_FILE_OFFSET]
    mz_header = exe_bytes[:MZ_HEADER_SIZE]

    # Build set of data byte offsets in code section
    data_offsets_in_code = set()
    for (offset, raw_hex) in code_data_bytes:
        byte_count = len(raw_hex) // 2
        for j in range(byte_count):
            data_offsets_in_code.add(offset + j)

    # Collect dat_ references for EQU definitions
    dat_refs = collect_dat_references(instr_map) if use_mnemonics else set()
    # Also include all data_labels
    for off in data_labels:
        dat_refs.add(off)

    line_to_cs = {}  # line_number -> cs_offset for mnemonic lines
    line_num = 0

    with open(output_file, 'w') as f:
        def wl(text):
            nonlocal line_num
            f.write(text + '\n')
            line_num += 1

        wl('; ============================================================')
        wl('; AlleyCat (1984) - Reconstructed NASM source')
        wl('; Original: cat.exe (55,067 bytes)')
        wl('; Assemble: nasm -f bin -o cat_rebuilt.exe cat.asm')
        wl('; ============================================================')
        wl('')

        # EQU definitions for data labels (only in mnemonic mode)
        if use_mnemonics and dat_refs:
            wl('; === Data Label Definitions ===')
            for off in sorted(dat_refs):
                name = data_labels.get(off, f'dat_{off:04x}')
                wl(f'{name} equ 0x{off:04x}')
            wl('')

        # MZ Header (raw bytes)
        wl('; === MZ EXE Header (512 bytes) ===')
        wl('; CS:IP=0723:0000  SS:SP=0000:0100  9 relocations')
        for row_start in range(0, MZ_HEADER_SIZE, 16):
            row_bytes = mz_header[row_start:row_start + 16]
            hex_str = ', '.join(f'0x{b:02x}' for b in row_bytes)
            wl(f'    db {hex_str}')
        wl('')

        # Stack area
        wl('; === Stack (256 bytes at start of load image) ===')
        wl('    times 0x100 db 0')
        wl('')

        # Data Segment
        wl('; === Data Segment (0x7130 bytes, DS = load_base + 0x10) ===')
        all_strings = dict(data_strings)
        i = 0
        while i < DATA_SIZE:
            if i in data_labels:
                wl(f'; {data_labels[i]}: (DS:0x{i:04x})')

            run_end = i + 1
            while run_end < DATA_SIZE and run_end not in data_labels:
                run_end += 1

            pos = i
            while pos < run_end:
                chunk = min(16, run_end - pos)
                for str_off in range(pos, pos + chunk):
                    if str_off in all_strings:
                        wl(f'; STRING @ 0x{str_off:04x}: "{all_strings[str_off]}"')
                byte_vals = data_bytes[pos:pos + chunk]
                hex_str = ', '.join(f'0x{b:02x}' for b in byte_vals)
                ascii_str = ''.join(
                    chr(b) if (0x20 <= b <= 0x7e and b != 0x5c) else '.'
                    for b in byte_vals
                )
                pad = max(1, 72 - 4 - len(hex_str) - 3)
                wl(f'    db {hex_str}{" " * pad}; {ascii_str}')
                pos += chunk
            i = run_end
        wl('')

        # Code Segment
        wl('; === Code Segment (CS = load_base + 0x723) ===')
        wl(f'; Size: 0x{code_size:04X} bytes')
        wl('')

        mnemonic_count = 0
        db_count = 0
        regs = {}  # Track register values for IO annotation

        cs_offset = 0
        while cs_offset < code_size:
            # Labels
            if cs_offset in all_code_labels:
                label = all_code_labels[cs_offset]
                if cs_offset in functions:
                    wl(f'\n; --- {functions[cs_offset]} ---')
                    regs = {}  # Reset tracking at function boundaries
                wl(f'{label}:')

            if cs_offset in instr_map:
                end_off, nasm_str, raw_hex, orig_mn, orig_ops = instr_map[cs_offset]
                raw_from_file = code_bytes[cs_offset:end_off]

                # Decide: mnemonic or db?
                emit_mnemonic = (use_mnemonics
                                 and nasm_str is not None
                                 and cs_offset not in force_db_offsets)

                if emit_mnemonic:
                    line_to_cs[line_num + 1] = cs_offset  # +1 because wl increments after
                    annotation = get_io_annotation(nasm_str, regs)
                    if annotation:
                        pad = max(1, 40 - 4 - len(nasm_str))
                        wl(f'    {nasm_str}{" " * pad}; {annotation}')
                    else:
                        wl(f'    {nasm_str}')
                    track_registers(regs, nasm_str)
                    mnemonic_count += 1
                else:
                    # Emit as db with mnemonic comment
                    hex_db = ', '.join(f'0x{b:02x}' for b in raw_from_file)
                    effective = nasm_str if nasm_str else f'{orig_mn.lower()} {orig_ops.lower()}'
                    comment = nasm_str if nasm_str else f'{orig_mn} {orig_ops}'
                    annotation = get_io_annotation(effective, regs)
                    if annotation:
                        comment = f'{comment}  -- {annotation}'
                    pad = max(1, 40 - 4 - len(hex_db) - 3)
                    wl(f'    db {hex_db}{" " * pad}; {comment}')
                    track_registers(regs, effective)
                    db_count += 1

                cs_offset = end_off

            elif cs_offset in data_offsets_in_code:
                run_start = cs_offset
                while cs_offset < code_size and cs_offset in data_offsets_in_code:
                    cs_offset += 1
                pos = run_start
                while pos < cs_offset:
                    chunk = min(16, cs_offset - pos)
                    byte_vals = code_bytes[pos:pos + chunk]
                    hex_str = ', '.join(f'0x{b:02x}' for b in byte_vals)
                    wl(f'    db {hex_str}')
                    pos += chunk
            else:
                b = code_bytes[cs_offset]
                wl(f'    db 0x{b:02x}  ; {cs_offset:04x}')
                cs_offset += 1

        wl('\n; === End ===')

    return line_to_cs, mnemonic_count, db_count


def iterative_convert(exe_file, ghidra_file, output_file):
    """Iteratively convert instructions to mnemonics, fixing mismatches."""
    exe_bytes = read_binary(exe_file)
    print(f"  File size: {len(exe_bytes)} bytes")

    print(f"Parsing Ghidra listing: {ghidra_file}")
    (data_labels, data_strings, code_labels, functions,
     code_instructions, code_data_bytes) = parse_ghidra_listing(ghidra_file)

    print(f"  Data labels: {len(data_labels)}")
    print(f"  Code labels: {len(code_labels)}")
    print(f"  Functions: {len(functions)}")
    print(f"  Instructions: {len(code_instructions)}")
    print(f"  Data bytes in code: {len(code_data_bytes)}")

    instr_map = build_instruction_map(code_instructions)

    # Count conversion failures
    convert_fails = sum(1 for v in instr_map.values() if v[1] is None)
    print(f"  Conversion failures (always db): {convert_fails}")

    # Pre-detect instructions where NASM uses shorter encodings
    size_ambig = detect_size_ambiguities(instr_map)
    print(f"  Size ambiguities pre-detected: {len(size_ambig)}")

    force_db = set(size_ambig)
    tmp_asm = output_file + '.tmp'
    tmp_exe = output_file + '.tmpexe'

    for iteration in range(50):
        line_to_cs, mn_count, db_count = generate_nasm(
            exe_bytes, data_labels, data_strings, code_labels,
            functions, code_instructions, code_data_bytes, tmp_asm,
            instr_map=instr_map, force_db_offsets=force_db
        )

        # Assemble
        result = subprocess.run(
            ['nasm', '-f', 'bin', '-o', tmp_exe, tmp_asm],
            capture_output=True, text=True
        )

        if result.returncode != 0:
            # NASM syntax error - find responsible instruction
            bad = handle_nasm_error(result.stderr, tmp_asm, instr_map, line_to_cs)
            if bad:
                force_db.update(bad)
                err_line = result.stderr.strip().split('\n')[0]
                print(f"  Iter {iteration}: NASM error, reverted {len(bad)} instruction(s): {err_line}")
                continue
            else:
                print(f"  NASM error (can't identify instruction):\n{result.stderr}")
                break

        rebuilt_bytes = read_binary(tmp_exe)

        if rebuilt_bytes == exe_bytes:
            # Success! Copy to final output
            os.replace(tmp_asm, output_file)
            if os.path.exists(tmp_exe):
                os.remove(tmp_exe)
            print(f"\n  IDENTICAL after {iteration} iteration(s)!")
            print(f"  Mnemonics: {mn_count}, Forced db: {db_count} "
                  f"(of which {convert_fails} unconvertible, {len(force_db)} encoding mismatches)")
            return True

        # Find mismatching instructions
        bad = find_mismatch_instructions(exe_bytes, rebuilt_bytes, instr_map)
        if not bad:
            print(f"  Mismatch but can't identify instructions (size diff: "
                  f"{len(rebuilt_bytes) - len(exe_bytes)})")
            break

        force_db.update(bad)
        size_diff = len(rebuilt_bytes) - len(exe_bytes)
        print(f"  Iter {iteration}: reverted {len(bad)} instruction(s), "
              f"total force_db: {len(force_db)}, size diff: {size_diff}")

    # Clean up
    for f in [tmp_asm, tmp_exe]:
        if os.path.exists(f):
            os.remove(f)
    return False


def main():
    print("=== AlleyCat Ghidra-to-NASM Converter ===")

    exe_file = 'cat.exe'
    ghidra_file = 'cat.txt'
    output_file = 'cat.asm'

    print(f"Reading binary: {exe_file}")
    success = iterative_convert(exe_file, ghidra_file, output_file)

    if success:
        print(f"\nTo assemble: nasm -f bin -o cat_rebuilt.exe {output_file}")
        print("To verify:   cmp cat.exe cat_rebuilt.exe")
    else:
        print("\nConversion did not converge. Check output for details.")


if __name__ == '__main__':
    main()

#!/usr/bin/python
"""find neon instructions in given so"""

import sys
import re

NEON_VALID = 0
NEON_INVALID_ILLEGAL = 1
NEON_INVALID_DATA = 2

def find_neon_instrs(asm_file, print_detail=False):
    """function to find neon inst"""
    all_neon_insts = {}
    neon_list = []
    ldr_lit_insts = {}
    found_neon_inst = False
    neon_inst_addr = 0
    neo = 0
    content = open(asm_file, 'r')
    for line in content.readlines():
        inst_line = line.strip()
        m = re.match(r'(^[    /w+])',line)
        if m:
            neo +=1
        if not is_arm_inst(inst_line):
            #found non-inst line
            if found_neon_inst:
                if is_neon_insts_illegal(neon_list):
                    all_neon_insts[neon_inst_addr] = [neon_list[:], 
                                                      NEON_INVALID_ILLEGAL]
                else:
                    all_neon_insts[neon_inst_addr] = [neon_list[:], 
                                                      NEON_VALID]
                neon_list = []
                neon_inst_addr = 0
                found_neon_inst = False
            continue
        if is_ldr_lit(inst_line):
            addr = parse_ldr_lit(inst_line)
            if addr in ldr_lit_insts:
                ldr_lit_insts[addr].append(inst_line)
            else:
                ldr_lit_insts[addr] = [inst_line]
        if is_neon_inst(inst_line):
            neon_list.append(inst_line)
            if not found_neon_inst:
                found_neon_inst = True
                neon_inst_addr = get_inst_addr(inst_line)
        else:
            if found_neon_inst:
                if is_neon_insts_illegal(neon_list):
                    all_neon_insts[neon_inst_addr] = [neon_list[:], 
                                                      NEON_INVALID_ILLEGAL]
                else:
                    all_neon_insts[neon_inst_addr] = [neon_list[:], 
                                                      NEON_VALID]
                neon_list = []
                neon_inst_addr = 0
                found_neon_inst = False
    content.close()

    neon_addrs = all_neon_insts.keys()
    neon_addrs.sort()
    neon_range = []
    for addr in neon_addrs:
        if all_neon_insts[addr][1] is NEON_VALID:
            size = 4*len(all_neon_insts[addr][0])
            neon_range.append((addr-2, addr+size))
    ldr_dest = ldr_lit_insts.keys()
    ldr_dest.sort()
    ldr_idx = 0
    neon_idx = 0
    neon_data_log = {}
    while ldr_idx < len(ldr_dest) and neon_idx < len(neon_range):
        if ldr_dest[ldr_idx] < neon_range[neon_idx][0]:
            ldr_idx += 1
        elif ldr_dest[ldr_idx] >= neon_range[neon_idx][1]:
            neon_idx += 1
        else:
            neon_inst_addr = neon_range[neon_idx][0]+2
            if neon_inst_addr in neon_data_log:
                neon_data_log[neon_inst_addr].append(ldr_dest[ldr_idx])
            else:
                neon_data_log[neon_inst_addr] = [ldr_dest[ldr_idx]]
            all_neon_insts[neon_inst_addr][1] = NEON_INVALID_DATA
            ldr_idx += 1
    inst_op_dist = {}
    valid_insts = []
    tmp_valid_cnt1 = 0
    dup_cnt = 0
    log_invalid = False
    for addr in neon_addrs:
        if all_neon_insts[addr][1] is not NEON_VALID:
            log_invalid = True
            continue
        tmp_valid_cnt1 += len(all_neon_insts[addr][0])
        for neon_inst in all_neon_insts[addr][0]:
            inst_op, inst_hex, inst_addr = parse_inst(neon_inst)
            if len(valid_insts) is 0:
                valid_insts.append((inst_op, inst_hex, neon_inst))
            else:
                if valid_insts[-1][1] == inst_hex:
                    dup_cnt += 1
                    continue
                else:
                    valid_insts.append((inst_op, inst_hex, neon_inst))
            if inst_op not in inst_op_dist:
                inst_op_dist[inst_op] = [inst_hex]
            else:
                inst_op_dist[inst_op].append(inst_hex)

    log_name = asm_file[:asm_file.rfind('.')]
    num_neon_valid = 0
    num_neon_illegal = 0
    num_neon_data = 0

    #log valid inst
    if valid_insts:
        num_neon_valid = len(valid_insts)
        with open(log_name+'.neon.log', 'w') as log_neon:
            output = ['<NEON-INST> %s' % valid_entry[2] for valid_entry in valid_insts]
            log_neon.write('\n'.join(output))
    if tmp_valid_cnt1 != num_neon_valid + dup_cnt:
        pass
        '''
        print "[WARNING] valid_cnt(raw)=%d valid_cnt(no_dup)=%d cnt(dup)=%d" % (tmp_valid_cnt1,
                                                                                num_neon_valid,
                                                                                dup_cnt)
        '''

    #log invalid inst
    if log_invalid:
        log_neon_invalid = open(log_name+'.neon.invalid.log', 'w')
        for addr in neon_addrs:
            neon_insts = all_neon_insts[addr][0]
            inst_type = all_neon_insts[addr][1]
            if inst_type is NEON_VALID:
                continue
            elif inst_type is NEON_INVALID_ILLEGAL:
                num_neon_illegal += len(neon_insts)
                for inst in neon_insts:
                    log_neon_invalid.write('<NEON-ILLEGAL> %s\n' % inst)
            elif inst_type is NEON_INVALID_DATA:
                num_neon_data += len(neon_insts)
        for addr in neon_data_log.keys():
            for ldr_addr in neon_data_log[addr]:
                log_neon_invalid.write('<INST-LDR>     %s\n' % ldr_lit_insts[ldr_addr][0])
            for inst in all_neon_insts[addr][0]:
                log_neon_invalid.write('<NEON-DATA>    %s\n' % inst)
        log_neon_invalid.close()

    tmp_valid_cnt2 = 0
    ret_op_dist = {}
    if inst_op_dist:
        for inst_op in inst_op_dist.keys():
            ret_op_dist[inst_op] = len(inst_op_dist[inst_op])
            tmp_valid_cnt2 += len(inst_op_dist[inst_op])
    if tmp_valid_cnt2 != num_neon_valid:
        pass
        #print "[WARNING] valid_cnt(no_dup)=%d valid_cnt(op)=%d" % (tmp_valid_cnt2, num_neon_valid)      

    #print "[LOG] INPUT:        %s" % asm_file
    if print_detail:
        pass
        #print "[LOG] NEON-DUP-VALID:   %d" % (tmp_valid_cnt1)
    if num_neon_valid > 0:
        pass
        #print "[LOG] NEON-VALID:   %d" % (num_neon_valid)
    if num_neon_illegal + num_neon_data > 0:
        pass
        #print "[LOG] NEON-INVALID: %d" % (num_neon_illegal+num_neon_data)
    return neo, num_neon_valid, num_neon_illegal+num_neon_data, ret_op_dist

def parse_inst(str_inst):
    """parse str inst and return (op, hex_inst, addr)"""
    sub_strs = str_inst.split()
    addr = sub_strs[0][:-1]
    if len(sub_strs[1]) is 4:
        #Thumb inst
        hex_inst = "%s %s" % (sub_strs[1], sub_strs[2])
        op = sub_strs[3][5:]
    elif len(sub_strs[1]) is 8:
        #ARM inst
        hex_inst = sub_strs[1]
        op = sub_strs[2][5:]
    else:
        pass
        #print "[WARNING] unhandled inst %s" % str_inst
    return op, hex_inst, addr

def is_neon_insts_illegal(insts):
    """check neon inst status"""
    is_illegal = False
    for inst in insts:
        if 'illegal' in inst:
            is_illegal = True
        if 'UNDEFINED' in inst:
            is_illegal = True
        if 'overflow' in inst:
            is_illegal = True
    return is_illegal

def get_inst_addr(str_line):
    """get inst addr"""
    idx = str_line.find(':')
    return int(str_line[:idx], 16)

def is_arm_inst(str_line):
    """check if is arm instruction"""
    if str_line:
        subs = str_line.split('\t')
        if len(subs) > 0 and subs[0][-1] == ':':
            return True
    return False

def is_ldr_lit(str_line):
    """check if is ldr(lit)"""
    if str_line:
        if "<UNPRE" in str_line or '[pc,' not in str_line:
            return False
        subs = str_line.split('\t')
        if len(subs) > 3 and subs[2].startswith('ldr'):
            tmp_ops = subs[3].split(',')
            if len(tmp_ops) is 3:
                rest = tmp_ops[2].strip()
                if rest[0] == '#' and rest[1:-1].isdigit():
                    return True
    return False

def is_neon_inst(str_line):
    """check if is neon inst"""
    if str_line:
        if 'neon.' in str_line:
            return True
    return False

def parse_ldr_lit(str_line):
    """parse inst ldr(lit)"""
    addr = 0
    semicolon_idx = str_line.find(';')
    if semicolon_idx > 0:
        str_addr = str_line[semicolon_idx+1:].strip().split()[0]
        if str_addr.startswith('('):
            addr = int(str_addr[1:], 16)
        else:
            addr = int(str_addr, 16)
    return addr

def main():
    """find neon instruction in given file"""
    if len(sys.argv) is 1:
        print "usage: %s [asm-files]" % sys.argv[0]
        sys.exit(0)
    asm_files = sys.argv[1:]
    total_valid = 0
    total_invalid = 0
    for asm_file in asm_files:
        inst_total, valid_num, invalid_num, op_dist = find_neon_instrs(asm_file)
        total_valid += valid_num
        total_invalid += invalid_num
        op_dist_cnt = 0
        for inst_op, op_cnt in op_dist:
            op_dist_cnt += op_cnt
        if valid_num != op_dist_cnt:
            pass
            #print "[WARNING] valid_num %d op_dist_cnt %d" % (valid_num, op_dist_cnt)
    #print "[RESULT] NEON.Valid   NEON.Invalid"
    #print "[RESULT] %-12d %-12d" % (total_valid, total_invalid) 


if __name__ == '__main__':
    main()

#!/usr/bin/python

import subprocess
import os
import sys
from find_neon_inst import find_neon_instrs

def dump_to_asm(path, file):
    cmd = ['./objdump','-d', path+'/'+file ]
    filename = os.path.join(path, file)
    outfile = filename.replace(".so",".asm")
    ret = execCMD(cmd, outfile)

    return outfile

def execCMD(cmd, outfile):
    out = open(outfile, 'w')
    proc = subprocess.Popen(cmd, stdout=out)
    proc.wait()
    out.close()
    return proc.returncode

def dump_so():
    for path in os.listdir("."):
        for parent,dirnames,filenames in os.walk(path):
            for filename in filenames:
                if filename.endswith(".so"):
                    pass
                    #print dump_to_asm(parent,filename)

def find_neon():
    Statistics = []
    num = 0
    all_op_dist = []
    total_inst = {}
    for path in os.listdir("."):
        if os.path.isdir(path) and path.endswith("-1.apk"):
            num += 1
            apk_total_valid = 0
            apk_total_invalid = 0
            asm = 0
            apk_total_inst = 0
            for parent,dirnames,filenames in os.walk(path):
                for filename in filenames:
                    asm_total_valid = 0
                    asm_total_invalid = 0
                    if filename.endswith(".asm"):
                        asm = 1
                        asm_total_inst, valid_num, invalid_num, op_dist = find_neon_instrs(os.path.join(parent,filename))
                        asm_total_valid += valid_num
                        asm_total_invalid += invalid_num
                        apk_total_valid += valid_num
                        apk_total_invalid += invalid_num
                        apk_total_inst += asm_total_inst
                        if op_dist:
                            for op in op_dist.keys():
                                if op not in total_inst:
                                    total_inst[op] = op_dist[op]
                                else:
                                    total_inst[op] += op_dist[op]
                            tmp_idx = parent.find('apk')
                            if tmp_idx > 0:
                                apkname = parent[:tmp_idx - 1]
                            else:
                                apkname = parent
                            all_op_dist.append(('%s(%s)' % (apkname, filename[:-4]), op_dist))
            if asm == 1:
                print "No. %d =======[ %s ] NEON: %d ,NEON.Invalid: %d ,Total inst: %d ======" % (num, path, apk_total_valid, apk_total_invalid, apk_total_inst)
                tmp_l = []
                tmp_l.append(path)
                tmp_l.append(apk_total_valid)
                tmp_l.append(apk_total_invalid)
                tmp_l.append(apk_total_inst)
                Statistics.append(tmp_l)
                with open("Statistics.csv","aw") as fp:
                    fp.write(path + "," + str(apk_total_valid) + "," + str(apk_total_invalid) + "," + str(apk_total_inst) + "\n")
    all_ops = total_inst.keys()
    all_ops.sort()
    all_op_dist.append(("total", total_inst))
    csv_dist = ["lib," + ",".join(all_ops)]
    for line in all_op_dist:
        csv_line = [line[0]]
        for inst_op in all_ops:
            if inst_op in line[1]:
                csv_line.append(str(line[1][inst_op]))
            else:
                csv_line.append('0')
        csv_dist.append(",".join(csv_line))
    with open('result.hisgraph.csv', 'w') as log_op_dist:
        log_op_dist.write("\n".join(csv_dist))

    return Statistics

def write_to_db(host,db_user,db_pwd,db_name,statistic):
    import MySQLdb as mydb
    try:
        conn = mydb.connect(host,db_user,db_pwd,db_name);
        cur = conn.cursor()
        cur.execute("select version()")
        version = cur.fetchone()
    except mydb.Error,e:
        print "Error %d:    %s" %(e.args[0],e.args[1])
        sys.exit(-1)

    for apk in statistic:
        apk_name = apk[0]
        neon = str(apk[1])
        neon_inval = str(apk[2])
        total = str(apk[3])
        sql = "update apk set neon_inst_num = " +neon+ ", neon_invalid_num = " +neon_inval+ ", total_inst_num = " +total+" where pkg_name = '" +apk_name+ "'"
        cur.execute(sql)
        conn.commit()


def main():
    write_to_db(sys.argv[1],sys.argv[2],sys.argv[3],sys.argv[4],find_neon())

if __name__ == '__main__':
    main()

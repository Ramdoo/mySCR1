import re
import sys, getopt

infile  = None
outfile = None
start_pc = 0x00000

argv = sys.argv[1:]
try:
    opts, args = getopt.getopt(argv, "i:o:")  
except:
    print("Error")
for opt, arg in opts:
    if opt in ['-i']:
        infile = arg
    elif opt in ['-o']:
        outfile = arg
 
# print(infile + " " + outfile)

file_input = open(infile, mode='r')
file_output = open(outfile, mode='w')

lines_input = file_input.readlines()
lines_output = []

for i in lines_input:
    if re.match('^@[0-9A-Fa-f]{8}$', i):
        m = re.match('^@([0-9A-Fa-f]{8})$', i)
        addr_8 = int(str(m.group(1)), 16)
        addr_32 = int((addr_8-start_pc) / 4)
        addr_32_hex = "{0:08X}".format(addr_32)
        # print(addr_32_hex)
        lines_output.append("@" + addr_32_hex + "\n")
    elif re.match('^([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2})', i):
        m = re.match('^([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2})', i)
        lines_output.append(str(m.group(4)) + str(m.group(3)) + str(m.group(2)) + str(m.group(1)) + '\n')
        lines_output.append(str(m.group(8)) + str(m.group(7)) + str(m.group(6)) + str(m.group(5)) + '\n')
        lines_output.append(str(m.group(12)) + str(m.group(11)) + str(m.group(10)) + str(m.group(9)) + '\n')
        lines_output.append(str(m.group(16)) + str(m.group(15)) + str(m.group(14)) + str(m.group(13)) + '\n')
    elif re.match('^([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2})', i):
        m = re.match('^([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2})', i)
        lines_output.append(str(m.group(4)) + str(m.group(3)) + str(m.group(2)) + str(m.group(1)) + '\n')
        lines_output.append(str(m.group(8)) + str(m.group(7)) + str(m.group(6)) + str(m.group(5)) + '\n')
        lines_output.append(str(m.group(12)) + str(m.group(11)) + str(m.group(10)) + str(m.group(9)) + '\n')  
    elif re.match('^([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2})', i):
        m = re.match('^([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2})', i)
        lines_output.append(str(m.group(4)) + str(m.group(3)) + str(m.group(2)) + str(m.group(1)) + '\n')
        lines_output.append(str(m.group(8)) + str(m.group(7)) + str(m.group(6)) + str(m.group(5)) + '\n')
    elif re.match('^([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2})', i):
        m = re.match('^([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2})', i)
        lines_output.append(str(m.group(4)) + str(m.group(3)) + str(m.group(2)) + str(m.group(1)) + '\n')
    else:
        print("error")
file_output.writelines(lines_output)

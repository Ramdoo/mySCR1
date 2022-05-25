import re, os
import sys, getopt

filepath_current = "./test_info"

with open(filepath_current, 'r+', encoding='utf-8') as file_read:
  while True:
    lines = file_read.readline()
    if not lines:
      break;
    if re.match('^.*.hex', lines):
      regular = re.findall(r"(.+?).hex",lines)
      print(regular[0])
      filein  = regular[0] + '.hex'
      fileout = regular[0] + '.mem'
      cmd     = 'python3 hex2mem_32.py -i ' + filein + ' -o ./mem/' + fileout
      os.system(cmd)


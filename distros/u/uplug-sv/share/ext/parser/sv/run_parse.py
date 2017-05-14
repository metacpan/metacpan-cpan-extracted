#!/usr/bin/python -O
# -*- coding: ISO-8859-1 -*-

#  Beata Megyesi
#  bea@speech.kth.se
#  Centre for Speech Technology, 
#  KTH, Stockholm, Sweden
#
#  Copyright (c) Beata Megyesi
#  
#  Permission is hereby granted, free of charge, to any person obtaining
#  a copy of this program and associated documentation files to deal in 
#  the program including the rights to use, modify, 
#  and merge of the program, and to permit persons to whom the program is 
#  furnished to do so, subject to the following conditions:
#  
#  The above copyright notice and this permission notice shall be
#  included in all copies or substantial portions of the program.
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
#  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
#  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
#  CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
#  TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
#  SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# './run_parse.py 12 423 infile.txt outfile.txt'
# will parse 423 lines (beginning with line 12) from 'infile.txt'
# and write the output to the file 'outfile.txt'
# If the first number (12 in this case) is outside the range,
# it will be set to 1. If the second number (423 in this case)
# is to large or if it is <= 0, the rest of 'infile.txt' will
# be read.

from sys import argv, exit, stdout
from os import popen
from string import split
from getopt import getopt

_BLOCK_SIZE = 100

def usage():
    print """\
  usage: 
    ./run_parse.py <option> [<first line no> <number of lines> <in-file> <out-file>]
    
      where <option> is one of:

      -t : tagged parse tree representation
      -p : parenthesised parse-tree representation
      -i : indented parse-tree representation
      -d : postscript picture of parse-tree (assumes that the graphviz
           package has been installed; ignores the value of the <number of lines>
           parameter)
      -r : lexical regular expressions and context free rules (no arguments needed,
           output directed to stdout)\
    
""",

try:
    optlist, args = getopt(argv[1:], 'tpidr')
except:
    usage()
    exit(2)

if len(optlist) != 1:
    usage()
    exit(2)

opt = optlist[0][0]

if len(args) == 0 and opt == "-r":
    res = popen("/usr/bin/python2 -O parse.py -r")
    stdout.write(res.read())
    exit(0)

if len(args) != 4 or opt == "-r":
    usage()
    exit(2)
        

start = int(args[0])
lines_to_read = int(args[1])

in_file = open(args[2])
in_file_len = len(split(in_file.read(), "\n"))
in_file.close()

if start < 1 or start > in_file_len:
    start = 1
if lines_to_read < 1 or lines_to_read > in_file_len - start + 1:
    lines_to_read = in_file_len - start + 1
if opt == "-d":
    lines_to_read = 1

out_file = open(args[3], "w")

blocks = lines_to_read / _BLOCK_SIZE
rest = lines_to_read % _BLOCK_SIZE

for i in xrange(blocks):
    res = popen("/usr/bin/python -O parse.py %s %d %d <" % (opt, start, _BLOCK_SIZE) + args[2])
    out_file.write(res.read())
    res.close()
    start = start + _BLOCK_SIZE

if rest:
    res = popen("/usr/bin/python -O parse.py %s %d %d <" % (opt, start, rest) + args[2])
    out_file.write(res.read())
    res.close()

out_file.close()



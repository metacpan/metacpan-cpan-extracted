#!/usr/bin/bash
#
# Name: read.write.tree.sh.
#
# Parameters:
# 1: The abbreviated name of sample input and output data files.
#	E.g. xyz simultaneously means read some_dir/xyz.tree and write some_dir/xyz.tree.out.
# 2 .. 5: Use for anything. E.g.: -maxlevel debug.

perl -Ilib scripts/read.write.tree.pl $1 $2 $3 $4

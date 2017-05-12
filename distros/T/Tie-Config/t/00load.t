#!/usr/bin/perl -w

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use Tie::Config;

$loaded = 1;
print "ok 1\n";

open(FILE,"> t/foo.txt");
print FILE <<EOM;
# comment
real = value
; another comment
second = param


numeric = 1
file = huhla.file
space = space at end  
nula = 0
EOM

print "ok 2\n";

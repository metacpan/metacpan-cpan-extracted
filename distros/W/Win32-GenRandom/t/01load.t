use strict;
use warnings;
use Win32::GenRandom;

print "1..1\n";

if($Win32::GenRandom::VERSION eq '0.04') {print "ok 1\n"}
else {
  warn "\$Win32::GenRandom::VERSION: $Win32::GenRandom::VERSION\n";
  print "not ok 1\n";
}

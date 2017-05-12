
require 5;
# -*-Perl-*-
use strict;  # Time-stamp: "2002-02-07 02:15:27 MST"
use Test;
BEGIN {
  plan 'tests' => 16;
  unshift @INC, ($MacPerl::Version && $MacPerl::Version)? ":t:testlibs" : 't/testlibs'
}

sub ::who_i_be {
  printf "# Loading package %s from file %s\n", (caller(0))[0,1];
  return;
}

print "# Running perl $] on $^O\n";
print "# \@INC:\n", map("#  $_\n", @INC), "# [end]\n";


#eval { strict::ModuleName->import };  ok($@, '');


eval 'require strict::ModuleName;' ;ok($@, ''); print "\n";


eval 'use _SMB1;'                 ;ok($@, ''); print "\n";
eval 'use _SMB1::Thing;'          ;ok($@, ''); print "\n";
eval 'use _SMB1::Dodad::Hoozits;' ;ok($@, ''); print "\n";

eval 'use _SMB2;'                 ;ok($@, ''); print "\n";
eval 'use _SMB2::Thing;'          ;ok($@, ''); print "\n";
eval 'use _SMB2::Dodad::Hoozits;' ;ok($@, ''); print "\n";


eval 'use _SMB3;'                 ;ok($@, '/./'); print "\n";
eval 'use _SMB4;'                 ;ok($@, '/./'); print "\n";
eval 'use _SMB5;'                 ;ok($@, '/./'); print "\n";
eval 'use _SMB6;'                 ;ok($@, '/./'); print "\n";

eval 'use _SMB7::Thing2;'         ;ok($@, '/./'); print "\n";
eval 'use _SMB7::Thing3;'         ;ok($@, '/./'); print "\n";
eval 'use _SMB7::Thing4;'         ;ok($@, '/./'); print "\n";
eval 'use _SMB7::Thing5;'         ;ok($@, '/./'); print "\n";
eval 'use _SMB7::Thing6;'         ;ok($@, '/./'); print "\n";


print "# Byebye\n";
exit;



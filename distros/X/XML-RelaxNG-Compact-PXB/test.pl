use strict;
use warnings;
use FindBin qw($Bin);   
BEGIN {
   unshift @INC, "$Bin/blib/lib" ; 
   unshift @INC, "$Bin/t/data";  
};
#
#  for those Test::Harness lovers out there
#
use Test::Harness;
  
 
 

if ($ARGV[0] && $ARGV[0] eq '-v') {
  $Test::Harness::Verbose = 1;
  shift @ARGV;
}

my $test_dir =  $Bin . '/t';
Test::Harness::runtests(<$test_dir/*.t>);
Test::Harness::runtests(<$test_dir/data/t/*.t>);

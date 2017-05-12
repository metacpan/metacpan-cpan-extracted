#!
#
# interactive test script: run all tests from .\t
# in interactive mode
use strict;
use warnings;

foreach my $script (<t/*.t>){
  $ENV{INTERACTIVE_MODE} = 1;
  $ENV{PERL5LIB} = "./lib";
  system "perl $script";
}

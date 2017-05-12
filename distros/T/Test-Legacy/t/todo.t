# -*-perl-*-
use strict;
use Test::Legacy qw(:DEFAULT $TESTOUT $TESTERR $ntest);

local $ENV{HARNESS_ACTIVE} = 0;

### This test is crafted in such a way as to prevent Test::Harness from
### seeing the todo tests, otherwise you get people sending in bug reports
### about Test.pm having "UNEXPECTEDLY SUCCEEDED" tests.

open F, ">todo";
$TESTOUT = *F{IO};
$TESTERR = *F{IO};
my $tests = 5; 
plan tests => $tests, todo => [2..$tests]; 


#line 16
# tests to go to the output file
ok(1);
ok(1);
ok(0,1);
ok(0,1,"need more tuits");
ok(1,1);

close F;
$TESTOUT = *STDOUT{IO};
$TESTERR = *STDERR{IO};
$ntest = 1;

open F, "todo";
my $out = join '', <F>;
close F;
unlink "todo";

my $expect = <<"EXPECT";
1..5
ok 1
ok 2 # TODO set in plan, $0 at line 18
not ok 3 # TODO set in plan, $0 at line 19
#     Failed (TODO) test ($0 at line 19)
#          got: '0'
#     expected: '1'
not ok 4 # TODO set in plan, $0 at line 20
#     Failed (TODO) test ($0 at line 20)
#          got: '0'
#     expected: '1'
ok 5 # TODO set in plan, $0 at line 21
EXPECT


sub commentless {
  my $in = $_[0];
  $in =~ s/^#[^\n]*\n//mg;
  $in =~ s/\n#[^\n]*$//mg;
  return $in;
}


Test::Builder->new->reset;
plan tests => 1;
ok( commentless($out), commentless($expect) );

# -*-perl-*-
use strict;
use Test::Legacy qw(:DEFAULT $TESTOUT $TESTERR $ntest);

local $ENV{HARNESS_ACTIVE} = 0;

### This test is crafted in such a way as to prevent Test::Harness from
### seeing the todo tests, otherwise you get people sending in bug reports
### about Test.pm having "UNEXPECTEDLY SUCCEEDED" tests.

open F, ">mix";
$TESTOUT = *F{IO};
$TESTERR = *F{IO};

plan tests => 4, todo => [2,3];

# line 16
ok(sub { 
       my $r = 0;
       for (my $x=0; $x < 10; $x++) {
	   $r += $x*($r+1);
       }
       $r
   }, 3628799);

ok(0);
ok(1);

skip(1,0);

close F;
$TESTOUT = *STDOUT{IO};
$TESTERR = *STDERR{IO};
$ntest = 1;

open F, "mix";
my $out = join '', <F>;
close F;
unlink "mix";

my $expect = <<"EXPECT";
1..4
ok 1
not ok 2 # TODO set in plan, $0 at line 24
#     Failed (TODO) test ($0 at line 24)
ok 3 # TODO set in plan, $0 at line 25
ok 4 # skip
EXPECT


sub commentless {
  my $in = $_[0];

  $in =~ s/^#.*\n?//mg;

  return $in;
}


#line 61
Test::Builder->new->reset;
plan tests => 1;
ok( commentless($out), commentless($expect) );

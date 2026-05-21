#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Tie::OrderedHash;

# scalar %h goes through the SCALAR tie hook.  We return truthy iff
# non-empty (matches plain HV's documented behaviour after 5.25).

tie my %h, 'Tie::OrderedHash';
ok(!scalar %h, 'scalar %h: empty is falsy');

$h{a} = 1;
ok(scalar %h, 'scalar %h: non-empty is truthy');

$h{b} = 2;
$h{c} = 3;
ok(scalar %h, 'scalar %h: still truthy with multiple keys');

# Empty back out.
%h = ();
ok(!scalar %h, 'scalar %h: empty after CLEAR is falsy');

done_testing;

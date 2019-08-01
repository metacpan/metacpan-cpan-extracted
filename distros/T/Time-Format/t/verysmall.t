#!/perl

# Test for very small time values; i.e., numerically very close to zero.
# See bug 87484 in CPAN's RT bug tracker: https://rt.cpan.org/Ticket/Display.html?id=87484
#
# When Perl stringifies numbers that are very close to zero, it uses exponential notation
# (under the default numeric format); e.g. "2.3e-05".  A user encountered this problem
# when using a time value that was a result of some computations.

use strict;
use Test::More tests => 6;

## ----------------------------------------------------------------------------------
## Test for availability of certain modules.
my $tl_ok;
BEGIN {$tl_ok = eval ('use Time::Local; 1')}


## ----------------------------------------------------------------------------------
## Load our module.
BEGIN { $Time::Format::NOXS = 1 }
BEGIN { use_ok 'Time::Format', qw(%time) }


## ----------------------------------------------------------------------------------
## Begin tests.

# Millisecond and microsecond values are rounded down (truncated toward zero), not
# rounded.  Two reasons for this: One, so that the same time value displayed with
# milliseconds and with microseconds will have the most similarity (overlap).
# Thus, 0.48964 seconds will display
#    as 0.489 milliseconds               and NOT as  0.490 milliseconds
#    or 0.489640 microseconds                    and 0.489640 microseconds
# Two, so that a time value very close to 1 (say, 0.999877 seconds) won't round up
# to 1, which would mean more calculations.
#
# The extra trailing digits below ensure that the floating-point input time value
# will be slightly higher than the value we want.  If for example, on the "Input
# minimal float for %time" test, we used '0.001' exactly, on some architectures that
# would be represented internally as 0.000999999974blahblahblah or something.
# Truncating that would yield 000 for the millisecond result, which would erroneously
# fail the test.  See bug 130150 (https://rt.cpan.org/Ticket/Display.html?id=130150)

my $inp;
my $out;

$inp = '0';
$out = eval{ $time{'mm:ss.mmm',$inp} } || $@;
is $out, '00:00.000' => 'Input 0 for %time';

$inp = '0.00100001';
$out = eval{ $time{'mm:ss.mmm',$inp} } || $@;
is $out, '00:00.001' => 'Input minimal float for %time';

$inp = '0.0008';
$out = eval{ $time{'mm:ss.mmm',$inp} } || $@;
is $out, '00:00.000' => 'Input too-small float for %time';

$inp = 0.000023;
$out = eval{ $time{'mm:ss.mmm',$inp} } || $@;
is $out, '00:00.000' => 'Input small exp for %time (msec)';

$inp = 0.000023001;
$out = eval{ $time{'mm:ss.uuuuuu',$inp} } || $@;
is $out, '00:00.000023' => 'Input small exp for %time (usec)';

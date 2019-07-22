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

my $inp;
my $out;

$inp = '0';
$out = eval{ $time{'mm:ss.mmm',$inp} } || $@;
is $out, '00:00.000' => 'Input 0 for %time';

$inp = '0.001';
$out = eval{ $time{'mm:ss.mmm',$inp} } || $@;
is $out, '00:00.001' => 'Input minimal float for %time';

$inp = '0.0008';
$out = eval{ $time{'mm:ss.mmm',$inp} } || $@;
is $out, '00:00.000' => 'Input too-small float for %time';

$inp = 0.000023;
$out = eval{ $time{'mm:ss.mmm',$inp} } || $@;
is $out, '00:00.000' => 'Input small exp for %time (msec)';

$inp = 0.000023;
$out = eval{ $time{'mm:ss.uuuuuu',$inp} } || $@;
is $out, '00:00.000023' => 'Input small exp for %time (usec)';


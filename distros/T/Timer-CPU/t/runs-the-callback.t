use strict;

use Test::More tests => 2;

use Timer::CPU;

my $junk;

my $result = Timer::CPU::measure(sub {
  $junk = "works";
});

is($junk, 'works', 'ran the callback');
diag("elapsed: $result");
like($result, qr/^[\d.]+$/, 'got a number back');

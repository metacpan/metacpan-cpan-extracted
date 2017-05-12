use strict;
use warnings;


# These tests may occationally fail due to small timing differences.

use Test::More tests => 8;
{
    local $SIG{__WARN__} = sub {
	if ($_[0] =~ /Time::HiRes/) {
	    ok 1;
	} else {
	    warn $_[0];
	}
    };
    require Time::Warp;
}
Time::Warp->import(qw(time to scale));
ok 1;
is scale(), 1;

scale(2);
is &scale, 2;
my $now = &time;
sleep 2;
is(&time - $now, 4);

to(CORE::time);
is(&time - CORE::time, 0);

scale(scale() * 2);
is(&time - CORE::time, 0);

Time::Warp::reset(); to(&time + 5);
is(&time - CORE::time, 5);

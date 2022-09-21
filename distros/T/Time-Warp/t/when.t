use strict;
use warnings;


use Test::More tests => 8;
# Use an overloaded time() (e.g. by Time::HiRes), or CORE::time as a reference
# clock.
my $ref_time = (exists $main::{'time'}) ? $main::{'time'} : $CORE::{'time'};

{
    my $time_hires_warning_emitted;
    local $SIG{__WARN__} = sub {
	if ($_[0] =~ /Time::HiRes/) {
	    $time_hires_warning_emitted = 1;
	} else {
	    warn $_[0];
	}
    };
    require Time::Warp;
    ok ($time_hires_warning_emitted xor exists $INC{'Time/HiRes.pm'});
}

Time::Warp->import(qw(time to scale));
ok 1;
is scale(), 1;

# These tests may occationally fail due to small timing differences.
sub approx {
    my ($got, $expected) = @_;
    my $epsilon = 0.3 * scale();
    ok($got - $expected < $epsilon,
        "$got is approximately equivalent to $expected with a tolerance $epsilon");
}

scale(2);
is &scale, 2;
my $now = &time;
sleep 2;
approx(&time - $now, 4);

to(&$ref_time);
approx(&time - &$ref_time, 0);

scale(scale() * 2);
approx(&time - &$ref_time, 0);

Time::Warp::reset(); to(&time + 5);
approx(&time - &$ref_time, 5);

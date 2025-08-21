use strict;
use warnings;
use Test::More;
use Time::HiRes qw(clock_gettime);
use Time::Left;

# Test clock constant
subtest 'clock selection' => sub {
    my $clock = Time::Left::CLOCK;
    ok(defined $clock, 'CLOCK constant is defined');
    ok($clock >= 0, 'CLOCK is a non-negative integer');
    
    # Try to use the clock
    my $time = eval { clock_gettime($clock) };
    ok(defined $time, 'Selected clock is functional');
    ok($time > 0, 'Clock returns positive time');
    
    # Report which clock was selected
    my $clock_name = 'UNKNOWN';
    if (eval { $clock == Time::HiRes::CLOCK_MONOTONIC_RAW() }) {
        $clock_name = 'CLOCK_MONOTONIC_RAW';
    } elsif (eval { $clock == Time::HiRes::CLOCK_MONOTONIC() }) {
        $clock_name = 'CLOCK_MONOTONIC';
    } elsif (eval { $clock == Time::HiRes::CLOCK_REALTIME() }) {
        $clock_name = 'CLOCK_REALTIME';
    }
    diag("Using clock: $clock_name ($clock)");
};

# Test timer precision
subtest 'timer precision' => sub {
    my $timer = Time::Left->new(1);
    
    # Take multiple readings
    my @readings;
    for (1..5) {
        push @readings, $timer->remaining;
        select(undef, undef, undef, 0.01); # Small delay
    }
    
    # Check readings are decreasing
    my $ok = 1;
    for (my $i = 1; $i < @readings; $i++) {
        $ok = 0 if $readings[$i] >= $readings[$i-1];
    }
    ok($ok, 'Timer readings decrease over time');
    
    # Check precision
    my $delta = $readings[0] - $readings[-1];
    ok($delta > 0, 'Timer shows time passage');
    ok($delta < 1, 'Timer shows reasonable precision');
};

done_testing();

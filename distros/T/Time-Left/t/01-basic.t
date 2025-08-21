use strict;
use warnings;
use Test::More;
use Time::HiRes qw(sleep);
use Time::Left qw(to_seconds time_left);

# Test to_seconds
subtest 'to_seconds' => sub {
    is(to_seconds(30), 30, 'Plain number');
    is(to_seconds('30'), 30, 'String number');
    is(to_seconds('30s'), 30, 'Seconds');
    is(to_seconds('2m'), 120, 'Minutes');
    is(to_seconds('1.5h'), 5400, 'Hours with decimal');
    is(to_seconds('2d'), 172800, 'Days');
    is(to_seconds('invalid'), undef, 'Invalid string returns undef');
    is(to_seconds('10x'), undef, 'Invalid suffix returns undef');
    is(to_seconds('-5m'), -300, 'Negative duration');
    is(to_seconds('0.5s'), 0.5, 'Fractional seconds');
};

# Test construction
subtest 'construction' => sub {
    my $timer = Time::Left->new(10);
    isa_ok($timer, 'Time::Left', 'new() creates object');
    
    my $timer2 = time_left('10s');
    isa_ok($timer2, 'Time::Left', 'time_left() creates object');
    
    my $indef = Time::Left->new(undef);
    isa_ok($indef, 'Time::Left', 'new(undef) creates object');
    
    my $indef2 = time_left(undef);
    isa_ok($indef2, 'Time::Left', 'time_left(undef) creates object');
    
    # Test invalid input
    eval { Time::Left->new('invalid') };
    like($@, qr/invalid time/, 'new() dies on non-numeric');
    
    eval { time_left('invalid') };
    like($@, qr/invalid duration/, 'time_left() dies on invalid duration');
};

# Test limited timers
subtest 'limited timers' => sub {
    my $timer = time_left('0.2s');
    
    ok($timer->active, 'New timer is active');
    ok(!$timer->expired, 'New timer not expired');
    ok($timer->is_limited, 'Timer is limited');
    
    my $remaining = $timer->remaining;
    ok($remaining > 0 && $remaining <= 0.2, 'Remaining time is positive and bounded');
    
    # Let it expire
    sleep(0.3);
    ok(!$timer->active, 'Timer no longer active after delay');
    ok($timer->expired, 'Timer expired after delay');
    ok($timer->remaining < 0, 'Remaining time is negative');
    ok($timer->is_limited, 'Still reports as limited');
};

# Test indefinite timers
subtest 'indefinite timers' => sub {
    my $timer = time_left(undef);
    
    ok(!$timer->is_limited, 'Indefinite timer is not limited');
    ok($timer->active, 'Indefinite timer is always active');
    ok(!$timer->expired, 'Indefinite timer never expires');
    is($timer->remaining, undef, 'Indefinite timer returns undef remaining');
};

# Test abort
subtest 'abort' => sub {
    my $timer = time_left('10s');
    ok($timer->active, 'Timer starts active');
    
    $timer->abort;
    ok(!$timer->active, 'Timer not active after abort');
    ok($timer->expired, 'Timer expired after abort');
    ok($timer->remaining <= 0, 'Remaining time non-positive after abort');
    
    # Test abort on indefinite timer
    my $indef = time_left(undef);
    ok($indef->active, 'Indefinite timer active');
    $indef->abort;
    ok(!$indef->active, 'Indefinite timer not active after abort');
    ok($indef->expired, 'Indefinite timer expired after abort');
    ok($indef->is_limited, 'Indefinite timer becomes limited after abort');
};

# Test negative initial values
subtest 'negative initial values' => sub {
    my $timer = time_left('-1s');
    ok($timer->expired, 'Negative timer starts expired');
    ok(!$timer->active, 'Negative timer not active');
    ok($timer->remaining < 0, 'Negative timer has negative remaining');
};

done_testing();

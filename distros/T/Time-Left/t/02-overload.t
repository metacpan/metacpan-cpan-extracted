use strict;
use warnings;
use Test::More;
use Time::HiRes qw(sleep);
use Time::Left qw(time_left);

# Test string overload
subtest 'string overload' => sub {
    my $timer = time_left('10s');
    my $str = "$timer";
    like($str, qr/^\d+\.\d{3}$/, 'String format is N.NNN');
    ok($str > 9 && $str <= 10, 'String value in expected range');
    
    my $indef = time_left(undef);
    is("$indef", 'Inf', 'Indefinite timer stringifies to Inf');
    
    # Test expired timer
    my $expired = time_left('-1s');
    like("$expired", qr/^-\d+\.\d{3}$/, 'Expired timer shows negative');

    # String comparison
    ok($timer le 'x', 'String comparison with char works');
    ok($timer le $indef, 'String comparison with timer works');
};

subtest 'numeric prohibition' => sub {
    my $timer = time_left(0.1);
    
    # Direct numification should die
    eval { select(undef, undef, undef, $timer) };
    like($@, qr/numify/, 'Numeric context dies');
    
    # But remaining() still works for select()
    my $remaining = $timer->remaining;
    ok(defined $remaining && $remaining > 0, 'remaining() method still works');
    
    eval { my $x = $timer + 1 };
    like($@, qr/does not overload/, 'Mathematical operation dies');
};

subtest 'comparison edge cases' => sub {
    my $t1 = time_left('5s');
    my $t2 = time_left('10s');
    my $expired = time_left('-1s');
    my $indef = time_left(undef);
    
    # Timer comparisons
    ok($t1 < $t2, 'Timer comparison: 5s < 10s');
    ok($t2 > $t1, 'Timer comparison: 10s > 5s');
    ok($expired < $t1, 'Expired timer < active timer');
    ok($indef > $t1, 'Indefinite > any limited timer');
    ok($indef > $expired, 'Indefinite > expired timer');
    
    # Comparing two indefinite timers
    my $indef2 = time_left(undef);
    ok(!($indef < $indef2), 'Indefinite timers are equal');
    ok(!($indef > $indef2), 'Indefinite timers are equal');
    ok($indef == $indef2, 'Indefinite == indefinite');
    
    # Number comparisons (seconds from now)
    ok($t1 < 10, '5s timer < 10 seconds from now');
    ok($t1 > 2, '5s timer > 2 seconds from now');
    ok(10 > $t1, 'Reversed: 10 seconds from now > 5s timer');
    
    # Indefinite vs numbers
    ok($indef > 1000000, 'Indefinite > any number');
    ok(!(1000000 > $indef), 'No number > indefinite');
};

# Test boolean overload
subtest 'boolean overload' => sub {
    my $timer = time_left('0.1s');
    ok($timer, 'Active timer is true');
    
    if ($timer) {
        pass('Timer works in if statement');
    } else {
        fail('Timer should be true');
    }
    
    sleep(0.2);
    ok(!$timer, 'Negated expired timer is true');
    
    if ($timer) {
        fail('Timer should be false');
    } else {
        pass('Timer works in if statement');
    }
    
    my $indef = time_left(undef);
    ok($indef, 'Indefinite timer is true');
    
    # Test in loops
    my $t = time_left('0.1s');
    my $count = 0;
    while ($t && $count < 100) {
        $count++;
        sleep(0.01);
    }
    ok($count > 0 && $count < 100, 'Boolean works in while loop');
};

# Test overload in real usage
subtest 'practical overload usage' => sub {
    # Countdown example from POD
    my $t = time_left('0.3s');
    my @times;
    while ($t && @times < 10) {
        push @times, "$t";
        sleep(0.05);
    }
    ok(@times >= 5, 'Collected some countdown values');
    ok((grep { /^\d+\.\d{3}$/ } @times) == @times, 'All times properly formatted');
    
    # Check times are decreasing
    my $decreasing = 1;
    for (my $i = 1; $i < @times; $i++) {
        $decreasing = 0 if $times[$i] >= $times[$i-1];
    }
    ok($decreasing, 'Times decrease monotonically');
};

done_testing();

use strict;
use warnings;
use Test::More;
use Time::Left qw(time_left);

# Test that examples from POD work
subtest 'POD examples compile and run' => sub {
    # Simulate the countdown example
    eval {
        my $t = time_left(0.1);
        my $count = 0;
        while ($t && $count < 5) { 
            $count++;
            select(undef, undef, undef, 0.01);
        }
    };
    ok(!$@, 'Countdown example runs without error');
    
    # Test AnyEvent-style usage
    my $timer = time_left('1s');
    if ($timer->is_limited) {
        my $after = $timer->remaining;
        ok(defined $after && $after > 0, 'Can get remaining for AnyEvent');
    }
    
    # Test with indefinite timer
    my $indef = time_left(undef);
    ok(!$indef->is_limited, 'Indefinite timer check works');
    is($indef->remaining, undef, 'Indefinite remaining is undef for select()');
};

done_testing();

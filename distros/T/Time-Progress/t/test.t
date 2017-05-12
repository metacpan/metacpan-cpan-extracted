#! perl

use 5.006;
use strict;
use warnings;

use Test::More 0.88;
use Time::Progress;

my @TESTS = (

    {
        format   => 'percent: %p',
        what     => 'percent display',
        expected => [
            'percent:   0.0%',
            'percent:  20.0%',
            'percent:  40.0%',
            'percent:  60.0%',
            'percent:  80.0%',
            'percent: 100.0%',
        ],
    },

    {
        format   => '%20b',
        what     => 'progress meter',
        expected => [
            '....................',
            '#####...............',
            '##########..........',
            '###############.....',
            '####################',
        ],
    },

);

plan tests => int(@TESTS);

TEST:
foreach my $test (@TESTS) {
    my $format   = $test->{format};
    my @expected = @{ $test->{expected} };
    my $min      = 0;
    my $max      = int(@expected) - 1;
    my $progress = Time::Progress->new(min => $min, max => $max);
    my $ok       = 1;

    STEP:
    for (my $step = $min; $step <= $max; $step++) {
        my $result = $progress->report($format, $step);
        if ($result ne $expected[$step]) {
            $ok = 0;
            last STEP;
        }
    }
    ok($ok, "check $test->{what}");
}


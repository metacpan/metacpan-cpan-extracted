use strict;
use warnings;

use Test::More;
use Test::Time;
use Test::Time::At;

use Time::Piece;

subtest 'do_at with epoch' => sub {
    $Test::Time::time = 1;
    is time, 1, 'time is 1 now';

    do_at {
        is time, 100, 'time is 100 in this scope';
        sleep 10;
        is time, 110, 'time is 110 after sleep';
    } 100;

    is time, 1, 'time is 1 after do_at';
};

subtest 'do_at with Time::Piece' => sub {
    $Test::Time::time = 1;

    is +gmtime->epoch, 1, 'gmtime->epoch is 1 now';

    my $target_t = Time::Piece->strptime('2015-08-10T06:29:00', '%Y-%m-%dT%H:%M:%S');
    do_at {
        is gmtime, $target_t, 'gmtime equals $target_t';

        sleep 10;

        is gmtime, Time::Piece->strptime('2015-08-10T06:29:10', '%Y-%m-%dT%H:%M:%S'), 'gmtime equals 10 seconds after $target_t';
    } $target_t;

    is +gmtime->epoch, 1, 'gmtime->epoch is 1 after do_at';
};

subtest 'sub_at' => sub {
    $Test::Time::time = 1;

    is time, 1, 'time is 1 now';

    subtest 'subtest wit sub_at' => sub_at {
        is time, 100, 'time is 100 in this subtest';
        sleep 10;
        is time, 110, 'time is 110 after sleep in this subtest';
    } 100;

    is time, 1, 'time is 1 after subtest';
};

done_testing();

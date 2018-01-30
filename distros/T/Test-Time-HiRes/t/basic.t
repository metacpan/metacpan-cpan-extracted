use strict;
use warnings;
use Test::More;
use Time::HiRes;
use Test::Time::HiRes time => 123.456789;

subtest initial_time => sub {
    is time(), 123, 'initial time taken from use line';
    is Time::HiRes::time(), 123.456789, 'initial time taken from use line';

    is_deeply [ Time::HiRes::gettimeofday() ], [ 123, 456789 ],
        'Time::HiRes::gettimeofday from initial time';
};

subtest real_sleep => sub {
    CORE::sleep(1);

    is time(), 123, "time unchanged after changes in real time";
    is Time::HiRes::time(), 123.456789,
        'apparent Time::HiRes::time unchanged after changes in real time';
    is_deeply [ Time::HiRes::gettimeofday() ], [ 123, 456789 ],
        'Time::HiRes::gettimeofday unchanged';
};

subtest fake_sleep => sub {
    sleep 1;
    is time(), 124, "apparent time updated after sleep";
    is Time::HiRes::time(), 124.456789,
        'apparent Time::HiRes::time updated after sleep';
    is_deeply [ Time::HiRes::gettimeofday() ], [ 124, 456789 ],
        'Time::HiRes::gettimeofday unchanged';
};

subtest fake_usleep => sub {

    Time::HiRes::usleep 0;
    is Time::HiRes::time(), '124.456789', 'apparent Time::HiRes::time not updated after empty usleep';
    is_deeply [ Time::HiRes::gettimeofday() ], [ 124, 456789 ],
        'Time::HiRes::gettimeofday not updated after empty usleep';

    Time::HiRes::usleep 1;
    is Time::HiRes::time(), '124.456790', 'apparent Time::HiRes::time updated after usleep';
    is_deeply [ Time::HiRes::gettimeofday() ], [ 124, 456790 ],
        'Time::HiRes::gettimeofday updated after usleep';

    Time::HiRes::usleep 1000;
    is Time::HiRes::time(), '124.457790', 'apparent Time::HiRes::time updated after usleep';
    is_deeply [ Time::HiRes::gettimeofday() ], [ 124, 457790 ],
        'Time::HiRes::gettimeofday updated after usleep';

    Time::HiRes::usleep 2_000_000;
    is time(), 126, "time updated after usleep()";
    is Time::HiRes::time(), '126.457790', 'apparent Time::HiRes::time updated after usleep';
    is_deeply [ Time::HiRes::gettimeofday() ], [ 126, 457790 ],
        'Time::HiRes::gettimeofday updated after usleep';

};

done_testing;

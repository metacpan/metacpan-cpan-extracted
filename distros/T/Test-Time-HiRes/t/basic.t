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

    is Test::Time::HiRes::_microseconds(), '456789', '_microseconds ok';
};

subtest real_sleep => sub {

    Test::Time::HiRes->set_time(123.456789);

    CORE::sleep(1);

    is time(), 123, "time unchanged after changes in real time";
    is Time::HiRes::time(), 123.456789,
        'apparent Time::HiRes::time unchanged after changes in real time';
    is_deeply [ Time::HiRes::gettimeofday() ], [ 123, 456789 ],
        'Time::HiRes::gettimeofday unchanged';
};

subtest fake_sleep => sub {

    Test::Time::HiRes->set_time(123.456789);

    sleep 1;
    is time(), 124, "apparent time updated after sleep";
    is Time::HiRes::time(), 124.456789, 'apparent Time::HiRes::time updated after sleep';
    is_deeply [ Time::HiRes::gettimeofday() ], [ 124, 456789 ],
        'Time::HiRes::gettimeofday unchanged';
};

subtest fake_usleep => sub {

    Test::Time::HiRes->set_time(123.456789);

    Time::HiRes::usleep 0;
    is Time::HiRes::time(), '123.456789',
        'apparent Time::HiRes::time not updated after empty usleep';
    is_deeply [ Time::HiRes::gettimeofday() ], [ 123, 456789 ],
        'Time::HiRes::gettimeofday not updated after empty usleep';

    Time::HiRes::usleep 1;
    is Time::HiRes::time(), '123.456790',
        'apparent Time::HiRes::time updated after usleep';
    is_deeply [ Time::HiRes::gettimeofday() ], [ 123, 456790 ],
        'Time::HiRes::gettimeofday updated after usleep';

    Time::HiRes::usleep 1000;
    is Time::HiRes::time(), '123.457790',
        'apparent Time::HiRes::time updated after usleep';
    is_deeply [ Time::HiRes::gettimeofday() ], [ 123, 457790 ],
        'Time::HiRes::gettimeofday updated after usleep';

    Time::HiRes::usleep 2_000_000;
    is time(), 125, "time updated after usleep()";
    is Time::HiRes::time(), '125.457790',
        'apparent Time::HiRes::time updated after usleep';
    is_deeply [ Time::HiRes::gettimeofday() ], [ 125, 457790 ],
        'Time::HiRes::gettimeofday updated after usleep';
};

subtest 'synchronises with Test::Time' => sub {

    Test::Time::HiRes->set_time(123.456789);

    $Test::Time::time = 20_000;

    is time(), 20_000, 'time() updated line';
    is Time::HiRes::time(), 20_000.456789, 'time updated from Test::Time';

    is_deeply [ Time::HiRes::gettimeofday() ], [ 20_000, 456789 ],
        'Time::HiRes::gettimeofday correct';

    is Test::Time::HiRes::_microseconds(), '456789', '_microseconds ok';
};

subtest unimport => sub {

    Test::Time::HiRes->set_time(123.456789);

    is time(), 123, "time set";
    is Time::HiRes::time(), 123.456789, 'hires time set';

    Test::Time::HiRes->unimport();

    isnt time(), 123, "time unset";
    isnt Time::HiRes::time(), 123.456789, 'hires time unset';

    Test::Time::HiRes->import();
};

done_testing;

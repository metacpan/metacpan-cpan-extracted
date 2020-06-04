use strict;
use warnings;
use Test::More;
use Time::HiRes;
use Test::Time::HiRes time => 123.056789;

subtest initial_time => sub {
    is time(), 123, 'initial time taken from use line';
    is Time::HiRes::time(), 123.056789, 'initial time taken from use line';

    is_deeply [ Time::HiRes::gettimeofday() ], [ 123, 56789 ],
        'Time::HiRes::gettimeofday from initial time';

    is scalar Time::HiRes::gettimeofday(), 123.056789,
        'scalar Time::HiRes::gettimeofday from initial time';

    is Test::Time::HiRes::_microseconds(), '56789', '_microseconds ok';
};

subtest real_sleep => sub {

    Test::Time::HiRes->set_time(123.056789);

    CORE::sleep(1);

    is time(), 123, "time unchanged after changes in real time";
    is Time::HiRes::time(), 123.056789,
        'apparent Time::HiRes::time unchanged after changes in real time';
    is_deeply [ Time::HiRes::gettimeofday() ], [ 123, 56789 ],
        'Time::HiRes::gettimeofday unchanged';

    is scalar( Time::HiRes::gettimeofday() ), 123.056789,
        'scalar Time::HiRes::gettimeofday unchanged';
};

subtest fake_sleep => sub {

    Test::Time::HiRes->set_time(123.056789);

    sleep 1;
    is time(), 124, "apparent time updated after sleep";
    is Time::HiRes::time(), 124.056789, 'apparent Time::HiRes::time updated after sleep';
    is_deeply [ Time::HiRes::gettimeofday() ], [ 124, 56789 ],
        'Time::HiRes::gettimeofday unchanged';
    is scalar( Time::HiRes::gettimeofday() ), 124.056789,
        'scalar Time::HiRes::gettimeofday unchanged';
};

subtest fake_usleep => sub {

    Test::Time::HiRes->set_time(123.056789);

    Time::HiRes::usleep 0;
    is Time::HiRes::time(), 123.056789,
        'apparent Time::HiRes::time not updated after empty usleep';
    is_deeply [ Time::HiRes::gettimeofday() ], [ 123, 56789 ],
        'Time::HiRes::gettimeofday not updated after empty usleep';
    is scalar( Time::HiRes::gettimeofday() ), 123.056789,
        'scalar Time::HiRes::gettimeofday not updated after empty usleep';

    Time::HiRes::usleep 1;
    is Time::HiRes::time(), 123.056790,
        'apparent Time::HiRes::time updated after usleep';
    is_deeply [ Time::HiRes::gettimeofday() ], [ 123, 56790 ],
        'Time::HiRes::gettimeofday updated after usleep';
    is scalar( Time::HiRes::gettimeofday() ), 123.056790,
        'scalar Time::HiRes::gettimeofday updated usleep';

    Time::HiRes::usleep 1000;
    is Time::HiRes::time(), 123.057790,
        'apparent Time::HiRes::time updated after usleep';
    is_deeply [ Time::HiRes::gettimeofday() ], [ 123, 57790 ],
        'Time::HiRes::gettimeofday updated after usleep';
    is scalar( Time::HiRes::gettimeofday() ), 123.057790,
        'scalar Time::HiRes::gettimeofday after usleep';

    Time::HiRes::usleep 2_000_000;
    is time(), 125, "time updated after usleep()";
    is Time::HiRes::time(), 125.057790,
        'apparent Time::HiRes::time updated after usleep';
    is_deeply [ Time::HiRes::gettimeofday() ], [ 125, 57790 ],
        'Time::HiRes::gettimeofday updated after usleep';
    is scalar( Time::HiRes::gettimeofday() ), 125.057790,
        'scalar Time::HiRes::gettimeofday after usleep';
};

subtest 'synchronises with Test::Time' => sub {

    Test::Time::HiRes->set_time(123.056789);

    $Test::Time::time = 20_000;

    is time(), 20_000, 'time() updated line';
    is Time::HiRes::time(), 20_000.056789, 'time updated from Test::Time';

    is_deeply [ Time::HiRes::gettimeofday() ], [ 20_000, 56789 ],
        'Time::HiRes::gettimeofday correct';

    is scalar( Time::HiRes::gettimeofday() ), 20000.056789,
        'scalar Time::HiRes::gettimeofday correct';

    is Test::Time::HiRes::_microseconds(), '56789', '_microseconds ok';
};

subtest unimport => sub {

    Test::Time::HiRes->set_time(123.056789);

    is time(), 123, "time set";
    is Time::HiRes::time(), 123.056789, 'hires time set';

    Test::Time::HiRes->unimport();

    isnt time(), 123, "time unset";
    isnt Time::HiRes::time(), 123.056789, 'hires time unset';

    Test::Time::HiRes->import();

    is time(), 123, "time set again";
    is Time::HiRes::time(), 123.056789, 'hires time set again';
};

done_testing;

use strict;
use warnings;

use Test::More;
use Test::Time;
use Test::Time::At;

use Test::Requires qw(DateTime);

subtest 'do_at with DateTime' => sub {
    $Test::Time::time = 1;

    is +DateTime->now->epoch, 1, 'DateTime->now->epoch is 1 now';

    my $target_dt = DateTime->new(year => 2015, month => 8, day => 10);
    do_at {
        is +DateTime->now, $target_dt, 'DateTime->now equals $target_dt';

        sleep 10;

        is +DateTime->now, $target_dt->clone->add(seconds => 10), 'DateTime->now equals 10 seconds after $target_dt';
    } $target_dt;

    is +DateTime->now->epoch, 1, 'DateTime->now->epoch is 1 after do_at';
};

done_testing();

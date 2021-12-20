#!perl

use strict;
use warnings;
use Test::More 0.98;

use Time::Local::ISO8601 qw(
                               timelocal_from_ymd
                               timegm_from_ymd
                    );

my $epoch1 = 1623894635; # Thu Jun 17 08:50:35 2021 Asia/Jakarta = Thu Jun 17 01:50:35 2021 UTC

subtest all => sub {
    local $ENV{TZ} = "Asia/Jakarta";
    is_deeply(timelocal_from_ymd(2021, 6, 17), $epoch1-8*3600-50*60-35);
};

DONE_TESTING:
done_testing;

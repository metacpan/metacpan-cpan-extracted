use strict;
use warnings;
use Test::More;
use POSIX qw( tzset );
use Test::Time time => 1;

is time(), 1, 'initial time taken from use line';

CORE::sleep(1);
is time(), 1, 'apparent time unchanged after changes in real time';

sleep 1;
is time(), 2, 'apparent time updated after sleep';

$ENV{TZ} = 'Europe/London';
tzset();
is scalar( localtime() ), "Thu Jan  1 01:00:02 1970",
    "localtime() in scalar context correct";

my @localtime = localtime();
is_deeply \@localtime, [ 2, 0, 1, 1, 0, 70, 4, 0, 0 ],
    "localtime() in list context correct";

is scalar( localtime(100) ), "Thu Jan  1 01:01:40 1970",
    "localtime() in scalar context with argument correct";

@localtime = localtime(100);
is_deeply \@localtime, [ 40, 1, 1, 1, 0, 70, 4, 0, 0 ],
    "localtime() in list context with argument correct";

Test::Time->unimport();

isnt time(), 2, "removed overwritten time()";
isnt scalar( localtime() ), "Thu Jan  1 01:00:02 1970", "removed overwritten localtime()";

Test::Time->import();

is time(), 2, "re-enabled overwritten time()";
is scalar( localtime() ), "Thu Jan  1 01:00:02 1970", "re-enabled overwritten localtime()";

done_testing;

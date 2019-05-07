use strict;
use warnings;
use Test::More;
use Test::Time time => 1;

is time(), 1, 'initial time taken from use line';

CORE::sleep(1);
is time(), 1, 'apparent time unchanged after changes in real time';

sleep 1;
is time(), 2, 'apparent time updated after sleep';

is scalar( localtime() ), scalar(localtime(2)),
    "localtime() in scalar context correct";

my @localtime = localtime();
is_deeply \@localtime, [ CORE::localtime(2) ],
    "localtime() in list context correct";

is scalar( localtime(100) ), scalar(localtime(100)),
    "localtime() in scalar context with argument correct";

@localtime = localtime(100);
is_deeply \@localtime, [ CORE::localtime(100) ],
    "localtime() in list context with argument correct";

my $overriden = scalar( localtime() );
Test::Time->unimport();

isnt time(), 2, "removed overwritten time()";
isnt scalar( localtime() ), $overriden, "removed overwritten localtime()";

Test::Time->import();

is time(), 2, "re-enabled overwritten time()";
is scalar( localtime() ), $overriden, "re-enabled overwritten localtime()";

done_testing;

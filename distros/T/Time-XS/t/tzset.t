use 5.012;
use warnings;
use Test::More;
use Test::Deep;
use lib 't/lib'; use MyTest;

tzset('Europe/Moscow');
is(tzname(), 'Europe/Moscow');

my $zone = tzget('America/New_York');
tzset($zone);
is(tzname(), 'America/New_York');

if ($^O ne 'MSWin32') {
    $ENV{TZ} = 'Europe/Moscow';
    tzset();
    is(tzname(), 'Europe/Moscow');
    
    $ENV{TZ} = 'America/New_York';
    tzset();
    is(tzname(), 'America/New_York');
}

delete $ENV{TZ};
tzset();
ok(tzname());

done_testing();

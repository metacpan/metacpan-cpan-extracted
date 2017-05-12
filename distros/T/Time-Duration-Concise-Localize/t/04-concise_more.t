use strict;
use warnings;

use Test::More tests => 1;
use Test::Exception;
use Test::FailWarnings;

use Time::Duration::Concise;

subtest 'multiple_units_of' => sub {

    my $day = new_ok('Time::Duration::Concise', [interval => '1d']);
    ok(!$day->multiple_units_of('d'),      'A day does not contain multiple days');
    ok($day->multiple_units_of('h'),       '  but does contain multiple hours');
    ok($day->multiple_units_of('m'),       '  and multiple minutes.');
    ok($day->multiple_units_of('seconds'), '  and, so, multiple seconds.');

    my $almost_two_minutes = new_ok('Time::Duration::Concise', [interval => '1m59s']);
    ok(!$almost_two_minutes->multiple_units_of('minute'), 'Just under 2 minutes does not contain multiple minutes.');
    ok($almost_two_minutes->multiple_units_of('s'),       ' but does contain multiple seconds.');

    my $two_minutes = new_ok('Time::Duration::Concise', [interval => '120s']);
    ok($two_minutes->multiple_units_of('minute'), 'Exactly 2 minutes contains multiple minutes.');

};

1;

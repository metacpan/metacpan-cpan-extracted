use strict;
use warnings;
use utf8;
use Test::More tests => 4;

BEGIN { use_ok 'Weather::TW' };
BEGIN { use_ok 'Weather::TW::Forecast' };

use Weather::TW::Forecast;

ok +Weather::TW::Forecast->new(location=>'台北市'),"new ok";
eval{Weather::TW::Forecast->new(location=>'blah')};
ok $@, "Should fail if location is not in enum";

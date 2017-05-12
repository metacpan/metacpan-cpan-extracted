use strict;
use warnings;
use lib ("t");
use Test::More;
use testlib::MockLingr qw(mock_useragent);
use WebService::Lingr::Archives;

my $lingr = new_ok(
    'WebService::Lingr::Archives',
    [user => $testlib::MockLingr::USERNAME,
     password => $testlib::MockLingr::PASSWORD,
     user_agent => mock_useragent()]
);


done_testing;


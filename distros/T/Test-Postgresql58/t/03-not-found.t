use strict;
use warnings;

use DBI;
use Test::Postgresql58;

use Test::More tests => 3;

$ENV{PATH} = '/nonexistent';
@Test::Postgresql58::SEARCH_PATHS = ();

ok(! defined $Test::Postgresql58::errstr);
ok(! defined Test::Postgresql58->new());
ok($Test::Postgresql58::errstr);

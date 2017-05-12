use strict;
use warnings;

use DBI;
use Test::More;
use Test::Postgresql58;

Test::Postgresql58->new()
    or plan skip_all => $Test::Postgresql58::errstr;

plan tests => 3;

my @pgsql = map {
    my $pgsql = Test::Postgresql58->new();
    ok($pgsql);
    $pgsql;
} 0..1;
is(scalar @pgsql, 2);

use strict;
use warnings;

use DBI;
use Test::More;
use Test::PostgreSQL;
use Try::Tiny;

try { Test::PostgreSQL->new } catch { plan skip_all => $_ };

plan tests => 3;

my @pgsql = map {
    my $pgsql = Test::PostgreSQL->new();
    ok($pgsql);
    $pgsql;
} 0..1;
is(scalar @pgsql, 2);

use strict;
use warnings;
use Test::More;
use Test::PostgreSQL::Docker;

my %opt = (
    tag    => '12-alpine',
    dbname => 'testdb',
    user   => 'foobar',
);

my $server = Test::PostgreSQL::Docker->new(%opt);

ok $server->run(), "server is runing";

my $dsn = $server->dsn;


is $server->{user}, 'foobar';
like $dsn, qr/dbname=testdb/;


my $dbh = DBI->connect($server->dsn(dbname => 'template1'), '', '', {});

ok $dbh, 'create dbh by DBI';

done_testing;

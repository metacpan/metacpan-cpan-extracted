use strict;
use warnings;
use Test::More;
use Test::PostgreSQL::Docker;

my %opt = (
    tag    => '12-alpine',
);

my $server1 = Test::PostgreSQL::Docker->new(%opt);

ok $server1->run(), "server1 is runing";

my $dsn1 = $server1->dsn;
my $dbh1 = DBI->connect($server1->dsn(dbname => 'template1'), '', '', {});
ok $dbh1, 'create dbh by DBI';

my $server2 = Test::PostgreSQL::Docker->new(%opt);

ok $server2->run(), "server2 is runing";

ok $server1->oid ne $server2->oid;

my $dsn2 = $server2->dsn;
my $dbh2 = DBI->connect($server2->dsn(dbname => 'template1'), '', '', {});
ok $dbh2, 'create dbh by DBI';

ok "$dbh1" ne "$dbh2";


done_testing;

use strict;
use warnings;
use lib qw(t/lib);
use Test::More;
use t::Util;


my $server1 = t::Util->new_server();

unless ( $server1->docker_is_running ) {
    plan skip_all => "docker is not running.";
    exit;
}

my $dsn1 = $server1->dsn;
my $dbh1 = DBI->connect($server1->dsn(dbname => 'template1'), '', '', {});
ok $dbh1, 'create dbh by DBI';

my $server2 = Test::PostgreSQL::Docker->new( t::Util->default_args_for_new );

ok $server2->run(), "server2 is runing";

ok $server1->oid ne $server2->oid;

my $dsn2 = $server2->dsn;
my $dbh2 = DBI->connect($server2->dsn(dbname => 'template1'), '', '', {});
ok $dbh2, 'create dbh by DBI';

ok "$dbh1" ne "$dbh2";


done_testing;

use strict;
use warnings;
use lib qw(t/lib);
use Test::More;
use t::Util;

my %opt = (
    dbname => 'testdb',
    dbowner=> 'foobar',
);

my $server = t::Util->new_server(%opt);

unless ( $server->docker_is_running ) {
    plan skip_all => "docker is not running.";
    exit;
}

my $dsn = $server->dsn;


is $server->{dbowner}, 'foobar';
like $dsn, qr/dbname=testdb/;


my $dbh = DBI->connect($server->dsn(dbname => 'template1'), '', '', {});

ok $dbh, 'create dbh by DBI';

done_testing;

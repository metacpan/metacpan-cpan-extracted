use strict;
use warnings;
use Test::More;
use Test::PostgreSQL::Docker;
use File::Spec;

my $server = Test::PostgreSQL::Docker->new(tag => '12-alpine');
isa_ok($server, 'Test::PostgreSQL::Docker');
can_ok($server, qw/pull run psql_args run_psql run_psql_scripts oid dbh dsn container_name image_name/);

my $fixture_file = File::Spec->catfile(qw/t data fixture.sql/);

my $dbh = $server
    ->run()
    ->run_psql_scripts($fixture_file)
    ->dbh();
isa_ok $dbh, "DBI::db";

my $sth = $dbh->prepare('SELECT * FROM Users');
$sth->execute();

my $res = $sth->fetchall_hashref('account_id');
is_deeply($res, {'1' => {
    'account_id' => 1,
    'account_name' => 'ytnobody',
    'email' => 'ytnobody@gmail.com',
    'password' => 'hogehoge'
}});

$server->run_psql('-c', q|"INSERT INTO users (account_name, password) VALUES ('foo','bar')"|);

$res = $dbh->selectrow_hashref(q/SELECT * FROM users WHERE account_name = 'foo'/);
is_deeply($res, {
    'account_id' => 2,
    'account_name' => 'foo',
    'email' => undef,
    'password' => 'bar'
});

done_testing;
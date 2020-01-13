#!/usr/bin/env perl
use strict;
use warnings;

use DBI;
use Test::More;
use Test::Exception;

use_ok 'Test::SQLite';

throws_ok {
    Test::SQLite->new
} qr/No schema or database given/,
'schema or database required';

throws_ok {
    Test::SQLite->new( schema => 'eg/test.sql', database => 'eg/test.db' )
} qr/may not be used at the same time/,
'schema and database declared together';

throws_ok {
    Test::SQLite->new( schema => 'eg/bogus.sql' )
} qr/schema does not exist/,
'schema does not exist';

throws_ok {
    Test::SQLite->new( database => 'eg/bogus.db' )
} qr/database does not exist/,
'database does not exist';

my $sqlite = Test::SQLite->new(
    schema    => 'eg/test.sql',
    dsn       => 'foo',
    dbh       => 'foo',
    _database => 'foo',
);
ok -e $sqlite->_database, 'create test database from schema';

isnt $sqlite->dsn, 'foo', 'dsn constructor ignored';
isnt $sqlite->dbh, 'foo', 'dbh constructor ignored';
isnt $sqlite->_database, 'foo', '_database constructor ignored';

my $sql = 'SELECT name FROM account';
my $expected = [ [ 'Gene' ] ];

my $dbh = DBI->connect( $sqlite->dsn, '', '' );
isa_ok $dbh, 'DBI::db';
my $sth = $dbh->prepare($sql);
$sth->execute;
my $got = $sth->fetchall_arrayref;
is_deeply $got, $expected, 'expected data';
$dbh->disconnect;

$sqlite = Test::SQLite->new( database => 'eg/test.db' );
ok -e $sqlite->_database, 'create test database from database';

$dbh = $sqlite->dbh;
isa_ok $dbh, 'DBI::db';
$sth = $dbh->prepare($sql);
$sth->execute;
$got = $sth->fetchall_arrayref;
is_deeply $got, $expected, 'expected data';

done_testing();

use strict;
use warnings;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../..";

use URT;
use Test::More;

use URT::DataSource::SomeSQLite;

my $dbh = URT::DataSource::SomeSQLite->get_default_handle();
$dbh->do('create table thing (thing_id integer PRIMARY KEY, value varchar, other varchar)');
my $sth = $dbh->prepare('insert into thing values (?,?,?)');
foreach my $id ( 2..10 ) { $sth->execute($id, chr($id + 64), chr($id + 64)) }
$sth->finish;

UR::Object::Type->define(
    class_name => 'URT::Thing',
    id_by => 'thing_id',
    has => ['value','other'],
    data_source => 'URT::DataSource::SomeSQLite',
    table_name => 'thing',
);

# Changing an object in memory and filtering on that change should not register as a DB deletion.
# - Had to get with multiple IDs in order to reproduce the bug we found.
# - Had to separate this in its own test because 95_detect_db_deleted.t's environment was unable to reproduce the bug.
# - The bug was that UR::Context::LoadingIterator was treating the case where a BoolExpr filter change was causing an exception to be thrown.

my @ids = (3, 5, 7);
my @things = URT::Thing->get(id => \@ids);
map { $_->value('A') } @things;
my @same_things = URT::Thing->get(value => 'A', id => \@ids);
is(scalar @things, scalar @same_things, 'got same number of same things as we created A');

done_testing();

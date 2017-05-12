use strict;
use warnings;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;

use Test::More tests => 9;
use URT::DataSource::SomeSQLite;

&setup_classes_and_db();

my $thing = URT::Thing->get('value like' => '%One');
ok($thing, "Loaded thing iwth 'value like' => '%One'");
is($thing->id, 1, 'It was the right thing');

my @things = URT::Thing->get('value not like' => '%Two');
is(scalar(@things), 4, "Loaded 4 things with 'value not like' => '%Two'");

@things = URT::Thing->get('value like' => 'Number%');
is(scalar(@things), 5, "Got 5 things with 'value like' => 'Number%'");

@things = URT::Thing->get('value not like' => '%blah%');
is(scalar(@things), 5, "Got 5 things with 'value not like' => '%blah%'");


sub setup_classes_and_db {
    my $dbh = URT::DataSource::SomeSQLite->get_default_handle;

    ok($dbh, 'Got DB handle');

    ok( $dbh->do("create table thing (thing_id integer NOT NULL PRIMARY KEY, value varchar)"),
        'created thing table');

    my $sth = $dbh->prepare('insert into thing values (?,?)');
    ok($sth, 'Prepared insert statement');
    $sth->execute(1,'Number One');
    $sth->execute(2,'Number Two');
    $sth->execute(3,'Number Three');
    $sth->execute(4,'Number Four');
    $sth->execute(5,'Number Five');
    $sth->finish;

    ok($dbh->commit(), 'DB commit');

    UR::Object::Type->define(
        class_name => 'URT::Thing',
        id_by => 'thing_id',
        has => [
            value => { is => 'String' },
        ],
        data_source => 'URT::DataSource::SomeSQLite',
        table_name => 'thing',
    );
}

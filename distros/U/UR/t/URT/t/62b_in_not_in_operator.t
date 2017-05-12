use strict;
use warnings;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;

use Test::More tests => 7;
use URT::DataSource::SomeSQLite;

&setup_classes_and_db();

#test quote escaping in IN clauses
my @odd_things = URT::Thing->get(value => [map(join("'", $_, $_), (1,3,5,7))]);
is(scalar(@odd_things), 4, 'got back four objects');

my @even_things = URT::Thing->get('value not in' => [map(join("'", $_, $_), (1,3,5,7))]);
is(scalar(@even_things), 4, 'got back four objects');

my %everything;
for my $t (@odd_things, @even_things) {
    $everything{$t->id} = $t;
}
is(scalar(keys(%everything)), 8, 'got entire set of things betwixt the odd and even');


sub setup_classes_and_db {
    my $dbh = URT::DataSource::SomeSQLite->get_default_handle;

    ok($dbh, 'Got DB handle');

    ok( $dbh->do("create table thing (thing_id integer NOT NULL PRIMARY KEY, value varchar)"),
        'created thing table');

    my $sth = $dbh->prepare('insert into thing values (?,?)');
    ok($sth, 'Prepared insert statement');
    foreach my $val ( 1,2,3,4,5,6,7,8 ) {
        $sth->execute($val,$val . "'" . $val);
    }
    $sth->finish;

    ok($dbh->commit(), 'DB commit');

    UR::Object::Type->define(
        class_name => 'URT::Thing',
        id_by => 'thing_id',
        has => [
            value => { is => 'Text' },
        ],
        data_source => 'URT::DataSource::SomeSQLite',
        table_name => 'thing',
    );
}

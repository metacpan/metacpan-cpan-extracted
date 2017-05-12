use strict;
use warnings;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;

use Test::More tests => 16;
use URT::DataSource::SomeSQLite;

# This tests a get() with some "or"s in the boolexpr.

&setup_classes_and_db();

my $boolexpr = UR::BoolExpr->resolve_for_string(
    'URT::Thing',
    '(id<0) or (name=Diane)',
);
ok($boolexpr, 'defined boolexpr');
my $iter = URT::Thing->create_iterator($boolexpr);
my $count = 0; my $thing = undef;
while(my $next = $iter->next) { $count++; $thing = $next; }
is($count, 1, 'found one thing');
is($thing->id, 3, 'is correct object');

$boolexpr = UR::BoolExpr->resolve_for_string(
    'URT::Thing',
    '(name=Bob) or (id<0)',
);
ok($boolexpr, 'defined boolexpr');
$iter = URT::Thing->create_iterator($boolexpr);
$count = 0; $thing = undef;
while(my $next = $iter->next) { $count++; $thing = $next; }
is($count, 1, 'found one thing');
is($thing->id, 1, 'is correct object');

$boolexpr = UR::BoolExpr->resolve_for_string(
    'URT::Thing',
    '(name=Bob) or (type_id=8)'
);
ok($boolexpr, 'defined boolexpr');
$iter = URT::Thing->create_iterator($boolexpr);
$count = 0;
while($iter->next) { $count++; }
is($count, 2, 'found two things');

$boolexpr = UR::BoolExpr->resolve_for_string(
    'URT::Thing',
    '(name=Christine) or (id>0)'
);
ok($boolexpr, 'defined boolexpr');
$iter = URT::Thing->create_iterator($boolexpr);
$count = 0;
while($iter->next) { $count++; }
is($count, 3, 'found all three things (with no duplicates)');






sub setup_classes_and_db {
    my $dbh = URT::DataSource::SomeSQLite->get_default_handle;

    ok($dbh, 'Got DB handle');

    ok( $dbh->do("create table thing (thing_id integer, name varchar, type_id integer)"),
       'Created thing table');

    my $ins_thing = $dbh->prepare("insert into thing (thing_id, name, type_id) values (?,?,?)");
    foreach my $row ( ( [1, 'Bob',1], [2, 'Christine',2], [3, 'Diane', 8]) ) {
        ok( $ins_thing->execute(@$row), 'Inserted a thing');
    }
    $ins_thing->finish;

    ok($dbh->commit(), 'DB commit');

     UR::Object::Type->define(
        class_name => 'URT::Thing',
        id_by => 'thing_id',
        has => [
            name => { is => 'String' },
            type_id => { is => 'Integer' },
        ],
        data_source => 'URT::DataSource::SomeSQLite',
        table_name => 'thing',
    );
}


use warnings;
use strict;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use UR;
use Test::More tests => 41;

UR::Object::Type->define(
    class_name => 'Acme',
    is => ['UR::Namespace'],
);

our $calculate_called = 0;
UR::Object::Type->define(
    class_name => 'Acme::Employee',
    has => [
        first_name => { type => "String" },
        last_name => { type => "String" },
        full_name => { 
            calculate_from => ['first_name','last_name'], 
            calculate => '$first_name . " " . $last_name', 
        },
        user_name => {
            calculate_from => ['first_name','last_name'],
            calculate => 'lc(substr($first_name,0,1) . substr($last_name,0,5))',
        },
        email_address => { calculate_from => ['user_name'] },
        cached_uc_full_name => {
            is_constant => 1,
            calculate => q(  $main::calculate_called = 1;
                             return uc($self->full_name);
                          ),
        },
    ]
);

sub Acme::Employee::email_address {
    my $self = shift;
    return $self->user_name . '@somewhere.tv';
}

$calculate_called = 0;
my $e1 = Acme::Employee->create(first_name => "John", last_name => "Doe");
ok($e1, "created an employee object");

ok($e1->can("full_name"), "employees have a full name");
ok($e1->can("user_name"), "employees have a user_name");
ok($e1->can("email_address"), "employees have an email_address");

is($e1->full_name,"John Doe", "name check works");
is($e1->user_name, "jdoe", "user_name check works");
is($e1->email_address, 'jdoe@somewhere.tv', "email_address check works");
is($calculate_called, 0, 'The cached calculation sub has not been called yet');

$calculate_called = 0;
my $saved_uc_full_name = uc($e1->full_name);
is($e1->cached_uc_full_name, $saved_uc_full_name, 'calculated + cached upper-cased name is correct');
is($calculate_called, 1, 'The calculation function was called');

$e1->first_name("Jane");
$e1->last_name("Smitharoonie");

is($e1->full_name,"Jane Smitharoonie", "name check works after changes");
is($e1->user_name, "jsmith", "user_name check works after changes");
is($e1->email_address, 'jsmith@somewhere.tv', "email_address check works");

$calculate_called = 0;
is($e1->cached_uc_full_name, $saved_uc_full_name, 'calculated + cached upper-cased name is correct');
is($calculate_called, 0, 'The calculation function was not called');
isnt($e1->cached_uc_full_name, uc($e1->full_name), 'it is correctly different than the current upper-case full name');



UR::Object::Type->define(
    class_name => "Acme::LineItem",
    has => [
        quantity    => { type => 'Number' },
        unit_price  => { type => 'Money'  },
        sum_total   => { type => 'Money', calculate => 'sum',
                            calculate_from => ['quantity','unit_price'] },
        sub_total   => { type => 'Money', calculate => 'product',
                            calculate_from => ['quantity','unit_price'] },
                            
    ],
);  

my $line = Acme::LineItem->create(quantity => 5, unit_price => 2);
ok($line, "made an order line item");
is($line->sum_total,7, "got the correct sum-total");
is($line->sub_total,10, "got the correct sub-total");


# Make a cached+calculated property that is also saved in the database
use URT::DataSource::SomeSQLite;

my $dbh = URT::DataSource::SomeSQLite->get_default_handle;
$dbh->do('create table thing (thing_id integer, name varchar, munged_name varchar)');
$dbh->do("insert into thing values (1234,'Bob', 'munged Bob')");
$dbh->do("Insert into thing values (2345,'Fred', null)");


$calculate_called = 0;
UR::Object::Type->define(
    class_name => 'Acme::SavedThing',
    id_by => 'thing_id',
    has => [
        name => { is => 'String' },
        munged_name => { is_mutable => 0,
                         column_name => 'munged_name',
                         calculate_from => ['name'],
                         calculate => sub { 
                             my($name) = @_;
                             $calculate_called = 1; 
                             return uc($name)
                         },
                     },
        name2 => { calculate_from => ['__self__'],
                   calculate => sub { return $_[0]->name },
                 },
    ],
    data_source => 'URT::DataSource::SomeSQLite',
    table_name => 'thing',
);

$calculate_called = 0;
my $new_thing = Acme::SavedThing->create(name => 'Foo');
ok($new_thing, 'Created a SavedThing');
ok($calculate_called, 'Its calculation sub was called');
$calculate_called = 0;
is($new_thing->munged_name, 'FOO', 'The munged_name property is correct');
is($calculate_called, 0, 'The calculation sub was not called again');
ok(! eval { $new_thing->munged_name('Something else') }, 'Changing munged_name correctly returned false');
ok($@, 'Trying to change munged_name generated an exception');

$calculate_called = 0;
$new_thing = Acme::SavedThing->create(name => 'Bar', munged_name => 'Something else');
ok($new_thing, 'Created another SavedThing');
is($calculate_called, 0, 'The calculation sub was not called');
is($new_thing->munged_name, 'Something else', 'The munged_name property is correct');
is($calculate_called, 0, 'The calculation sub was still not called');

$calculate_called = 0;
$new_thing = Acme::SavedThing->get(name => 'Bob');
ok($new_thing, 'Got a SavedThing from the DB');
is($new_thing->munged_name, 'munged Bob', 'The munged_name property is correct');
is($calculate_called, 0, 'The calculation sub was not called');

$calculate_called = 0;
$new_thing = Acme::SavedThing->get(name => 'Fred');
ok($new_thing, 'Got another SavedThing from the DB');
is($new_thing->munged_name, undef, 'The munged_name property is correctly undef');
is($calculate_called, 0, 'The calculation sub was not called');

is($new_thing->name, $new_thing->name2, 'calling calculated sub where calculate_from includes __self__ works');

ok(UR::Context->commit, 'Saved to the DB');

my @row = $dbh->selectrow_array(q(select thing_id, name, munged_name from thing where name = 'Foo'));
ok(scalar(@row), 'Retrieved row from DB where name is Foo');
is($row[2], 'FOO', 'Saved munged_name is correct');

@row = $dbh->selectrow_array(q(select thing_id, name, munged_name from thing where name = 'Bar'));
ok(scalar(@row), 'Retrieved row from DB where name is Bar');
is($row[2], 'Something else', 'Saved munged_name is correct');

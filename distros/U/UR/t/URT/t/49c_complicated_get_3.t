use strict;
use warnings;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;

use Test::More tests => 11;
use URT::DataSource::SomeSQLite;

# This tests a get() with several unusual properties....
#     - The property we're filtering on is doubly delegated
#     - Each class through the indirection has a parent class with a table

&setup_classes_and_db();

my $person = URT::Person->get(animal_breed_is_smart => 1);
ok($person, 'get() returned an object');
isa_ok($person, 'URT::Person');
is($person->name, 'Jeff', 'The expected object was returned');
is($person->animal_name, 'Lassie', 'the delegated property has the expected value');
is($person->animal_breed_name, 'Collie', 'the delegated property has the expected value');

sub setup_classes_and_db {
    my $dbh = URT::DataSource::SomeSQLite->get_default_handle;

    ok($dbh, 'Got DB handle');

    # Schema/class design
    # NamedThing is things with names... parent class for the other classes
    # Person is-a NamedThing, it has an Animal with animal_name, and the animal has a animal_breed_name
    # Animal is-a NamedThing.  it has a AnimalBreed with a breed_name
    # AnimalBreed is-a NamedThing.  It has a name
    ok( $dbh->do("create table named_thing (named_thing_id integer PRIMARY KEY, name varchar NOT NULL)"),
        'Created named_thing table');

    ok( $dbh->do("create table breed (breed_id PRIMARY KEY REFERENCES named_thing(named_thing_id), is_smart integer NOT NULL)"),
        'created animal breed table');

    ok( $dbh->do("create table animal (animal_id PRIMARY KEY REFERENCES named_thing(named_thing_id), breed_id REFERENCES breed(breed_id))"),
        'created animal table');

    ok( $dbh->do("create table person (person_id integer PRIMARY KEY REFERENCES named_thing(named_thing_id), animal_id integer REFERENCES animal(animal_id))"),
       'Created people table');

    my $name_insert = $dbh->prepare('insert into named_thing (named_thing_id, name) values (?,?)');
    my $breed_insert = $dbh->prepare('insert into breed (breed_id, is_smart) values (?,?)');
    my $animal_insert = $dbh->prepare('insert into animal (animal_id, breed_id) values (?,?)');
    my $person_insert = $dbh->prepare('insert into person (person_id,animal_id) values (?,?)');

    # Insert a breed named Collie
    $name_insert->execute(1, 'Collie');
    $breed_insert->execute(1,1);

    # A Dog named Lassie
    $name_insert->execute(2, 'Lassie');
    $animal_insert->execute(2, 1);

    # a person named Jeff
    $name_insert->execute(3, 'Jeff');
    $person_insert->execute(3,2);

    $name_insert->finish;
    $breed_insert->finish;
    $animal_insert->finish;
    $person_insert->finish;

    ok($dbh->commit(), 'DB commit');

    UR::Object::Type->define(
        class_name => 'URT::NamedThing',
        id_by => [
            named_thing_id => { is => 'Integer' },
        ],
        has => [
            name => { is => 'String' },
        ],
        is_abstract => 1,
        data_source => 'URT::DataSource::SomeSQLite',
        table_name => 'named_thing',
    );

    UR::Object::Type->define(
        class_name => 'URT::Breed',
        is => 'URT::NamedThing',
        id_by => ['breed_id'],
        has => [
            is_smart => { is => 'Boolean', },
        ],
        data_source => 'URT::DataSource::SomeSQLite',
        table_name => 'breed',
    );

    UR::Object::Type->define(
        class_name => 'URT::Animal',
        is => 'URT::NamedThing',
        id_by => ['animal_id'],
        has => [
            breed => { is => 'URT::Breed', id_by => 'breed_id' },
            breed_name => { via => 'breed', to => 'name' },
            breed_is_smart => { via => 'breed', to => 'is_smart' },
        ],
        data_source => 'URT::DataSource::SomeSQLite',
        table_name => 'animal',
    );

    UR::Object::Type->define(
        class_name => 'URT::Person',
        is => 'URT::NamedThing',
        id_by => ['person_id'],
        has => [
            animal => { is => 'URT::Animal', id_by => 'animal_id' },
            animal_name => { via => 'animal', to => 'name' },
            animal_breed_name => { via => 'animal', to => 'breed_name' },
            animal_breed_is_smart => { via => 'animal', to => 'breed_is_smart' },
        ],
        data_source => 'URT::DataSource::SomeSQLite',
        table_name => 'person',
    );
}


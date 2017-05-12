use strict;
use warnings;
use Test::More tests => 2;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__).'/../..';

# Tests that the code to efficiently load data from double delegated properties
# works properly when the linkage between classes involves multiple primary keys

use URT;

subtest 'via/reverse-as' => sub {
# This is essentially the same test as 87_is_many_indirect_is_efficient.t, except
# that the link between Car and CarPart has a 2-column foreign key.  This means
# the system needs to perform more than one query to collect the result objects

    plan tests => 7;

    ok(UR::Object::Type->define(
        class_name => 'URT::Person',
        id_by => [
            person_id => { is => 'NUMBER' },
        ],
        has => [
            name      => { is => 'String' },
            is_cool   => { is => 'Boolean' },
            cars       => { is => 'URT::Car', reverse_as => 'owner', is_many => 1, is_optional => 1 },
            primary_car => { is => 'URT::Car', via => 'cars', to => '__self__', where => ['is_primary true' => 1] },
            primary_car_parts => { via => 'primary_car', to => 'parts' },
            car_color => { via => 'cars', to => 'color' },

            car_parts => { is => 'URT::CarParts', via => 'cars', to => 'parts', is_optional => 1, is_many => 1 },
            car_parts_prices => { via => 'cars', to => 'parts_prices', is_optional => 1, is_many => 1 },
        ],
    ),
    'Created class for people');

    ok(UR::Object::Type->define(
            class_name => 'URT::Car',
            id_by => [
                car_id  =>           { is => 'NUMBER' },
                car_id2 =>           { is => 'NUMBER' },
            ],
            has => [
                color   => { is => 'String' },
                is_primary => { is => 'Boolean' },
                owner   => { is => 'URT::Person', id_by => 'owner_id' },
                parts   => { is => 'URT::CarParts', reverse_as => 'car', is_many => 1 },
                parts_prices => { via => 'parts', to => 'price', is_many => 1},
            ],
        ),
        "Created class for Car");

    ok(UR::Object::Type->define(
            class_name => 'URT::CarParts',
            id_by => 'part_id',
            has => [
                name => { is => 'String' },
                price => { is => 'Integer' },
                car   => { is => 'URT::Car', id_by => ['car_id', 'car_id2'] },
            ],
        ),
        "Created class for CarParts");
            
    # Create some objects
    # Bob and Mike have red cars, Fred and Joe have blue cars.  Frank has no car.  Bob, Joe and Frank are cool
    # Bob also has a yellow car that's his primary car
    foreach my $row ( [ 1, 'Bob',1 ], [2, 'Fred',0], [3, 'Mike',0],[4,'Joe',1], [5,'Frank', 1] ) {
        my %args; @args{qw( person_id name is_cool )} = @$row;
        URT::Person->create(%args);
    }

    foreach my $row ( [ 1,1,'red',0,1], [ 2,2,'blue',1, 2], [3,3,'red',1,3],[4,4,'blue',1,4],[5,5,'yellow',1,1] ) {
        my %args; @args{qw( car_id car_id2 color is_primary owner_id )} = @$row;
        URT::Car->create(%args);
    }

    # Bob's non-primary car has wheels and engine,
    # Bob's primary car has custom wheels and neon lights
    # Fred's car has wheels and seats
    # Mike's car has engine and radio
    # Joe's car has seats and radio
    foreach my $row ( [1, 'wheels', 100, 1,1],
                      [2, 'engine', 200, 1,1],
                      [3, 'wheels', 100, 2,2],
                      [4, 'seats',  50,  2,2],
                      [5, 'engine', 200, 3,3],
                      [6, 'radio',  50,  3,3],
                      [7, 'seats',  50,  4,4],
                      [8, 'radio',  50,  4,4],
                      [9, 'custom wheels', 200, 5,5],
                      [10,'neon lights',   100, 5,5],
                    ) {
        my %args; @args{qw( part_id name price car_id car_id2 )} = @$row;
        URT::CarParts->create(%args);
    }

    my $person = URT::Person->get(1);
    ok($person, 'Got person object');

    my @colors = $person->cars();
    is(scalar(@colors), 2, 'person has 2 cars with colors');

    my @prices = $person->car_parts_prices();
    is(scalar(@prices), 4, "person's cars have 4 car_parts with prices");

    URT::CarParts->unload();
    my @parts = $person->car_parts;
    my @parts_ids = sort { $a <=> $b }
                    map { $_->id } @parts;
    is_deeply(\@parts_ids,
              [1, 2, 9, 10],
              'Got the correct CarParts objects');
};

subtest 'via/via' => sub {
    # This is the same as the '"to" is via-to' test in 56c_via_property_with_order_by.t
    # except for multiple FK properties for value_obj
    plan tests => 1;

    UR::Object::Type->define(
        class_name => 'ViaThing',
        has_many => [
            attribs => { is => 'ViaAttribute', reverse_as => 'thing' },
            favorites => { via => 'attribs', to => 'value', where => [ key => 'favorite']},#, '-order_by' => 'rank' ] },
        ],
    );
    UR::Object::Type->define(
        id_by => ['id1', 'id2'],
        class_name => 'ViaValue',
        has => [ 'value' ],
    );
    UR::Object::Type->define(
        class_name => 'ViaAttribute',
        has => [
            thing => { is => 'ViaThing', id_by => 'thing_id' },
            key => { is => 'String' },
            value_obj => { is => 'ViaValue', id_by => ['value_obj_id', 'value_obj_id2'] },
            value => { via => 'value_obj', to => 'value' },
            rank => { is => 'Integer' },
        ]
    );

    # make a Thing with favorites 1, 2, 4 and 6, ranked in numerical order
    # but their IDs are not sorted the same as their values/ranks
    my $thing = ViaThing->create();

    my @value_objs = do {
        my $id = 100;
        map { ViaValue->create(id1 => $id, id2 => $id++, value => $_) } (qw( 4 2 6 2 1));
    };
    my @attrib_objs = map { ViaAttribute->create(
                                    thing_id => $thing->id,
                                    key => 'favorite',
                                    value_obj_id => $_->id1,
                                    value_obj_id2 => $_->id2,
                                    rank => $_->value,
                                )
                            } @value_objs;

    my @favorites = sort { $a <=> $b } $thing->favorites;
    is_deeply(\@favorites,
              [ 1, 2, 2, 4, 6],
              'Got back ordered favorites',
            );


};

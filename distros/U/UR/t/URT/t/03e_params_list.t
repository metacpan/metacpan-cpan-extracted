use strict;
use warnings;
use Test::More tests=> 7;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__).'/../..';

use URT;

ok(UR::Object::Type->define(
        class_name => 'URT::Person',
        table_name => 'PERSON',
        id_by => [
            person_id           => { is => 'Number' },
        ],
        has => [
            name                => { is => 'Text' },
            is_cool             => { is => 'Boolean' },
            age                 => { is => 'Integer' },
            cars                => { is => 'URT::Car', reverse_as => 'owner', is_many => 1, is_optional => 1 },
            primary_car         => { is => 'URT::Car', via => 'cars', to => '__self__', where => ['is_primary true' => 1] },
            car_colors          => { via => 'cars', to => 'color', is_many => 1 },
            primary_car_color   => { via => 'primary_car', to => 'color' },
        ],
    ),
    'created class for people');

ok(UR::Object::Type->define(
        class_name => 'URT::Car',
        table_name => 'CAR',
        id_by => [
            car_id          => { is => 'Number' },
        ],
        has => [
            color           => { is => 'String' },
            is_primary      => { is => 'Boolean' },
            owner           => { is => 'URT::Person', id_by => 'owner_id' },
            engine          => { is => 'URT::Car::Engine', reverse_as => 'car', is_many => 1 },
        ],
    ),
    "created class for Car");

ok(UR::Object::Type->define(
        class_name => 'URT::Car::Engine',
        table_name => 'CAR_ENGINE',
        id_by => [
            engine_id   => { is => 'Number' },
        ],
        has => [
            size        => { is => 'Number' },
            car         => { is => 'URT::Car', id_by => 'car_id' },
        ],
        data_source => 'URT::DataSource::SomeSQLite',
    ),
    "created class for Engine");


my $bx1 = URT::Person->define_boolexpr(
    'is_cool' => 1,
    'primary_car_color like' => 'red%',
    'primary_car.engine.size' => [428,429],
    'cars.color in' => ['red','blue'],
);

my $bx2 = URT::Person->define_boolexpr(
    -or => [
        [
            'is_cool' => 1,
            'cars.color in' => ['red','blue'],
        ],
        [
            'primary_car_color like' => 'red%',
            'primary_car.engine.size' => [428,429],
        ],
    ]
);

for my $bx ($bx1, $bx2) {
    my @pa = $bx->params_list;
    my @pb = $bx->_params_list;

    my $bxa = URT::Person->define_boolexpr(@pa);
    is($bxa->id, $bx->id, "the params_list reconstructs the same object $bxa");

    my $bxb = URT::Person->define_boolexpr(@pb);
    is($bxb->id, $bx->id, "the params_list reconstructs the same object $bxb");
}


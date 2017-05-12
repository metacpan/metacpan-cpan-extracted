use strict;
use warnings;

use Test::More tests => 246;

use_ok('YAWF::Object::MongoDB');
use_ok('t::lib::Car');

# Clean up test space
t::lib::Car->_collection->drop;

# Create some cars
my @colors = ( 'red', 'blue', 'green' );
my @brands = ( 1 .. 3 );
my @models = ( 'a' .. 'c' );
for my $color (@colors) {
    for my $brand (@brands) {
        for my $model (@models) {
            my $prefix = "[$color|$brand|$model] ";
            my $car    = t::lib::Car->new;
            is( ref($car), 't::lib::Car', $prefix . 'Check object type' );
            is( $car->color($color), $color, $prefix . 'Set color' );
            is( $car->brand($brand), $brand, $prefix . 'Set brand' );
            is( $car->model($model), $model, $prefix . 'Set model' );
            ok( $car->flush, $prefix . 'Flush object to database' );
        }
    }
}

is(
    t::lib::Car->count,
    scalar(@colors) * scalar(@brands) * scalar(@models),
    'Check car count'
);

# Basic sorting
for my $color (@colors) {
    for my $brand (@brands) {
        my @list = t::lib::Car->list(
            { color => $color, brand => $brand },
            { order_by => { -asc => 'model' } }
        );
        for ( 0 .. $#models ) {
            is( $list[$_]->model, $models[$_],
                "[$color|$brand|$_] Check model sort order" );
        }
    }
}

my @scolors = sort { $b cmp $a } (@colors);
for my $model (@models) {
    for my $brand (@brands) {
        my @list = t::lib::Car->list(
            { model => $model, brand => $brand },
            { order_by => { -desc => 'color' } }
        );
        for ( 0 .. $#scolors ) {
            is( $list[$_]->color, $scolors[$_],
                "[$model|$brand|$_] Check color sort order" );
        }
    }
}

# Two key sorting
SKIP: {
    skip
"Perl MongoDB module doesn't support multi-key sorting atm (hash keys have no order)'",
      54;
    for my $model (@models) {
        my @list = t::lib::Car->list( { model => $model },
            { order_by => [ { -desc => 'color' }, 'brand' ] } );
        for my $c ( 0 .. $#scolors ) {
            for my $b ( 0 .. $#brands ) {
                my $item = shift @list;
                is( $item->color, $scolors[$c],
                    "[2:$model|$c|$b] Check color sort order" );
                is( $item->brand, $brands[$b],
                    "[2:$model|$c|$b] Check brand sort order" );
            }
        }
    }
}

END {
    t::lib::Car->_collection->drop;
}

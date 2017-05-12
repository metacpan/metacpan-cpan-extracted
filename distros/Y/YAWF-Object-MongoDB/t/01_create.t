use Test::More tests => 34;

use_ok('YAWF::Object::MongoDB');
use_ok('t::lib::Car');

my $first = t::lib::Car->new;    # Create a new car
is( ref($first),              't::lib::Car', 'Check first object type' );
is( $first->color('red'),     'red',         'Set first color' );
is( $first->brand('Ferrari'), 'Ferrari',     'Set first brand' );
is( $first->model('Enzo'),    'Enzo',        'Set first model' );
ok( $first->flush, 'Flush first object to database' );

my $second = t::lib::Car->new;    # Create a new car
is( ref($second),             't::lib::Car', 'Check second object type' );
is( $second->color('blue'),   'blue',        'Set second color' );
is( $second->brand('Jaguar'), 'Jaguar',      'Set second brand' );
is( $second->model('XF'),     'XF',          'Set second model' );
ok( $second->flush, 'Flush second object to database' );

is( t::lib::Car->new( $first->id )->id, $first->id,
    'Get first document by id' );
for ( 'color', 'brand', 'model' ) {
    is( t::lib::Car->new( $_ => $first->$_ )->id,
        $first->id, 'Get first document by ' . $_ );
}

is( t::lib::Car->new( $second->id )->id,
    $second->id, 'Get second document by id' );
for ( 'color', 'brand', 'model' ) {
    is( t::lib::Car->new( $_ => $second->$_ )->id,
        $second->id, 'Get second document by ' . $_ );
}

my $third = t::lib::Car->new;    # Create a new car
is( $third->color('red'), 'red', 'Set third color' );
is( $third->set_column( 'engine', '12V' ), '12V', 'Set third custom key' );
ok( $third->flush, 'Flush third object to database' );
is( t::lib::Car->new( engine => $third->get_column('engine') )->id,
    $third->id, 'Get third document by custom key' );

my @list = t::lib::Car->list;
is( scalar(@list), 3, 'Check car list' );
is( t::lib::Car->count, 3, 'Check car count' );

@list = t::lib::Car->list( { color => 'red' } );
is( scalar(@list), 2, 'Check red car count' );

for (@list) {
    ok( $_->delete, 'Remove a car' );
}

@list = t::lib::Car->list;
is( scalar(@list), 1, 'Check car list' );
is( t::lib::Car->count, 1, 'Check car count' );

for (@list) {
    ok( $_->delete, 'Remove last car' );
}

@list = t::lib::Car->list;
is( scalar(@list), 0, 'Check car list' );
is( t::lib::Car->count, 0, 'Check car count' );

END {
    t::lib::Car->_collection->drop;
}

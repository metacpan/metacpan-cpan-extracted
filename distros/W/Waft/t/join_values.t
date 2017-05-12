
use Test;
BEGIN { plan tests => 10 };

use strict;
BEGIN { eval { require warnings } ? 'warnings'->import : ( $^W = 1 ) }

use base 'Waft';

my $obj = __PACKAGE__->new;

$obj->clear_values;

$obj->{ q{ %-} } = q{ %-};
ok( $obj->join_values('ALL_VALUES') eq '%20%25%2d-%20%25%2d' );

$obj->{a} = q{};
ok( $obj->join_values('ALL_VALUES') eq '%20%25%2d-%20%25%2d a-' );

$obj->set_values( b => ( q{}, q{} ) );
ok( $obj->join_values('ALL_VALUES') eq '%20%25%2d-%20%25%2d a- b--' );

$obj->set_values( c => () );
ok( $obj->join_values('ALL_VALUES') eq '%20%25%2d-%20%25%2d a- b-- c' );

$obj->clear_values;

ok( @{ $obj->keys_arrayref } == 0 );

$obj->initialize_values('%20%25%2d-%20%25%2d a- b-- c');

ok( $obj->{ q{ %-} } eq q{ %-} );
ok( $obj->{a} eq q{} );
ok( $obj->{b} eq q{} );
ok( $obj->get_value('b', 1) eq q{} );
ok( not defined $obj->{c} );

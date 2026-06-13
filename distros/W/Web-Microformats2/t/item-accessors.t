use strict;
use warnings;
use Test::More;

use Web::Microformats2::Item;

# The five prefix-keyed property attributes (plain, p-, u-, e-, dt-) are
# identical in shape and a candidate for being generated in a loop (issue #12).
# Whatever the implementation, every prefix must still expose its has_*
# accessors and behave as a per-prefix property store. This guards the refactor.

my %accessors = (
    ''   => [ qw( has_properties    has_property    ) ],
    'p-' => [ qw( has_p_properties  has_p_property  ) ],
    'u-' => [ qw( has_u_properties  has_u_property  ) ],
    'e-' => [ qw( has_e_properties  has_e_property  ) ],
    'dt-'=> [ qw( has_dt_properties has_dt_property ) ],
);

my $item = Web::Microformats2::Item->new( types => [ 'entry' ] );

for my $prefix ( sort keys %accessors ) {
    can_ok( $item, $_ ) for @{ $accessors{ $prefix } };
}

# Each prefix store should be independently addressable: adding a property
# under one prefix lands in that prefix's store and nowhere else.
$item->add_property( 'p-name', 'Alice' );
$item->add_property( 'u-url',  'http://example.com/' );

is_deeply( $item->get_properties( 'name' ), [ 'Alice' ],
    'p- property is retrievable' );
is_deeply( $item->get_properties( 'url' ), [ 'http://example.com/' ],
    'u- property is retrievable' );

ok( $item->has_p_property( 'name' ), 'name is stored in the p- prefix store' );
ok( $item->has_u_property( 'url' ),  'url is stored in the u- prefix store' );
ok( !$item->has_u_property( 'name' ),
    'name did not leak into the u- prefix store' );

done_testing;

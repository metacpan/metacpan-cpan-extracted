package My::Types;

use Carp;
use Type::Utils;
use Type::Library -base,
  -declare => 'MinMax',
  'Bounds', 'Positive';

use Types::Standard -types, 'is_Num';

use Type::TinyX::Facets;

# independent facets
facet 'min', sub {
    my ( $o, $var ) = @_;
    return unless exists $o->{min};
    croak( "argument to 'min' facet must be a number\n" )
      unless is_Num( $o->{min} );
    sprintf( '%s >= %s', $var, delete $o->{min} );
};

facet 'max', sub {
    my ( $o, $var ) = @_;
    return unless exists $o->{max};
    croak( "argument to 'max' facet must be a number\n" )
      unless is_Num( $o->{max} );
    sprintf( '%s <= %s', $var, delete $o->{max} );
};

declare MinMax, as Num, with_facets [ 'min', 'max' ];

# related facets
facet bounds => sub {
    my ( $o, $var ) = @_;
    return unless exists $o->{max} || exists $o->{min};
    croak( "constraint fails condition: max >= min\n" )
      if exists $o->{max} && exists $o->{min} && $o->{max} < $o->{min};

    my @code;

    if ( exists $o->{min} ) {
        croak( "argument to 'min' facet must be a number\n" )
          unless is_Num( $o->{min} );
        push @code, sprintf( '%s >= %s', $var, delete $o->{min} );
    }

    if ( exists $o->{max} ) {
        croak( "argument to 'max' facet must be a number\n" )
          unless is_Num( $o->{max} );
        push @code, sprintf( '%s <= %s', $var, delete $o->{max} );
    }

    return join( ' and ', @code );
};

declare Bounds, as Num, with_facets ['bounds'];


# on-the-fly creation of a facet
declare Positive, as Num, with_facets [
    'min', 'max',
    positive => sub {
        my ( $o, $var ) = @_;
        return unless exists $o->{positive};
        delete $o->{positive};
        sprintf( '%s > 0', $var );
    },
];

1;

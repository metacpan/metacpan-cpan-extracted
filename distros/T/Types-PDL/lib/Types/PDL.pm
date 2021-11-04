package Types::PDL;

# ABSTRACT: PDL types using Type::Tiny

use v5.10;

use strict;
use warnings;

our $VERSION = '0.04';

use Type::Library -base,
  -declare => qw[
    NDArray
    NDArray0D
    NDArray1D
    NDArray2D
    NDArray3D
    NDArrayFromAny
    ],

    # eventually will be deprecated
  qw[
    Piddle
    Piddle0D
    Piddle1D
    Piddle2D
    Piddle3D
    PiddleFromAny
  ];


use Types::Standard -types, 'is_Int';
use Type::Utils;
use Type::TinyX::Facets;
use B qw(perlstring);

sub _croak {
    require Carp;
    goto \&Carp::croak;
}


facet 'empty', sub {
    my ( $o, $var ) = @_;
    return unless exists $o->{empty};
    sprintf( '%s%s->isempty', !!delete( $o->{empty} ) ? '' : '!', $var );
};

facet 'null', sub {
    my ( $o, $var ) = @_;
    return unless exists $o->{null};
    sprintf( '%s%s->isnull', !!delete( $o->{null} ) ? '' : '!', $var );
};

facet ndims => sub {
    my ( $o, $var ) = @_;

    my %o = map { ( $_ => delete $o->{$_} ) }
      grep { exists $o->{$_} } qw[ ndims ndims_min ndims_max ];

    return unless keys %o;

    _croak( "'$_' must be an integer\n" )
      for grep { !is_Int( $o{$_} ) } keys %o;


    if ( exists $o{ndims_max} and exists $o{ndims_min} ) {

        if ( $o{ndims_max} < $o{ndims_min} ) {
            _croak( "'ndims_min' must be <= 'ndims_max'\n" );
        }

        elsif ( $o{ndims_min} == $o{ndims_max} ) {

            _croak(
                "cannot mix 'ndims' facet with either 'ndims_min' or 'ndims_max'\n"
            ) if exists $o{ndims};

            $o{ndims} = delete $o{ndims_min};
            delete $o{ndims_max};
        }
    }

    my @code;

    if ( exists $o{ndims_max} or exists $o{ndims_min} ) {

        if ( exists $o{ndims_min} ) {
            push @code, sprintf( '%s->ndims >= %d', $var, delete $o{ndims_min} );
        }

        if ( exists $o{ndims_max} ) {
            push @code, sprintf ( '%s->ndims <= %d', $var, delete $o{ndims_max} );
        }
    }

    elsif ( exists $o{ndims} ) {
        push @code, sprintf( '%s->ndims == %d', $var, delete $o{ndims} );
    }

    else {
        return;
    }

    _croak( "cannot mix 'ndims' facet with either 'ndims_min' or 'ndims_max'\n" )
      if keys %o;

    return join( ' and ', @code );
};


facet 'type', sub {
    my ( $o, $var ) = @_;
    return unless exists $o->{type};
    my $type = eval { PDL::Type->new( delete $o->{type} )->ioname };
    _croak( "type must be a valid type name or a PDL::Type object: $@\n" )
      if $@;

    sprintf ( '%s->type->ioname eq q[%s]', $var, $type );
};

facet 'shape', sub {
    my ( $o, $var ) = @_;
    return unless exists $o->{shape};

    my $shape = delete $o->{shape};

    _croak( "shape must be a string or an arrayref of specifications" )
      unless 'ARRAY' eq ref $shape or ! ref $shape;

    sprintf( q|join( ',', %s->dims) =~ qr/%s/x|, $var, _mk_shape_regexp( $shape ) );
};

# --------------------------------------------------------------------------#
# eventually will be deprecated

facetize qw[ empty null ndims type shape ], class_type Piddle, { class => 'PDL' };

facetize qw[ null type ], declare Piddle0D, as Piddle [ ndims => 0 ];

facetize qw[ empty null type shape ], declare Piddle1D, as Piddle [ ndims => 1 ];

facetize qw[ empty null type shape ], declare Piddle2D, as Piddle [ ndims => 2 ];

facetize qw[ empty null type shape ], declare Piddle3D, as Piddle [ ndims => 3 ];

declare_coercion PiddleFromAny, to_type Piddle, from Any, q[ do { local $@;
          require PDL::Core;
          my $new = eval { PDL::Core::topdl( $_ )  };
          $@ ? $_ : $new
     }
  ];


# --------------------------------------------------------------------------#

facetize qw[ empty null ndims type shape ], class_type NDArray, { class => 'PDL' };

facetize qw[ null type ], declare NDArray0D, as NDArray [ ndims => 0 ];

facetize qw[ empty null type shape ], declare NDArray1D, as NDArray [ ndims => 1 ];

facetize qw[ empty null type shape ], declare NDArray2D, as NDArray [ ndims => 2 ];

facetize qw[ empty null type shape ], declare NDArray3D, as NDArray [ ndims => 3 ];

declare_coercion NDArrayFromAny, to_type NDArray, from Any, q[ do { local $@;
          require PDL::Core;
          my $new = eval { PDL::Core::topdl( $_ )  };
          $@ ? $_ : $new
     }
  ];


# --------------------------------------------------------------------------#


sub _mk_shape_regexp {

    my $spec = shift;

    # positive integer
    my $int = q/(?:[0123456789]+)/;

    my $re = qr/
               \s*(?:
                   (?:
                       (?<int> $int )
                       |
                       (?<any> X | : ) )
                   (?:
                        (?<quant>[*+?])
                    | (?:\{
                                (?<min>$int)
                                (?:(?<comma>,) (?<max>$int)? )?
                         \}
                        )
                   )?
               )
               \s*
               /x;

    my @spec;

    if ( !ref $spec ) {
        push @spec, { %+ }  while $spec =~ /\G$re,?/gc;
        _croak( "error in spec starting HERE ==>",
            substr( $spec, pos( $spec ) || 0 ), "<\n" )
          if ( pos( $spec ) || 0 ) != length( $spec );
    }
    else {

        @spec = map {
            _croak( "error parsing spec: >$_<\n" )
              unless /^$re$/;
            +{ %+ }
        } @$spec;
    }


    my @shape;

    for my $spec ( @spec ) {

        my $extent;

        if ( defined $spec->{int} ) {
            $extent = $spec->{int};
            _croak( "extent cannot be zero"  )
              if ( $extent += 0 ) == 0;
        }
        else {
            $extent = $int;
        }

        my $res = "(?:${extent},?)";


        if ( defined $spec->{quant} ) {
            $res .= $spec->{quant};
        }
        elsif ( defined $spec->{min} ) {

                $res .= '{' . $spec->{min};

                $res .= ',' if defined $spec->{comma};
                $res .= $spec->{max} if defined $spec->{max};
                $res .= '}';
            }

        push @shape, $res;
    }

    #  this must be a string!
    return '^' . join( '', @shape ) . '$';
}



1;

#
# This file is part of Types-PDL
#
# This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=head1 NAME

Types::PDL - PDL types using Type::Tiny

=head1 VERSION

version 0.04

=head1 SYNOPSIS

  use Types::PDL -types;
  use Type::Params qw[ validate ];
  use PDL;

  validate( [ pdl ], NDArray );

=head1 DESCRIPTION

This module provides L<Type::Tiny> compatible types for L<PDL>.

=head2 Types

Types which accept parameters (see L</Parameters>) will list them.

=head3 C<NDArray> | C<Piddle> (I<deprecated>)

Allows an object blessed into the class C<PDL>, e.g.

  validate( [pdl], NDarray );

It accepts the following parameters:

  null
  empty
  ndims
  ndims_min
  ndims_max
  shape
  type

=head3 C<NDArray0D> | C<Piddle0D> (I<deprecated>)

Allows an object blessed into the class C<PDL> with C<ndims> = 0.
It accepts the following parameters:

  null
  type

=head3 C<NDArray1D> | C<Piddle1D> (I<deprecated>)

Allows an object blessed into the class C<PDL> with C<ndims> = 1.
It accepts the following parameters:

  null
  empty
  shape
  type

=head3 C<NDArray2D> | C<Piddle2D> (I<deprecated>)

Allows an object blessed into the class C<PDL> with C<ndims> = 2.
It accepts the following parameters:

  null
  empty
  shape
  type

=head3 C<NDArray3D> | C<Piddle3D> (I<deprecated>)

Allows an object blessed into the class C<PDL> with C<ndims> = 3.
It accepts the following parameters:

  null
  empty
  shape
  type

=head2 Coercions

The following coercions are provided, and may be applied via a type
object's L<Type::Tiny/plus_coercions> or
L<Type::Tiny/plus_fallback_coercions> methods, e.g.

  NDArray->plus_coercions( NDArrayFromAny );

=head3 C<NDArrayFromAny> | C<PiddleFromAny> (I<deprecated>)

Uses L<PDL::Core/topdl> to coerce the value into a PDL object.

=head2 Parameters

Some types take optional parameters which add additional constraints
on the object.  For example, to indicate that only empty PDL objects are
accepted:

  validate( [pdl], NDArray[ empty => 1 ] );

The available parameters are:

=head3 C<empty>

This accepts a boolean value; if true the PDL object must be empty
(i.e. the C<isempty> method returns true), if false, it must not be
empty.

=head3 C<null>

This accepts a boolean value; if true the PDL object must be a null
PDL object, if false, it must not be null.

=head3 C<ndims>

This specifies a fixed number of dimensions which the PDL object must
have. Don't mix use this with C<ndims_min> or C<ndims_max>.

=head3 C<ndims_min>

The minimum number of dimensions the PDL object may have. Don't specify
this with C<ndims>.

=head3 C<ndims_max>

The maximum number of dimensions the PDL object may have. Don't specify
this with C<ndims>.

=head3 C<shape>

The shape of the PDL object.

The value is a list of specifications for dimensions, expressed either
as elements in a Perl array or as comma-delimited fields in a string.

The specifications are reminiscent of regular expressions.  A specification
is composed of an extent size followed by an optional quantifier indicating
the number of dimensions it should match.

Extent sizes may be

=over

=item 1

A non-zero positive integer representing the extent of the dimension.

=item 2

The strings C<X> or C<:> indicating that any extent is accepted for that dimension

=back

Quantifiers may be

  *           Match 0 or more times
  +           Match 1 or more times
  ?           Match 1 or 0 times
  {n}         Match exactly n times
  {n,}        Match at least n times
  {n,m}       Match at least n but not more than m times

Here are some example specifications and the shapes they might match  (in the match, C<X> means any extent):

  2,2     => (2,2)
  3,3,3   => (3,3,3)
  3{3}    => (3,3,3)
  3{2,3}  => (3,3),  (3,3,3)
  1,X     => (1,X)
  1,X+    => (1,X), (1,X,X),  (1,X,X,X), ...
  1,X{1,} => (1,X), (1,X,X),  (1,X,X,X), ...
  1,X?,3   => (1,X,3), (1,3)
  1,2,X*   => (1,2), (1,2,X),  (1,2,X,X), ...
  1,2,3*,5   => (1,2,5), (1,2,3,5),  (1,2,3,3,5), ...

=head3 C<type>

The type of the PDL object. The value may be a L<PDL::Type> object or a
string containing the name of a type (e.g., C<double>). For a complete
list of types, run this command:

  perl -MPDL::Types=mapfld,ppdefs \
    -E 'say mapfld( $_ => 'ppsym' => 'ioname' )  for ppdefs'

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-types-pdl@rt.cpan.org  or through the web interface at: https://rt.cpan.org/Public/Dist/Display.html?Name=Types-PDL

=head2 Source

Source is available at

  https://gitlab.com/djerius/types-pdl

and may be cloned from

  https://gitlab.com/djerius/types-pdl.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<package Types::PDL;|package Types::PDL;>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut

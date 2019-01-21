package Type::TinyX::Facets;

# ABSTRACT: Easily create a facet parameterized Type::Tiny type

use strict;
use warnings;

our $VERSION = '0.03';

use B qw(perlstring);
use base 'Exporter::Tiny';
use Exporter::Tiny qw(mkopt);
use Carp;
use Safe::Isa;

our @EXPORT = qw'facet facetize';

my %FACET;




























sub facet {

    my ( $name, $coderef ) = @_;

    my $caller = caller;

    $FACET{$caller} ||= {};
    $FACET{$caller}{$name} = $coderef;
}




























sub facetize {

    # type may be first or last parameter
    my $self
      = $_[-1]->$_isa( 'Type::Tiny' )
      ? pop
      : croak( "type object must be last parameter\n" );

    my $FACET = $FACET{ caller() };

    my @facets = map {
        my ( $facet, $sub ) = @{$_};
        $sub ||= $FACET->{$facet} || croak( "unknown facet: $facet" );
        [ $facet, $sub ];
    } @{ mkopt( \@_ ) };


    my $name = "$self";

    my $inline_generator = sub {
        my %p_not_destroyed = @_;
        return sub {
            my %p   = %p_not_destroyed;    # copy;
            my $var = $_[1];
            my $r   = sprintf(
                '(%s)',
                join( ' and ',
                    $self->inline_check( $var ),
                    map { $_->[1]->( \%p, $var, $_->[0] ) } @facets ),
            );

            croak sprintf(
                'Attempt to parameterize type "%s" with unrecognised parameter%s %s',
                $name,
                scalar( keys %p ) == 1 ? '' : 's',
                join( ", ", map( qq["$_"], sort keys %p ) ),
            ) if keys %p;
            return $r;
        };
    };

    $self->{inline_generator}     = $inline_generator;
    $self->{constraint_generator} = sub {
        my $sub = sprintf( 'sub { %s }',
            $inline_generator->( @_ )->( $self, '$_[0]' ),
        );
        ## no critic( ProhibitStringyEval )
        eval( $sub ) or croak "could not build sub: $@\n\nCODE: $sub\n";
    };
    $self->{name_generator} = sub {
        my ( $s, %a ) = @_;
        sprintf( '%s[%s]',
            $s, join q[,],
            map sprintf( "%s=>%s", $_, perlstring $a{$_} ),
            sort keys %a );
    };

    return if $self->is_anon;

    ## no critic( ProhibitNoStrict )
    no strict qw( refs );
    no warnings qw( redefine prototype );
    *{ $self->library . '::' . $self->name } = $self->library->_mksub( $self );
}



1;

#
# This file is part of Type-TinyX-Facets
#
# This software is copyright (c) 2017 by Smithsonian Astrophysical Observatory.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory facetize TOBYINK thusly
GitLab

=head1 NAME

Type::TinyX::Facets - Easily create a facet parameterized Type::Tiny type

=head1 VERSION

version 0.03

=head1 SYNOPSIS

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
 
 facetize qw[min max], declare MinMax, as Num;
 
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
 
 facetize qw[bounds], declare Bounds, as Num;
 
 
 # on-the-fly creation of a facet
 facetize positive => sub {
     my ( $o, $var ) = @_;
     return unless exists $o->{positive};
     delete $o->{positive};
     sprintf( '%s > 0', $var );
   },
   qw[ min max ],
   declare Positive, as Num;
 
 1;

And in some other code:

 use My::Types -types;
 use Type::Params qw[ validate ];
 
 validate( [5], MinMax [ min => 2 ] );              # passes
 validate( [5], MinMax [ min => 2, max => 6 ] );    # passes
 
 validate( [5], Bounds [ min => 2 ] );              # passes
 validate( [5], Bounds [ min => 2, max => 6 ] );    # passes
 validate( [5], Bounds [ min => 5, max => 2 ] )
   ;    # fails to construct as min > max
 
 validate( [0], Positive [ positive => 1 ] );    # fails!
 validate( [1], Positive [ positive => 1 ] );    # passes

=head1 DESCRIPTION

B<Type::TinyX::Facets> make it easy to create parameterized types with facets.

C<Type::Tiny> allows definition of types which can accept parameters:

  use Types::Standard -types;

  my $t1 = Array[Int];
  my $t2 = Tuple[Int, HashRef];

This defines C<$t1> as an array of integers.  and C<$t2> as a tuple of
two elements, an integer and a hash.

Parameters are passed as a list to the parameterized constraint
generation machinery, and there is great freedom in how they may be interpreted.

This module makes it easy to create a parameterized type which takes
I<name - value> pairs
or,L<facets|https://en.wikipedia.org/wiki/Faceted_classification>. (The
terminology is taken from L<Types::XSD::Lite>, to which this module
owes its existence.)

=head2 Alternate Names

B<Type::TinyX::Facets> uses L<Exporter::Tiny>, so one might correct(!?) the spelling of L</facetize> thusly:

  use Type::TinyX::Facets facetize => { -as => "facetise" };

=head1 SUBROUTINES

=head2 facet( $name, $coderef )

Declare a facet with the given name and code generator. C<$coderef>
will be called as

  $coderef->( $options, $name, $facet_name );

where C<$options> is a hash of the parameters passed to the type, and
C<$name> is the name of the variable to check against.

The code should return if the passed options are of no interest (and
thus the facet should not be applied), otherwise it should return a
string containing the validation code.  I<< It must delete the parameters
that it uses from C<$o> >>.

For example, to implement a minimum value check:

  facet 'min',
    sub { my ( $o, $var ) = @_;
          return unless exists $o->{min};
          croak( "argument to 'min' facet must be a number\n" )
            unless is_Num( $o->{min} );
          sprintf('%s >= %s', $var, delete $o->{min} );
      };

=head2 facetize( @facets, $type )

Add the specified facets to the given type.  The type should not have
any constraints other than through inheritance from a parent type.

C<@facets> is a list of facets.  If a facet was previously created with the
L</facet> subroutine, only the name (as a string) need be specified. A facet
may also be specified as a name, coderef pair, e.g.

  @facets = (
      'min',
      positive => sub {  my ($o, $var) = @_;
                         return unless exists $o->{positive};
                         delete $o->{positive};
                         sprintf('%s > 0', $var);
                     }
  );

Typically B<facetize> is applied directly to a L<Type::Utils/declare>
statement, e.g.:

  facetize @facets,
    declare T1, as Num;

=head1 LIMITATIONS

Facets defined in one package are not available to another package.

=head1 THANKS

=over

=item L<TOBYINK|https://metacpan.org/author/TOBYINK>

The idea and most of the code was lifted from L<Types::XSD::Lite>.
Any bugs are definitely mine.

=back

=head1 SOURCE

The development version is on GitLab at L<https://gitlab.com/djerius/type-tinyx-facets>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Type-TinyX-Facets>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Smithsonian Astrophysical Observatory.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

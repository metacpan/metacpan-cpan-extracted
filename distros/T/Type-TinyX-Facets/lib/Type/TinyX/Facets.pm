package Type::TinyX::Facets;

# ABSTRACT: Easily create a facet parameterized Type::Tiny type

use strict;
use warnings;

our $VERSION = '1.3';

use B              ();
use Exporter::Tiny ();
use Eval::TypeTiny ();
use Safe::Isa;

use parent 'Exporter::Tiny';
our @EXPORT = qw( with_facets facet facetize );

# handle both generations of Type::Tiny interfaces to create library
# subs. only used by facetize.
my $type_to_coderef
  = exists &Eval::TypeTiny::type_to_coderef
  ? \&Eval::TypeTiny::type_to_coderef
  : do {
    require Type::Library;
    exists &Type::Library::_mksub;
  }
  ? sub { $_[0]->library->_mksub( $_[0] ) }
  : _croak( "can't find type-to-coderef function?" );

sub _croak {
    require Carp;
    goto &Carp::croak;
}

my %FACET;




























sub facet {

    my ( $name, $coderef ) = @_;

    my $caller = caller();

    $FACET{$caller} ||= {};
    $FACET{$caller}{$name} = $coderef;
}






















sub with_facets {
    _with_facets( scalar caller(), @_ );
}


sub _with_facets {

    my ( $caller, $facets ) = ( shift, shift );

    my $FACET = $FACET{$caller};

    my @facets = map {
        my ( $facet, $sub ) = @{$_};
        $sub ||= $FACET->{$facet} || _croak( "unknown facet: $facet" );
        [ $facet, $sub ];
    } @{ Exporter::Tiny::mkopt( $facets ) };


    # so blithely stolen from Type::XSD::Lite.  Thanks TOBYINK!
    my %return;
    my $IG = $return{inline_generator} = sub {
        my %p_not_destroyed = @_;
        return sub {
            my %p   = %p_not_destroyed;    # copy;
            my $var = $_[1];
            my @r   = map $_->[1]->( \%p, $var, $_->[0] ), @facets;
            _croak sprintf(
                'Attempt to parameterize type "%s" with unrecognised parameter%s %s',
                $_[0]->name,
                scalar( keys %p ) == 1 ? '' : 's',
                Type::Utils::english_list( map( qq["$_"], sort keys %p ) ),
            ) if keys %p;
            return ( undef, @r );
        };
    };

    $return{constraint_generator} = sub {
        my $base   = do { no warnings 'once'; $Type::Tiny::parameterize_type };
        my %params = @_ or return $base;
        my @checks = $IG->( %params )->( $base, '$_[0]' );
        $checks[0] = $base->inline_check( '$_[0]' );
        my $sub = sprintf( 'sub { %s }', join( ' and ', map "($_)", @checks ), );
        ## no critic (ProhibitStringyEval)
        eval( $sub ) or _croak "could not build sub: $@\n\nCODE: $sub\n";
    };

    $return{name_generator} = sub {
        my ( $s, %a ) = @_;
        sprintf( '%s[%s]', $s, join q[,], map sprintf( "%s=>%s", $_, B::perlstring $a{$_} ), sort keys %a );
    };

    return ( %return, @_ );
}
































sub facetize {

    # maybe at some later date, just to annoy.
    # warnings::warnif( 'deprecated',
    #                     q{'facetize' is deprecated; use 'with_facets' instead.} );

    # type may be first or last parameter
    my $self
      = $_[-1]->$_isa( 'Type::Tiny' )
      ? pop
      : _croak( "type object must be last parameter\n" );

    my %args = _with_facets( scalar caller(), \@_ );

    # old skool poke at the guts. need to do this in-place, and
    # Type::Tiny objects are pretty immutable, e.g. there is no
    # defined API to modify them after they're creaed.  which is why
    # this approach is deprecated.
    $self->{$_} = $args{$_} for keys %args;

    return if $self->is_anon;

    ## no critic( ProhibitNoStrict )
    no strict qw( refs );
    no warnings qw( redefine prototype );
    *{ $self->library . '::' . $self->name } = $type_to_coderef->( $self );
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

version 1.3

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

=head2 with_facets

   ..., with_facets \@facets, ...

Add a facet to the type being declared.  C<with_facets> takes an
arrayref of one or more facet names or coderefs to apply to the type,
e.g.

   declare BoundedEvenInt, as Int,
   with_facets [ 'min', 'max',
      even => sub {  my ($o, $var) = @_;
                     return unless exists $o->{even};
                     delete $o->{even};
                     "! ( ${var} % 2 )";
                  },
   ],
   message { "This failed" }
   ;

=head2 facetize( @facets, $type )

B<DEPRECATED>. This function currently pokes at L</Type::Tiny>'s innards, and future
compatibility cannot be guaranteed.

Use L</with_facets> instead.

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

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to   or through the web interface at: https://rt.cpan.org/Public/Dist/Display.html?Name=Type-TinyX-Facets

=head2 Source

Source is available at 

  https://gitlab.com/djerius/type-tinyx-facets

and may be cloned from

  https://gitlab.com/djerius/type-tinyx-facets.git

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Smithsonian Astrophysical Observatory.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

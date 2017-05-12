package pragma;
use strict;
use warnings;
use Carp 'carp';

our $VERSION = '0.02';
our $DEBUG;

=head1 NAME

pragma - A pragma for controlling other user pragmas

=head1 DESCRIPTION

The C<pragma> pragma is a module which influences other user pragmata
such as L<lint>. With Perl 5.10 you can create user pragmata and the
C<pragma> pragma can modify and peek at other pragmata.

=head1 SUBCLASSING

All methods may be subclassed. Importing pragma with the single
parameter '-base' will do the proper stuff so your class is now a
pragma.

  package your_pragma;
  use pragma -base;

  # Woot!

  1;

Subclassed pragmas are stored in the hints hash with their package
name as a prefix. This prevents pragmas from unintentionally stomping
on each other.

  # sets 'your::pragma::foo = 42
  use your_prama foo => 42;

=head1 A BASIC EXAMPLE

Assume you're using the C<myint> pragma mentioned in
L<perlpragma>. For ease, that pragma is duplicated here. You'll see it
sets the C<myint> value to 1 when on and 0 when off.

    package myint;
    
    use strict;
    use warnings;
    
    sub import {
        $^H{myint} = 1;
    }
    
    sub unimport {
        $^H{myint} = 0;
    }
    
    1;

Other code might casually wish to dip into C<myint>:
    
    no pragma 'myint';      # delete $^H{myint}
    use pragma myint => 42; # $^H{myint} = 42

    print pragma->peek( 'myint' ); # prints '42'

The above could have been written without the C<pragma> module as:

    BEGIN { delete $^H{myint} }
    BEGIN { $^H{myint} = 42 }

    print $^H{myint};

=cut

=head1 CLASS METHODS

=over

=item C<< use pragma PRAGMA => VALUE >>

=item C<< pragma->import( PRAGMA => VALUE ) >>

=item C<< pragma->poke( PRAGMA => VALUE ) >>

Sets C<PRAGMA>'s value to C<VALUE>.

=cut

# TODO: figure out how to get Module::Compile::TT to integrate nicely
# so instead of a pragma.pm and pragma.pmc I have in the source distro
# a src/lib/pragma.pm and a lib/pragma.pm.

# use tt subs => [qw[import poke]];
# [% FOREACH sub IN subs %]
sub import {

    # Handle "use pragma;"
    return if 1 == @_;

    # [% IF sub == 'import' %]
    # Handle "use pragma -base;"
    if ( 2 == @_ and $_[1] eq '-base' ) {
        no strict 'refs';
        my $tgt = caller;
        carp "$tgt ISA $_[0]\n" if $DEBUG;
        @{ caller() . '::ISA' } = $_[0];
        return;
    }

    # [% END %]

    # TODO: support "use pragma 'foo'" to mean "use pragma 'foo' =>
    # '1'"

    my $class = shift @_;
    $class = $class eq __PACKAGE__ ? '' : "$class\::";
    while (@_) {
        my ( $pragma, $value ) = splice @_, 0, 2;
        my $hh_pragma = "$class$pragma";

        $value //= '';
        carp "$hh_pragma = $value\n" if $DEBUG;
        $^H{$hh_pragma} = $value;
    }

    return;
}

# [% END ]
# no tt;

sub poke {

    my $class = shift @_;
    $class = $class eq __PACKAGE__ ? '' : "$class\::";
    while (@_) {
        my ( $pragma, $value ) = splice @_, 0, 2;
        my $hh_pragma = "$class$pragma";

        $value //= '';
        carp "$hh_pragma = $value\n" if $DEBUG;
        $^H{$hh_pragma} = $value;
    }

    return;
}

=item C<< no pragma PRAGMA >>

=item C<< pragma->unimport( PRAGMA ) >>

Unsets C<PRAGMA>.

=cut

sub unimport {

    # Handle "no pragma";
    return if 1 == @_;

    my ( $class, $pragma ) = @_;
    $class = $class eq __PACKAGE__ ? '' : "$class\::";
    my $hh_pragma = "$class$pragma";

    delete $^H{$hh_pragma} if exists $^H{$hh_pragma};
    return;
}

=item C<< pragma->peek( PRAGMA ) >>

Returns the current value of C<PRAGMA>.

=cut

sub peek {
    my ( $class, $pragma ) = @_;
    $class = $class eq __PACKAGE__ ? '' : "$class\::";

    # use Data::Dumper 'Dumper';
    # my $cx = 0;
    # while ( caller $cx ) {
    #     print Dumper( [ $cx, ( caller $cx )[10] ] );
    #     ++$cx;
    # }

    my $hints_hash = ( caller 0 )[10];
    return unless $hints_hash;
    return unless exists $hints_hash->{"$class$pragma"};
    return $hints_hash->{"$class$pragma"};
}

=back

=cut

q[And I don't think an entire stallion of horses, or a tank, could stop you two from getting married.];

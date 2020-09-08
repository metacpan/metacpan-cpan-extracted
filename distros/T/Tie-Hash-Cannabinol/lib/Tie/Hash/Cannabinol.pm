# $Id$

=head1 NAME

Tie::Hash::Cannabinol - Perl extension for creating hashes that forget things

=head1 SYNOPSIS

  use Tie::Hash::Cannabinol;

  my %hash;
  tie %hash, 'Tie::Hash::Cannabinol';

or

  my %hash : Stoned;

  # % hash can now be treated exactly like a normal hash - but don't trust
  # anything it tells you.

=head1 DESCRIPTION

Tie::Hash::Cannabinol is a completely useless demonstration of how to use
Tie::StdHash to pervert the behaviour of Perl hashes. Once a hash has been
C<tie>d to Tie::Hash::Cannabinol, there is a 25% chance that it will forget
anything that you tell it immediately and a further 25% chance that it 
won't be able to retrieve any information you ask it for. Any information
that it does return will be pulled at random from its keys.

Oh, and the return value from C<exists> isn't to be trusted either :)

=cut

package Tie::Hash::Cannabinol; 

use 5.006;
use strict;
use warnings;
use Tie::Hash;
use Attribute::Handlers autotie => { "__CALLER__::Stoned" => __PACKAGE__ };

our $VERSION = '1.12.0';
our @ISA = qw(Tie::StdHash);

=head2 STORE

Stores data in the hash 3 times out of 4.

=cut

sub STORE {
  my ($self, $key, $val) = @_;

  return if rand > .75;

  $self->{$key} = $val;
}

=head2 FETCH

Fetchs I<something> from the hash 3 times out of 4.

=cut

sub FETCH {
  my ($self, $key) = @_;

  return if rand > .75;

  return $self->{(keys %$self)[rand keys %$self]};
}

=head2 EXISTS

Gives very dodgy information about the existence of keys in the hash.

=cut

sub EXISTS {
  return rand > .5;
}

1;
__END__


=head1 AUTHOR

Dave Cross <dave@mag-sol.com>

=head1 UPDATES

The latest version of this module will always be available from
L<http://code.mag-sol.com/Tie-Hash-Cannabinol> or from CPAN
at L<http://search.cpan.org/dist/Tie-Hash-Cannabinol/>.

=head1 COPYRIGHT

Copyright (C) 2001-8, Magnum Solutions Ltd.  All Rights Reserved.

=head1 LICENSE

This script is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), perltie(1), Tie::StdHash(1)

=cut

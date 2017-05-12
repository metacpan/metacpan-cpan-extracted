# $Id: FixedKeys.pm 19 2008-06-30 14:51:47Z dave $

=head1 NAME

Tie::Hash::FixedKeys - Perl extension for hashes with fixed keys

=head1 SYNOPSIS

  use Tie::Hash::FixedKeys;

  my @keys = qw(forename surname date_of_birth gender);
  my %person;
  tie %person, 'Tie;::Hash::FixedKeys', @keys;

  @person{@keys} = qw(Fred Bloggs 19700101 M);

  $person{height} = "6'"; # generates a warning

or (new! improved!)

  use Tie::Hash::FixedKeys;

  my %person : FixedKeys(qw(forename surname date_of_birth gender));

=head1 DESCRIPTION

Tie::Hash::FixedKeys is a class which changes the behaviour of Perl hashes.
Any hash which is tied to this class can only contain a fixed set of keys.
This set of keys is given when the hash is tied. For example, after running
the code:

  my @keys = qw(forename surename date_of_birth gender);
  my %person;
  tie %person, 'Tie;::Hash::FixedKeys', @keys;

the hash C<%person> can only contain the keys forename, surname, 
date_of_birth and gender. Any attempt to set a value for another key
will generate a run-time warning.

=head2 ATTRIBUTE INTERFACE

From version 1.5, you can use attributes to set the keys for your hash.
You will need Attribute::Handlers version 0.76 or greater.

=head2 CAVEAT

The tied hash will always contain exactly one value for each of the keys
in the list. These values are initialised to C<undef> when the hash is
tied. If you try to C<delete> one if the keys, the effect is that the
value is reset to C<undef>.

=head2 NOTE

Versions of Perl from 5.8.0 include a module called L<Hash::Util> which
contains a function called C<lock_keys> which does the same as this module
but in a faster and more powerful way. I recommend that you use that 
method in place of this module.

This module is left on CPAN as an example of tied hashes.

=cut

package Tie::Hash::FixedKeys; 

use 5.006;
use strict;
use warnings;

use Tie::Hash;
use Carp;
use vars qw(@ISA $VERSION);

use Attribute::Handlers autotie => { "__CALLER__::FixedKeys" => __PACKAGE__ };

@ISA = qw(Tie::StdHash);

$VERSION = sprintf "%d", '$Revision: 19 $ ' =~ /(\d+)/;

=head1 METHODS

=head2 TIEHASH

Creates a tied hash containing all the keys initialised to C<undef>.

=cut

sub TIEHASH {
  my $class = shift;

  my %hash;
  @hash{@_} = (undef) x @_;

  bless \%hash, $class;
}

=head2 STORE

Attempts to store a value in the hash. If the key isn't in the valid
list (i.e. it doesn't already exist) the program croaks.

=cut

sub STORE {
  my ($self, $key, $val) = @_;

  unless (exists $self->{$key}) {
    croak "invalid key [$key] in hash\n";
  }
  $self->{$key} = $val;
}

=head2 DELETE

Delete a value from the hash. Actually it just sets the value back to
C<undef>.

=cut

sub DELETE {
  my ($self, $key) = @_;

  return unless exists $self->{$key};

  my $ret = $self->{$key};

  $self->{$key} = undef;

  return $ret;
}

=head2 CLEAR

Clears all values but resetting them to C<undef>.

=cut

sub CLEAR {
  my $self = shift;

  $self->{$_} = undef foreach keys %$self;
}

1;
__END__

=head1 AUTHOR

Dave Cross <dave@mag-sol.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2001, Magnum Solutions Ltd.  All Rights Reserved.

This script is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), perltie(1).

=cut

# DESCRIPTION Tie::Hash::TwoWay is a Perl module for associative
#  two-way mapping between two disjoint sets.  Elements of the sets
#  are treated as hash keys.
#
# AUTHOR
#   Teodor Zlatanov <tzz@lifelogs.com>
#
# COPYRIGHT
#   Copyright (C) 2001, 2005 Gold Software Systems
#
#   This script is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#

package Tie::Hash::TwoWay;

require 5.005_62;
use strict;
use vars qw($VERSION @ISA);
use Tie::Hash;
use Carp;

use constant PRIMARY   => 0;
use constant SECONDARY => 1;

$VERSION = sprintf "%d.%02d", '$Revision 1.8 $' =~ /(\d+)\.(\d+)/;
@ISA = qw/Tie::StdHash/;

# Preloaded methods go here.

sub STORE
{
 my ($self, $key, $value) = @_;
 my $val_array_ref;

 if (ref $value eq 'ARRAY')		# array refs can be recognized
 {
  $val_array_ref = $value;
 }
 else			# everything else gets converted to array refs
 {
  $val_array_ref = [ $value ];
 }

 # add the values in the passed array to the primary and secondary hashes
 foreach my $value (@$val_array_ref)
 {
  $self->{SECONDARY}->{$value}->{$key} = 1;
  $self->{PRIMARY}->{$key}->{$value} = 1;
 }

 return 1;
}

# return the primary or secondary key, in that order (duplicate keys
# are not detected here)
sub FETCH
{
 my ($self, $key) = @_;

 exists $self->{PRIMARY}->{$key} &&
  return $self->{PRIMARY}->{$key};

 exists $self->{SECONDARY}->{$key} &&
  return $self->{SECONDARY}->{$key};

 return undef;
}

# return the primary or secondary key existence, in that order
# (duplicate keys are not detected here)
sub EXISTS
{
 my ($self, $key) = @_;

 return undef unless (exists $self->{PRIMARY} &&
		      exists $self->{SECONDARY});
 
 return (exists $self->{PRIMARY}->{$key} ||
	 exists $self->{SECONDARY}->{$key});
}

# delete the primary or secondary key, in that order (duplicate keys
# are not detected here)
sub DELETE
{
 my ($self, $key) = @_;

 return undef unless (exists $self->{PRIMARY} &&
		      exists $self->{SECONDARY});

 # make sure to delete reverse associations as well
 if (exists $self->{PRIMARY}->{$key})
 {

  foreach (keys %{$self->{SECONDARY}})
  {
   delete $self->{SECONDARY}->{$_}->{$key};
   delete $self->{SECONDARY}->{$_}
    unless scalar keys %{$self->{SECONDARY}->{$_}};
  }

  return delete $self->{PRIMARY}->{$key};
 }
 
 if (exists $self->{SECONDARY}->{$key})
 {

  foreach (keys %{$self->{PRIMARY}})
  {
   delete $self->{PRIMARY}->{$_}->{$key};
   delete $self->{PRIMARY}->{$_}
    unless scalar keys %{$self->{PRIMARY}->{$_}};
  }

  return delete $self->{SECONDARY}->{$key};
 }
 
}

sub CLEAR
{
 my ($self, $key) = @_;

 %$self = ();				# clear the whole hash

 return 1;
}

sub FIRSTKEY
{
 my ($self) = @_;

 return undef unless (exists $self->{PRIMARY} &&
		      exists $self->{SECONDARY});
 
 return each %{$self->{PRIMARY}};
}

sub NEXTKEY
{
 my ($self, $lastkey) = @_;

 return undef unless (exists $self->{PRIMARY} &&
		      exists $self->{SECONDARY});
 
 return each %{$self->{PRIMARY}};
}

sub SCALAR
{
 my ($self) = @_;

 return undef unless (exists $self->{PRIMARY} &&
		      exists $self->{SECONDARY});
 
 return $self->{SECONDARY};
}

1;
__END__

=pod

=head1 NAME

Tie::Hash::TwoWay - Perl extension for two-way mapping between two disjoint sets

=head1 SYNOPSIS

  use Tie::Hash::TwoWay;
  tie %hash, 'Tie::Hash::TwoWay';

  my %list = (
	      Asimov => ['novelist', 'scientist'],
              King => ['novelist', 'horror'],
             );


  foreach (keys %list)			# these are the primary keys of the hash
  {
   $hash{$_} = $list{$_};
  }

  $hash{White} = 'novelist';
  $hash{White} = 'color';

  # these will all print 'yes'
  print 'yes' if exists $hash{scientist};
  print 'yes' if exists $hash{novelist}->{Asimov};
  print 'yes' if exists $hash{novelist}->{King};
  print 'yes' if exists $hash{novelist}->{White};
  print 'yes' if exists $hash{King}->{novelist};

  my $secondary = scalar %hash;
  print "Secondary keys: ";
  print "$_\n" foreach keys %$secondary;

=head1 DESCRIPTION

Tie::Hash::TwoWay will take a list of one-way associations and
transparently create their reverse.  For instance, say you have a list
of machines, and a list of classes that each machine belongs to.
Tie::Hash::TwoWay will take the machines, one by one, with an
associated array reference of class names, and build the reverse
mapping of classes to machines.  All the mappings are stored as
hashes.  You can access the secondary mappings as if they were hash
keys in their own right.

Deleting a key in either the forward or reverse mapping will delete
all its mappings in the other direction as well.  If a key has no more
mappings, the key itself is deleted as well. For example, if you
delete machine "joe" that was in class "extra", and there are no other
machines in class "extra", that class will be automatically deleted as
well.

Peculiarities, which might be considered bugs:

Duplicate keys, overlapping between the primary and the secondary, are
allowed (for instance, a class named the same as a machine).  Fetching
a key, checking for its existence, and deleting it will go to the
primary mapping first and then to the secondary.

The keys of the TwoWay hash are the keys of the primary mapping.  The
reverse mapping (which is just a hash reference) can be obtained by
using the scalar operator on the tied hash.

Everything is stored in hashes for faster access, at the expense of
memory.

=head2 EXPORT

Nothing.

=head1 AUTHOR

Teodor Zlatanov <tzz@lifelogs.com>

=head1 SEE ALSO

perl(1).

perldoc Tie::Hash
perldoc Tie::StdHash


=cut

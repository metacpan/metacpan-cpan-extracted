#!perl
package Tie::Hash::StructKeyed; 
# $Id: StructKeyed.pm 344 2005-04-14 23:43:00Z hakim $

use strict; use warnings;
use Tie::Hash;
use YAML;

our $VERSION       = "0.04";
our @ISA           = qw (Tie::Hash);

=head1 NAME

Tie::Hash::StructKeyed - use structures like hashes and arrays as keys to a hash

=head1 SYNOPSIS

   use Tie::Hash::StructKeyed;
   tie %hash,  'Tie::Hash::StructKeyed';

   $hash{[1,2,3]} = 'Keyed by listref';

   my $h = { one=>1, two=>2 };
   $hash{$h}      = 'Keyed by hashref';
    
=head1 DESCRIPTION

Tie::Hash::StructKeyed ties a hash so that you can use arrays, hashes or
complex structures as the key of the hash.

=head1 NOTE

The current implementation uses YAML to generate the hash-key for the
structure.  This is possibly the easiest way to get a powerful and flexible
key-hashing behaviour.

It does mean that the behaviour for objects is undefined: Two objects with
the same representation will hash the same.  The same object, after an internal
state change may hash differently.  Behaviour of objects as keys (or as part
of a key) is subject to change in future versions.

=cut

sub TIEHASH {
  my $something = shift;
  my ($class)   = ref ($something) || $something;
  return bless {}, $class;
}

sub STORE {
  my $self = shift;
	my ($key,$value) = @_;

  my $yaml = Dump($key);
  $self->{$yaml}[0] = $key;
  $self->{$yaml}[1] = $value;
}

sub FETCH {
  my $self = shift;

  my $key = (@_ > 1) ?  \@_ : shift;
    
  my $value = $self->{Dump($key)};
  return unless defined $value;
  return $value->[1];
}

sub DELETE {
  my $self = shift;
	
  my $key = (@_ > 1) ?  \@_ : shift;

  delete $self->{Dump($key)};
}

sub CLEAR {
  my $self = shift;

	%$self = ();
}

sub EXISTS {
  my $self = shift;

  my $key = (@_ > 1) ?  \@_ : shift;
  return exists $self->{Dump($key)};
}

sub FIRSTKEY {
  my $self = shift;
	
	my $a = keys %$self; # Resets the 'each' to the start
	my $key = scalar each %$self;
	return if (not defined $key);
	return $self->{$key}[0];
}

sub NEXTKEY {
  my $self = shift;

	my ($last_key) = @_;
	my $key = scalar each %$self;
	return if (not defined $key);
	return $self->{$key}[0];
}

sub DESTROY {
  my $self = shift;
}


=head1 AUTHOR

osfameron - osfameron@cpan.org

=head1 VERSION

Version 0.03 Apr 14 2005

 This program is free software; you can redistribute it
 and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl perltie

=cut

1;

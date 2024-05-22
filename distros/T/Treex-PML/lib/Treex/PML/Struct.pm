
=head1 NAME

Treex::PML::Struct - PML attribute value structure

=head1 DESCRIPTION

This class implements the data type 'structure'.  Structure consists
of items called members. Each member is a name-value pair, where the
name uniquely determines the member within the structure
(i.e. distinct members of a structure have distinct names).

=over 4

=cut

package Treex::PML::Struct;
use Carp;
use warnings;

use vars qw($VERSION);
BEGIN {
  $VERSION='2.28'; # version template
}
use strict;
use UNIVERSAL::DOES;

=item Treex::PML::Struct->new ({name=>value, ...},reuse?)

NOTE: Don't call this constructor directly, use Treex::PML::Factory->createStructure() instead!

Create a new structure (optionally initializing its members).  If
reuse is true, the hash reference passed may be reused (re-blessed)
into the structure.

=cut

sub new {
  my ($class,$hash,$reuse) = @_;
  if (ref $hash) {
    return $reuse ? bless $hash, $class 
                  : bless Treex::PML::CloneValue($hash), $class;
  } else {
    return bless {}, $class;
  }
}

=item $struct->get_member ($name)

Return value of the given member.

=cut

sub get_member {
  my ($self,$name) = @_;
  return unless defined $name;
  return $self->{$name};
}

=item $struct->set_member ($name,$value)

Set value of the given member.

=cut

sub set_member {
  my ($self,$name,$value) = @_;
  return unless defined $name;
  return $self->{$name}=$value;
}


=item $struct->delete_member ($name)

Delete the given member (returning its last value).

=cut

sub delete_member {
  my ($self,$name) = @_;
  return unless defined $name;
  return delete $self->{$name};
}

=item $struct->members ()

Return (assorted) list of names of all members.

=cut

sub members {
  return keys %{$_[0]};
}


=back

=cut

sub DESTROY {
  my ($self) = @_;
  %{$self}=(); # this should not be needed, but
               # without it, perl 5.10 leaks on weakened
               # structures, try:
               #   Scalar::Util::weaken({}) while 1
}

1;
__END__

=head1 SEE ALSO

L<Treex::PML>, L<Treex::PML::Factory>, L<Treex::PML::Schema>, L<Treex::PML::Container>, L<Treex::PML::Seq>, L<Treex::PML::Node>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2010 by Petr Pajas, 2010-2024 Jan Stepanek

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

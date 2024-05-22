
package Treex::PML::Alt;
use Carp;
use warnings;

use vars qw($VERSION);
BEGIN {
  $VERSION='2.28'; # version template
}
use strict;

=head1 NAME

Treex::PML::Alt - an alternative of uniformly typed PML values

=head1 DESCRIPTION

This class implements the attribute value type 'alternative'.

=over 4

=cut


=item Treex::PML::Alt->new (value1,value2,...)

Create a new alternative (optionally populated with given values).

NOTE: Don't call this constructor directly, use Treex::PML::Factory->createAlt() instead!

=cut

sub new {
  my $class = shift;
  return bless [@_],$class;
}


=item Treex::PML::Alt->new_from_ref (array_ref, reuse)

Create a new alternative consisting of values in a given array
reference.  If reuse is true, then the same array_ref scalar is reused
to represent the Treex::PML::Alt object (i.e. blessed). Otherwise, a copy is
created in the constructor.

NOTE: Don't call this constructor directly, use Treex::PML::Factory->createAlt() instead!

=cut

sub new_from_ref {
  my ($class,$array,$reuse) = @_;
  if ($reuse) {
    if (UNIVERSAL::isa($array,'ARRAY')) {
      return bless $array,$class;
    } else {
      croak("Usage: new_from_ref(ARRAY_REF,1) - arg 1 is not an ARRAY reference!");
    }
  } else {
    return bless [@$array],$class;
  }
}


=item $alt->values ()

Retrurns a its values (i.e. the alternatives).

=cut

sub values {
  return @{$_[0]};
}

=item $alt->count ()

Retrurn number of values in the alternative.

=cut

sub count {
  return scalar(@{$_[0]});
}

=item $alt->add (@values)

Add given values to the alternative. Only values which are not already
included in the alternative are added.

=cut

sub add {
  my $self = shift;
  $self->add_list(\@_);
  return $self;
}

=item $alt->add_list ($list)

Add values of the given list to the alternative. Only values which are
not already included in the alternative are added.

=cut

sub add_list {
  die 'Usage: Treex::PML::Alt->add_list() (wrong number of arguments!)'
    if @_!=2;
  my $self = shift;
  my $list = shift;
  my %a; @a{ @$self } = ();
  push @{$self}, grep { exists($a{$_}) ? 0 : ($a{$_}=1) } @$list;
  return $self;
}

=item $alt->delete_value ($value)

Delete all occurences of value $value. Values are compared as strings.

=cut

sub delete_value {
  die 'Usage: Treex::PML::Alt->delete_value($value) (wrong number of arguments!)'
    if @_!=2;
  my ($self,$value) = @_;
  @$self = grep { $_ ne $value } @$self;
  return $self;
}

=item $alt->delete_values ($value1,$value2,...)

Delete all occurences of values $value1, $value2,... Values are
compared as strings.

=cut

sub delete_values {
  my $self = shift;
  my %d; %d = @_;
  @$self = grep { !exists($d{$_}) } @$self;
  return $self;
}

=item $list->empty ()

Remove all values from the alternative.

=cut

sub empty {
  die 'Usage: Treex::PML::Alt->empty() (wrong number of arguments!)'
    if @_!=1;
  my $self = shift;
  @$self=();
  return $self;
}

=back

=head1 SEE ALSO

L<Treex::PML>, L<Treex::PML::Factory>, L<Treex::PML::Schema>, L<Treex::PML::List>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2010 by Petr Pajas, 2010-2024 Jan Stepanek

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut


1;

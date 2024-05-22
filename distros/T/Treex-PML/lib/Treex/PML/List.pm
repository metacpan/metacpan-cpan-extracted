
############################################################

=head1 NAME

Treex::PML::List - lists of uniformly typed PML values

=head1 DESCRIPTION

This class implements the attribute value type 'list'.

=over 4

=cut

package Treex::PML::List;
use Carp;
use warnings;

use vars qw($VERSION);
BEGIN {
  $VERSION='2.28'; # version template
}
use strict;

=item Treex::PML::List->new (val1,val2,...)

Create a new list (optionally populated with given values).

NOTE: Don't call this constructor directly, use Treex::PML::Factory->createList() instead!

=cut

sub new {
  my $class = shift;
  return bless [@_],$class;
}

=item Treex::PML::List->new_from_ref (array_ref, reuse)

Create a new list consisting of values in a given array reference.
Use this constructor instead of new() to pass large lists by reference. If
reuse is true, then the same array_ref scalar is used to represent the
Treex::PML::List object (i.e. blessed). Otherwise, a copy is created in
the constructor.

NOTE: Don't call this constructor directly, use Treex::PML::Factory->createList() instead!

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

=item $list->values ()

Returns all its values (i.e. the list members).

=cut

sub values {
  return @{$_[0]};
}

=item $list->count ()

Return number of values in the list.

=cut

sub count {
  return scalar(@{$_[0]});
}

=item $list->append (@values)

Append given values to the list.

=cut

sub append {
  my $self = shift;
  CORE::push(@$self,@_);
  return $self;
}
BEGIN{
*push = \&append;
}

=item $list->push (@values)

An alias for C<$list->append()).

=cut


=item $list->append_list ($list2)

Append values from a given list or ARRAY-reference to the current list.

=cut

sub append_list {
  my ($self, $list) = @_;
  CORE::push(@$self,@$list);
  return $self;
}


=item $list->insert ($index, @values)

Insert values before the value at a given position in the list.  The
index of the first position in the list is 0.  It is an error if
$index is less then 0. If $index equals the index of the last
value + 1, then values are appended to the list, but it is an error if
$index is greater than that.

=cut

sub insert {
  my $self = shift;
  my $pos = shift;
  $self->insert_list($pos,\@_);
  return $self;
}

=item $list->insert_list ($index, $list)

Insert all values in $list before the value at a given position in the
current list. The index of the first position in the current list is
0.  It is an error if $index is less then 0. If $index equals
the index of the last value + 1, then values are appended to the list,
but it is an error if $index is greater than that.

=cut

sub insert_list {
  die 'Usage: Treex::PML::List->insert_list($index,$list) (wrong number of arguments!)'
    if @_!=3;
  my ($self,$pos,$list) = @_;
  die 'Treex::PML::List->insert: position out of bounds' if ($pos<0 or $pos>@$self);
  if ($pos==@$self) {
    CORE::push(@$self,@$list);
  } else {
    splice @$self,$pos,0,@$list;
  }
  return $self;
}

=item $list->delete ($index, $count)

Delete $count values from the list starting at index $index.

=cut

sub delete {
  die 'Usage: Treex::PML::List->delete($index,$count) (wrong number of arguments!)'
    if @_!=3;
  my ($self,$pos,$count) = @_;
  die 'Treex::PML::List->insert: position out of bounds' if ($pos<0 or $pos>=@$self);
  splice @$self,$pos,$count;
  return $self;
}

=item $list->delete_value ($value)

Delete all occurences of value $value. Values are compared as strings.

=cut

sub delete_value {
  die 'Usage: Treex::PML::List->delete_value($value) (wrong number of arguments!)'
    if @_!=2;
  my ($self,$value) = @_;
  @$self = grep { $_ ne $value } @$self;
  return $self;
}

=item $list->delete_values ($value1,$value2,...)

Delete all occurences of values $value1, $value2,... Values are
compared as strings.

=cut

sub delete_values {
  my $self = shift;
  my %d; @d{@_} = ();
  @$self = grep { !exists($d{$_}) } @$self;
  return $self;
}

=item $list->replace ($index, $count, @list)

Replacing $count values starting at index $index by values provided
in the @list (the count of values in @list may differ from $count).

=cut

sub replace {
  die 'Usage: Treex::PML::List->replace($index,$count,@list) (wrong number of arguments!)'
    unless @_>=3;
  my $self = shift;
  my $pos = shift;
  my $count = shift;
  $self->replace_list($pos,\@_);
  return $self;
}

=item $list->replace_list ($index, $count, $list)

Like replace, but replacement values are taken from a Treex::PML::List
object $list.

=cut

sub replace_list {
  my ($self,$pos,$count,$list)=@_;
  die 'Usage: Treex::PML::List->replace_list($index,$count,$list) (wrong number of arguments!)'
    if @_!=4;
  die 'Treex::PML::List->replace_list: position out of bounds' if ($pos<0 or $pos>=@$self);
  splice @$self,$pos,$count,@$list;
  return $self;
}

=item $list->value_at ($index)

Return value at index $index. This is in fact the same as
$list->[$index] only $index is checked to be non-negative and less
then the index of the last value.

=cut

sub value_at {
  my ($self,$pos)=@_;
  die 'Usage: Treex::PML::List->value_at($index) (wrong number of arguments!)'
    if @_!=2;
  die 'Treex::PML::List->value_at: position out of bounds' if ($pos<0 or $pos>=@$self);
  return $self->[$pos];
}

=item $list->set_value_at ($index,$value)

Set value at index $index to $value. This is in fact the same as
assigning directly to $list->[$index], except that $index is checked
to be non-negative and less then the index of the last value.  Returns
$value.

=cut

sub set_value_at {
  my ($self,$pos,$value)=@_;
  die 'Usage: Treex::PML::List->set_value_at($index,$value) (wrong number of arguments!)'
    if @_!=3;
  die 'Treex::PML::List->set_value_index: position out of bounds' if ($pos<0 or $pos>=@$self);
  return $self->[$pos] = $value;
}

=item $list->index_of ($value)

Search the list for the first occurence of value $value. Returns index
of the first occurence or undef if the value is not in the
list. (Values are compared as strings.)

=cut

sub index_of {
  my ($self,$value)=@_;
  die 'Usage: Treex::PML::List->index_of($value) (wrong number of arguments!)'
    if @_!=2;
  return &Treex::PML::Index;
}

=item $list->unique_values ()

Return unique values in the list (ordered by the index of the first
occurence). Values are compared as strings.

=cut

sub unique_values {
  die 'Usage: Treex::PML::List->unique_values() (wrong number of arguments!)'
    if @_!=1;
  my $self = shift;
  my %a; 
  return grep { !($a{$_}++) } @$self;
}

=item $list->unique_list ()

Return a new Treex::PML::List object consisting of unique values in the
current list (ordered by the index of the first occurence).  Values
are compared as strings.

=cut

sub unique_list {
  die 'Usage: Treex::PML::List->unique_values() (wrong number of arguments!)'
    if @_!=1;
  my $self = shift;
  my %a; 
  my $class = ref $self;
  return $class->new_from_ref([grep { !($a{$_}++) } @$self],1);
}


=item $list->make_unique ()

Remove duplicated values from the list. Values are compared as
strings. Returns $list.

=cut

sub make_unique {
  die 'Usage: Treex::PML::List->make_unique() (wrong number of arguments!)'
    if @_!=1;
  my $self = shift;
  my %a; @$self = grep { !($a{$_}++) } @$self;
  return $self;
}



=item $list->empty ()

Remove all values from the list.

=cut

sub empty {
  die 'Usage: Treex::PML::List->empty() (wrong number of arguments!)'
    if @_!=1;
  my $self = shift;
  @$self=();
  return $self;
}


=back

=cut

=head1 SEE ALSO

L<Treex::PML>, L<Treex::PML::Factory>, L<Treex::PML::Schema>, L<Treex::PML::Alt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2010 by Petr Pajas, 2010-2024 Jan Stepanek

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut


1;

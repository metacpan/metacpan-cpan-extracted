
package Treex::PML::Seq;
use Carp;
use warnings;

use vars qw($VERSION);
BEGIN {
  $VERSION='2.24'; # version template
}
use strict;
use Treex::PML::List;
use Treex::PML::Seq::Element;


=head1 NAME

Treex::PML::Seq - sequence of PML values of various types

=head1 DESCRIPTION

This class implements the data type 'sequence'. A sequence contains of
zero or more elements (L<Treex::PML::Seq::Element>), each consisting of
a name and value. The ordering of elements in a sequence may be
constrained by a regular-expression-like pattern operating on element
names. Validation of a sequence against this constraint pattern is not
automatic but can be performed at any time on demand.

=over 4

=item Treex::PML::Seq->new (element_array_ref?, content_pattern?,$reuse?)

NOTE: Don't call this constructor directly, use Treex::PML::Factory->createSeq() instead!

Create a new sequence (optionally populated with elements from a given
array_ref).  Each element should be a Treex::PML::Element::Seq object. The
second optional argument is a regular expression constraint which can
be stored in the object and used later for validating content (see
validate() method below). The C<$reuse> argument is a boolean flag
indicating whether the passed array reference can be used directly (if
C<$reuse> is true) or copied (if C<$reuse> ise false).

=cut

  sub new {
    my ($class,$array,$content_pattern,$reuse) = @_;
    $array = [] unless defined($array);
    return bless [Treex::PML::List->new_from_ref($array,$reuse), # a list consisting of [name,value] pairs
		  $content_pattern                  # a content_pattern constraint
		 ],$class;
  }

=item $seq->elements ($name?)

Return a list of [ name, value ] pairs representing the sequence
elements. If the optional $name argument is given, select
only elements whose name is $name.

=cut

  sub elements {
    my ($self,$name)=@_;
    if (defined $name and $name ne '*') {
      return grep { $_->[0] eq $name } @{$_[0]->[0]};
    } else {
      return @{$_[0]->[0]};
    }
  }

=item $seq->elements_list ()

Like C<elements> without a name, only this method returns directly the
Treex::PML::List object associated with this sequence.

=cut

  sub elements_list {
    return $_[0]->[0];
  }


=item $seq->content_pattern ()

Return the regular expression constraint stored in the sequence object (if any).

=cut

  sub content_pattern {
    return $_[0]->[1];
  }

=item $seq->set_content_pattern ()

Store a regular expression constraint in the sequence object. This
expression can be used later to validate sequence content (see
validate() method).

=cut

  sub set_content_pattern {
    $_[0]->[1] = $_[1];
  }


=item $seq->values (name?)

If no name is given, return a list of values of all elements of the
sequence. If a name is given, return a list consisting of values of
elements with the given name.

In array context, the returned value is a list, in scalar
context the result is a Treex::PML::List object.

=cut

  sub values {
    my ($self,$name)=@_;
    my @values = map { $_->[1] } ((defined($name) and length($name))
				    ? (grep $_->[0] eq $name, @{$self->[0]})
				    : @{$self->[0]});
    return wantarray ? @values : bless \@values, 'Treex::PML::List'; #->new_from_ref(\@values,1);
  }

=item $seq->names ()

Return a list of names of all elements of the sequence. In array
context, the returned value is a list, in scalar context the result is
a Treex::PML::List object.

=cut

  sub names {
    my @names = map { $_->[0] } $_[0][0]->values;
    return wantarray ? @names : bless \@names, 'Treex::PML::List'; #Treex::PML::List->new_from_ref(\@names,1);
  }

=item $seq->element_at (index)

Return the element of the sequence on the position specified by a
given index. Elements in the sequence are indexed as elements in Perl
arrays, i.e. starting from $[, which defaults to 0 and nobody sane
should ever want to change it.

=cut

  sub element_at {
    my ($self, $index)=@_;
    return $self->[0][$index];
  }


=item $seq->name_at (index)

Return the name of the element on a given position.

=cut

  sub name_at {
    my ($self, $index)=@_;
    my $el =  $self->[0][$index];
    return $el->[0] if $el;
  }

=item $seq->value_at (index)

Return the value of the element on a given position.

=cut

  sub value_at {
    my ($self, $index)=@_;
    my $el =  $self->[0][$index];
    return $el->[1] if $el;
  }

=item $seq->delegate_names (key?)

If all element values are HASH-references, then it is possible to
store each element's name in its value under a given key (that is, to
delegate the name to the HASH value). The default value for key is
C<#name>. It is a fatal error to try to delegate names if some of the
values is not a HASH reference.

=cut

  sub delegate_names {
    my ($self,$key) = @_;
    $key = '#name' unless defined $key;
    if (grep { !UNIVERSAL::isa($_->[1],'HASH') } @{$self->[0]}) {
      croak("Error: sequence contains a non-HASH element (Treex::PML::Seq can only delegate names to values if all values are HASH refs)!");
    }
    foreach my $element (@{$self->[0]}) {
      $element->[1]{$key} = $element->[0]; # store element's name in key $key of its value
    }
  }


=item $seq->validate (content_pattern?)

Check that content of the sequence satisfies a constraint specified
by means of a regular expression C<content_pattern>. If no content_pattern is
given, the one stored with the object is used (if any; otherwise undef
is returned).

Returns: 1 if the content satisfies the constraint, 0 otherwise.

=cut

  sub validate {
    my ($self,$re) = @_;
    $re = $self->content_pattern if !defined($re);
    return unless defined $re;
    my $content = join "",map { "<$_>"} $self->names;
    $re=~s/\#/\\\#/g;
    $re=~s/,/ /g;
    $re=~s/\s+/ /g;
    $re=~s/([^()?+*|,\s]+)/(?:<$1>)/g;
    # warn "'$content' VERSUS /$re/\n";
    return $content=~m/^$re$/x ? 1 : 0;
  }

=item $seq->push_element (name, value)

Append a given name-value pair to the sequence.

=cut

  sub push_element {
    my ($self,$name,$value)=@_;
    push @{$self->[0]},Treex::PML::Seq::Element->new($name,$value);
  }

=item $seq->push_element_obj (obj)

Append a given Treex::PML::Seq::Element object to the sequence.

=cut

  sub push_element_obj {
    my ($self,$obj)=@_;
    push @{$self->[0]},$obj;
  }

=item $seq->unshift_element (name, value)

Prepend a given name-value pair to the sequence.

=cut

  sub unshift_element {
    my ($self,$name,$value)=@_;
    unshift @{$self->[0]},Treex::PML::Seq::Element->new($name,$value);
  }

=item $seq->unshift_element_obj (obj)

Unshift a given Treex::PML::Seq::Element object to the sequence.

=cut

  sub unshift_element_obj {
    my ($self,$obj)=@_;
    unshift @{$self->[0]},$obj;
  }

=item $seq->delete_element (element)

Find and remove (all occurences) of a given Treex::PML::Seq::Element object
in the sequence. Returns the number of elements removed.

=cut

=item $seq->delete_element (element)

Find and remove (all occurences) of a given Treex::PML::Seq::Element object
in the sequence. Returns the number of elements removed.

=cut

  sub delete_element {
    my ($self,$element)=@_;
    my $start = @{$self->[0]};
    @{$self->[0]} = grep { $_ != $element } @{$self->[0]};
    my $end = @{$self->[0]};
    return $start-$end;
  }

=item $seq->delete_value (value)

Find and remove all elements with a given value. Returns the number of
elements removed.

=cut

  sub delete_value {
    my ($self,$value)=@_;
    my $start = @{$self->[0]};
    my $v;
    if (ref($value)) {
      @{$self->[0]} = grep { $v = $_->value; ref($v) and ($v != $value) } @{$self->[0]};
    } else {
      @{$self->[0]} = grep { $v = $_->value; !ref($v) and ($v ne $value) } @{$self->[0]};
    }
    my $end = @{$self->[0]};
    return $start-$end;
  }

=item $seq->index_of ($value)

Search the sequence for a particular value
and return the index of its first occurence in the sequence.

Note: Use $seq->elements_list->index_of($element) to search for a Treex::PML::Seq::Element.

=cut

  sub index_of {
    my ($self,$value)=@_;
    die 'Usage: Treex::PML::Seq->index_of($value) (wrong number of arguments!)'
      if @_!=2;
    my $list = $self->[0];
    if (ref($value)) {
      my $v;
      for my $i (0..$#$list) {
	$v = $list->[$i]->value;
	return $i if ref($v) and $value == $v;
      }
    } else {
      my $v;
      for my $i (0..$#$list) {
	$v = $list->[$i]->value;
	return $i if !ref($v) and $value eq $v;
      }
    }
    return;
  }

  # sub splice {
  #   # TODO
  # }
  # sub delete_element_at {
  #   # TODO
  # }
  # sub store_element_at {
  #   # TODO
  # }

=item $list->empty ()

Remove all values from the sequence.

=cut

sub empty {
  die 'Usage: Treex::PML::Seq->empty() (wrong number of arguments!)'
    if @_!=1;
  my $self = shift;
  $self->[0]->empty;
  return $self;
}

=back

=head1 AUXILIARY FUNCTIONS

=over 5

=item Treex::PML::Seq::content_pattern2regexp($pattern)

This utility function converts a given sequence content pattern string
into a Perl regular expression. The resulting expression matches
a list of element 'tags', where a tag is an element name surrounded by < and >.
For example, the content pattern 'A,#TEXT,(B+|C)*' translates roughly 
to '<A><\#TEXT>(?:(?:<B>)+(?:<C>))*' and matches (a substring of) each of the following strings:

  '<A><#TEXT>'
  'foo<A><#TEXT><B><B><C>bar'
  '<A><#TEXT><B><C><D>'

=back

=cut


  sub content_pattern2regexp {
    my ($re)=@_;
    $re=~s/[\${}\\]//g; # sanity
    $re=~s/\(\?//g;     # safety
    $re=~s/\#/\\\#/g;
    $re=~s/,/ /g;
    $re=~s/\s+/ /g;
    $re=~s/([^()?+*|,\s]+)/(?:<$1>)/g;
    $re=~s/ //g;
    return $re;
  }


=head1 SEE ALSO

L<Treex::PML>, L<Treex::PML::Factory>, L<Treex::PML::Schema>, L<Treex::PML::Seq::Element>, L<Treex::PML::List>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2010 by Petr Pajas

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut


1;

package Valiant::HTML::Util::Collection;

use warnings;
use strict;
use Scalar::Util (); 

sub new {
  my ($class) = shift;
  my @items = map {
    Scalar::Util::blessed($_) ? $_ : $class->_build_item($_)
    } @_;
  return bless +{ collection=>\@items, pointer=>0 }, $class;
}

sub _build_item {
  my ($class, $item) = @_;
  return bless $item, 'Valiant::HTML::Util::Collection::HashItem' if (ref($item)||'') eq 'HASH';
  $item = [$item, $item] unless ref($item);
  return bless $item, 'Valiant::HTML::Util::Collection::Item';
}

sub next {
  my $self = shift;
  if(my $item = $self->{collection}->[$self->{pointer}]) {
    $self->{pointer}++;
    return $item;
  } else {
    return;
  }
}

sub build {
  my $self = shift;
  return bless \@_, 'Valiant::HTML::Util::Collection::Item';
}

sub current_index { return shift->{pointer} }

sub current_item { return $_[0]->{collection}->[$_[0]->{pointer}] }

sub size { scalar @{$_[0]->{collection}} }

sub reset { $_[0]->{pointer} = 0 }

sub all { @{$_[0]->{collection}} }

package Valiant::HTML::Util::Collection::Item;

use overload 
  bool => sub { shift->value }, 
  '""' => sub { shift->value },
  fallback => 1;

sub label { return shift->[0] }
sub value { return shift->[1] }

package Valiant::HTML::Util::Collection::HashItem;

sub can {
  my ($self, $method) = @_;
  return exists($self->{$method});
}

sub AUTOLOAD {
  my $self = shift;
  my $method = our $AUTOLOAD;
  $method =~ s/.*:://;
  return $self->{$method};
}

1;

=head1 NAME

Valiant::HTML::Util::Collection - A utility class for creating collections of items.

=head1 SYNOPSIS

    use Valiant::HTML::Util::Collection;

    my $collection = Valiant::HTML::Util::Collection->new(@items);

    while(my $item = $collection->next) {
# do something with $item
    }

    $collection->reset;

    my $size = $collection->size;

=head1 DESCRIPTION

Valiant::HTML::Util::Collection is a utility class for creating collections of items. The collection can 
contain any type of item, but each item is represented as a LValiant::HTML::Util::Collection::Item object.

=head1 METHODS

=over 4

=item new(@items)

Constructs a new Valiant::HTML::Util::Collection object with the provided items. Each item can be any type of 
scalar value, or an object that has been blessed into the Valiant::HTML::Util::Collection::Item package.

=item next

Returns the next item in the collection, or undef if there are no more items. The current position within
the collection is advanced by one.

=item build

Constructs a new Valiant::HTML::Util::Collection::Item object from the provided arguments. The first argument
is the label, and the second argument is the value.

=item current_index

Returns the current position within the collection.

=item current_item

Returns the current item in the collection.

=item size

Returns the size of the collection.

=item reset

Resets the current position within the collection to the beginning.

=item all

Returns all of the items in the collection as a list.

=back

=head1 SEE ALSO

L<Valiant>, L<Valiant::HTML::SafeString>, L<Valiant::HTML::FormBuilder>

=head1 AUTHOR
 
See L<Valiant>

=head1 COPYRIGHT & LICENSE
 
See L<Valiant>

=cut

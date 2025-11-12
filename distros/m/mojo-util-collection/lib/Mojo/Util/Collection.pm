package Mojo::Util::Collection;
use Mojo::Base -base;

use Exporter 'import';
use Mojo::Util::Model;

our @EXPORT_OK = qw(
    collect
);

our $VERSION = '0.0.17';

use List::Util;
use Scalar::Util qw(blessed);

use Mojo::Util::Collection::Comparator;
use Mojo::Util::Collection::Formatter;
use Mojo::Util::Model;


has 'comparator' => sub {
    return Mojo::Util::Collection::Comparator->new;
};

has 'formatter' => sub {
    return Mojo::Util::Collection::Formatter->new;
};

has 'index' => 0;

has 'items' => sub { [] };

has 'limit' => 10;

has 'model' => sub {
    return Mojo::Util::Model->new;
};

has 'objects' => sub {
    my $self = shift;

    my @objects = map { $self->newObject(%{$_ || {}}) } @{ $self->items || [] };

    return \@objects;
};

has 'pager' => sub { {} };


=head2 add

    Add an object

    Returns:
    C<Collection> of C<Model> objects

=cut

sub add {
    my ($self, $object) = @_;

    if (ref($object) eq 'ARRAY') {
        $self->add($_) for (@$object);

        return $self;
    }

    my @objects = @{ $self->objects };

    if (ref($object) eq 'HASH') {
        push(@objects, $self->newObject(%$object));
    } elsif (blessed($object)) {
        if ($object->isa('Mojo::Util::Collection')) {
            push(@objects, @{ $object->objects });
        } elsif ($object->isa('Mojo::Util::Model')) {
            push(@objects, $object);
        } else {
            warn "Can't add object of type " . ref($object);
        }
    } else {
        warn "Can't add object of type " . ref($object);
    }

    $self->objects(\@objects);

    return $self;
}

=head2 as

    Set model for collection

=cut

sub as {
    my ($self, $as) = @_;

    $self->model($as);

    return $self;
}

=head2 asOptions

    Return an array ref containing [{ value => $value, label => $label }, ...]

=cut

sub asOptions {
    my $self = shift;

    return $self->formatter->asOptions($self->objects, @_);
}

=head2 avg

    Return the average value for given $field

=cut

sub avg {
    my ($self, $field) = @_;
    my $values = $self->lists($field);

    return List::Util::sum(@$values) / scalar(@$values);
}

=head2 collect

    Instantiate a new collection

=cut

sub collect {
    my $items = shift;

    return Mojo::Util::Collection->new({ items => $items });
}

=head2 count

    Return the size of objects

=cut

sub count {
    return (scalar(@{ shift->objects }));
}

=head2 each

    Map through each object and call the callback

=cut

sub each {
    my ($self, $callback) = @_;

    $callback->($_) for (@{ $self->objects });
}

=head2 exclude

    Exclude objects that doesn't match criteria

    Returns:
    C<Collection> of C<Model> objects

=cut

sub exclude {
    my ($self, $args) = @_;

    my $collection = $self->filter(sub {
        my $object = shift;

        return List::Util::notall { $self->comparator->verify($object->get($_), $args->{ $_ }) } keys(%$args);
    });

    return $collection;
}

=head2 filter

    Filter objects by callback

    Returns:
    C<Collection> of C<Model> objects

=cut

sub filter {
    my ($self, $callback) = @_;

    my @objects = grep { $callback->($_) } @{ $self->objects };

    return $self->new({ objects => \@objects })->as($self->model);
}

=head2 find

    Find object by primary key, of if args is a hash ref then find first object matching given args

    Returns:
    C<Model> object

=cut

sub find {
    my ($self, $args) = @_;

    if (ref($args) eq 'HASH') {
        return $self->__first(sub {
            my $object = shift;

            return List::Util::all { $self->comparator->verify($object->get($_), $args->{ $_ }) } keys(%$args);
        });
    }

    my $object = $self->__first(sub {
        my $object = shift;

        return ($object->pk eq $args);
    });

    return $object;
}

=head2 findOrNew

    Find object or create a new instance

    Returns:
    C<Model> object

=cut

sub findOrNew {
    my ($self, $args, $extra) = @_;

    my %new_args = (%{ $args || {} }, %{ $extra || {} });

    return $self->find($args) || $self->newObject(%new_args);
}

=head2 first

    Get first object

    Returns:
    C<Model> object

=cut

sub first {
    return shift->get(0);
}

=head2 firstOrNew

    Get first object if exists, otherwise create one

    Returns:
    C<Model> object

=cut

sub firstOrNew {
    my ($self, $args) = @_;

    return $self->first || $self->newObject(%$args);
}

=head2 get

    Get object by index

    Returns:
    C<Collection> of C<Model> objects

=cut

sub get {
    my ($self, $index) = @_;

    return $self->objects->[$index];
}

=head2 indexOf

    Get the index of an object

    Returns:
    Integer index

=cut

sub indexOf {
    my ($self, $object) = @_;

    my $index = -1;
    my @objects = @{ $self->objects };

    if (ref($object) ne ref($self->model)) {
        $object = $self->newObject(%$object);
    }

    for (my $i = 0; $i < scalar(@objects); $i++) {
        if ($objects[$i]->pk eq $object->pk) {
            $index = $i;
            last;
        }
    }

    return $index;
}

=head2 intersect

    Return a new collection containing only items that exist in both collections

    Returns:
    C<Collection> of C<Model> objects

=cut

sub intersect {
    my ($self, $other_collection) = @_;

    return $self->search({
        $self->model->primary_key => $other_collection->lists($other_collection->model->primary_key),
    });
}

=head2 last

    Get last object

    Returns:
    C<Model> object

=cut

sub last {
    my $self= shift;

    return $self->get(scalar(@{ $self->objects }) - 1);
}

=head2 lists

    Return an array ref containing all the fields from all objects for the given $field.
    Return a hash ref containing $key_field => $value_field if both are given.

=cut

sub lists {
    my ($self, $key_field, $value_field) = @_;

    if ($key_field && $value_field) {
        my %list = map { $_->get($key_field) => $_->get($value_field) } @{ $self->objects };

        return \%list;
    }

    my @fields = map { $self->__list($_->get($key_field)) } @{ $self->objects };

    return \@fields;
}

=head2 max

    Return the maximum value for given $field

=cut

sub max {
    my ($self, $field) = @_;
    my $values = $self->lists($field);

    return List::Util::max(@$values);
}

=head2 min

    Return the minimum value for given $field

=cut

sub min {
    my ($self, $field) = @_;
    my $values = $self->lists($field);

    return List::Util::min(@$values);
}

=head2 missing

    Return a new collection containing only items that exist in this collection
    but not in the other collection

    Returns:
    C<Collection> of C<Model> objects

=cut

sub missing {
    my ($self, $other_collection) = @_;

    return $self->exclude({
        $self->model->primary_key => $other_collection->lists($other_collection->model->primary_key),
    });
}

=head2 newObject

    Instantiate new object

    Returns:
    C<Model> object

=cut

sub newObject {
    my $self = shift;

    if (ref($self->model) eq 'CODE') {
        return $self->model->(@_);
    }

    return $self->model->new(@_);
}

=head2 next

    Get next object

    Returns:
    C<Model> object

=cut

sub next {
    my $self = shift;
    my $index = $self->index;

    $self->index($index + 1);

    my $object = $self->get($index);

    # Auto reset
    if (! $object) {
        $self->reset;
    }

    return $object;
}

=head2 only

    Return an array ref containing only given @keys

=cut

sub only {
    my ($self, @keys) = @_;

    my $only = [];

    foreach my $object (@{ $self->objects }) {
        push @$only, { map { $_ => $object->get($_) } @keys };
    }

    return $only;
}

=head2 orderBy

    Order collection

=cut

sub orderBy {
    my ($self, $field, $direction, $string) = @_;

    $direction ||= 'asc';
    $string = 1 unless defined $string;

    my @objects = @{ $self->objects };
    my @sorted;

    if ($direction eq 'asc') {
        if ($string) {
            @sorted = sort { $a->get($field, '') cmp $b->get($field, '') } @objects;
        }
        else {
            @sorted = sort { $a->get($field, '') <=> $b->get($field, '') } @objects;
        }
    } else {
        if ($string) {
            @sorted = sort { $b->get($field, '') cmp $a->get($field, '')} @objects;
        }
        else {
            @sorted = sort { $b->get($field, '') <=> $a->get($field, '')} @objects;
        }
    }

    $self->objects(\@sorted);

    return $self;
}

=head2 page

    Take a collection containing only the results from a given page

    Returns:
    C<Collection> of C<Model> objects

=cut

sub page {
    my ($self, $page) = @_;
    $page ||= 1;

    my @objects = @{ $self->objects };

    my $start = ($page - 1) * $self->limit;
    my $end = List::Util::min(($page * $self->limit), scalar(@objects)) - 1;

    my $last_page = int((scalar(@objects) + $self->limit - 1) / $self->limit);

    my $pager = {
        count       => $self->count,
        limit       => $self->limit,
        prev_page   => ($page > 1) ? $page - 1 : 1,
        first_page  => 1,
        page        => $page,
        next_page   => ($page < $last_page) ? $page + 1 : $last_page,
        last_page   => $last_page,
        start       => $start + 1,
        end         => $end + 1,
    };

    my $next = $self->slice($start, $end);

    $next->pager($pager);

    return $next;
}

=head2 remove

    Remove an object

=cut

sub remove {
    my ($self, $object) = @_;

    if (ref($object) eq 'ARRAY') {
        $self->remove($_) for (@{ $object });

        return $self;
    }

    my @objects = @{ $self->objects };

    # Remove only if exists
    if ($self->indexOf($object) >= 0) {
        return $self->splice($self->indexOf($object), 1);
    }

    return $self;
}

=head2 reset

    Reset index

=cut

sub reset {
    my $self = shift;

    $self->index(0);

    return $self;
}

=head2 search

    Search objects by given args

    Returns:
    C<Collection> of C<Model> objects

=cut

sub search {
    my ($self, $args) = @_;

    my $collection = $self->filter(sub {
        my $object = shift;

        return List::Util::all { $self->comparator->verify($object->get($_), $args->{ $_ }) } keys(%$args);
    });

    return $collection;
}

=head2 slice

    Take a slice from the collection

    Returns:
    C<Collection> of C<Model> objects

=cut

sub slice {
    my ($self, $start, $end) = @_;

    $start //= 0;
    $end //= $self->count - $start;

    my @objects = @{ $self->objects };
    my @partition = @objects[$start .. $end];

    return $self->new({ objects => \@partition })->as($self->model);
}

=head2 splice

    Splice objects

=cut

sub splice {
    my ($self, $offset, $length) = @_;

    if (! $length) {
        $length = $offset || 1;
        $offset = 0;
    }

    my @objects = @{ $self->objects };

    splice(@objects, $offset, $length);

    $self->objects(\@objects);

    return $self;
}

=head2 sum

    Sum by $field

=cut

sub sum {
    my ($self, $field) = @_;
    my $values = $self->lists($field);

    return List::Util::sum(@$values);
}

=head2 toArray

    Convert collection to array ref

=cut

sub toArray {
    my $self = shift;

    return $self->formatter->toArray($self->objects, @_);
}

=head2 toCsv

    Convert collection to CSV string

=cut

sub toCsv {
    my $self = shift;

    return $self->formatter->toCsv($self->objects, @_);
}

=head2 toJson

    Convert collection to JSON string

=cut

sub toJson {
    my $self = shift;

    return $self->formatter->toJson($self->objects, @_);
}

=head2 touch

    Touch collections model

=cut

sub touch {
    my ($self, $callback) = @_;

    my $objects = $self->objects;

    for (my $i = 0; $i < $self->count; $i++) {
        $callback->($objects->[$i]);
    }

    $self->objects($objects);

    return $self;
}

=head2 unique

    Return an array ref containing only unique values for given $field

=cut

sub unique {
    my ($self, $field) = @_;

    my %fields = map { $_->get($field) => 1 } @{ $self->objects };

    my @unique = keys(%fields);

    return \@unique;
}

=head2 where

    Search objects where field is equal to value

    Returns:
    C<Collection> of C<Model> objects

=cut

sub where {
    my $self = shift;

    return $self->search(@_);
}

=head2 whereIn

    Search objects where field is in $array

    Returns:
    C<Collection> of C<Model> objects

=cut

sub whereIn {
    my ($self, $field, $array) = @_;

    my $collection = $self->filter(sub {
        my $object = shift;

        return grep { $object->get($field) eq $_ } @$array;
    });

    return $collection;
}

=head2 whereNotIn

    Search objects where field is not in $array

    Returns:
    C<Collection> of C<Model> objects

=cut

sub whereNotIn {
    my ($self, $field, $array) = @_;

    return $self->exclude({ $field => $array });
}

=head2 __first

    Find first object that match $callback

    Returns:
    C<Model> object

=cut

sub __first {
    my ($self, $callback) = @_;

    return List::Util::first { $callback->($_) } @{ $self->objects };
}

=head2 __list

    Return a scalar, or an array if the value is a collection

=cut

sub __list {
    my ($self, $value) = @_;

    if (blessed($value) && $value->isa('Mojo::Util::Collection')) {
        return @{ $value->objects };
    }

    return $value;
}

1;

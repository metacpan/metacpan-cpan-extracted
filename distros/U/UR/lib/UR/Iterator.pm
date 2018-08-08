package UR::Iterator;

use strict;
use warnings;

our $VERSION = "0.47"; # UR $VERSION;

our @CARP_NOT = qw( UR::Object );

# These are not UR Objects.  They're regular blessed references that
# get garbage collected in the regular ways

sub create {
    my $class = shift;
    Carp::croak("$class objects cannot be created via create().  Please see the documentation for more details");
}

sub create_for_list {
    my $class = shift;
    my $items = \@_;

    foreach my $item ( @$items ) {
        unless (defined $item) {
            Carp::croak('undefined items are not allowed in an iterator list');
        }
    }

    my $code = sub {
        shift @$items;
    };
    my $self = bless { _iteration_closure => $code }, __PACKAGE__;
    return $self;
}

sub map($&) {
    my($self, $mapper) = @_;

    my $wrapper = sub {
        local $_ = $self->next;
        defined($_) ? $mapper->() : $_;
    };

    return bless { _iteration_closure => $wrapper }, __PACKAGE__;
}

sub _iteration_closure {
    my $self = shift;
    if (@_) {
        return $self->{_iteration_closure} = shift;
    }
    $self->{_iteration_closure};
}


sub peek {
    my $self = shift;
    unless (exists $self->{peek_value}) {
        $self->{peek_value} = $self->{_iteration_closure}->();
    }
    $self->{peek_value};
}


sub next {
    my $self = shift;
    if (exists $self->{peek_value}) {
        delete $self->{peek_value};
    } else {
        $self->{_iteration_closure}->(@_);
    }
}

sub remaining {
    my $self = shift;
    my @remaining;
    while (defined(my $o = $self->next )) {
        push @remaining, $o;
    }
    @remaining;
}

1;

=pod

=head1 NAME

UR::Iterator - API for iterating through data

=head1 SYNOPSIS

  my $iter = UR::Iterator->create_for_list(1, 2, 3, 4);
  while (my $i = $iter->next) {
    print $i\n";
  }

  my $mapped_iter = $iter->map(sub { $_ + 1 });
  while (my $i = $mapped_iter->next) {
    print "$i\n";
  }

=head1 DESCRIPTION

UR::Iterator instances implement the iterator pattern.  These objects can
be created with either a list of values, or by applying a mapping function
to another iterator.

UR::Iterator instances are normal Perl object references, not UR-based
objects.  They do not live in the Context's object cache, and obey the
normal Perl rules about scoping.

=head1 METHODS

=over 4

=item create_for_list

  $iter = UR::Object::Iterator->create_for_list(@values);

Creates an iterator based on values contained in the given list.  This
constructor will throw an exception if any of the supplied values is
C<undef>.

=item map

  $new_iter = $iter->map(sub { $_ + 1 });

Creates a new iterator based on an existing iterator.  Values returned by this
new iterator are based on the values of the existing iterator after going
through a mapping function.  This new iterator will  be exhausted when the
original iterator is exhausted.

When the mapping function is called, C<$_> is set to the value obtained from
the original iterator.

=item next

  $obj = $iter->next();

Return the next object matching the iterator's rule.  When there are no more
matching objects, it returns undef.

=item peek

  $obj = $iter->peek();

Return the next object matching the iterator's rule without removing it.  The
next call to peek() or next() will return the same object.  Returns undef if
there are no more matching objects.

This is useful to test whether a newly created iterator matched anything.

=item remaining

  @objs = $iter->remaining();

Return a list of all the objects remaining in the iterator.  The list will be
empty if there is no more data.

=back

=head1 SEE ALSO

L<UR::Object::Iterator>

=cut

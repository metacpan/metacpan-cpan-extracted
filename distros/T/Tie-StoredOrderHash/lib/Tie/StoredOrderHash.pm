package Tie::StoredOrderHash;

use strict;
use warnings;

our $VERSION = '0.22';

sub new {
    # Return a reference to a new tied hash
    my $class = shift;
    my %hash;

    if (@_ == 1  &&  ref $_[0] eq 'ARRAY') {
        tie %hash, $class, @{$_[0]};
        return \%hash;
    }
    else {
        tie %hash, $class, @_;
        return \%hash;
    }
}

sub ordered($) {
    # Convenience wrapper around new [ ... ], exported by request
    return __PACKAGE__->new(@_);
}

sub is_ordered {
    # Return true if the argument is a reference to a hash tied to a T::SOH.
    return eval {
        (tied %{shift()})->isa(__PACKAGE__)
    }
}

use Exporter 'import';
our @EXPORT_OK = qw/ ordered is_ordered /;


# T::SOH object is implemented as hash, pointing into an linked-list;
# the object itself is a blessed arrayref.
# There are four entries in the array ...
sub lookup { 0 }
sub first_link { 1 }
sub last_link { 2 }
sub iter_link { 3 }

# Each entry in the list contains the (key, value) pair
# as well as the familiar (prev, next) links
sub key { 0 }
sub value { 1 }
sub prev_link { 2 }
sub next_link { 3 }

# Note that these subs above are just the same as 'use constant'ing, but ...
# you know ...
# some people are superstitious about how long it takes to load that module.


sub TIEHASH {
    my $class = shift;

    if (@_) {
        # Construct doubly-linked list for (key, value) pairs
        # The list entry containing "key" is stored as $list{"key"}
        my ($first, $last);
        my %list;
        my $next = [];  # dummy
        while (@_) {
            # Traverse the arg list backwards so we get most recent keys first.
            my ($value, $key) = (pop, pop);	# gets a treat?
            $first = $list{$key} = $next = [ $key, $value, undef, $next ]
                unless $list{$key};
            $last ||= $first;
            # We're going backwards, so the last shall be first (Matthew 20:16)
        }
        $_->[next_link]->[prev_link] = $_ foreach values %list;
        $last->[next_link] = undef;  # get rid of dummy

        # [ lookup-list, first-link, last-link, iter-link ]
        return bless [ \%list, $first, $last, undef ], $class;
    }
    else {
        return bless [ {}, undef, undef, undef ], $class;
    }
}

sub FETCH {
    my ($self, $key) = @_;
    return unless exists $self->[lookup]->{$key};

    return $self->[lookup]->{$key}->[value];
}

sub STORE {
    my ($self, $key, $value) = @_;

    my $list_entry;
    if (exists $self->[lookup]->{$key}) {
        # Hard case: we're updating an existing element

        $list_entry = $self->[lookup]->{$key};
        if ($list_entry == $self->[last_link]) {
            # When an element is stored, move it to the end of our list of keys.
            # In this case, though, we're updating the last element, so there's
            # no need for costly rearrangement.
            return ($list_entry->[value] = $value);
        }

        # Classic first year CS stuff to update the doubly linked list
        # (do they even teach CS anywhere anymore?)

        # First, remove our list-entry from its current position in the list ...
        $list_entry->[prev_link]->[next_link] = $list_entry->[next_link]
            if $list_entry->[prev_link];
        $list_entry->[next_link]->[prev_link] = $list_entry->[prev_link]
            if $list_entry->[next_link];

        # Update the hash iterator as appropriate ...
        $self->[iter_link] = $list_entry->[next_link]
            if $self->[iter_link] && $self->[iter_link] == $list_entry;

        # Update first-link if our list-entry was at the beginning of the list
        $self->[first_link] = $list_entry->[next_link]
            if $self->[first_link] && $self->[first_link] == $list_entry;
    }
    else {
        # Easy case: we're simply adding a new entry at the end
        $list_entry = [ $key ];
        $self->[lookup]->{$key} = $list_entry;
    }

    # More CS stuff ... Aho & Ullman p78, second code snippet
    $self->[last_link]->[next_link] = $list_entry  if $self->[last_link];
    $list_entry->[prev_link] = $self->[last_link];
    $list_entry->[next_link] = undef;
    $self->[last_link] = $list_entry;
    $self->[first_link] = $list_entry  unless $self->[first_link];

    return ($list_entry->[value] = $value);
}

sub EXISTS {
    my ($self, $key) = @_;
    return exists $self->[lookup]->{$key};
}

sub DELETE {
    my ($self, $key) = @_;
    return unless exists $self->[lookup]->{$key};

    my $list_entry = $self->[lookup]->{$key};
    $self->[first_link] = $list_entry->[next_link]
        if $self->[first_link] && $self->[first_link] == $list_entry;
    $self->[last_link] = $list_entry->[prev_link]
        if $self->[last_link] && $self->[last_link] == $list_entry;

    $self->[iter_link] = $list_entry->[next_link]
        if $self->[iter_link] && $self->[iter_link] == $list_entry;

    $list_entry->[next_link]->[prev_link] = $list_entry->[prev_link]
        if $list_entry->[next_link];
    $list_entry->[prev_link]->[next_link] = $list_entry->[next_link]
        if $list_entry->[prev_link];

    return delete $self->[lookup]->{$key};
}

sub CLEAR {
    my ($self) = @_;

    $self->[lookup] = {};
    $self->[first_link] = undef;
    $self->[last_link] = undef;
    $self->[iter_link] = undef;

    return;
}

sub FIRSTKEY {
    my ($self) = @_;
    return unless $self->[first_link];

    $self->[iter_link] = $self->[first_link]->[next_link];
    my $list_entry = $self->[first_link];
    return wantarray? ($list_entry->[key], $list_entry->[value])
                    : $list_entry->[key];
}

sub NEXTKEY {
    my ($self) = @_;

    my $iter = $self->[iter_link];
    $self->[iter_link] = $iter->[next_link];

    return wantarray? ($iter->[key], $iter->[value])
                    : $iter->[key];
}

1;

__END__

=head1 NAME

Tie::StoredOrderHash - ordered associative arrays for Perl

=head1 SYNOPSIS

# Standard hash operations
    use Tie::StoredOrderHash;

    tie my %hash, 'Tie::StoredOrderHash', (a => 1, b => 2, c => 3);

    $hash{d} = 4;
    print join " ", %hash;    # => a 1 b 2 c 3 d 4
    $hash{a} = 5;
    print join " ", %hash;    # => b 2 c 3 d 4 a 5

 
# Optional utility functions
    use Tie::StoredOrderHash qw/ ordered is_ordered /;

    my $hash = ordered [ one => 1, two => 2, three => 3 ];
    while (my($k, $v) = each %$hash) {
        print "$k: $v  ";
    } # one: 1  two: 2  three: 3

    print "stored-order hashref is ordered"
        if is_ordered($hash);
    print "regular hashref is NOT ordered"
        unless is_ordered({});

=head1 DESCRIPTION

Tie::StoredOrderHash is a(nother) implementation of a Perl hash that
preserves the order in which elements are stored.

While uncooked Perl hashes make no guarantees about the order in which
elements are iterated, T::SOH objects iterate over elements in a
consistent order, starting with the least-recently-updated element,
and finishing with the element that was most-recently added I<or updated>.

=head2 Standard usage

The module implements C<TIEHASH>, as one would expect.  Any extra parameters
to C<tie> are treated as key-value pairs for initialisation:

    tie %hash, 'Tie::StoredOrderHash', ('key1' => 'value1', ...);

This hash is then available for lookup, storage and deletion using
the standard notation:

    print $hash{"key1"};    # value1
    $hash{"foo"} = "bar";
    delete $hash{"key1"};
    exists $hash{"key1"};   # falsey

The difference from a regular hash would only be observed when iterating,
either explicitly,

    tie %hash, 'Tie::StoredOrderHash', qw( 1 one 2 two 3 three );

    while (my ($key, $value) = each %hash) {
        print "[$key]: $value\n";
        # [1]: one
        # [2]: two
        # [3]: three
    }

or implicitly,

    print %hash;                # 1 one 2 two 3 three

    my @values = values %hash;  # ('one', 'two', 'three')
    my @keys = keys %hash;      # (1, 2, 3)
    my @arrayified = %hash;     # (1, 'one', 2, 'two', 3, 'three')

    $hash{2} = "re-ordered";
    print %hash;                # 1 one 3 three 2 re-ordered

Note that T::SOH is not strictly LRU (least-recently-used), as elements only
"float" to the end when inserted or updated, not when accessed.
Such behaviour is not hard to emulate, however, if the element is
"changed to what it was" whenever it's read:

    tie my %lru, 'Tie::StoredOrderHash';

    # ... some things happen, the hash is populated somehow ...
    my $elt = ($lru{$key} = $lru{$key});    # update this value in-place

    # ... more things happen, things are said that can't be unsaid ...

    # Delete the least-recently-used element in the hash.
    my @keys = keys(%lru);
    delete $lru{$keys[0]};

Note that T::SOH attempts to "do the right thing" as much as possible during
iteration:

=over

=item * if an entry I<after> the current position is updated, then obviously
no harm is done (it will be iterated eventually),

=item * if an entry I<before> the current position is updated, then the
entry moves to the end of the order (and will be re-iterated),

=item * if the I<current> entry is updated, then it is moved to the end of
the order and will be re-iterated.

=back

If updates must be made to the elements during a once-through iteration, then
maybe what you actually want to do is grab the keys before starting:

    foreach my $key (keys(%hash)) {
        my $value = $hash{$key};
        # ... destructive fun goes here ...
    }

... but, hey, I don't wanna harsh your buzz.


=head2 Other usage

Although the C<tie> interface is possessing of a certain austere beauty, it can
be somewhat cumbersome, especially when constructing nested data structures.
A single hashref tied to C<Tie::StoredOrderHash> may be constructed in the
familiar OO fashion, using C<new>, with an optional list of key-value pairs:

    my $hashref = Tie::StoredOrderHash->new(
        'key1' => 'value1',
        'key2' => 'value2',
        ...
    );

As a special case, if a single list-ref is passed to C<new>, then its contents
are used as the key-value pairs for initialisation:

    # Equivalent to previous code snippet
    my $hashref = Tie::StoredOrderHash->new(
        [
            'key1' => 'value1',
            'key2' => 'value2',
            ...
        ]
    );

As a beautiful and terse alternative, you may import the C<ordered> function
from C<Tie::StoredOrderHash>, and provide it with a list-ref of initial values:

    use Tie::StoredOrderHash qw/ ordered /;

    # This is spartan (and equivalent to the previous code snippets)
    my $hashref = ordered [
        'key1' => 'value1',
        'key2' => 'value2',
        ...
    ];

    # Also does what you'd expect with nested structures
    my $nested_hashref = ordered [
        one => 1,
        two => ordered [
            a => "a",   # a is a
            b => "b",
            c => "c",
            d => ordered [
                'us' => 'all your base'
            ]
        ],
        three => 3
    ];

Also exported (but not by default) is the C<is_ordered> function, which takes
a single hashref as parameter, and returns truthfulness if the hashref is
tied to Tie::StoredOrderHash (or one of its subclasses).  This is useful when
you're working with a bunch of maniacs who can't be consistent about their
configuration files, err, for instance.


=head1 IMPLEMENTATION AND MOTIVATION

There are several other CPAN modules that iterate over insert-order, which is
very close to store-order, but these typically use an array-list to keep
track of ordering.  This makes deletion and reordering-on-update expensive, 
but they may be more suitable for you than T::SOH if you have a hash that
doesn't change often, or at least mostly grows at the ends.
Tie::StoredOrderHash maintains a linked-list of its entries, at a little
extra cost, which makes the basic insert/update/delete operations cheap.
List-refs rather than hash-refs are used internally wherever possible,
and this does avoid a significant performance penalty from previous versions.

Tie::StoredOrderHash might not be the Swiss Army Knife you're looking for,
but it's already been cheap and useful in a variety of situations.


=head1 BUGS

Could be a few ... it's been in major production use for about a year, and it
was only a couple of revisions ago that a problem with duplicate keys in the
initialisation list was spotted.

More likely is that it doesn't quite do what you want.  Should be simple
enough to subclass it, e.g.

    package Tie::LRUHash;
    use base 'Tie::StoredOrderHash';

    # Hash with full least-recently-used behaviour
    sub FETCH {
        my ($self, $key) = @_;
        my $value = $self->SUPER::FETCH($key);
        $self->SUPER::STORE($key, $value);
    }

    1;

It would potentially also be useful to have the stack and queue style
operations of Tie::IxHash, but I'm not convinced those belong in this package
(maybe, once again, in a fairly trivial subclass in a future revision).


=head1 SEE ALSO

=over

=item * C<Tie::IxHash> - Gurusamy Sarathy's original insert-order hash.
It's even mentioned in one of the O'Reilly books, I think that makes it
"venerable".

=item * C<Tie::InsertOrderHash> - very similar implementation to C<IxHash>
without the stack/queue utilities

=item * C<Tie::Hash::Indexed> - XS module, similar to C<IxHash>

=item * C<Tie::LLHash> - pure Perl implementation of the insert-order hash
built on top of a linked list

Any of these is particularly suitable for hashes which are built once and
not modified thereafter.  Tie::StoredOrderHash is geared towards LRU-like
applications.

=back


=head1 AUTHOR

tom murtagh E<lt>cpan@notto.beE<gt>

Copyright (c) 2009 tom murtagh.  All rights reserved.
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

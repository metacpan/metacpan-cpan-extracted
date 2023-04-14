=head1 NAME

Tuple::Munge - manipulate Perl's tuple object representations

=head1 SYNOPSIS

    use Tuple::Munge qw(pure_tuple constant_tuple variable_tuple);

    $tuple = pure_tuple(\$s, \@a, \%h, \&c);
    $tuple = constant_tuple(\$s, \@a, \%h, \&c);
    $tuple = variable_tuple(\$s, \@a, \%h, \&c);

    use Tuple::Munge
	qw(tuple_mutable tuple_length tuple_slot tuple_slots);

    if(tuple_mutable($tuple)) { ...
    $len = tuple_length($tuple);
    $ref = tuple_slot($tuple, 3);
    @refs = tuple_slots($tuple);

    use Tuple::Munge qw(tuple_set_slot tuple_set_slots tuple_seal);

    tuple_set_slot($tuple, 3, \$s);
    tuple_set_slots($tuple, \$s, \@a, \%h, \&c);
    tuple_seal($tuple);

=head1 DESCRIPTION

This module provides functions to manipulate Perl's tuples, the data
structures that were introduced in Perl 5.37.9 to support the core class
system.  As of Perl 5.37.10, the Perl core notably lacks both general
manipulation facilities and documentation for these data structures.

Tuple data structures are experimental, so the feature could change
significantly or disappear entirely in future versions of Perl.
Be mindful of the portability issues (requiring a recent Perl and having
doubtful forward portability) in any decision about whether to use tuples.

=head2 Tuple data type

The tuple data type is a structured data type that can be used to
contain arbitrary Perl objects.  It sits alongside the array and hash
data types in Perl's type system.  A tuple is not a scalar value, and
so cannot be stored directly in a scalar variable, and in fact there is
no type of Perl variable that can directly contain a tuple.  A tuple
can be referenced through a Perl reference, which is a scalar value,
and indeed this is the only way to handle a tuple in Perl code.

At any time, a tuple has a sequence of zero or more slots, each of
which either is empty or references a Perl object.  The objects that a
tuple references may be of any type: scalar, array, hash, subroutine,
format, I/O, or tuple.  This is unlike an array or a hash, which can only
reference scalars.  The objects referenced by a tuple may simultaneously
be referenced in other places, for example by being a package variable.
A tuple slot is not itself a referencable object.  Operations on
an arbitrary slot of a tuple, identified by index, are efficient.
Operating on all the slots simultaneously is also efficient.

In general it is possible to mutate an existing tuple.  It is possible
to write to any slot within a tuple (either emptying it or writing in an
object reference), and it is also possible to replace a tuple's entire
sequence of slot values with a different one.  A tuple can be marked as
read-only to prevent any mutation.  A tuple thus being immutable only
prevents mutation of the tuple's sequence of slot values (and blessing
of the tuple); it doesn't affect mutation of the objects referenced by
the tuple.

It is possible for mutation to change the number of slots in a tuple,
but this is a relatively expensive operation that should be avoided.
Other than writing to a single slot and replacement of the complete
sequence of slot values, tuples do not naturally support operations to
edit the slot value sequence, such as adding an object reference onto
the end of a tuple.  Such an operation can be constructed via complete
replacement of a tuple's slot value sequence, but if the desire to do
that arises then it suggests that an array would be a more appropriate
data structure.

A tuple can be identified as such through the
L<C<builtin::reftype>|builtin/reftype> function, which will return
C<OBJECT> when given a reference to one.  Correspondingly, the
L<C<ref>|perlfunc/ref> function will return C<OBJECT> if given a reference
to an unblessed tuple, and the default stringification of a reference to a
tuple will include C<OBJECT>.  Beware that this usage of the word "object"
is confusing: it was already a somewhat overloaded term before the tuple
data type existed, so it makes a poor way to identify the tuple data type.

Via this module, a tuple can be constructed from a list of slot values,
and the slot values in a tuple can be read and written.  This module
represents each slot value in the form of a reference value (for a slot
referencing an object) or an undefined value (for an empty slot).

=head2 Core class system

The L<Perl core class system|perlclass> (introduced alongside tuples in
Perl 5.37.9) uses tuples as the representation format for its classful
objects.  This class system is not the subject of this module, but it
has a special relationship to the tuple data type, which is worthy of
comment.  Beware that the core documentation overloads the term "class",
using it both to refer to Perl classes in general (i.e., packages into
which objects get blessed) and to refer specifically to the classes of
this class system.

A blessed object constructed through the automatically-generated
constructor for a core class system class is always a tuple object,
and its slots reference the field variables for that class and its
superclasses.  The field variables can only be scalars, arrays, and
hashes, so those are the only types of objects that will be referenced
by such tuples.  Once the object is fully constructed and visible as
C<$self> to method code, none of the tuple slots are empty, and the
sequence of object references never subsequently changes.

Beware that mutating a tuple used as the representation of one of these
blessed objects can easily cause malfunction of its class.  Of course,
the same goes for mutating the innards of any data structure representing
a classful object.

=head2 Experimental status

The tuple data type as supplied by the Perl core is experimental.
This means that it could change significantly, or be removed entirely,
in a future version of Perl.

Furthermore, the manner in which this module uses the tuple data type
is somewhat speculative.  The Perl core does not document precisely what
kinds of operations are intended to be possible on tuples, and there is no
established common practice, so the semantics offered by this module are
in part guesses.  For example, rewriting a tuple in a way that changes
the number of slots it has is something that's naturally possible to do
with the data structure, but isn't ever performed by core code, and it
might be decided in the future that it should never happen to a tuple
beyond its initial construction.

The mutability semantics offered by this module are particularly
speculative.  As of Perl 5.37.10, the Perl core neither sets nor honours
the read-only flag that this module uses.  It is not possible to discern
in what situations the core intends tuples to be mutable, because the core
code is not self-consistent on this point: it assumes that slot values
will not change in situations in which it can actually change them.
When some coherent semantics are decided upon for the core, it should
be possible to achieve cooperation between this module and the core,
and this module might also change behaviour on the buggy Perl versions
to get closer to the consensus semantics.

=cut

package Tuple::Munge;

{ use 5.037009; }
use warnings;
use strict;

use XSLoader;

our $VERSION = "0.001";

use parent "Exporter";
our @EXPORT_OK = qw(
	pure_tuple constant_tuple variable_tuple
	tuple_mutable tuple_length tuple_slot tuple_slots
	tuple_set_slot tuple_set_slots tuple_seal
);

XSLoader::load(__PACKAGE__, $VERSION);

=head1 FUNCTIONS

=head2 Construction

=over

=item pure_tuple(REF ...)

Returns a reference to an immutable tuple.  The tuple is composed of
the slot values supplied by the I<REF>s, each of which must be either
a reference or undefined.  The tuple is not necessarily fresh.

=item constant_tuple(REF ...)

Creates a fresh immutable tuple and returns a reference to it.  The tuple
is composed of the slot values supplied by the I<REF>s, each of which
must be either a reference or undefined.

=item variable_tuple(REF ...)

Creates a fresh mutable tuple and returns a reference to it.  The tuple
is initialised to contain the slot values supplied by the I<REF>s,
each of which must be either a reference or undefined.

=back

=head2 Examination

=over

=item tuple_mutable(TUPLE)

I<TUPLE> must be a reference to a tuple.  Returns a truth value indicating
whether the tuple is mutable.

=item tuple_length(TUPLE)

I<TUPLE> must be a reference to a tuple.  Returns the number of slots
that the tuple currently has.

=item tuple_slot(TUPLE, INDEX)

I<TUPLE> must be a reference to a tuple.  Returns the slot value (either a
reference or undefined) in the tuple's slot identified by the zero-based
index I<INDEX>.  C<die>s if the index is out of bounds (less than zero,
or greater than or equal to the number of slots).

=item tuple_slots(TUPLE)

I<TUPLE> must be a reference to a tuple.  Returns a list of the slot
values (each either a reference or undefined) in all the slots of
the tuple.  C<die>s if called in scalar context.

=back

=head2 Mutation

=over

=item tuple_set_slot(TUPLE, INDEX, REF)

I<TUPLE> must be a reference to a mutable tuple.  Sets the tuple's slot
identified by the zero-based index I<INDEX> to contain the slot value
supplied by I<REF>, which must be either a reference or undefined.
Returns the new slot value (i.e., a copy of I<REF>).  C<die>s if the
index is out of bounds (less than zero, or greater than or equal to the
number of slots).

=item tuple_set_slots(TUPLE, REF ...)

I<TUPLE> must be a reference to a mutable tuple.  Sets the tuple's
complete slot sequence to contain the slot values supplied by the I<REF>s,
each of which must be either a reference or undefined.  Returns no
useful value.  This function is capable of changing the number of slots
in a tuple, but doing so is a relatively expensive operation, so avoid
doing that routinely.

=item tuple_seal(TUPLE)

I<TUPLE> must be a reference to a mutable tuple.  Makes the tuple
immutable.  Returns a reference to the tuple (i.e., a copy of I<TUPLE>).

=back

=head1 BUGS

As of Perl 5.37.10, the L<C<bless>|perlfunc/bless> function in the Perl
core has a problem with tuples.  Although it will bless an unblessed
tuple just as it will any other object, it refuses to bless a tuple that
is already blessed.  It permits reblessing of objects other than tuples,
and so is discriminating against tuples.  This prohibition appears to
be a result of concern for the integrity of classes of the core class
system, but isn't actually justified by such concerns.  (It was added
alongside the prohibition on manually blessing into classes of the core
class system, a prohibition which is justified by such concerns.)

As of Perl 5.37.10, the Perl core provides no coherent semantics regarding
the mutability of tuples.  It does not enforce immutability, by looking at
any flag attached to a tuple.  This means that the immutability offered
by this module can be violated by exploiting core features.  But the
core also assumes in some situations that tuples will not be mutated.
This immutability assumed by the core can be violated by the use of this
module, or by exploiting core features without any use of this module.

=head1 SEE ALSO

L<Scalar::Construct>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2023 Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

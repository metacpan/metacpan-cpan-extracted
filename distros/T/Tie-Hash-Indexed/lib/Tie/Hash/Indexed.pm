################################################################################
# 
# Copyright (c) Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
# 
################################################################################

package Tie::Hash::Indexed;
use 5.004;
use strict;
use DynaLoader;
use Tie::Hash;
use vars qw($VERSION @ISA);

@ISA = qw(DynaLoader Tie::Hash);
$VERSION = '0.07';

bootstrap Tie::Hash::Indexed $VERSION;

1;

__END__

=head1 NAME

Tie::Hash::Indexed - Ordered hashes for Perl

=head1 SYNOPSIS

  use Tie::Hash::Indexed;

  # Object Oriented Interface
  my $hash = Tie::Hash::Indexed->new(
               I => 1, n => 2, d => 3, e => 4);
  $hash->push(x => 5);

  print $hash->keys, "\n";   # prints 'Index'
  print $hash->values, "\n"; # prints '12345'

  # Tied Interface
  tie my %hash, 'Tie::Hash::Indexed';

  %hash = ( I => 1, n => 2, d => 3, e => 4 );
  $hash{x} = 5;

  print keys %hash, "\n";    # prints 'Index'
  print values %hash, "\n";  # prints '12345'

=head1 DESCRIPTION

Tie::Hash::Indexed is intentionally very similar to other
ordered hash modules, most prominently Hash::Ordered.
However, Tie::Hash::Indexed is written completely in XS
and is, often significantly, faster than other modules.
For a lot of operations, it's more than twice as fast as
Hash::Ordered, especially when using the object-oriented
interface instead of the tied interface. Other modules,
for example Tie::IxHash, are even slower.

The object-oriented interface of Tie::Hash::Indexed is
almost identical to that of Hash::Ordered, so in most
cases you should be able to easily replace one with the
other.

If you don't need the last bit of performance and feel
more comfortable with a pure-Perl module, Hash::Ordered
is definitely a good alternative.

=head1 COMPATIBILITY

Tie::Hash::Indexed should build with perl versions as
old as 5.005. It should build on any platform if a C
compiler is available.

=head2 Hash::Ordered

Tie::Hash::Indexed has no C<clone> method, but cloning can be
emulated with:

  $clone = Tie::Hash::Indexed->new($orig->items);

Tie::Hash::Indexed has an C<items> method as an alias for
C<as_list>, which Hash::Ordered lacks. If you want to be able
to switch modules, you should prefer to use C<as_list>.

Tie::Hash::Indexed also has a C<has> method as aliases for
C<exists>.

Tie::Hash::Indexed also has C<dor_assign> and C<or_assign> as
aliases for C<dor_equals> and C<or_equals>.

Tie::Hash::Indexed has C<multiply>, C<divide> and C<modulo>
methods in addition to C<add> and C<subtract>. Hash::Ordered
only supports C<add> and C<subtract>.

Tie::Hash::Indexed has an C<assign> method that can be used
to directly assign a new list of key-value pairs to an existing
instance. With Hash::Ordered, you can call C<clear> followed by
C<merge> to get the same behaviour.

Tie::Hash::Indexed has a C<reverse_iterator> method, which can
be emulated in Hash::Ordered by passing the reversed list of
keys to C<iterator>. On the other hand, the C<iterator> method
of Tie::Hash::Indexed doesn't support passing in a list of keys
at all.

Tie::Hash::Indexed objects always evaluate to a true value in
boolean context, unlike Hash::Ordered object, which evaluate
to a false value if they are empty, and a true value otherwise.
You can use C<$obj->keys> with Tie::Hash::Indexed instead, which
is extremely cheap to call in scalar context.

=head1 METHODS

=head2 new

  $obj = Tie::Hash::Indexed->new;
  $obj = Tie::Hash::Indexed->new(@kvpairs);

Construct and optionally initialize a new object.

=head2 clear

  $obj->clear;

Removes all contents from the hash. Returns the object, which
allows for method chaining.

Invalidates iterators.

=head2 assign

  $obj->assign(@kvpairs);

Clears the hash and assigns the list of key-value pairs.
Identical to:

  $obj->clear->merge(@kvpairs);

Returns the number of keys stored in the hash after assigning.

Invalidates iterators.

=head2 merge

  $obj->merge(@kvpairs);

Merge a lists of key-value pairs into the hash. Existing keys
will remain in their position and have their value updated.
New keys will be appended to the end.

Returns the number of keys stored in the hash after merging.

Invalidates iterators.

=head2 exists

  $bool = $obj->exists($key)

Returns a boolean indicating if a key exists in the hash.

=head2 has

An alias for C<exists>.

=head2 get

  $value = $obj->get($key)

Returns the value for a single key, or C<undef> if the key
was not found.

=head2 set

  $obj->set($key, $value)

If the key already exists, update the value without affecting
the item order. Otherwise append the key-value pair. This is
equivalent to calling C<merge> with a single key-value pair,
except for the return value.

Returns the value.

Invalidates iterators.

=head2 push

  $obj->push(@kvpairs)

Push one or more key-value pairs. This is similar to C<merge>,
but instead of preserving the position of existing keys, this
will remove existing keys and append all key-value pairs to
the end.

Returns the number of keys stored in the hash after pushing.

Invalidates iterators.

=head2 unshift

  $obj->unshift(@kvpairs)

Pushes one or more key-value pairs to the start. This is similar
to C<push>, but operates on the start of the ordered hash.
Existing keys will be removed and inserted at the start.

Returns the number of keys stored in the hash after unshifting.

Invalidates iterators.

=head2 pop

  $value = $obj->pop;
  ($key, $value) = $obj->pop;

Removes the last item from the ordered hash.

Returns the value in scalar context or the key-value pair in
list context.

Invalidates iterators.

=head2 shift

  $value = $obj->shift;
  ($key, $value) = $obj->shift;

Removes the first item from the ordered hash.

Returns the value in scalar context or the key-value pair in
list context.

Invalidates iterators.

=head2 delete

  $value = $obj->delete($key);

Removes a key-value pair from the ordered hash and returns the
value.

Invalidates iterators if the key was found.

=head2 items

  @kvpairs = $obj->items;
  @kvpairs = $obj->items(@keys);

Returns the key-value pairs for all items in the hash, or just
for the selected keys. In scalar context, returns the number
of list elements that would be returned in list context.

If a key is not found, the associated value will be returned
as C<undef>.

=head2 as_list

An alias for C<items>.

=head2 keys

  @keys = $obj->keys;
  @keys = $obj->keys(@keys);

Returns the keys for all items in the hash, or just
for the selected keys. In scalar context, returns the number
of list elements that would be returned in list context.

=head2 values

  @values = $obj->values;
  @values = $obj->values(@keys);

Returns the values for all items in the hash, or just
for the selected keys. In scalar context, returns the number
of list elements that would be returned in list context.

If a key is not found, the associated value will be returned
as C<undef>.

=head2 concat

  $obj->concat($key, $str);

This is equivalent to, but more efficient than:

  $obj->set($key, $obj->get($key) . $str);

=head2 add

  $obj->add($key, $value);

This is equivalent to, but more efficient than:

  $obj->set($key, $obj->get($key) + $value);

=head2 subtract

  $obj->subtract($key, $value);

This is equivalent to, but more efficient than:

  $obj->set($key, $obj->get($key) - $value);

=head2 multiply

  $obj->multiply($key, $value);

This is equivalent to, but more efficient than:

  $obj->set($key, $obj->get($key) * $value);

=head2 divide

  $obj->divide($key, $value);

This is equivalent to, but more efficient than:

  $obj->set($key, $obj->get($key) / $value);

=head2 modulo

  $obj->modulo($key, $value);

This is equivalent to, but more efficient than:

  $obj->set($key, $obj->get($key) % $value);

=head2 dor_assign

  $obj->dor_assign($key, $value);

This is equivalent to, but more efficient than:

  $obj->set($key, $obj->get($key) // $value);

=head2 dor_equals

This is an alias for C<dor_assign>.

=head2 or_assign

  $obj->or_assign($key, $value);

This is equivalent to, but more efficient than:

  $obj->set($key, $obj->get($key) || $value);

=head2 or_equals

This is an alias for C<or_assign>.

=head2 postinc

  $val = $obj->postinc($key);

This is equivalent to, but more efficient than:

  $val = $obj->get($key);
  $obj->set($key, $val + 1);

=head2 postdec

  $val = $obj->postdec($key);

This is equivalent to, but more efficient than:

  $val = $obj->get($key);
  $obj->set($key, $val - 1);

=head2 preinc

  $val = $obj->preinc($key);

This is equivalent to, but more efficient than:

  $val = $obj->set($key, $obj->get($key) + 1);

=head2 predec

  $val = $obj->predec($key);

This is equivalent to, but more efficient than:

  $val = $obj->set($key, $obj->get($key) - 1);

=head2 iterator

  my $i = $h->iterator;
  while (my($k, $v) = $i->next) {
    push @key, $k;
    push @val, $v;
  }

Bidirectional forward iterator for ordered hash traversal.

=head2 reverse_iterator

  for (my $i = $h->reverse_iterator; $i->valid; $i->next) {
    push @key, $i->key;
    push @val, $i->value;
  }

Bidirectional reverse iterator for ordered hash traversal.

=head1 ENVIRONMENT

=head2 C<THI_DEBUG_OPT>

If Tie::Hash::Indexed is built with debugging support, you
can use this environment variable to specify debugging
options. Currently, the only useful values you can pass
in are C<d> or C<all>, which both enable debug output for
the module.

=head1 PROBLEMS

As the data of Tie::Hash::Indexed objects is hidden inside
the XS implementation, cloning/serialization is problematic.
Tie::Hash::Indexed implements hooks for Storable, so cloning
or serializing objects using Storable is safe.

Tie::Hash::Indexed tries very hard to detect any corruption
in its data at runtime. So if something goes wrong, you'll
most probably receive an appropriate error message.

=head1 BUGS

If you find any bugs, Tie::Hash::Indexed doesn't seem to
build on your system or any of its tests fail, please use
the CPAN Request Tracker at L<http://rt.cpan.org/> to create
a ticket for the module. Alternatively, just send a mail
to E<lt>mhx@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright (c) Marcus Holland-Moritz. All rights reserved.
This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

See L<perltie>, L<Hash::Ordered>, L<Tie::IxHash>.

=cut

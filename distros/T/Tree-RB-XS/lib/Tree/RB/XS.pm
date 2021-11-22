package Tree::RB::XS;
$Tree::RB::XS::VERSION = '0.05';
# VERSION
# ABSTRACT: Red/Black Tree implemented in C, with similar API to Tree::RB

use strict;
use warnings;
use Carp;
require XSLoader;
XSLoader::load('Tree::RB::XS', $Tree::RB::XS::VERSION);
use Exporter 'import';
our @_key_types= qw( KEY_TYPE_ANY KEY_TYPE_INT KEY_TYPE_FLOAT KEY_TYPE_BSTR KEY_TYPE_USTR );
our @_cmp_enum= qw( CMP_PERL CMP_INT CMP_FLOAT CMP_MEMCMP CMP_UTF8 CMP_NUMSPLIT );
our @_lookup_modes= qw( GET_EQ GET_EQ_LAST GET_GT GET_LT GET_GE GET_LE GET_LE_LAST GET_NEXT GET_PREV
                        LUEQUAL LUGTEQ LULTEQ LUGREAT LULESS LUNEXT LUPREV );
our @EXPORT_OK= (@_key_types, @_cmp_enum, @_lookup_modes);
our %EXPORT_TAGS= (
	key_type => \@_key_types,
	cmp      => \@_cmp_enum,
	lookup   => \@_lookup_modes,
	get      => \@_lookup_modes,
	all      => \@EXPORT_OK,
);


sub new {
	my $class= shift;
	my %options= @_ == 1 && ref $_[0] eq 'HASH'? %{$_[0]}
		: @_ == 1? ( compare_fn => $_[0] )
		: @_;
	my $self= bless \%options, $class;
	$self->_init_tree(delete $self->{key_type}, delete $self->{compare_fn});
	$self->allow_duplicates(1) if delete $self->{allow_duplicates};
	$self->compat_list_get(1) if delete $self->{compat_list_get};
	$self;
}


*root= *root_node;
*min= *min_node;
*max= *max_node;
*nth= *nth_node;


sub iter {
	my ($self, $key_or_node, $mode)= @_;
	$key_or_node= $self->get_node($key_or_node, @_ > 2? $mode : GET_GE())
		if @_ > 1 && ref $key_or_node ne 'Tree::RB::XS::Node';
	Tree::RB::XS::Iter->_new($key_or_node || $self, 1);
}

sub rev_iter {
	my ($self, $key_or_node, $mode)= @_;
	$key_or_node= $self->get_node($key_or_node, @_ > 2? $mode : GET_LE_LAST())
		if @_ > 1 && ref $key_or_node ne 'Tree::RB::XS::Node';
	Tree::RB::XS::Iter->_new($key_or_node || $self, -1);
}


*Tree::RB::XS::Node::min=         *Tree::RB::XS::Node::left_leaf;
*Tree::RB::XS::Node::max=         *Tree::RB::XS::Node::right_leaf;
*Tree::RB::XS::Node::successor=   *Tree::RB::XS::Node::next;
*Tree::RB::XS::Node::predecessor= *Tree::RB::XS::Node::prev;


sub Tree::RB::XS::Node::strip {
	my ($self, $cb)= @_;
	my ($at, $next, $last)= (undef, $self->left_leaf || $self, $self->right_leaf || $self);
	do {
		$at= $next;
		$next= $next->next;
		if ($at != $self) {
			$at->prune;
			$cb->($at) if $cb;
		}
	} while ($at != $last);
}

sub Tree::RB::XS::Node::as_lol {
	my $self= $_[1] || $_[0];
	[
		$self->left? $self->left->as_lol : '*',
		$self->right? $self->right->as_lol : '*',
		($self->color? 'R':'B').':'.($self->key||'')
	]
}

sub Tree::RB::XS::Node::iter {
	Tree::RB::XS::Iter->_new($_[0], 1);
}

sub Tree::RB::XS::Node::rev_iter {
	Tree::RB::XS::Iter->_new($_[0], -1);
}


# I can't figure out how to do the closure in XS yet
sub Tree::RB::XS::Iter::_new {
	my $class= shift;
	my ($self,$y);
	$self= bless sub { Tree::XS::RB::Iter::next($y) }, $class;
	Scalar::Util::weaken($y= $self);
	$self->_init(@_);
}
sub Tree::RB::XS::Iter::clone {
	my $self= shift;
	ref($self)->_new($self);
}


*TIEHASH= *new;
*STORE= *put;
*CLEAR= *clear;

sub hseek {
	my ($self, $key, $opts)= @_;
	if (@_ == 2 && ref $key eq 'HASH') {
		$opts= $key;
		$key= $opts->{'-key'};
	}
	my $reverse= $opts && $opts->{'-reverse'} || 0;
	my $node= defined $key? $self->get_node($key, $reverse? GET_LE_LAST() : GET_GE()) : undef;
	$self->_set_hashiter($node, $reverse);
}


*LUEQUAL= *GET_EQ;
*LUGTEQ=  *GET_GE;
*LUGTLT=  *GET_LE;
*LUGREAT= *GET_GT;
*LULESS=  *GET_LT;
*LUPREV=  *GET_PREV;
*LUNEXT=  *GET_NEXT;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tree::RB::XS - Red/Black Tree implemented in C, with similar API to Tree::RB

=head1 SYNOPSIS

B<NOTICE:> This module is very new and you should give it some thorough testing before
trusting it with production data.

  use Tree::RB::XS qw/ :cmp :get /;
  
  my $tree= Tree::RB::XS->new;
  $tree->put($_ => $_) for 'a'..'z';    # store key/value, overwrite
  say $tree->get('a');                  # get value by key, or undef
  $tree->delete('a');                   # delete by key
  say $tree->get('a', GET_GT);          # find relative to the key, finds 'b'
  $tree->delete('a','z');               # delete a range, inclusive
  $tree->delete($tree->min_node);       # delete using nodes or iterators
  $tree->clear;                         # efficiently delete all nodes
  
  $tree= Tree::RB::XS->new(CMP_INT);    # optimize for integer comparisons
  $tree->put(1 => "x");

  $tree= Tree::RB::XS->new(
    compare_fn => 'float',              # optimize for floating-point
    allow_duplicates => 1
  );
  $tree->put(rand() => 1) for 1..1000;
  $tree->delete(0, $tree->get_node_lt(.5));
  
  $tree= Tree::RB::XS->new(CMP_MEMCMP); # optimize for byte strings
  $tree->put("test" => "x");
  
  say $tree->min->key;                  # inspect the node objects
  say $tree->nth(0)->key;
  my $node= $tree->min;
  my $next= $node->next;
  $node->prune;
  
  # iterators
  
  for (my $i= $tree->iter; !$i->done; $i->step) {
    if ($i->key ...) { $i->value .... }
  }
  
  my $i= $tree->rev_iter;
  while (my $node= $i->next) {
    $node->prune if $node->key =~ ...;
  }
  
  my $i= $tree->iter;
  while (my @batch= $i->next_values(100)) {
    ...
  }

=head1 DESCRIPTION

This module is a wrapper for a Red/Black Tree implemented in C.  It's primary features over
other search trees on CPAN are optimized comparisons of keys (speed), C<< O(log N) >>
node-by-index lookup (which allows the tree to act as an array), and the option to
allow duplicate keys while preserving insertion order.

The API is almost a complete superset of L<Tree::RB> with a few differences:

=over

=item *

The C<get> method in this module is not affected by array context, unless you
request L</compat_list_get>.

=item *

C<resort> is not implemented (would be lots of effort, and unlikely to be needed)

=item *

Tree structure is not mutable via the attributes of Node, nor can nodes be created
independent from a tree.

=item *

Many functions have official names changed, but aliases are provided for compatibility.

=back

=head1 CONSTRUCTOR

=head2 new

  my $tree= Tree::RB::XS->new( %OPTIONS );
                     ...->new( $compare_fn );

If C<new> is given a single parameter, it is assumed to be the C<compare_fn>.

Options:

=over

=item L</compare_fn>

Choose a custom key-compare function.  This can be the ID of an optimized function,
a coderef, or the name of one of the optimized IDs like "int" for C<CMP_INT>.
See below for details.

=item L</allow_duplicates>

Whether to allow two nodes with the same key.  Defaults to false.

=item L</compat_list_get>

Whether to enable full compatibility with L<Tree::RB>'s list-context behavior for L</get>.
Defaults to false.

=item L</key_type>

This is an internal detail that probably shouldn't have been exposed, and might be removed
in the future.  Choose one of the optimized C<compare_fn> instead.

=back

=head1 ATTRIBUTES

=head2 compare_fn

Specifies the function that compares keys.  Read-only; pass as an option to
the constructor.

This is one of: L</CMP_PERL> (default), L</CMP_INT>, L</CMP_FLOAT>, L</CMP_MEMCMP>,
L</CMP_UTF8>, L</CMP_NUMSPLIT>, or a coderef.  C<CMP_INT> and C<CMP_FLOAT> are the
most efficient, and internally store the key as a number.  C<CMP_MEMCMP> and
C<CMP_UTF8> copy the key into an internal buffer, and offer moderate speed gains
over C<CMP_PERL>.  C<CMP_PERL> is Perl's own C<cmp> operator.

If set to a coderef, it should take two parameters and return an integer
indicating their order in the same manner as Perl's C<cmp>.
Beware that using a custom coderef throws away most of the speed gains from using
this XS variant over plain L<Tree::RB>.  If speed is important, try pre-processing
your keys in a way that allows you to use one of the built-in ones.

Patches welcome, for anyone who wants to expand the list of optimized built-in
comparison functions.

=head2 allow_duplicates

Boolean, read/write.  Controls whether L</insert> will allow additional nodes with
keys that already exist in the tree.  This does not change the behavior of L</put>,
only L</insert>.  If you set this to false, it does not remove duplicates that
already existed.  The initial value is false.

=head2 compat_list_get

Boolean, read/write.  Controls whether L</get> returns multiple values in list context.
I wanted to match the API of C<Tree::RB>, but I can't bring myself to make an innocent-named
method like 'get' change its behavior in list context.  So, by deault, this attribute is
false and C<get> always returns one value.  But if you set this to true, C<get> changes in
list context to also return the Node, like is done in L<Tree::RB/lookup>.

=head2 key_type

The key-storage strategy used by the tree.  Read-only; pass as an option to
the constructor.  This is an implementation detail that may be removed in a future
version.

=head2 size

Returns the number of elements in the tree.

=head2 root_node

Get the root node of the tree, or C<undef> if the tree is empty.

Alias: C<root>

=head2 min_node

Get the tree node with minimum key.  Returns undef if the tree is empty.

Alias: C<min>

=head2 max_node

Get the tree node with maximum key.  Returns undef if the tree is empty.

Alias: C<max>

=head2 nth_node

Get the Nth node in the sequence from min to max.  N is a zero-based index.
You may use negative numbers to count down form max.

Alias: C<nth>

=head1 METHODS

=head2 get

  my $val= $tree->get($key);
             ...->get($key, $mode);

Fetch a value from the tree, by its key.  Unlike L<Tree::RB/get>, this returns a single
value, regardless of list context.  But, you can set L<compat_list_get> to make C<get>
an alias for C<lookup>.

Mode can be used to indicate something other than an exact match:
L</GET_EQ>, L</GET_EQ_LAST>, L</GET_LE>, L</GET_LE_LAST>, L</GET_LT>, L</GET_GE>, L</GET_GT>.
(described below)

=head2 get_node

Same as L</get>, but returns the node instead of the value.  In trees with
duplicate keys, this returns the first matching node.
(nodes with identical keys are preserved in the order they were added)

Aliases with built-in mode constants:

=over 20

=item get_node_last

=item get_node_le

=item get_node_le_last

=item get_node_lt

=item get_node_ge

=item get_node_gt

=back

=head2 get_all

  my @values= $tree->get_all($key);

In trees with duplicate keys, this method is useful to return the values of all
nodes that match the key.  This can be more efficient than stepping node-to-node
for small numbers of duplicates, but beware that large numbers of duplicate could
have an adverse affect on Perl's stack.

=head2 lookup

Provided for compatibility with Tree::RB.  Same as L</get> in scalar context, but
if called in list context it returns both the value and the node from L</get_node>.
You can also use Tree::RB's lookup-mode constants of "LUEQUAL", etc.

=head2 put

  my $old_val= $tree->put($key, $new_val);

Associate the key with a new value.  If the key previously existed, this returns
the old value, and updates the tree to reference the new value.  If the tree
allows duplicate keys, this will remove all but one node having this key and
then set its value.  Only the first old value will be returned.

=head2 insert

Insert a new node into the tree, and return the index at which it was inserted.
If L</allow_duplicates> is not enabled, and the node already existed, this returns -1
and does not change the tree.  If C<allow_duplicates> is enabled, this adds the new
node after all nodes of the same key, preserving the insertion order.

=head2 delete

  my $count= $tree->delete($key);
               ...->delete($key1, $key2);
               ...->delete($node1, $node2);
               ...->delete($start, $tree->get_node_lt($limit));

Delete any node with a key identical to C<$key>, and return the number of nodes
removed.  If you supply two keys (or two nodes) this will delete those nodes and
all nodes inbetween; C<$key1> is searched with mode C<GET_GE> and C<$key2> is
searched with mode C<GET_LE_LAST>, so the keys themselves do not need to be found in
the tree.
The keys (or nodes) must be given in ascending order, else no nodes are deleted.

If you want to delete a range *exclusive* of one or both ends of the range, just
use the L</get_node> method with the desired mode to look up each end of the nodes
that you do want removed.

=head2 clear

  my $count= $tree->clear();

This is the fastest way to remove all nodes from the tree.  It gets to destroy all
the nodes without worrying about the tree structure or shifting iterators aside.

=head2 iter

  my $iter= $tree->iter;                              # from min_node
              ...->iter($from_key, $get_mode=GET_GE); # from get_node
              ...->iter($from_node);                  # from existing node

Return an L<iterator object|/ITERATOR OBJECTS> that traverses the tree from min to max,
or from the key or node you provide up to max.

=head2 rev_iter

Like C<iter>, but the C<< ->next >> and C<< ->step >> methods walk backward to smaller key
values, and the default C<$get_mode> is L</GET_LE_LAST>.

=head1 NODE OBJECTS

=head2 Node Attributes

=over

=item key

The sort key.  Read-only, but if you supplied a reference and you modify what it
points to, you will break the sorting of the tree.

=item value

The data associated with the node.  Read/Write.

=item prev

The previous node in the sequence of keys.  Alias C<predecessor> for C<Tree::RB::Node> compat.

=item next

The next node in the sequence of keys.  Alias C<successor> for C<Tree::RB::Node> compat.

=item tree

The tree this node belongs to.  This becomes C<undef> if the tree is freed or if the node
is pruned from the tree.

=item left

The left sub-tree.

=item left_leaf

The left-most leaf of the sub-tree.  Alias C<min> for C<Tree::RB::Node> compat.

=item right

The right sub-tree.

=item right_leaf

The right-most child of the sub-tree.  Alias C<max> for C<Tree::RB::Node> compat.

=item parent

The parent node, if any.

=item color

0 = black, 1 = red.

=item count

The number of items in the tree rooted at this node (inclusive)

=back

=head2 Node Methods

=over

=item prune

Remove this single node from the tree.  The node will still have its key and value,
but all attributes linking to other nodes will become C<undef>.

=item strip

Remove all children of this node, optionally calling a callback for each.
For compat with L<Tree::RB::Node/strip>.

=item as_lol

Return sub-tree as list-of-lists. (array of arrays rather?)
For compat with L<Tree::RB::Node/as_lol>.

=item iter

Shortcut for C<< $node->tree->iter($node) >>.

=item rev_iter

Shortcut for C<< $node->tree->rev_iter($node) >>.

=back

=head1 ITERATOR OBJECTS

Iterators are similar to Nodes, but they hold a strong reference to the tree, and if a node
they point to is removed from the tree they advance to the next node.  (and obviously they
iterate, where node objects do not)

The iterator references a "current node" which you can inspect the key and value of.  You
can call 'step' to move to a new current node, and you can call 'next' which returns the
current node while switching the reference to the next node.

Note that if you avoid referencing the Node, and stick to the attributes and methods of the
iterator, the tree can avoid allocating the Perl object to represent the Node.  This gives a
bit of a performance boost for large tree operations.

=head2 Iterator Attributes

=over

=item key

The key of the current node.

=item value

The value of the current node.  Note that this returns the actual value, which in an aliased
context allows you to modify the value stored in the tree.

  $_++ for $iter->value;

=item index

The index of the current node.

=item tree

A reference back to the Tree.  Note that each iterator holds a strong reference to the tree.

=item done

True if the iterator has reached the end of its sequence, and no longer references a
current Node.

=back

=head2 Iterator Methods

=over

=item next

  my $nodes= $iter->next;
  my @nodes= $iter->next($count);
  my @nodes= $iter->next('*');

Return the current node (as a L<node object|/NODE OBJECTS>) and advance to the following node
in the sequence.  After the end of the sequence, calls to C<next> return C<undef>.
If you pass the optional C<$count>, it will return up to that many nodes, as a list.
It will also return an empty list at the end of the sequence instead of returning C<undef>.
You can use the string C<'*'> for the count to indicate all the rest of the nodes in the
sequence.

=item next_keys

Same as C<next>, but return the keys of the nodes.

=item next_values

Same as C<next>, but return the values of the nodes.  Like L</value>, these are also aliases,
and can be modified.

  $_++ for $iter->next_values('*');

=item next_kv

  my %x= $iter->next_kv('*');

Same as C<next>, but return pairs of key and value for each node.  This is useful for dumping
them into a hash. (B<unless> you have duplicate keys enabled, then don't dump them into a hash
or you would lose elements)

=item step

  $iter->step;     # advance by one node
  $iter->step(10); # advance by 10 nodes
  $iter->step(-4); # back up 4 nodes

This moves the iterator by one or more nodes in the forward or backward direction.
For a reverse-iterator, positive numbers move toward the minimum key and negative numbers
move toward the maximum key.  If the offset would take the iterator beyond the last node,
the current node becomes C<undef>.  If the offset would take the iterator beyond the first
node, the first node becomes the current node.

=item delete

Delete the current node, return its value, and advance to the next node.

  for (my $i= $tree->iter; !$i->done;) {
    if ($i->key =~ ...) {
      say "Removing ".$i->key." = ".$i->delete;
    } else {
      $i->step;
    }
  }

This is useful when combined with the C<key> and C<value> attributes of the iterator, but not
so much when you are looping using C<next>, because C<next> has already moved to the next node
beyond the one it returned to you.  When using C<next>, call C<delete> on the node, not the
iterator.

=item clone

Returns a new iterator of the same direction pointing at the same node.

=back

=head1 TIE HASH INTERFACE

This class implements the required methods needed for C<tie>:

  my %hash
  my $tree= tie %hash, 'Tree::RB::XS';
  $hash{$_}= $_ for 1..10;
  delete $hash{3};
  $_ += 1 for values %hash;
  tied(%hash)->hseek(5);
  say each %hash;  # 5

But you get better performance by using the tree's API directly.  This should only be used when
you need to integrate with code that isn't aware of the tree.

=over

=item hseek

  tied(%hash)->hseek( $key );
             ->hseek({ -reverse => $bool });
             ->hseek( $key, { -reverse => $bool });

This is a method of the tree, but only relevant to the tied hash interface.  It controls the
behavior of the next call to C<< each %hash >> or C<< keys %hash >>, causing the first element
to be the node at or after the C<$key>.  (or before, if you change to a reverse iterator)

This method differs from L<Tree::RB/hseek> in that C<Tree::RB> will change the logical first
node of the iteration *indefinitely* such that repeated calls to C<keys> do not see any element
less than C<$key>.  This C<hseek> only applies to the next iteration.  (which I'm guessing was
th intent in Tree::RB?)

=back

=head1 EXPORTS

=head2 Comparison Functions

Export all with ':cmp'

=over

=item CMP_PERL

Use Perl's C<cmp> function.  This forces the keys of the nodes to be stored as
Perl Scalars.

=item CMP_INT

Compare keys directly as whatever integer type Perl was compiled with.
(i.e. 32-bit or 64-bit)  This is the fastest option.

=item CMP_FLOAT

Compare the keys directly as whatever floating-point type Perl was compiled with.
(i.e. 64-bit double or 80-bit long double)

=item CMP_UTF8

Compare the keys as UTF8 byte strings, using Perl's internal C<bytes_cmp_utf8> function.

=item CMP_MEMCMP

Compare the keys using C's C<memcmp> function.

=item CMP_NUMSPLIT

Compare using the equivalent of this coderef:

  sub {
    my @a_parts= split /([0-9]+)/, $_[0];
    my @b_parts= split /([0-9]+)/, $_[1];
    for (my $i= 0; $i < @a_parts || $i < @b_parts; $i++) {
      no warnings 'uninitialized';
      my $cmp= ($i & 1)? ($a_parts[$i] <=> $b_parts[$i])
             : ($a_parts[$i] cmp $b_parts[$i]);
      return $cmp if $cmp;
    }
    return 0;
  }

except the XS implementation is not limited by the integer size of perl,
and operates directly on the strings without splitting anything. (i.e. much faster)

This results in a sort where integer portions of a string are sorted numerically,
and any non-digit segment is compared as a string.  This produces sort-orders like
the following:

  2020-01-01
  2020-4-7
  2020-10-12

or

  14.4.2
  14.14.0

If the C<key_type> is C<KEY_TYPE_BSTR> this will sort the string portions using
C<memcmp>, else they are sorted with Perl's unicode-aware sort.

=back

=head2 Key Types

Export all with ':key_type';

=over

=item KEY_TYPE_ANY

This C<key_type> causes the tree to store whole Perl scalars for each node.
Its default comparison function is Perl's own C<cmp> operator.

=item KEY_TYPE_INT

This C<key_type> causes the tree to store keys as Perl's integers,
which are either 32-bit or 64-bit depending on how Perl was compiled.
Its default comparison function puts the numbers in non-decreasing order.

=item KEY_TYPE_FLOAT

This C<key_type> causes the tree to store keys as Perl's floating point type,
which are either 64-bit doubles or 80-bit long-doubles.
Its default comparison function puts the numbers in non-decreasing order.

=item KEY_TYPE_BSTR

This C<key_type> causes the tree to store keys as byte strings.
The default comparison function is the standard Libc C<memcmp>.

=item KEY_TYPE_USTR

Same as C<KEY_TYPE_BSTR> but reads the bytes from the supplied key as UTF-8 bytes.
The default comparison function is also C<memcmp> even though this does not sort
Unicode correctly.  (for correct unicode, use C<KEY_TYPE_ANY>, but it's slower...)

=back

=head2 Lookup Mode

Export all with ':get'

=over

=item GET_EQ

This specifies a node with a key equal to the search key.  If duplicate keys are enabled,
this specifies the left-most match (least recently added).
Has alias C<LUEQUAL> to match Tree::RB.

=item GET_EQ_LAST

Same as C<GET_EQ>, but if duplicate keys are enabled, this specifies the right-most match
(most recently inserted).

=item GET_GE

This specifies the same node of C<GET_EQ>, unless there are no matches, then it falls back
to the left-most node with a key greater than the search key.
Has alias C<LUGTEQ> to match Tree:RB.

=item GET_LE

This specifies the same node of C<GET_EQ>, unless there are no matches, then it falls back
to the right-most node with a key less than the search key.
Has alias C<LULTEQ> to match Tree::RB.

=item GET_LE_LAST

This specifies the same node of C<GET_EQ_LAST>, unless there are no matches, then it falls
back to the right-most node with a key less than the search key.

=item GET_GT

Return the first node greater than the key,
or C<undef> if the key is greater than any node.
Has alias C<LUGREAT> to match Tree::RB.

=item GET_LT

Return the right-most node less than the key,
or C<undef> if the key is less than any node.
Has alias C<LULESS> to match Tree::RB.

=item GET_NEXT

Look for the last node matching the specified key (returning C<undef> if not found)
then return C<< $node->next >>.  This is the same as C<GET_GT> except it ensures the
key existed.
Has alias C<LUNEXT> to match Tree::RB.

=item GET_PREV

Look for the first node matching the specified key (returning C<undef> if not found)
then return C<< $node->prev >>.  This is the same as C<GET_LT> except it ensures the
key existed.
Has alias C<LUPREV> to match Tree::RB.

=back

=head1 SEE ALSO

=over

=item L<Tree::RB>

The Red/Black module this one used as API inspiration.  The fastest pure-perl tree module on
CPAN.  Implemented as blessed arrayrefs.

=item L<AVLTree>

Another XS-based tree module.  About 6%-70% slower than this one depending on whether you use
coderef comparisons or optimized comparisons.

=item L<Tree::AVL>

An AVL tree implementation in pure perl.  The API is perhaps more convenient, with the ability
to add your object to the tree with a callback that derives the key from that object.
However, it runs significantly slower than Tree::RB.

=back

=head1 VERSION

version 0.05

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

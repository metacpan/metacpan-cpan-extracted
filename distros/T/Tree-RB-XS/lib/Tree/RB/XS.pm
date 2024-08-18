package Tree::RB::XS;
$Tree::RB::XS::VERSION = '0.14';
# VERSION
# ABSTRACT: Red/Black Tree and LRU Cache implemented in C

use strict;
use warnings;
use Carp;
use Scalar::Util ();
require XSLoader;
XSLoader::load('Tree::RB::XS', $Tree::RB::XS::VERSION);
use Exporter 'import';
our @_key_types= qw( KEY_TYPE_ANY KEY_TYPE_INT KEY_TYPE_FLOAT KEY_TYPE_BSTR KEY_TYPE_USTR );
our @_cmp_enum= qw( CMP_PERL CMP_INT CMP_FLOAT CMP_MEMCMP CMP_UTF8 CMP_NUMSPLIT );
our @_lookup_modes= qw( GET_EQ GET_EQ_LAST GET_GT GET_LT GET_GE GET_LE GET_LE_LAST GET_NEXT GET_PREV
                        GET_OR_ADD LUEQUAL LUGTEQ LULTEQ LUGREAT LULESS LUNEXT LUPREV );
our @EXPORT_OK= (@_key_types, @_cmp_enum, @_lookup_modes, 'cmp_numsplit');
our %EXPORT_TAGS= (
	key_type => \@_key_types,
	cmp      => \@_cmp_enum,
	lookup   => \@_lookup_modes,
	get      => \@_lookup_modes,
	all      => \@EXPORT_OK,
);


*root= *root_node;
*min= *min_node;
*max= *max_node;
*nth= *nth_node;
*oldest= *oldest_node;
*newest= *newest_node;


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

sub iter_newer {
	my ($self, $node)= @_;
	Tree::RB::XS::Iter->_new($node || $self, 2);
}

sub iter_older {
	my ($self, $node)= @_;
	Tree::RB::XS::Iter->_new($node || $self, -2);
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

sub Tree::RB::XS::Node::iter_newer {
	Tree::RB::XS::Iter->_new($_[0], 2);
}

sub Tree::RB::XS::Node::iter_older {
	Tree::RB::XS::Iter->_new($_[0], -2);
}


# I can't figure out how to do the closure in XS yet
sub Tree::RB::XS::Iter::_new {
	my $class= shift;
	my ($self,$y);
	$self= bless sub { Tree::RB::XS::Iter::next($y) }, $class;
	Scalar::Util::weaken($y= $self);
	$self->_init(@_);
}
sub Tree::RB::XS::Iter::clone {
	my $self= shift;
	ref($self)->_new($self);
}


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

Tree::RB::XS - Red/Black Tree and LRU Cache implemented in C

=head1 SYNOPSIS

Basic dictionary features:

  my $tree= Tree::RB::XS->new;
  $tree->put($_ => 0) for 'a'..'z';      # store key/value, overwrite
  say $tree->get('a');                   # get value by key
  $tree->get('a')++                      # 'get' returns lvalues
    if $tree->exists('a');
  $tree->delete('a');                    # delete by key
  $tree->clear;                          # efficiently delete all nodes

Tree-specific features:

  use Tree::RB::XS qw/ :get /;
  
  $tree->put(a => 1);
  $tree->put(m => 13);
  $tree->put(z => 26);
  $nd= $tree->get_node('f', GET_GE);     # returns node of 'm'
  $nd= $tree->get_node('f', GET_LT);     # returns node of 'a'
  $nd= $tree->nth_node(2);               # returns node of 'z', O(log N) time
  $tree->max_node->index;                # returns 2, also O(log N) time
  my $iter= $tree->iter;                 # iterates in key order
  
  $tree->delete('f','w');                # delete a range, deletes 'm'
  $tree->delete($iter, $tree->max_node); # delete using nodes or iterators
  
  $tree->put(b => 2);
  $tree->min_node->prune;                # manipulate tree via node methods

Support duplicate keys:

  use Tree::RB::XS qw/ :cmp /;

  $tree= Tree::RB::XS->new(
    compare_fn => CMP_NUMSPLIT,          # string-of-numbers comparison
    allow_duplicates => 1,
  );
  $tree->insert('192.168.0.1'  => time); # 'insert' instead of 'put'
  $tree->insert('192.168.0.40' => time);
  $tree->insert('192.168.0.1'  => time);
  
  # analyze subnet
  $first= $tree->get_node_ge('192.168.0.0');
  $last=  $tree->get_node_le('192.168.0.255');
  say $last->index - $first->index + 1;  # 3 in subnet

LRU Cache feature:

  $tree= Tree::RB::XS->new(
    track_recent => 1,                   # Remember order of added nodes
  );
  $tree->put($_,$_) for 1,3,2;
  say $tree->newest->key;                # 2
  say $tree->oldest->key;                # 1
  @insertion_order=
    $tree->iter_newer->next_keys(1e99);  # (1,3,2)
  $tree->get_node(1)->mark_newest;       # 'touch' a node to end of list
  $tree->iter_newer->next_keys(1e99);    # (3,2,1)
  $tree->iter_older->next_keys(1e99);    # (1,2,3)
  @removed= $tree->truncate_recent(2);   # returns (3), leaves (2,1) in tree

Fancy iterators:

  # iterator has 'current position'. inspect it, then step
  for (my $i= $tree->iter; !$i->done; $i->step) {
    if ($i->key ...) { $i->value .... }
  }
  
  # Call iterator as a function that returns the next node
  my $i= $tree->rev_iter;
  while (my $node= &$i) {
    $node->prune if $node->key =~ ...;
  }
  
  # Return batches of values from iterator, to reduce loop overhead
  my $i= $tree->iter;
  while (my @batch= $i->next_values(100)) {
    ...
  }
  
  # If you delete the node an iterator is on, it moves to the next
  $tree= Tree::RB::XS->new(
    track_recent => 1,
    kv => [ a => 1, c => 3, b => 2 ],
  );
  $middle_node= $tree->nth(1);           # node of 'b'
  $forward= $middle_node->iter;          # iterate to higher keys
  $reverse= $middle_node->rev_iter;      # iterate to lower keys
  $newer= $middle_node->iter_newer;      # iterate to more recent keys
  $older= $middle_node->iter_older;      # iterate to less recent keys
  $middle_node->prune;                   # remove node from tree
  
  say $_->key for $forward, $reverse;    # c, a
  say $_->key for $newer, $older;        # undef, c

=head1 DESCRIPTION

This is a feature-rich Red/Black Tree implemented in C.  Special features (above and beyond the
basics you'd expect from a treemap) include:

=over

=item *

Optimized storage and L<comparisons of keys|/compare_fn> (speed)

=item *

C<< O(log N) >> L<Nth-node lookup|/nth_node> (which allows the tree to act as an array)

=item *

Smart bi-directional L<iterators|/ITERATOR OBJECTS> that advance when you delete the current node.

=item *

Option to allow L<duplicate keys|/allow_duplicates> while preserving insertion order.

=item *

Optional linked-list of L<"recent" order|/track_recent>, to facilitate LRU or MRU caches.

=back

=head1 CONSTRUCTOR

=head2 new

  my $tree= Tree::RB::XS->new( %OPTIONS );
                     ...->new( $compare_fn );

If C<new> is given a single parameter, it is assumed to be the C<compare_fn>.

Options:

=over

=item *

C<compare_fn>

Choose a custom key-compare function.  This can be the ID of an optimized function,
a coderef, or the name of one of the optimized IDs like "int" for C<CMP_INT>.
See below for details.

=item *

C<allow_duplicates>

Whether to allow two nodes with the same key.  Defaults to false.

=item *

C<compat_list_get>

Whether to enable full compatibility with L<Tree::RB>'s list-context behavior for L</get>.
Defaults to false.

=item *

C<track_recent>

Whether to keep track of the insertion order of nodes, by default.  Defaults to false.
You may toggle this attribute after construction.

=item *

C<lookup_updates_recent>

Whether L</lookup> and L</get> methods automatically mark a node as the most recent.

=item *

C<kv>

An initial arrayref of C<key,value> pairs to initialize the tree with.  If allow_duplicates
is requested, this uses L</insert_multi>, else it uses L</put_multi> (so later duplicate
keys replace the values of earlier ones).

=item *

C<keys>

An arrayref of keys to use to initialize the tree.  If C<values> are not provided, the value
of each node will be C<undef>.

=item *

C<values>

An arrayref of values to use to initialize the tree.  If provided, it must be the same length
as C<keys>.

=item *

C<recent>

Specifies a list of integers which initialize the list used by the "track_recent" feature,
overriding the order seen in C<keys> or C<kv>.  The integer refers to the L</nth> node of the
assembled tree.  The list does not need to include all the nodes.

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
already exist in the tree.  The initial value is false.

=head2 compat_list_get

Boolean, read/write.  Controls whether L</get> returns multiple values in list context.
I wanted to match the API of C<Tree::RB>, but I can't bring myself to make an innocent-named
method like 'get' change its behavior in list context.  So, by deault, this attribute is
false and C<get> always returns one value.  But if you set this to true, C<get> changes in
list context to also return the Node, like is done in L<Tree::RB/lookup>.

=head2 track_recent

Boolean, read/write.  Enabling this causes all nodes added (afterward) with L</put> or
L</insert> to be added to an insertion-order linked list.  You can then inspect or iterate them
with related methods.  Note that each node can be tracked or un-tracked individually, and this
setting just changes the default for new nodes.  This allows you to differentiate more permanent
data points vs. temporary ones that you might want to expire over time.

See also: L</oldest_node>, L</newest_node>, L</recent_count>, L</iter_newer>, L</iter_older>,
L</truncate_recent>, and Node methods L</newer>, L</older>, L</mark_newest>,
and L</recent_tracked>.

=head2 lookup_updates_recent

Whether L</lookup> and L</get> methods automatically mark a node as the most recent.
This defaults to false, so only 'put' methods (including insert) mark a node recent.
Even when true, 'exists' does not mark a node as recent, nor do iterators, min_node, max_node,
nth_node, newest_node or oldest_node, as it is assumed using those methods are more about
inspecting the state of the tree than representing access patterns of important keys.

=head2 key_type

The key-storage strategy used by the tree.  Read-only; pass as an option to
the constructor.  This is an implementation detail that may be removed in a future
version.

=head2 size

Returns the number of elements in the tree.

=head2 recent_count

Returns the number of nodes with insertion-order tracking enabled.  See L</track_recent>.

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

=head2 oldest_node

  $oldest= $tree->oldest_node;
  $tree->oldest_node($node);

The earliest node that was inserted with L</track_recent> enabled/applied.
C<undef> if no nodes have insertion-order tracking.

Alias: C<oldest>

=head2 newest_node

  $newest= $tree->newest_node;
  $tree->newest_node($node);

The most recent node that was inserted with L</track_recent> enabled/applied.
C<undef> if no nodes have insertion-order tracking.

Alias: C<newest>

=head1 METHODS

=head2 get

  my $val= $tree->get($key);
             ...->get($key, $mode);
  
  $tree->get($key) += 5;   # also, they're lvalues

Fetch a value from the tree, by its key.  Unlike L<Tree::RB/get>, this returns a single
value, regardless of list context.  But, you can set L<compat_list_get> to make C<get>
an alias for C<lookup>.

Mode can be used to indicate something other than an exact match:
L</GET_EQ>, L</GET_EQ_LAST>, L</GET_LE>, L</GET_LE_LAST>, L</GET_LT>, L</GET_GE>, L</GET_GT>.
(described below)  It can also be L</GET_OR_ADD> to automatically create a node with the key
if one didn't exist.

Aliases with built-in mode constants:

=over 20

=item get_or_add

Handy for things like C<< ( $tree->get_or_add($key) //= '') .= "test" >>

=back

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

=head2 get_key

Returns the key closest to the comparison criteria.  This is a shortcut for
C<< get_node(...)->key >> but avoids the C<undef> check and avoids inflating the tree node
to a perl object.

Aliases with built-in mode constants:

=over 20

=item get_key_le

=item get_key_lt

=item get_key_ge

=item get_key_gt

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

=head2 exists

  $count= $tree->exists($key);
  $count= $tree->exists(@keys);

Check whether a key exists (or multiple keys exist) in the tree, returning the
total count of nodes having these keys.

=head2 put

  my $old_val= $tree->put($key, $new_val);

Associate the key with a new value.  If the key previously existed, this returns
the old value, and updates the tree to reference the new value.  If the tree
allows duplicate keys, this will remove all but one node having this key and
then set its value.  Only the first old value will be returned.

=head2 put_multi

  $added_count= $tree->put_multi($k, $v, $k, $v, ...);
  $added_count= $tree->put_multi([ $k, $v, $k, $v, ... ]);

Put multiple keys and values into the tree.  If duplicate keys are supplied and
L</allow_duplicates> is false, earlier (k,v) will be overwritten by later conflicting
(k,v) in the list, the same way that happens when assigning this list to a perl hash.
If C<allow_duplicates> is true, all key/value pairs will get added to the tree.

The return value is the number of new keys added to the tree, not counting overwrites.

=head2 insert

  my $idx= $tree->insert($key, $value);

Insert a new node into the tree, and return the index at which it was inserted.
If L</allow_duplicates> is not enabled, and the node already existed, this returns -1
and does not change the tree.  If C<allow_duplicates> is enabled, this adds the new
node after all nodes of the same key, preserving the insertion order.

=head2 insert_multi

  $added_count= $tree->insert_multi($k, $v, $k, $v, ...);
  $added_count= $tree->insert_multi([ $k, $v, $k, $v, ... ]);

Perform multiple insertions, and return the number of items which got added.  Like
L</insert> when L</allow_duplicates> is false, this does not replace existing values
if the key already exists.

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

=head2 truncate_recent

  my @nodes= $tree->truncate_recent($max_count);

Reduce the number of "recent" nodes (those with insertion-order tracking enabled) to
C<$max_count>.  (See L</track_recent>)  The pruned nodes are returned as a list.

The intent here is that you may have some "permanent" nodes that stay in the tree, but more
transient ones that you add on demand, and then you might want to purge the oldest of those
when they exceed a threshold.

If there are fewer than C<$max_count> nodes with insertion-order tracking, this has no effect.

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

=head2 iter_newer

Return an iterator that iterates the insertion-order from oldest to newest.  This only iterates
nodes with insertion-order tracking enabled.  See L</track_recent>.

=head2 iter_older

Return an iterator that iterates the insertion-order from newest to oldest.  This only iterates
nodes with insertion-order tracking enabled.  See L</track_recent>.

=head1 NODE OBJECTS

See L<Tree::RB::XS::Node>

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

=item node

The current node.

=item key

The key of the current node.

=item value

The value of the current node.  Note that this returns an lvalue, which in an aliased
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
  my @nodes= $iter->next('*' || inf);

Return the current node (as a L<node object|/NODE OBJECTS>) and advance to the following node
in the sequence.  After the end of the sequence, calls to C<next> return C<undef>.
If you pass the optional C<$count>, it will return up to that many nodes, as a list.
It will also return an empty list at the end of the sequence instead of returning C<undef>.
You can use the string C<'*'> for the count to indicate all the rest of the nodes in the
sequence.  Likewise, any numeric value larger than the number of nodes in the tree
(like builtin::inf) will return them all.

=item next_key

Same as C<next>, but return the keys of the nodes.

=item next_value

Same as C<next>, but return the values of the nodes.  Like L</value>, these are also aliases,
and can be modified.

  $_++ for $iter->next_value('*');

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
the intent in Tree::RB?)

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

=item cmp_numsplit

  use Tree::RB::XS 'cmp_numsplit';
  $cmp= cmp_numsplit('192.168.10.1', '192.168.4.255');

You can export the comparison function I<itself>, for use elsewhere.  It's rather useful.
Maybe it should be its own module?

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

=item GET_OR_ADD

Look up the key, and if it doesn't exist, insert a node for it into the tree.
When getting the value, this provides an lvalue which you can assign to.

  ++($tree->get("a", GET_OR_ADD) //= 0);
  ($tree->get("b", GET_OR_ADD) //= '') .= "example";

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

The fastest pure-perl tree module on CPAN.  Implemented as blessed arrayrefs.

Tree::RB::XS was originally just an XS version of this module's API, with a few important
differences:

=over

=item *

The C<get> method in Tree::RB::XS is not affected by array context, unless you
request L</compat_list_get>.

=item *

C<resort> is not implemented in Tree::RB::XS

=item *

Tree structure is not mutable via the attributes of Node, nor can nodes be created
independent from a tree.

=item *

Many methods have official names changed, but aliases are provided for compatibility.

=back

=item L<AVLTree>

Another XS-based tree module.  About 6%-70% slower than Tree::RB::XS depending on whether you
use coderef comparisons or optimized comparisons.

=item L<Tree::AVL>

An AVL tree implementation in pure perl.  The API is perhaps more convenient, with the ability
to add your object to the tree with a callback that derives the key from that object.
However, it runs significantly slower than Tree::RB.

=item L<Tie::Hash::Indexed>

Not a tree, but the second-fastest module on CPAN if you want a hash that preserves insertion
order, such as for an LRU cache.  Technically a hash table should out-perform a binary tree on
massive collections (O(1) lookup time vs. O(log N) lookup time), but currently Tree::RB::XS
benchmarks quite a bit faster.

=item L<Hash::Ordered>

The fastest pure-perl module on CPAN for ordered hashes / LRU caches.

=back

=head1 VERSION

version 0.14

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package Tree::BPTree;

# $Id: BPTree.pm,v 1.4 2003/09/15 19:50:39 sterling Exp $

use 5.008;
use strict;
use warnings;

# all the math is for indexing
use integer;

use Carp;

our $VERSION = '1.08';

=head1 NAME

Tree::BPTree - Perl implementation of B+ trees

=head1 SYNOPSIS

  use Tree::BPTree;
  
  # These arguments are actually the defaults
  my $tree = new Tree::BPTree(
      -n        => 3,
      -unique   => 0,
      -keycmp   => sub { $_[0] cmp $_[1] },
      -valuecmp => sub { $_[0] <=> $_[1] },
  );

  # index the entries in this string:
  my $string = "THERE'S MORE THAN ONE WAY TO DO IT"; # TMTOWTDI
  my $i = 0;
  $tree->insert($_, $i++) foreach (split //, $string);

  # find the index of the first 'T'
  my $t = $tree->find('T');

  # find the indexes of every 'T'
  my @t = $tree->find('T');

  # We don't like the word 'WAY ', so let's remove it
  my $i = index $string, 'W';
  $tree->delete($_, $i++) foreach (split //, substr($string, $i, 4));

  # Reverse the sort order
  $tree->reverse;

  # Iterate through each key/value pair just like built-in each operator
  while (my ($key, $value) = $tree->each) {
      print "$key => $value\n";
  }

  # Reset the iterator when we quit from an "each-loop" early
  $tree->reset;

  # You might also be interested in using multiple each loops at once, which is
  # possible through the cursor syntax. You can even delete individual pairs
  # from the list during iteration.
  my $cursor = $tree->new_cursor;
  while (my ($key, $value) = $cursor->each) {
      my $nested = $tree->new_cursor;
      while (my ($nkey, $nvalue) = $nested->each) {
          if ($key->shouldnt_be_in_this_tree_with($nkey)) {
              $nested->delete;
          }
      }
  }

  # Iterate using an iterator subroutine
  $tree->iterate(sub { print "$_[0] => $_[1]\n" });

  # Iterate using an iterator subroutine that returns the list of return values
  # returned by the iterator
  print join(', ', $tree->map(sub { "$_[0] => $_[1]" })),"\n";

  # Grep-like operations
  my @pairs  = $tree->grep                 (sub { $_[0] =~ /\S/ });
  my @keys   = $tree->grep_keys            (sub { $_[0] =~ /\S/ });
  my @values = $tree->grep_values          (sub { $_[0] =~ /\S/ });

  # Get all keys, values
  my @all_keys   = $tree->keys;
  my @all_values = $tree->values;

  # Clear it out and start over
  $tree->clear;

=head1 DESCRIPTION

B+ trees are balanced trees which provide an ordered map from keys to values.
They are useful for indexing large bodies of data. They are similar to 2-3-4
Trees and Red-Black Trees. This implementation supports B+ trees using an
arbitrary I<n> value.

=head2 STRUCTURE

Each node in a B+ tree contains I<n> pointers and I<n - 1> keys. The pointers
in the node are placed between the ordered keys so that there is one pointer on
either end and one pointer in between each value. Searching for a key involves
checking to see which keys in the node the key falls between and then following
the corresponding pointers down the tree.

The pointers in the branches of thre tree always point to nodes deeper in the
tree. The leaves use all pointers but the last to point to buckets containing
values. The last pointer in each leaf forms a singly-linked list called the
linked leaf list. Iterating through this list gives us an ordered traversal of
all keys and/or values in the tree.

Finally, all non-root branch nodes must contain at least I<n/2> pointers. If it
becomes necessary to add values to a node which already contains I<n> pointers,
then the node will be split in half first (possibly requiring the split of
parents). If deletion of a node leaves a branch with fewer than I<n/2> pointers,
the node will either be coalesced (joined to) a neigboring node or it will take
on a pointer from a neighbor node. Coalescing can also result in the further
rebalancing of the tree in parents using more coalesce or redistribute
operations.

Here's a diagram of a valid B+ tree when n = 3 that stores my last name,
"HANENKAMP":

            ---<K>----
           /          \
          /            \
         <H>         --<N>--
        /   \       /       \
       /     \     /        | 
     <A,E>> <H>> <K,M>>   <N,P>>
     / \     |   /  \    /  \
    /   \    |   |  |    |   \
  [1,6] [3] [0] [5][7] [2,4] [8]

Anyway, you don't need to know any of that to use this implementation. The
abstraction layer set on top makes it look something like a typical hash.
Insertion and deletion both require a specific key and value since multiple
values can be mapped to each key--unless the "-unique" flag has been set.

By default, the tree assumes that it is being used to map strings to indexes. I
chose to set this default because this is the most common use I will put it to.
That is, I have lists of strings that I want to index, so the keys will be the
strings to index and the values will be indexes into the list.

If you need to store something different, all you need to do is store a
reference to the objects (keys or values) and set the "-keycmp" and "-valuecmp"
options to appropriate values during initialization.

=head2 PERFORMANCE

At some point, I want to post the best, average, and worst-case operation speed
for this implementation of B+ trees, but for now we'll just have to live without
those stats. For raw benchmarks, you should see the L<BUGS|/BUGS> section as the
actual performance of this module is pretty slow.

=head2 IMPLEMENTATION

As a quick note on implementation, if you want to know how specific operations
work, please browse the source. I have included extensive comments within the
definitions of the methods themselves explaining most of the important steps. I
did this for my own sanity because B+ trees can be quite complicated.

This code has been optimized a bit, but I haven't nearly made as many
optimizations as are likely possible. I'm open to any suggestions. If you have
some, send me email at the address given below.

=head2 METHOD REFERENCE

=over

=cut

package Tree::BPTree::Node;

use integer;

sub new {
	my ($class, @data) = @_;
	@data = ( undef ) unless @data;
	return bless \@data, ref $class || $class;
}

# sub key {
# 	my ($self, $k, $new) = @_;
# 	$$self[$k * 2 + 1] = $new if defined $new;
# 	return $$self[$k * 2 + 1];
# }
# 
# sub value {
# 	my ($self, $v, $new) = @_;
# 	$$self[$v * 2] = $new if defined $new;
# 	return $$self[$v * 2];
# }
# 
# sub last_key {
# 	my ($self, $new) = @_;
# 	$$self[-2] = $new if defined $new;
# 	return $$self[-2];
# }
# 
# sub last_value {
# 	my ($self, $new) = @_;
# 	$$self[-1] = $new if defined $new;
# 	return $$self[-1];
# }
# 
sub first_leaf {
	my ($self) = @_;
	my $current = $self;
	until ($current->isa('Tree::BPTree::Leaf')) {
		$current = $$current[0];
	}
	return $current;
}

sub last_leaf {
	my ($self) = @_;
	my $current = $self;
	until ($current->isa('Tree::BPTree::Leaf')) {
		$current = $$current[-1];
	}
	return $current;
}
# 
# sub nkeys {
# 	my ($self) = @_;
# 	return (scalar(@$self) - 1) / 2;
# }
# 
# sub nvalues {
# 	my ($self) = @_;
# 	return (scalar(@$self) + 1) / 2;
# }
 
# The find operation differs slightly between branch and leaf. See the comment
# near Tree::BPTree::Leaf::find for details.
sub find {
	my ($self, $cmp, $key) = @_;
	my $nkeys = (@$self - 1) / 2;
	for (my $k = 0; $k < $nkeys; $k++) {
		if (&$cmp($key, $self->[($k) * 2 + 1]) < 0) {
			return $k;
		}
	}
	return (@$self + 1) / 2 - 1;
}

sub insert {
	my ($self, $v, $key, $value) = @_;
	splice @$self, $v * 2, 0, $value, $key;
}

sub split {
	my ($self, $n, $cmp, $key) = @_;

	# find the node we're going to insert to; split that node; if it splits
	# either incorporate the split in ourselves or split ourselves if we are
	# full
	my $v = $self->find($cmp, $key);
	my $result = $self->[($v) * 2]->split($n, $cmp, $key);
	if ((@$self + 1) / 2 == $n && defined $result) {
		# We're full and they split, we must split too. The way the split must
		# be handled will depend upon whether this is a Left, Center, or Right
		# split. That is, is the sub-split node pointer on the left side, the
		# middle, or the right. But first, let's go ahead and split the node in
		# half.
		#
		# The way a node can be split depends on the oddness of n. If n is odd
		# (normal looking node split), then we split at index n-1 and give the
		# new node n elements. If n is even, we split at index n and give the
		# new node n-1 elements. The combinatorics of this solution are kind of
		# interesting. In any case, we create the new node complete while
		# leaving the current node with a missing end-pointer.
		my $new_node = Tree::BPTree::Node->new(
			splice @$self, 
			$n - ($n % 2),       # n - 1 for odd or n - 0 for even
			$n - (($n + 1) % 2), # n - 0 for odd or n - 1 for even
		);

		my $root_key;
		if ($v < $n / 2) {
			# This is a left split. We need to clip off the last key, insert the
			# child's new root key and set the pointers on either side to the
			# new root nodes. Finally, return a new root with clipped key
			# pointing to us and the new node.
			$root_key = pop @$self;
			my $i = $self->find($cmp, $result->[1]);
			$self->insert($i, $result->[1], $result->[0]);
			$self->[($i+1) * 2] = $result->[2];

		} elsif ($v > $n / 2) {
			# This is a right split. Same as left in reverse, basically. We do
			# need to first shear of the first pointer to the new node and
			# append it back onto as the last pointer of the first node first.
			push @$self, shift @$new_node;
			$root_key = shift @$new_node;
			my $i = $new_node->find($cmp, $result->[1]);
			$new_node->[($i) * 2] = $result->[2];
			$new_node->insert($i, $result->[1], $result->[0]);
		} else {
			# This is a center split. Here, we append to ourself a new pointer
			# pointing to the new left node. We set the new node's first pointer
			# to the new right node. And we set the new root key to the child's
			# new root key.
			push @$self, $result->[0];
			$new_node->[0] = $result->[2];
			$root_key = $result->[1];
		}

		return Tree::BPTree::Node->new($self, $root_key, $new_node);
	} elsif (defined $result) {
		# We have room to accomodate their split, add the new nodes here.
		# Regular insert will do this in the wrong order.
#		$self->insert($v, $$result[-1]->first_leaf->[1], $$result[-1]);

		# The new node will always be the last node, so we need to insert the
		# key/pointer in reverse order from normal such that the key happens at
		# $i and the value is at $i + 1
		my $i = $self->find($cmp, $key);
		splice @$self, $i * 2 + 1, 0, $$result[-1]->first_leaf->[1], $$result[-1];
		return undef;
	} else {
		# They didn't split, so we don't have to either
		return undef;
	}
}

sub delete {
	my ($self, $n, $cmp, $key) = @_;

	# Go to the bottom and drop the key from the leaf node
	my $v = $self->find($cmp, $key);
	my $result = $self->[($v) * 2]->delete($n, $cmp, $key);

	# On our way back up, make the tree consistent; i.e., no empty leaves and no
	# non-root nodes with less than n/2 values. If a key is deleted, but doesn't
	# cause a coalesce or redistribute, we may keep that key in a branch node as
	# a sort key, this shouldn't hurt us.
	if ($self->[($v) * 2]->isa('Tree::BPTree::Leaf')) {
		# Since this is a leaf, we only care if the leaf becomes empty. If it
		# does, we remove the pointer to it from the current node and pass
		# control upwards. 
		if ($result == 1) {
			# The leaf is too small, so we need to delete it from our list. This
			# may result in rebalancing further up the tree.
			#
			# NOTE: This operation will leave orphaned nodes in the linked leaf
			# list. It is too hard to remove the orphans here.  Instead, orphans
			# should be removed by the iterators.
			if ($v == 0) {
				# This node is the first index, so we delete it and the next key
				splice @$self, 0, 2;
			} else {
				# This node is not first, so we delete it and the preceding key
				splice @$self, $v * 2 - 1, 2;
			}
		} # else no rebalancing will take place here on up
	} else {
		# As a branch, the child node must not have fewer than n/2 children. If
		# it does, we need to try to coalesce it with a neighbor or redistribute
		# the children from a neighbor to the small node.
		if ($result <= $n / 2) {
			# The branch is too small, we'll try to coalesce first
			if ($v > 0 && ((@{$self->[($v - 1) * 2]} + 1) / 2) + ((@{$self->[($v    ) * 2]} + 1) / 2) <= $n) {
				# We can coalesce the small node with it's left neighbor
				$self->[($v-1) * 2]->coalesce($self->[($v) * 2]);
				
				# The removed node (the small node) is not first, so we delete
				# it and the preceding key
				splice @$self, $v * 2 - 1, 2;
			} elsif ($v < (((@$self + 1) / 2) - 1) && ((@{$self->[($v    ) * 2]} + 1) / 2) + ((@{$self->[($v + 1) * 2]} + 1) / 2) <= $n) {
				# We can coalesce the small node with it's right neighbor
				$self->[($v) * 2]->coalesce($self->[($v+1) * 2]);

				# The removed node (the right neighbor) is not first, so we
				# delete it and the preceding key
				splice @$self, ($v + 1) * 2 - 1, 2;
			} else {
				# We must redistribute, we pull the node from the left neighbor,
				# if there is a left neighbor; otherwise, we'll pull the node
				# from the right.
				if ($v > 0) {
					$self->[($v-1) * 2]->redistribute($self->[($v) * 2]);
				} else {
					$self->[($v) * 2]->redistribute($self->[($v+1) * 2]);
				}
				
				# Furthermore, we need to reset the key affected in this node to
				# make sure that we don't lose sort order in the branches. (That
				# is, we might have just moved a lower key right making this key
				# too high or a higher key left making this key too low.
				#
				# We always use the latter pointer which is normally $v+1 or $v
				# if it is already the last pointer.
				if ($v > 0) {
					$self->[($v - 1) * 2 + 1] = $self->[$v * 2]->first_leaf->[1];
				} else {
					$self->[($v) * 2 + 1] = $self->[($v + 1) * 2]->first_leaf->[1];
				}
			}
		}
	}

	# Return the number of values remaining
	return (@$self + 1) / 2;
}

sub coalesce {
	my ($self, $that) = @_;
	push @$self, $$that[0]->first_leaf->[1], @$that;
	return $self;
}

sub redistribute {
	my ($self, $that) = @_;

	# Who's stealing nodes from whom? When deciding on the new index key to
	# insert, we choose to use the first key of that, in either case, as it will
	# always be higher than the last key of self. (The first key in that is
	# always the key associated with the value being redistributed.)
	if ((@$that + 1) / 2 < (@$self + 1) / 2) {
		# Redistribute values from left to right
		my @middle = splice @$self, -2, 2;
		unshift @$that, $middle[-1], $$that[0]->first_leaf->[1];
	} else {
		# Redistribute values from right to left
		my @middle = splice @$that, 0, 2;
		push @$self, $middle[0]->first_leaf->[1], $middle[0];
	}
}

sub reverse {
	my ($self) = @_;

	# Reverses the children, reverses the internal list, and then connects the
	# linked-list pointer of the last_leaf of each subnode to the
	# first_leaf of the following subnode. Finally, we need to change the
	# index key.
	@$self = reverse @$self;
	my $nvalues = (@$self + 1) / 2;
	for (my $v = 0; $v < $nvalues; ++$v) {
		$self->[($v) * 2]->reverse;
	}

	my $nkeys = (@$self - 1) / 2;
	for (my $k = 0; $k < $nkeys; ++$k) {
		# Set the last pointer in the first node's last leaf to the first leaf
		$self->[($k) * 2    ]->last_leaf->[-1] = $self->[($k + 1) * 2]->first_leaf;

		# Set the current key to the second node's first leaf's key
		$self->[($k) * 2 + 1]                  = $self->[($k + 1) * 2]->first_leaf->[1];
	}
}

package Tree::BPTree::Leaf;

use integer;

our @ISA = qw(Tree::BPTree::Node);

# Ordering in leaves is slightly different because we want to store the buckets
# for the node in the same pointer as the node when keys are equal. In branches,
# we want to find the value by the pointer *after* the node if the keys are
# equal.
sub find {
	my ($self, $cmp, $key) = @_;
	my $nkeys = (@$self - 1) / 2;
	for (my $k = 0; $k < $nkeys; $k++) {
		if (&$cmp($key, $self->[($k) * 2 + 1]) <= 0) {
			return $k;
		}
	}
	return (@$self + 1) / 2 - 1;
}

sub split {
	my ($self, $n) = @_;

	if ((@$self + 1) / 2 == $n) {
		# We're big enough, we must split in anticipation of an insert. See the
		# comments in Tree::BPTree::split if you want to know more about why
		# choosing where and how many nodes to splice looks so weird.
		my $new_node = Tree::BPTree::Leaf->new(
			splice @$self, 
			$n - ($n % 2),       # n - 1 for odd or n - 0 for even
			$n - (($n + 1) % 2), # n - 0 for odd or n - 1 for even
		);
		push @$self, $new_node;

		# return new root, which is used or tossed depending on the needs of the
		# caller
		return Tree::BPTree::Node->new($self, $$new_node[1], $new_node);
	} else {
		# We're not too big, so we can take at least one more value
		return undef;
	}
}

sub delete {
	my ($self, $n, $cmp, $key) = @_;

	# Find the node and delete it (we assume this node exists if we've been
	# called!)
	my $i = $self->find($cmp, $key);
	splice @$self, $i * 2, 2;

	# Return the number of values remaining
	return (@$self + 1) / 2;
}

sub reverse {
	my ($self) = @_;

	# For leaves, we must before the reverse, then copy the value pointers
	# backwards one position. We even reverse the buckets to create a completely
	# symmetric reversal.
	@$self = reverse @$self;
	my $nvalues = (@$self + 1) / 2 - 1;
	for (my $v = 0; $v < $nvalues; ++$v) {
		$self->[($v) * 2] = [ reverse @{ $self->[($v+1)*2] } ];
	}
	$$self[-1] = undef;
}

package Tree::BPTree;

=item $tree = Tree::BPTree->new(%args)

The constructor builds a new tree using the given arguments. All arguments are
optional and have defaults that should suit many applications. The arguments
include:

=over

=item -n

This sets the maximum number of pointers permitted in each node. Setting this
number very high will cause search operations to slow down as it will spend a
lot of time searching arrays incrementally--something like a binary search could
be used to speed these times a bit, but no such method is used at this time.
Setting this number very low will cause insert and delete operations to slow
down as they are required to split and coalesce more often. The default is the
minimum value of 3.

=item -unique

This determines whether keys are unique or not. If this is set, then an
exception will be raised whenever an insert is attempted for a key that already
exists in the tree.

=item -keycmp

This is a comparator function that takes two arguments and returns -1, 0, or 1
to indicate the result of the comparison. If the first argument is less than the
second, then -1 is returned. If the first argument is greater than the second,
then 1 is returned. If the arguments are equal, then 0 is returned. This
comparator should be appropriate for comparing keys. By default, the built-in
string comparator C<cmp> is used. See L<perlop> for details on C<cmp>.

=item -valuecmp

This is a comparator function that takes two arguments and returns -1, 0, or 1
to indicate the result of the comparison--just like the "-keycmp" argument. This
comparator should be appropriate for comparing values. By default, the built-in
numeric comparator C<E<lt>=E<gt>> is used. See L<perlop> for details on
C<E<lt>=E<gt>>.

=back

The tree created by this constructor is always initially empty.

=cut

sub new {
	my ($class, %args) = @_;

	$args{-n}        = 3 unless defined $args{-n};
	$args{-keycmp}   = sub { $_[0] cmp $_[1] } unless defined $args{-keycmp};
	$args{-valuecmp} = sub { $_[0] <=> $_[1] } unless defined $args{-valuecmp};
	$args{-unique}   = 0 unless defined $args{-unique};
	$args{-root}     = Tree::BPTree::Leaf->new;

	# This cursor is special as it doesn't have a link back to self. It will not
	# be released to the user to call methods on directly anyway. Having the
	# link back to self would cause a memory leak.
	$args{-cursor}   = bless {}, 'Tree::BPTree::Cursor';

	croak "Illegal value for n $args{-n}. It must be greater than or equal to 3."
			if $args{-n} < 3;
	
	return bless \%args, ref $class || $class;
}

sub _find_leaf {
	my ($self, $key) = @_;

	my $cmp = $$self{-keycmp};
	my $current = $$self{-root};
	while (defined $current and not $current->isa('Tree::BPTree::Leaf')) {
		my $v = $current->find($cmp, $key);
		$current = $current->[$v * 2];
	}

	return $current;
}

=item $value = $tree->find($key)

=item @values = $tree->find($key)

This method attempts to find the value or values in the bucket matching C<$key>.
If no such C<$key> has been stored in the tree, then C<undef> is returned. If
the C<$key> is found, then either the first value stored in the bucket is
returned (in scalar context) or all values stored are returned (in list
context). Using scalar context is useful when the tree stores unique keys where
there will never be more than one value per key.

=cut

sub find {
	my ($self, $key) = @_;
	
	my $cmp = $$self{-keycmp};
	my $leaf = $self->_find_leaf($key);
	my $v = $leaf->find($cmp, $key);
	if (&$cmp($leaf->[($v) * 2 + 1], $key) == 0) {
		return wantarray ? @{ $leaf->[($v) * 2] } : ${ $leaf->[($v) * 2] }[0];
	} else {
		return undef;
	}
}

=item $tree->insert($key, $value)

This method inserts the key/value pair given into the tree. If the tree requires
unique keys, an exception will be thrown if C<$key> is already stored.

=cut

sub insert {
	my ($self, $key, $value) = @_;
	my $n = $$self{-n};
	my $cmp = $$self{-keycmp};

	# In the case of insert, we have three steps:
	#   1. See if the key already exists. If so, add the value to the bucket
	#      there (or die if keys are unique). Otherwise, go to step 2.
	#   2. Tell the tree to split if it is full along the path to where the new
	#      key will be placed.
	#   3. Find the leaf and insert the key/value pair there.

	# First, see if the value is already there
	my $leaf = $self->_find_leaf($key);
	my $k = $leaf->find($cmp, $key);
	if (defined $leaf->[($k) * 2 + 1] && &$cmp($leaf->[($k) * 2 + 1], $key) == 0) {
		croak "Unique key violation." if $$self{-unique};
		push @{ $leaf->[($k) * 2] }, $value;
		return;
	}
	
	# Then, tell the tree to split straight down if it will need to
	my $new_root = $$self{-root}->split($n, $cmp, $key);
	$$self{-root} = $new_root if defined $new_root;
	
	# Next, insert the new value (we need a new leaf in case a split occurred)
	$leaf = $self->_find_leaf($key);
	$leaf->insert($leaf->find($cmp, $key), $key, [ $value ]);
}

=item $tree->delete($key, $value)

This method removes the key/value pair given from the tree. If the pair cannot
be found, then the tree is not changed. If C<$value> is stored multiple times at
C<$key>, then all values matching C<$value> will be removed.
=cut

sub delete {
	my ($self, $key, $value) = @_;
	my $cmp = $$self{-keycmp};
	my $valcmp = $$self{-valuecmp};

	# In the case of delete, we have two steps:
	#   1. Find the leaf containing the key.
	#        a. If no matching key is found in the leaf where it should be, quit.
	#        b. If the bucket for the key found contains multiple values, remove
	#           one and quit.
	#        c. Otherwise, continue to step 2.
	#   2. Starting at the top, tell the tree to delete the node.
	#        a. The tree will then prune off any leaves that become empty.
	#        b. The tree will prune of branches that aren't needed. This may
	#           result in branches with less than n/2 nodes, so we will need to
	#           rebalance the tree.
	#        c. The tree will perform rebalancing on it's way back up from the
	#           leaf. It will attempt to coalesce where needed and possible and
	#           redistribute if needed and coalesce won't work.
	
	# First, find the leaf containing the key
	my $leaf = $self->_find_leaf($key);
	my $i = $leaf->find($cmp, $key);
	if (defined $leaf->[($i) * 2 + 1] && &$cmp($leaf->[($i) * 2 + 1], $key) == 0) {
		if (scalar(@{ $leaf->[($i) * 2] }) > 1) {
			my $bucket = $leaf->[($i) * 2];
			@$bucket = grep { &$valcmp($value, $_) != 0 } @$bucket;

			# If the bucket has more elements, we quit here. Otherwise, we need
			# to remove the node.
			return if @$bucket > 0;
		} elsif (!grep { &$valcmp($value, $_) == 0 } @{ $leaf->[($i) * 2] }) {
			# no match for value, let's quit
			return;
		}
	} else {
		# no match for key, let's quit
		return;
	}

	# Then, since we're still here, we know there is a key/value match that
	# we intend to remove. Since this removal will empty a bucket, we need to
	# bring out the big guns. Tell the tree to take care of it and it will take
	# care of coalescing and redistributing nodes.
	my $values = $$self{-root}->delete($$self{-n}, $cmp, $key);

	# if the tree contains only a single value and is a branch, then the tree is
	# one level shallower than before the delete
	$$self{-root} = $$self{-root}->[0]
			if not $$self{-root}->isa('Tree::BPTree::Leaf') and $values == 1;
}

=item $tree->reverse

Reverse the sort order. This is done by reversing every key in the tree,
adjusting the linked leaf list, and replacing the "-keycmp" method with a new
one that simply negates the old one. If this method is called again, the same
node reversal will happen, but the original "-keycmp" will be reinstated rather
than doing a double negation.

=cut

sub reverse {
	my ($self) = @_;
	$$self{-root}->reverse;
	if (defined $$self{-reverse_keycmp}) {
		$$self{-keycmp} = delete $$self{-reverse_keycmp};
	} else {
		$$self{-reverse_keycmp} = $$self{-keycmp};
		my $cmp = $$self{-keycmp};
		$$self{-keycmp} = sub { -( &$cmp(@_) ) };
	}
}

=item $cursor = $tree->new_cursor

This method allows you to have multiple, simultaneous iterators through the
same index. If you pass the C<$cursor> value returned from C<new_cursor> to
C<each>, it will be used instead of the default internal cursor. That is,

  my $c1 = $tree->new_cursor;
  my $c2 = $tree->new_cursor;
  while (my ($key, $values) = $tree->each($c1)) {
      # let's go through $c1 twice as fast
      my ($nextkey, $nextvalue) = $tree->each($c1);

      # next is an alias for each
      my ($otherkey, $othervalue) = $tree->next($c2);
  }

  # and we can reset $c2 after we're done too
  $tree->reset($c2);

Cursors also have their own methods, so this same snippet could have been
written like this instead:

  my $c1 = $tree->new_cursor;
  my $c2 = $tree->new_cursor;
  while (my ($key, $value) = $c1->each) {
      # let's go through $c1 twice as fast
      my ($nextkey, $nextvalue) = $c1->each;

      # next is an alias for each
      my ($otherkey, $othervalue) = $c2->each;
  }

  # and we can reset $c2 after we're done too
  $c2->reset;

There are additional features provided with cursors that are not provided when
using the internal cursor. You may delete the last key/values pair returned by a
call to C<each>/C<next> by calling C<delete> on the cursor. Or, you may specify
a specific value in the bucket to be deleted. For example:

  my $cursor = $tree->new_cursor;
  while (my ($key, $value) = $cursor->next) {
      # In this example, the keys are objects with a is_bad method. If "bad" is
      # set, we want to remove the corresponding values.
      if ($key->is_bad) {
          $cursor->delete;
      }
  }

This form of delete is completely safe and will not cause the iterator to slip
off track as a similar operation might mess up array iteration if one isn't
careful.

Another feature of cursors, is that you may retrieve the previously returned
value by calling the C<current> method. This will return the same result as the
last call to C<next> or C<each>.  That is, unless C<reset> has been called or
C<delete> removed the previously returned key, then this will return an empty
list.

For example:

  # This assumes you use the typical string keys with numeric values
  $cursor = $tree->new_cursor;
  while (my ($key, $value) = $cursor->next) {
      my ($currkey, $currval) = $cursor->current;
      die unless $key eq $currkey and $value == $currval
  }

This example shouldn't die.

=cut

package Tree::BPTree::Cursor;

# These keep the real work in Tree::BPTree
sub each {
	my ($self) = @_;
	$$self{-tree}->each($self);
}

sub next {
	my ($self) = @_;
	$$self{-tree}->each($self);
}

sub current {
	my ($self) = @_;
	return () unless defined $$self{-last};
	return (
		$$self{-last}{-node}->[($$self{-last}{-index}) + 1],
		$$self{-last}{-node}->[($$self{-last}{-index})][($$self{-last}{-value})],
	);
	
}

sub reset {
	my ($self) = @_;
	$$self{-tree}->reset($self);
}

sub delete {
	my ($self) = @_;

	Carp::croak "No node to delete. This has occurred because a delete was attempted before iteration started or delete was attempted twice on the same node."
		unless defined $$self{-last};

	# We must be careful as removing the node might throw off $$self{-index} if
	# $$self{-node} == $$self{-last}{-node}. In the case that we remove the node
	# altogether and $$self{-node} == $$self{-last}{-node}, we must decrement
	# $$self{-index} by 2 to keep it from skipping a node or falling off the end
	# of the node.
	my $cmp = $$self{-tree}{-keycmp};
	my $valcmp = $$self{-tree}{-valuecmp};

	my $leaf = $$self{-last}{-node};
	my $i = $$self{-last}{-index};
	my $value = $$self{-last}{-value};
	if (@{ $leaf->[$i] } > 1) {
		# The bucket contains more than one value. Drop the current index, keep
		# us from calling delete again and quit.
		my $bucket = $leaf->[$i];
		splice @$bucket, $value, 1;

		# If this node and the last node are equivalent, we need to decrement
		# the current value to keep us from skipping nodes are falling of the
		# end of the bucket
		--$$self{-value} if defined $$self{-node} and $$self{-last}{-node} == $$self{-node};

		delete $$self{-last};
		return;
	} # Otherwise, this value is the last in the node and we drop it entirely

	# We're still here, so the $value is the only remaining value
	my $values = $$self{-tree}{-root}->delete($$self{-tree}{-n}, $cmp, $leaf->[$i + 1]);

	# if the tree contains only a single value and is a branch, then the tree is
	# one level shallower than before the delete
	$$self{-tree}{-root} = $$self{-tree}{-root}->[0]
			if not $$self{-tree}{-root}->isa('Tree::BPTree::Leaf') and $values == 1;

	# If this node and the last node are equivalent, we need to decrement the
	# current index to keep the cursor going in the correct place.
	$$self{-index} -= 2 if defined $$self{-node} and $$self{-last}{-node} == $$self{-node};

	# We can't delete again since we've just annihilated the key
	delete $$self{-last};
}

package Tree::BPTree;

sub new_cursor {
	my ($self) = @_;
	return bless { -tree => $self }, 'Tree::BPTree::Cursor';
}

=item ($key, $value) = $tree->each [ ($cursor) ]

This method provides a similar facility as that of the C<each> operator. Each
call will iterate through each key/value pair in sort order. After the last
key/value pair has been returned, C<undef> will be returned once before starting
again. This is useful for using within C<while> loops:

  while (my ($key, $value) = $tree->each) {
      # do stuff
  }

=cut

sub each {
	my ($self, $cursor) = @_;
	$cursor = $$self{-cursor} unless defined $cursor;

	# This method operates on a cursor in three states:
	#   1. Fresh. $$cursor{-index} is undefined to show that we are in a fresh
	#      state and should return the very first index.
	#   2. Iterating. $$cursor{-index} and $$cursor{-node} are defined to show
	#      that we are somewhere in the middle of the list.
	#   3. Dead. $$cursor{-node} is undefined to show that we have reached the
	#      last node. At this point () should be returned and then
	#      $$cursor{-index} deleted to return us to Fresh state.
	#
	# It is possible to move directly from Fresh to Dead in one call by checking
	# the size of $$cursor{-node}. If $$cursor{-node}->nvalues == 1, then the
	# very first node is empty, so we immediately return that we are Dead and
	# return to a Fresh state.

	# If the cursor is empty, then they haven't ran each yet (or the last run
	# has concluded). Set a new iteration run up.
	unless (defined $$cursor{-index}) {
		$$cursor{-node}  = $$self{-root}->first_leaf;
		$$cursor{-index} = 0;
		$$cursor{-value} = 0;
	}

	if (defined $$cursor{-node} and @{$$cursor{-node}} > 1) {
		# The last run didn't detect the end of the list, so give them the next
		# value
		my @next = (
			$$cursor{-node}->[($$cursor{-index}) + 1],
			$$cursor{-node}->[($$cursor{-index})][($$cursor{-value})],
		);

		# Remember this position, in case we want to delete it
		$$cursor{-last}{-node}  = $$cursor{-node};
		$$cursor{-last}{-index} = $$cursor{-index};
		$$cursor{-last}{-value} = $$cursor{-value};

		# Increment the value point first
		if ($$cursor{-value} == $#{$$cursor{-node}[$$cursor{-index}]}) {
			# In this case, we're at the end, so we need to increment in the
			# index and return this to the first value of the next bucket
			$$cursor{-value} = 0;

			if ($$cursor{-index} + 2 == $#{$$cursor{-node}}) {
				# We've reached the end of a node, move to the next
				my $next_node = $$cursor{-node}->[$$cursor{-index} + 2];

				# Check for orphaned nodes and remove them
				while (defined $next_node and @$next_node == 1) {
					$next_node = $next_node->[0];
				}
				$$cursor{-node}->[$$cursor{-index} + 2] = $next_node;

				# Move to the next node
				$$cursor{-node}  = $next_node;
				$$cursor{-index} = 0;
			} else {
				# We've still got more key/value pairs to read in this node
				$$cursor{-index} += 2;
			}

			return @next;
		} else {
			# We've still got more values, so we need to get ready for the next
			++$$cursor{-value};
			return @next;
		}
	} else {
		# The last run reached the end of the list, so delete the -index element
		# so we can start anew and return undef once, just like the each
		# operator.
		delete $$cursor{-index};

		# Also clear the last pointers so we can't call delete on the cursor
		# until we've called each at least once.
		delete $$cursor{-last};

		return ();
	}
}

=item $tree->reset [ ($cursor) ]

Reset the given cursor to a fresh state--that is, ready to return the first
value on the next call to C<each>. If no C<$cursor> is given, then the default
internal cursor is reset.

=cut

sub reset {
	my ($self, $cursor) = @_;
	$cursor = $$self{-cursor} unless defined $cursor;
	delete $$cursor{-index};
}

=item $tree->iterate(\&iter)

For each key/value pair in the database, the function C<&iter> will be called
with the key as the first argument and value as the second. Iteration will occur
in sort order.

=cut

sub iterate {
	my ($self, $iter) = @_;

	while (my ($k, $v) = $self->each) {
		&$iter($k, $v);
	}
}

=item @results = $tree->map(\&mapper)

Nearly identical to C<iterate>, this method captures the return values of each
call and then returns all the results as a list. The C<&mapper> function takes
the same arguments as in C<iterate>.

=cut

sub map {
	my ($self, $mapper) = @_;

	my @result;
	while (my ($k, $v) = $self->each) {
		push @result, &$mapper($k, $v);
	}

	return @result;
}

=item @pairs = $tree->grep(\&pred)

=item @keys = $tree->grep_keys(\&pred)

=item @values = $tree->grep_values(\&pred)

Iterates through all key/value pairs in sort order. For each key/value pair, the
function C<&pred> will be called by passing the key as the first argument and
the value as the second. If C<&pred> returns a true value, then the matched
value will be added to the returned list.

C<grep> returns a list of pairs such that each element is a two-element array
reference where the first element is they key and the second is the value. 

C<grep_keys> returns a list of keys.

C<grep_values> returns a list of values.

=cut

sub grep {
	my ($self, $pred) = @_;

	my @result;
	while (my ($k, $v) = $self->each) {
		push @result, [ $k, $v ] if &$pred($k, $v);
	}

	return @result;
}

sub grep_keys {
	my ($self, $pred) = @_;

	my @result;
	while (my ($k, $v) = $self->each) {
		push @result, $k if &$pred($k, $v);
	}

	return @result;
}

sub grep_values {
	my ($self, $pred) = @_;

	my @result;
	while (my ($k, $v) = $self->each) {
		push @result, $v if &$pred($k, $v);
	}

	return @result;
}

=item @pairs = $tree->pairs

=item @keys = $tree->keys

=item @values = $tree->values

Returns all elements of the given type.

C<pairs> returns all key/value pairs stored in the tree. Each pair is returned
as an array reference contain two elements. The first element is the key. The
second element is a bucket, which is an array-reference of stored values.

C<keys> returns all keys stored in the tree.

C<values> returns all values stored in the tree.

=cut

sub pairs {
	my ($self) = @_;

	my @pairs;
	while (my ($k, $v) = $self->each) {
		push @pairs, [ $k, $v ];
	}

	return @pairs;
}

sub keys {
	my ($self) = @_;

	my @keys;
	while (my ($k, $v) = $self->each) {
		push @keys, $k;
	}

	return @keys;
}

sub values {
	my ($self) = @_;

	my @values;
	while (my ($k, $v) = $self->each) {
		push @values, $v;
	}

	return @values;
}

=item $tree->clear

This method empties the tree of all values. This basically creates a new tree
and allows the old tree to be garbage collected at the interpreter's leisure.

=cut

sub clear {
	my ($self) = @_;
	$$self{-root} = Tree::BPTree::Leaf->new;
}

=back

=head1 CREDITS

The basis for B+ trees implemented here can be found in I<Database System
Concepts>, 4th ed. by Silbershatz et al. published by McGraw-Hill. I have
somewhat modified the structure specified there to make the code easier to read
and to adapt the code to Perl.

In addition, while preparing to write this module I also consulted an old book
of mine, I<C++ Algorithms> by Robert Sedgewick (Addison Wesley), for more
general information on trees. I also used some ideas on how and when to perform
split, coalesce, and redistribute as the Silbershatz pseudo-code is a little
obfuscated--or at least, the different operations are presented monolithically
so that it's difficult to digest. The sections in Sedgewick on 2-3-4 and
Red-Black trees were especially helpful.

=head1 BUGS

This module is pretty slow. Better performance is possible, especially for small
bodies of data, if you use a hash to do most of these operations. See
F<benchmark.pl> for a sample of the performance issues. There you can also find
code for performing essentially the same thing using different data structures.

On my machine, a small benchmark showed the following:

  Insert into B+ Trees (this implementation) is:
    61   times slower than hash insert and
     3.9 times slower than ordered list insert.

  Ordered iteration of B+ Trees is:
     1.6 times slower than ordering a hash and then iterating the pairs and
    14   times slower than iterating through an ordered list.

  Finding a key in B+ Trees is:
    34   times slower than hash fetch but
     1.2 times faster than searching an ordered list (with grep, which probably
         isn't the fastest solution, a manual binary search should be better).

I'm still putting together more benchmarks and looking into places where
improvement is possible. Iteration of this structure should scale better than
taking a hash and ordering the keys to iterate through.

I have made some recent headway by removing some simple functions and replacing
them with raw computation. If I did this the way I'd really like to, I need to
find or build a L<Filter::Simple> module to perform something similar to a C
C<#define> or C++ C<inline> function. However, instead I just did a search and
replace with Vim.

I should probably port this to XS to make it really compete with built-in
hashes.

=head1 AUTHOR

Andrew Sterling Hanenkamp, E<lt>hanenkamp@users.sourceforge.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Andrew Sterling Hanenkamp

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1

package Tree::SizeBalanced;

# vim: filetype=perl

use 5.008009;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Tree::SizeBalanced ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.

our $VERSION = '2.006002';

=head1 NAME

Tree::SizeBalanced - Size balanced binary search tree (XS implementation)

Handy for in-memory realtime ranking systems.

=head1 SYNOPSIS

  use Tree::SizeBalanced; # use $tree = Tree::SizeBalanced::int_any->new
  use Tree::SizeBalanced qw(:long); # use $tree = sbtree_int_any;
  use Tree::SizeBalanced qw(:short); # use $tree = sbtreeia;
  use Tree::SizeBalanced qw(:all); # export :short and :long

  my $tree_map_any_any = sbtree_any_any { length($b) <=> length($a) };
  my $tree_map_any_any = sbtreeaa { length($b) <=> length($a) }; # shorter form
  my $tree_map_any_any = Tree::SizeBalanced::any_any->new
    sub { length($b) <=> length($a) }; # full form
  # tree map with any scalars as keys

  my $tree_set_num = sbtree_num_void;
  my $tree_set_num = sbtreen; # shorter form
  my $tree_set_num = Tree::SizeBalanced::num_void->new; # full form
  # or set version.
  #  This one use numeric values (floating point numbers) as keys

  my $tree = sbtree_int_any;
  my $tree = sbtreeia; # shorter form
  my $tree = Tree::SizeBalanced::int_any->new; # full form
  # tree map (key value pairs)
  #  the keys are signed integers
  #  the values are any scalars

  $tree->insert(1, {a => 3});

  ...

  my $count = $tree->count_lt(25);
  # how many entries in the tree whose key is less than 25
  my $count = $tree->count_gt(25);
  # how many entries in the tree whose key is greater than 25

  ($key, $value) = $tree->skip_l(23);
  $key = $tree->skip_l(23);
  # Get the first (smallest) entry whose key is greater than 23

  ($key, $value) = $tree->skip_g(23);
  $key = $tree->skip_g(23);
  # Get the first (largest) entry whose key is less than 23

  ($key, $value) = $tree->find_min;
  $key = $tree->find_min;
  ($key, $value) = $tree->find_max;
  $key = $tree->find_max;

  ($k1, $v1, $k2, $v2) = $tree->find_min(2);
  ($k1, $v1, $k2, $v2, $k3, $v3) = $tree->find_min(3);
  ($k1, $v1, $k2, $v2, $k3, $v3, ...) = $tree->find_min(-1);

  ($k1, $v1, ...= $tree->find_lt_gt($lower_bound, $upper_bound);

  ...

  $tree->delete(1);

=head1 DESCRIPTION

Quoted from L<http://wcipeg.com/wiki/Size_Balanced_Tree>:

=encoding UTF-8

> A size balanced tree (SBT) is a self-balancing binary search tree (BBST) first published by Chinese student Qifeng Chen in 2007. The tree is rebalanced by examining the sizes of each node's subtrees. Its abbreviation resulted in many nicknames given by Chinese informatics competitors, including "sha bi" tree (Chinese: 傻屄树; pinyin: shǎ bī shù; literally meaning "dumb cunt tree") and "super BT", which is a homophone to the Chinese term for snot (Chinese: 鼻涕; pinyin: bítì) suggesting that it is messy to implement. Contrary to what its nicknames suggest, this data structure can be very useful, and is also known to be easy to implement. Since the only extra piece of information that needs to be stored is sizes of the nodes (instead of other "useless" fields such as randomized weights in treaps or colours in red–black tress), this makes it very convenient to implement the select-by-rank and get-rank operations (easily transforming it into an order statistic tree). It supports standard binary search tree operations such as insertion, deletion, and searching in O(log n) time. According to Chen's paper, "it works much faster than many other famous BSTs due to the tendency of a perfect BST in practice."

For performance consideration, this module provides trees with many stricter types.

If you choose any scalar as the key type, you must provide a comparing sub.
The comparing sub should exammed localized C<$a> and C<$b> (or C<$::a> and C<$::b> if there are introduced lexical <$a> and <$b> right outside the sub).
And if your comparing sub using an indirect way to judge the size of the keys,
don't do anything that will change the judge result. Or, the tree will be confused and give you incorrect results.

If you put more than one entries with equal-sized keys,
the insertion order is preserved by treating the first one as the smallest one among them.

PS. Qifeng Chen is 陈启峰 in simplified Chinese.

This module has been tested on perl version 5.8.9, 5.10.1, 5.12.5, 5.14.4, 5.16.3, 5.18.4, 5.20.3, 5.22.2

=head2 EXPORT

All exported subs are different style ways to create new trees.

=over 4

=item (nothing)

Without importing anything, you can use the full form to obtain a new tree:

  my $tree = Tree::SizeBalanced::str_any->new;

=item :long

With the long form:

  my $tree = sbtree_any_str { length($a) <=> length($b) || $a cmp $b };

=item :short

With the short form:

  my $tree = sbtreei;

=item :all = :short + :long

=back

=head2 Different trees with different types

=cut

our @EXPORT_OK = qw(sbtree);
our %EXPORT_TAGS = (
    'all' => ['sbtree'],
    'short' => ['sbtree'],
    'long' => [],
);


=head3 Tree::SizeBalanced::int_void

Tree set with key type signed integers (32bits or 64bits according to your perl version).

=over 4

=item $tree = Tree::SizeBalanced::int_void->new

=item $tree = sbtree_int_void

=item $tree = sbtreei

Creat a new empty tree.

=item $tree->insert($key)

=item $tree->insert_after($key)

Insert an entry into the tree.
If there are any entries with the same key size,
insert the new one after them.

=item $tree->insert_before($key)

Insert an entry into the tree.
If there are any entries with the same key size,
insert the new one before them.

=item $tree->delete($key)

=item $tree->delete_last($key)

Delete one entry whose key is equal to $key.
If there ary more than one entry with the same key size,
delete the last inserted one.

=item $tree->delete_first($key)

Delete one entry whose key is equal to $key.
If there ary more than one entry with the same key size,
delete the first inserted one.

=item $size = $tree->size

Get the number of entries in the tree

=item $key or ($key1, $key2, ...) = $tree->find($key, $limit=1)

=item $key or ($key1, $key2, ...) = $tree->find_first($key, $limit=1)

Get entries with key sizes equal to $key,
from the first inserted one to the last inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $key2, ...) = $tree->find_last($key, $limit=1)

Get entries with key sizes equal to $key,
from the last inserted one to the first inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $key2, ...) = $tree->find_lt($key, $limit=1)

Get entries, whose keys are smaller than $key, from the largest entry.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $key2, ...) = $tree->find_le($key, $limit=1)

Get entries, whose keys are smaller than or equal to $key, from the largest entry.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $key2, ...) = $tree->find_gt($key, $limit=1)

Get entries, whose keys are greater than $key, from the smallest one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $key2, ...) = $tree->find_ge($key, $limit=1)

Get entries, whose keys are greater than or equal to $key, from the smallest one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $key2, ...) = $tree->find_gt_lt($lower_key, $upper_key)

Get entries, whose keys are greater than $lower_key and smaller than $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $key2, ...) = $tree->find_gt_le($lower_key, $upper_key)

Get entries, whose keys are greater than $lower_key and smaller than or equal to $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $key2, ...) = $tree->find_ge_lt($lower_key, $upper_key)

Get entries, whose keys are greater than or equal to $lower_key and smaller than $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $key2, ...) = $tree->find_ge_le($lower_key, $upper_key)

Get entries, whose keys are greater than or equal to $lower_key and smaller than or equal to $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $key2, ...) = $tree->find_min($limit=1)

Get entries from the one with smallest key.
If there are more than one entries with smallest key,
begin from the first inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $key2, ...) = $tree->find_max($limit=1)

Get entries from the one with largest key.
If there are more than one entries with smallest key,
begin from the last inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $key2, ...) = &tree->skip_l($offset, $limit=1)

Get the first entry from one with the smallest key after skipping $offset entries.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $key2, ...) = &tree->skip_g($offset, $limit=1)

Get the first entry from one with the largest key after skipping $offset entries.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $count = $tree->count_lt($key)

Get the number of entries whose keys are smaller than $key.

=item $count = $tree->count_le($key)

Get the number of entries whose keys are smaller than or equal to $key.

=item $count = $tree->count_gt($key)

Get the number of entries whose keys are greater than $key.

=item $count = $tree->count_ge($key)

Get the number of entries whose keys are greater than or equal to $key.

=item $dump_str = $tree->dump

Get a string which represent the whole tree structure. For debug use.

=item ($order_consistent, $size_consistent, $balanced) = $tree->check

Check the tree property. For debug use.

=item $ever_height = $tree->ever_height

Get the maximum height the tree has ever been. For debug use

=back

=cut

use Tree::SizeBalanced::int_void;

sub sbtree_int_void() {
    unshift @_, 'Tree::SizeBalanced::int_void';
    goto \&Tree::SizeBalanced::int_void::new;
}

sub sbtreei() {
    unshift @_, 'Tree::SizeBalanced::int_void';
    goto \&Tree::SizeBalanced::int_void::new;
}

push @EXPORT_OK, qw(sbtree_int_void sbtreei);
push @{$EXPORT_TAGS{'all'}}, qw(sbtree_int_void sbtreei);
push @{$EXPORT_TAGS{'short'}}, qw(sbtreei);
push @{$EXPORT_TAGS{'long'}}, qw(sbtree_int_void);


=head3 Tree::SizeBalanced::int_int

Tree map with key type signed integers (32bits or 64bits according to your perl version) and value type signed integers (32bits or 64bits according to your perl version).

=over 4

=item $tree = Tree::SizeBalanced::int_int->new

=item $tree = sbtree_int_int

=item $tree = sbtreeii

Creat a new empty tree.

=item $tree->insert($key, $value)

=item $tree->insert_after($key, $value)

Insert an entry into the tree.
If there are any entries with the same key size,
insert the new one after them.

=item $tree->insert_before($key, $value)

Insert an entry into the tree.
If there are any entries with the same key size,
insert the new one before them.

=item $tree->delete($key)

=item $tree->delete_last($key)

Delete one entry whose key is equal to $key.
If there ary more than one entry with the same key size,
delete the last inserted one.

=item $tree->delete_first($key)

Delete one entry whose key is equal to $key.
If there ary more than one entry with the same key size,
delete the first inserted one.

=item $size = $tree->size

Get the number of entries in the tree

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find($key, $limit=1)

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_first($key, $limit=1)

Get entries with key sizes equal to $key,
from the first inserted one to the last inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_last($key, $limit=1)

Get entries with key sizes equal to $key,
from the last inserted one to the first inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_lt($key, $limit=1)

Get entries, whose keys are smaller than $key, from the largest entry.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_le($key, $limit=1)

Get entries, whose keys are smaller than or equal to $key, from the largest entry.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_gt($key, $limit=1)

Get entries, whose keys are greater than $key, from the smallest one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_ge($key, $limit=1)

Get entries, whose keys are greater than or equal to $key, from the smallest one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_gt_lt($lower_key, $upper_key)

Get entries, whose keys are greater than $lower_key and smaller than $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_gt_le($lower_key, $upper_key)

Get entries, whose keys are greater than $lower_key and smaller than or equal to $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_ge_lt($lower_key, $upper_key)

Get entries, whose keys are greater than or equal to $lower_key and smaller than $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_ge_le($lower_key, $upper_key)

Get entries, whose keys are greater than or equal to $lower_key and smaller than or equal to $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_min($limit=1)

Get entries from the one with smallest key.
If there are more than one entries with smallest key,
begin from the first inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_max($limit=1)

Get entries from the one with largest key.
If there are more than one entries with smallest key,
begin from the last inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = &tree->skip_l($offset, $limit=1)

Get the first entry from one with the smallest key after skipping $offset entries.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = &tree->skip_g($offset, $limit=1)

Get the first entry from one with the largest key after skipping $offset entries.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $count = $tree->count_lt($key)

Get the number of entries whose keys are smaller than $key.

=item $count = $tree->count_le($key)

Get the number of entries whose keys are smaller than or equal to $key.

=item $count = $tree->count_gt($key)

Get the number of entries whose keys are greater than $key.

=item $count = $tree->count_ge($key)

Get the number of entries whose keys are greater than or equal to $key.

=item $dump_str = $tree->dump

Get a string which represent the whole tree structure. For debug use.

=item ($order_consistent, $size_consistent, $balanced) = $tree->check

Check the tree property. For debug use.

=item $ever_height = $tree->ever_height

Get the maximum height the tree has ever been. For debug use

=back

=cut

use Tree::SizeBalanced::int_int;

sub sbtree_int_int() {
    unshift @_, 'Tree::SizeBalanced::int_int';
    goto \&Tree::SizeBalanced::int_int::new;
}

sub sbtreeii() {
    unshift @_, 'Tree::SizeBalanced::int_int';
    goto \&Tree::SizeBalanced::int_int::new;
}

push @EXPORT_OK, qw(sbtree_int_int sbtreeii);
push @{$EXPORT_TAGS{'all'}}, qw(sbtree_int_int sbtreeii);
push @{$EXPORT_TAGS{'short'}}, qw(sbtreeii);
push @{$EXPORT_TAGS{'long'}}, qw(sbtree_int_int);


=head3 Tree::SizeBalanced::int_num

Tree map with key type signed integers (32bits or 64bits according to your perl version) and value type numeric numbers (floating point numbers).

=over 4

=item $tree = Tree::SizeBalanced::int_num->new

=item $tree = sbtree_int_num

=item $tree = sbtreein

Creat a new empty tree.

=item $tree->insert($key, $value)

=item $tree->insert_after($key, $value)

Insert an entry into the tree.
If there are any entries with the same key size,
insert the new one after them.

=item $tree->insert_before($key, $value)

Insert an entry into the tree.
If there are any entries with the same key size,
insert the new one before them.

=item $tree->delete($key)

=item $tree->delete_last($key)

Delete one entry whose key is equal to $key.
If there ary more than one entry with the same key size,
delete the last inserted one.

=item $tree->delete_first($key)

Delete one entry whose key is equal to $key.
If there ary more than one entry with the same key size,
delete the first inserted one.

=item $size = $tree->size

Get the number of entries in the tree

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find($key, $limit=1)

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_first($key, $limit=1)

Get entries with key sizes equal to $key,
from the first inserted one to the last inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_last($key, $limit=1)

Get entries with key sizes equal to $key,
from the last inserted one to the first inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_lt($key, $limit=1)

Get entries, whose keys are smaller than $key, from the largest entry.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_le($key, $limit=1)

Get entries, whose keys are smaller than or equal to $key, from the largest entry.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_gt($key, $limit=1)

Get entries, whose keys are greater than $key, from the smallest one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_ge($key, $limit=1)

Get entries, whose keys are greater than or equal to $key, from the smallest one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_gt_lt($lower_key, $upper_key)

Get entries, whose keys are greater than $lower_key and smaller than $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_gt_le($lower_key, $upper_key)

Get entries, whose keys are greater than $lower_key and smaller than or equal to $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_ge_lt($lower_key, $upper_key)

Get entries, whose keys are greater than or equal to $lower_key and smaller than $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_ge_le($lower_key, $upper_key)

Get entries, whose keys are greater than or equal to $lower_key and smaller than or equal to $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_min($limit=1)

Get entries from the one with smallest key.
If there are more than one entries with smallest key,
begin from the first inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_max($limit=1)

Get entries from the one with largest key.
If there are more than one entries with smallest key,
begin from the last inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = &tree->skip_l($offset, $limit=1)

Get the first entry from one with the smallest key after skipping $offset entries.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = &tree->skip_g($offset, $limit=1)

Get the first entry from one with the largest key after skipping $offset entries.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $count = $tree->count_lt($key)

Get the number of entries whose keys are smaller than $key.

=item $count = $tree->count_le($key)

Get the number of entries whose keys are smaller than or equal to $key.

=item $count = $tree->count_gt($key)

Get the number of entries whose keys are greater than $key.

=item $count = $tree->count_ge($key)

Get the number of entries whose keys are greater than or equal to $key.

=item $dump_str = $tree->dump

Get a string which represent the whole tree structure. For debug use.

=item ($order_consistent, $size_consistent, $balanced) = $tree->check

Check the tree property. For debug use.

=item $ever_height = $tree->ever_height

Get the maximum height the tree has ever been. For debug use

=back

=cut

use Tree::SizeBalanced::int_num;

sub sbtree_int_num() {
    unshift @_, 'Tree::SizeBalanced::int_num';
    goto \&Tree::SizeBalanced::int_num::new;
}

sub sbtreein() {
    unshift @_, 'Tree::SizeBalanced::int_num';
    goto \&Tree::SizeBalanced::int_num::new;
}

push @EXPORT_OK, qw(sbtree_int_num sbtreein);
push @{$EXPORT_TAGS{'all'}}, qw(sbtree_int_num sbtreein);
push @{$EXPORT_TAGS{'short'}}, qw(sbtreein);
push @{$EXPORT_TAGS{'long'}}, qw(sbtree_int_num);


=head3 Tree::SizeBalanced::int_any

Tree map with key type signed integers (32bits or 64bits according to your perl version) and value type any scalars.

=over 4

=item $tree = Tree::SizeBalanced::int_any->new

=item $tree = sbtree_int_any

=item $tree = sbtreeia

Creat a new empty tree.

=item $tree->insert($key, $value)

=item $tree->insert_after($key, $value)

Insert an entry into the tree.
If there are any entries with the same key size,
insert the new one after them.

=item $tree->insert_before($key, $value)

Insert an entry into the tree.
If there are any entries with the same key size,
insert the new one before them.

=item $tree->delete($key)

=item $tree->delete_last($key)

Delete one entry whose key is equal to $key.
If there ary more than one entry with the same key size,
delete the last inserted one.

=item $tree->delete_first($key)

Delete one entry whose key is equal to $key.
If there ary more than one entry with the same key size,
delete the first inserted one.

=item $size = $tree->size

Get the number of entries in the tree

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find($key, $limit=1)

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_first($key, $limit=1)

Get entries with key sizes equal to $key,
from the first inserted one to the last inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_last($key, $limit=1)

Get entries with key sizes equal to $key,
from the last inserted one to the first inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_lt($key, $limit=1)

Get entries, whose keys are smaller than $key, from the largest entry.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_le($key, $limit=1)

Get entries, whose keys are smaller than or equal to $key, from the largest entry.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_gt($key, $limit=1)

Get entries, whose keys are greater than $key, from the smallest one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_ge($key, $limit=1)

Get entries, whose keys are greater than or equal to $key, from the smallest one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_gt_lt($lower_key, $upper_key)

Get entries, whose keys are greater than $lower_key and smaller than $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_gt_le($lower_key, $upper_key)

Get entries, whose keys are greater than $lower_key and smaller than or equal to $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_ge_lt($lower_key, $upper_key)

Get entries, whose keys are greater than or equal to $lower_key and smaller than $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_ge_le($lower_key, $upper_key)

Get entries, whose keys are greater than or equal to $lower_key and smaller than or equal to $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_min($limit=1)

Get entries from the one with smallest key.
If there are more than one entries with smallest key,
begin from the first inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_max($limit=1)

Get entries from the one with largest key.
If there are more than one entries with smallest key,
begin from the last inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = &tree->skip_l($offset, $limit=1)

Get the first entry from one with the smallest key after skipping $offset entries.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = &tree->skip_g($offset, $limit=1)

Get the first entry from one with the largest key after skipping $offset entries.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $count = $tree->count_lt($key)

Get the number of entries whose keys are smaller than $key.

=item $count = $tree->count_le($key)

Get the number of entries whose keys are smaller than or equal to $key.

=item $count = $tree->count_gt($key)

Get the number of entries whose keys are greater than $key.

=item $count = $tree->count_ge($key)

Get the number of entries whose keys are greater than or equal to $key.

=item $dump_str = $tree->dump

Get a string which represent the whole tree structure. For debug use.

=item ($order_consistent, $size_consistent, $balanced) = $tree->check

Check the tree property. For debug use.

=item $ever_height = $tree->ever_height

Get the maximum height the tree has ever been. For debug use

=back

=cut

use Tree::SizeBalanced::int_any;

sub sbtree_int_any() {
    unshift @_, 'Tree::SizeBalanced::int_any';
    goto \&Tree::SizeBalanced::int_any::new;
}

sub sbtreeia() {
    unshift @_, 'Tree::SizeBalanced::int_any';
    goto \&Tree::SizeBalanced::int_any::new;
}

push @EXPORT_OK, qw(sbtree_int_any sbtreeia);
push @{$EXPORT_TAGS{'all'}}, qw(sbtree_int_any sbtreeia);
push @{$EXPORT_TAGS{'short'}}, qw(sbtreeia);
push @{$EXPORT_TAGS{'long'}}, qw(sbtree_int_any);


=head3 Tree::SizeBalanced::num_void

Tree set with key type numeric numbers (floating point numbers).

=over 4

=item $tree = Tree::SizeBalanced::num_void->new

=item $tree = sbtree_num_void

=item $tree = sbtreen

Creat a new empty tree.

=item $tree->insert($key)

=item $tree->insert_after($key)

Insert an entry into the tree.
If there are any entries with the same key size,
insert the new one after them.

=item $tree->insert_before($key)

Insert an entry into the tree.
If there are any entries with the same key size,
insert the new one before them.

=item $tree->delete($key)

=item $tree->delete_last($key)

Delete one entry whose key is equal to $key.
If there ary more than one entry with the same key size,
delete the last inserted one.

=item $tree->delete_first($key)

Delete one entry whose key is equal to $key.
If there ary more than one entry with the same key size,
delete the first inserted one.

=item $size = $tree->size

Get the number of entries in the tree

=item $key or ($key1, $key2, ...) = $tree->find($key, $limit=1)

=item $key or ($key1, $key2, ...) = $tree->find_first($key, $limit=1)

Get entries with key sizes equal to $key,
from the first inserted one to the last inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $key2, ...) = $tree->find_last($key, $limit=1)

Get entries with key sizes equal to $key,
from the last inserted one to the first inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $key2, ...) = $tree->find_lt($key, $limit=1)

Get entries, whose keys are smaller than $key, from the largest entry.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $key2, ...) = $tree->find_le($key, $limit=1)

Get entries, whose keys are smaller than or equal to $key, from the largest entry.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $key2, ...) = $tree->find_gt($key, $limit=1)

Get entries, whose keys are greater than $key, from the smallest one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $key2, ...) = $tree->find_ge($key, $limit=1)

Get entries, whose keys are greater than or equal to $key, from the smallest one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $key2, ...) = $tree->find_gt_lt($lower_key, $upper_key)

Get entries, whose keys are greater than $lower_key and smaller than $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $key2, ...) = $tree->find_gt_le($lower_key, $upper_key)

Get entries, whose keys are greater than $lower_key and smaller than or equal to $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $key2, ...) = $tree->find_ge_lt($lower_key, $upper_key)

Get entries, whose keys are greater than or equal to $lower_key and smaller than $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $key2, ...) = $tree->find_ge_le($lower_key, $upper_key)

Get entries, whose keys are greater than or equal to $lower_key and smaller than or equal to $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $key2, ...) = $tree->find_min($limit=1)

Get entries from the one with smallest key.
If there are more than one entries with smallest key,
begin from the first inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $key2, ...) = $tree->find_max($limit=1)

Get entries from the one with largest key.
If there are more than one entries with smallest key,
begin from the last inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $key2, ...) = &tree->skip_l($offset, $limit=1)

Get the first entry from one with the smallest key after skipping $offset entries.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $key2, ...) = &tree->skip_g($offset, $limit=1)

Get the first entry from one with the largest key after skipping $offset entries.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $count = $tree->count_lt($key)

Get the number of entries whose keys are smaller than $key.

=item $count = $tree->count_le($key)

Get the number of entries whose keys are smaller than or equal to $key.

=item $count = $tree->count_gt($key)

Get the number of entries whose keys are greater than $key.

=item $count = $tree->count_ge($key)

Get the number of entries whose keys are greater than or equal to $key.

=item $dump_str = $tree->dump

Get a string which represent the whole tree structure. For debug use.

=item ($order_consistent, $size_consistent, $balanced) = $tree->check

Check the tree property. For debug use.

=item $ever_height = $tree->ever_height

Get the maximum height the tree has ever been. For debug use

=back

=cut

use Tree::SizeBalanced::num_void;

sub sbtree_num_void() {
    unshift @_, 'Tree::SizeBalanced::num_void';
    goto \&Tree::SizeBalanced::num_void::new;
}

sub sbtreen() {
    unshift @_, 'Tree::SizeBalanced::num_void';
    goto \&Tree::SizeBalanced::num_void::new;
}

push @EXPORT_OK, qw(sbtree_num_void sbtreen);
push @{$EXPORT_TAGS{'all'}}, qw(sbtree_num_void sbtreen);
push @{$EXPORT_TAGS{'short'}}, qw(sbtreen);
push @{$EXPORT_TAGS{'long'}}, qw(sbtree_num_void);


=head3 Tree::SizeBalanced::num_int

Tree map with key type numeric numbers (floating point numbers) and value type signed integers (32bits or 64bits according to your perl version).

=over 4

=item $tree = Tree::SizeBalanced::num_int->new

=item $tree = sbtree_num_int

=item $tree = sbtreeni

Creat a new empty tree.

=item $tree->insert($key, $value)

=item $tree->insert_after($key, $value)

Insert an entry into the tree.
If there are any entries with the same key size,
insert the new one after them.

=item $tree->insert_before($key, $value)

Insert an entry into the tree.
If there are any entries with the same key size,
insert the new one before them.

=item $tree->delete($key)

=item $tree->delete_last($key)

Delete one entry whose key is equal to $key.
If there ary more than one entry with the same key size,
delete the last inserted one.

=item $tree->delete_first($key)

Delete one entry whose key is equal to $key.
If there ary more than one entry with the same key size,
delete the first inserted one.

=item $size = $tree->size

Get the number of entries in the tree

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find($key, $limit=1)

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_first($key, $limit=1)

Get entries with key sizes equal to $key,
from the first inserted one to the last inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_last($key, $limit=1)

Get entries with key sizes equal to $key,
from the last inserted one to the first inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_lt($key, $limit=1)

Get entries, whose keys are smaller than $key, from the largest entry.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_le($key, $limit=1)

Get entries, whose keys are smaller than or equal to $key, from the largest entry.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_gt($key, $limit=1)

Get entries, whose keys are greater than $key, from the smallest one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_ge($key, $limit=1)

Get entries, whose keys are greater than or equal to $key, from the smallest one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_gt_lt($lower_key, $upper_key)

Get entries, whose keys are greater than $lower_key and smaller than $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_gt_le($lower_key, $upper_key)

Get entries, whose keys are greater than $lower_key and smaller than or equal to $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_ge_lt($lower_key, $upper_key)

Get entries, whose keys are greater than or equal to $lower_key and smaller than $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_ge_le($lower_key, $upper_key)

Get entries, whose keys are greater than or equal to $lower_key and smaller than or equal to $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_min($limit=1)

Get entries from the one with smallest key.
If there are more than one entries with smallest key,
begin from the first inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_max($limit=1)

Get entries from the one with largest key.
If there are more than one entries with smallest key,
begin from the last inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = &tree->skip_l($offset, $limit=1)

Get the first entry from one with the smallest key after skipping $offset entries.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = &tree->skip_g($offset, $limit=1)

Get the first entry from one with the largest key after skipping $offset entries.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $count = $tree->count_lt($key)

Get the number of entries whose keys are smaller than $key.

=item $count = $tree->count_le($key)

Get the number of entries whose keys are smaller than or equal to $key.

=item $count = $tree->count_gt($key)

Get the number of entries whose keys are greater than $key.

=item $count = $tree->count_ge($key)

Get the number of entries whose keys are greater than or equal to $key.

=item $dump_str = $tree->dump

Get a string which represent the whole tree structure. For debug use.

=item ($order_consistent, $size_consistent, $balanced) = $tree->check

Check the tree property. For debug use.

=item $ever_height = $tree->ever_height

Get the maximum height the tree has ever been. For debug use

=back

=cut

use Tree::SizeBalanced::num_int;

sub sbtree_num_int() {
    unshift @_, 'Tree::SizeBalanced::num_int';
    goto \&Tree::SizeBalanced::num_int::new;
}

sub sbtreeni() {
    unshift @_, 'Tree::SizeBalanced::num_int';
    goto \&Tree::SizeBalanced::num_int::new;
}

push @EXPORT_OK, qw(sbtree_num_int sbtreeni);
push @{$EXPORT_TAGS{'all'}}, qw(sbtree_num_int sbtreeni);
push @{$EXPORT_TAGS{'short'}}, qw(sbtreeni);
push @{$EXPORT_TAGS{'long'}}, qw(sbtree_num_int);


=head3 Tree::SizeBalanced::num_num

Tree map with key type numeric numbers (floating point numbers) and value type numeric numbers (floating point numbers).

=over 4

=item $tree = Tree::SizeBalanced::num_num->new

=item $tree = sbtree_num_num

=item $tree = sbtreenn

Creat a new empty tree.

=item $tree->insert($key, $value)

=item $tree->insert_after($key, $value)

Insert an entry into the tree.
If there are any entries with the same key size,
insert the new one after them.

=item $tree->insert_before($key, $value)

Insert an entry into the tree.
If there are any entries with the same key size,
insert the new one before them.

=item $tree->delete($key)

=item $tree->delete_last($key)

Delete one entry whose key is equal to $key.
If there ary more than one entry with the same key size,
delete the last inserted one.

=item $tree->delete_first($key)

Delete one entry whose key is equal to $key.
If there ary more than one entry with the same key size,
delete the first inserted one.

=item $size = $tree->size

Get the number of entries in the tree

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find($key, $limit=1)

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_first($key, $limit=1)

Get entries with key sizes equal to $key,
from the first inserted one to the last inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_last($key, $limit=1)

Get entries with key sizes equal to $key,
from the last inserted one to the first inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_lt($key, $limit=1)

Get entries, whose keys are smaller than $key, from the largest entry.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_le($key, $limit=1)

Get entries, whose keys are smaller than or equal to $key, from the largest entry.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_gt($key, $limit=1)

Get entries, whose keys are greater than $key, from the smallest one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_ge($key, $limit=1)

Get entries, whose keys are greater than or equal to $key, from the smallest one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_gt_lt($lower_key, $upper_key)

Get entries, whose keys are greater than $lower_key and smaller than $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_gt_le($lower_key, $upper_key)

Get entries, whose keys are greater than $lower_key and smaller than or equal to $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_ge_lt($lower_key, $upper_key)

Get entries, whose keys are greater than or equal to $lower_key and smaller than $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_ge_le($lower_key, $upper_key)

Get entries, whose keys are greater than or equal to $lower_key and smaller than or equal to $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_min($limit=1)

Get entries from the one with smallest key.
If there are more than one entries with smallest key,
begin from the first inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_max($limit=1)

Get entries from the one with largest key.
If there are more than one entries with smallest key,
begin from the last inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = &tree->skip_l($offset, $limit=1)

Get the first entry from one with the smallest key after skipping $offset entries.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = &tree->skip_g($offset, $limit=1)

Get the first entry from one with the largest key after skipping $offset entries.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $count = $tree->count_lt($key)

Get the number of entries whose keys are smaller than $key.

=item $count = $tree->count_le($key)

Get the number of entries whose keys are smaller than or equal to $key.

=item $count = $tree->count_gt($key)

Get the number of entries whose keys are greater than $key.

=item $count = $tree->count_ge($key)

Get the number of entries whose keys are greater than or equal to $key.

=item $dump_str = $tree->dump

Get a string which represent the whole tree structure. For debug use.

=item ($order_consistent, $size_consistent, $balanced) = $tree->check

Check the tree property. For debug use.

=item $ever_height = $tree->ever_height

Get the maximum height the tree has ever been. For debug use

=back

=cut

use Tree::SizeBalanced::num_num;

sub sbtree_num_num() {
    unshift @_, 'Tree::SizeBalanced::num_num';
    goto \&Tree::SizeBalanced::num_num::new;
}

sub sbtreenn() {
    unshift @_, 'Tree::SizeBalanced::num_num';
    goto \&Tree::SizeBalanced::num_num::new;
}

push @EXPORT_OK, qw(sbtree_num_num sbtreenn);
push @{$EXPORT_TAGS{'all'}}, qw(sbtree_num_num sbtreenn);
push @{$EXPORT_TAGS{'short'}}, qw(sbtreenn);
push @{$EXPORT_TAGS{'long'}}, qw(sbtree_num_num);


=head3 Tree::SizeBalanced::num_any

Tree map with key type numeric numbers (floating point numbers) and value type any scalars.

=over 4

=item $tree = Tree::SizeBalanced::num_any->new

=item $tree = sbtree_num_any

=item $tree = sbtreena

Creat a new empty tree.

=item $tree->insert($key, $value)

=item $tree->insert_after($key, $value)

Insert an entry into the tree.
If there are any entries with the same key size,
insert the new one after them.

=item $tree->insert_before($key, $value)

Insert an entry into the tree.
If there are any entries with the same key size,
insert the new one before them.

=item $tree->delete($key)

=item $tree->delete_last($key)

Delete one entry whose key is equal to $key.
If there ary more than one entry with the same key size,
delete the last inserted one.

=item $tree->delete_first($key)

Delete one entry whose key is equal to $key.
If there ary more than one entry with the same key size,
delete the first inserted one.

=item $size = $tree->size

Get the number of entries in the tree

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find($key, $limit=1)

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_first($key, $limit=1)

Get entries with key sizes equal to $key,
from the first inserted one to the last inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_last($key, $limit=1)

Get entries with key sizes equal to $key,
from the last inserted one to the first inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_lt($key, $limit=1)

Get entries, whose keys are smaller than $key, from the largest entry.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_le($key, $limit=1)

Get entries, whose keys are smaller than or equal to $key, from the largest entry.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_gt($key, $limit=1)

Get entries, whose keys are greater than $key, from the smallest one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_ge($key, $limit=1)

Get entries, whose keys are greater than or equal to $key, from the smallest one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_gt_lt($lower_key, $upper_key)

Get entries, whose keys are greater than $lower_key and smaller than $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_gt_le($lower_key, $upper_key)

Get entries, whose keys are greater than $lower_key and smaller than or equal to $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_ge_lt($lower_key, $upper_key)

Get entries, whose keys are greater than or equal to $lower_key and smaller than $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_ge_le($lower_key, $upper_key)

Get entries, whose keys are greater than or equal to $lower_key and smaller than or equal to $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_min($limit=1)

Get entries from the one with smallest key.
If there are more than one entries with smallest key,
begin from the first inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_max($limit=1)

Get entries from the one with largest key.
If there are more than one entries with smallest key,
begin from the last inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = &tree->skip_l($offset, $limit=1)

Get the first entry from one with the smallest key after skipping $offset entries.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = &tree->skip_g($offset, $limit=1)

Get the first entry from one with the largest key after skipping $offset entries.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $count = $tree->count_lt($key)

Get the number of entries whose keys are smaller than $key.

=item $count = $tree->count_le($key)

Get the number of entries whose keys are smaller than or equal to $key.

=item $count = $tree->count_gt($key)

Get the number of entries whose keys are greater than $key.

=item $count = $tree->count_ge($key)

Get the number of entries whose keys are greater than or equal to $key.

=item $dump_str = $tree->dump

Get a string which represent the whole tree structure. For debug use.

=item ($order_consistent, $size_consistent, $balanced) = $tree->check

Check the tree property. For debug use.

=item $ever_height = $tree->ever_height

Get the maximum height the tree has ever been. For debug use

=back

=cut

use Tree::SizeBalanced::num_any;

sub sbtree_num_any() {
    unshift @_, 'Tree::SizeBalanced::num_any';
    goto \&Tree::SizeBalanced::num_any::new;
}

sub sbtreena() {
    unshift @_, 'Tree::SizeBalanced::num_any';
    goto \&Tree::SizeBalanced::num_any::new;
}

push @EXPORT_OK, qw(sbtree_num_any sbtreena);
push @{$EXPORT_TAGS{'all'}}, qw(sbtree_num_any sbtreena);
push @{$EXPORT_TAGS{'short'}}, qw(sbtreena);
push @{$EXPORT_TAGS{'long'}}, qw(sbtree_num_any);


=head3 Tree::SizeBalanced::str_void

Tree set with key type strings.

=over 4

=item $tree = Tree::SizeBalanced::str_void->new

=item $tree = sbtree_str_void

=item $tree = sbtrees

Creat a new empty tree.

=item $tree->insert($key)

=item $tree->insert_after($key)

Insert an entry into the tree.
If there are any entries with the same key size,
insert the new one after them.

=item $tree->insert_before($key)

Insert an entry into the tree.
If there are any entries with the same key size,
insert the new one before them.

=item $tree->delete($key)

=item $tree->delete_last($key)

Delete one entry whose key is equal to $key.
If there ary more than one entry with the same key size,
delete the last inserted one.

=item $tree->delete_first($key)

Delete one entry whose key is equal to $key.
If there ary more than one entry with the same key size,
delete the first inserted one.

=item $size = $tree->size

Get the number of entries in the tree

=item $key or ($key1, $key2, ...) = $tree->find($key, $limit=1)

=item $key or ($key1, $key2, ...) = $tree->find_first($key, $limit=1)

Get entries with key sizes equal to $key,
from the first inserted one to the last inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $key2, ...) = $tree->find_last($key, $limit=1)

Get entries with key sizes equal to $key,
from the last inserted one to the first inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $key2, ...) = $tree->find_lt($key, $limit=1)

Get entries, whose keys are smaller than $key, from the largest entry.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $key2, ...) = $tree->find_le($key, $limit=1)

Get entries, whose keys are smaller than or equal to $key, from the largest entry.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $key2, ...) = $tree->find_gt($key, $limit=1)

Get entries, whose keys are greater than $key, from the smallest one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $key2, ...) = $tree->find_ge($key, $limit=1)

Get entries, whose keys are greater than or equal to $key, from the smallest one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $key2, ...) = $tree->find_gt_lt($lower_key, $upper_key)

Get entries, whose keys are greater than $lower_key and smaller than $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $key2, ...) = $tree->find_gt_le($lower_key, $upper_key)

Get entries, whose keys are greater than $lower_key and smaller than or equal to $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $key2, ...) = $tree->find_ge_lt($lower_key, $upper_key)

Get entries, whose keys are greater than or equal to $lower_key and smaller than $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $key2, ...) = $tree->find_ge_le($lower_key, $upper_key)

Get entries, whose keys are greater than or equal to $lower_key and smaller than or equal to $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $key2, ...) = $tree->find_min($limit=1)

Get entries from the one with smallest key.
If there are more than one entries with smallest key,
begin from the first inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $key2, ...) = $tree->find_max($limit=1)

Get entries from the one with largest key.
If there are more than one entries with smallest key,
begin from the last inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $key2, ...) = &tree->skip_l($offset, $limit=1)

Get the first entry from one with the smallest key after skipping $offset entries.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $key2, ...) = &tree->skip_g($offset, $limit=1)

Get the first entry from one with the largest key after skipping $offset entries.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $count = $tree->count_lt($key)

Get the number of entries whose keys are smaller than $key.

=item $count = $tree->count_le($key)

Get the number of entries whose keys are smaller than or equal to $key.

=item $count = $tree->count_gt($key)

Get the number of entries whose keys are greater than $key.

=item $count = $tree->count_ge($key)

Get the number of entries whose keys are greater than or equal to $key.

=item $dump_str = $tree->dump

Get a string which represent the whole tree structure. For debug use.

=item ($order_consistent, $size_consistent, $balanced) = $tree->check

Check the tree property. For debug use.

=item $ever_height = $tree->ever_height

Get the maximum height the tree has ever been. For debug use

=back

=cut

use Tree::SizeBalanced::str_void;

sub sbtree_str_void() {
    unshift @_, 'Tree::SizeBalanced::str_void';
    goto \&Tree::SizeBalanced::str_void::new;
}

sub sbtrees() {
    unshift @_, 'Tree::SizeBalanced::str_void';
    goto \&Tree::SizeBalanced::str_void::new;
}

push @EXPORT_OK, qw(sbtree_str_void sbtrees);
push @{$EXPORT_TAGS{'all'}}, qw(sbtree_str_void sbtrees);
push @{$EXPORT_TAGS{'short'}}, qw(sbtrees);
push @{$EXPORT_TAGS{'long'}}, qw(sbtree_str_void);


=head3 Tree::SizeBalanced::str_int

Tree map with key type strings and value type signed integers (32bits or 64bits according to your perl version).

=over 4

=item $tree = Tree::SizeBalanced::str_int->new

=item $tree = sbtree_str_int

=item $tree = sbtreesi

Creat a new empty tree.

=item $tree->insert($key, $value)

=item $tree->insert_after($key, $value)

Insert an entry into the tree.
If there are any entries with the same key size,
insert the new one after them.

=item $tree->insert_before($key, $value)

Insert an entry into the tree.
If there are any entries with the same key size,
insert the new one before them.

=item $tree->delete($key)

=item $tree->delete_last($key)

Delete one entry whose key is equal to $key.
If there ary more than one entry with the same key size,
delete the last inserted one.

=item $tree->delete_first($key)

Delete one entry whose key is equal to $key.
If there ary more than one entry with the same key size,
delete the first inserted one.

=item $size = $tree->size

Get the number of entries in the tree

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find($key, $limit=1)

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_first($key, $limit=1)

Get entries with key sizes equal to $key,
from the first inserted one to the last inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_last($key, $limit=1)

Get entries with key sizes equal to $key,
from the last inserted one to the first inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_lt($key, $limit=1)

Get entries, whose keys are smaller than $key, from the largest entry.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_le($key, $limit=1)

Get entries, whose keys are smaller than or equal to $key, from the largest entry.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_gt($key, $limit=1)

Get entries, whose keys are greater than $key, from the smallest one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_ge($key, $limit=1)

Get entries, whose keys are greater than or equal to $key, from the smallest one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_gt_lt($lower_key, $upper_key)

Get entries, whose keys are greater than $lower_key and smaller than $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_gt_le($lower_key, $upper_key)

Get entries, whose keys are greater than $lower_key and smaller than or equal to $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_ge_lt($lower_key, $upper_key)

Get entries, whose keys are greater than or equal to $lower_key and smaller than $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_ge_le($lower_key, $upper_key)

Get entries, whose keys are greater than or equal to $lower_key and smaller than or equal to $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_min($limit=1)

Get entries from the one with smallest key.
If there are more than one entries with smallest key,
begin from the first inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_max($limit=1)

Get entries from the one with largest key.
If there are more than one entries with smallest key,
begin from the last inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = &tree->skip_l($offset, $limit=1)

Get the first entry from one with the smallest key after skipping $offset entries.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = &tree->skip_g($offset, $limit=1)

Get the first entry from one with the largest key after skipping $offset entries.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $count = $tree->count_lt($key)

Get the number of entries whose keys are smaller than $key.

=item $count = $tree->count_le($key)

Get the number of entries whose keys are smaller than or equal to $key.

=item $count = $tree->count_gt($key)

Get the number of entries whose keys are greater than $key.

=item $count = $tree->count_ge($key)

Get the number of entries whose keys are greater than or equal to $key.

=item $dump_str = $tree->dump

Get a string which represent the whole tree structure. For debug use.

=item ($order_consistent, $size_consistent, $balanced) = $tree->check

Check the tree property. For debug use.

=item $ever_height = $tree->ever_height

Get the maximum height the tree has ever been. For debug use

=back

=cut

use Tree::SizeBalanced::str_int;

sub sbtree_str_int() {
    unshift @_, 'Tree::SizeBalanced::str_int';
    goto \&Tree::SizeBalanced::str_int::new;
}

sub sbtreesi() {
    unshift @_, 'Tree::SizeBalanced::str_int';
    goto \&Tree::SizeBalanced::str_int::new;
}

push @EXPORT_OK, qw(sbtree_str_int sbtreesi);
push @{$EXPORT_TAGS{'all'}}, qw(sbtree_str_int sbtreesi);
push @{$EXPORT_TAGS{'short'}}, qw(sbtreesi);
push @{$EXPORT_TAGS{'long'}}, qw(sbtree_str_int);


=head3 Tree::SizeBalanced::str_num

Tree map with key type strings and value type numeric numbers (floating point numbers).

=over 4

=item $tree = Tree::SizeBalanced::str_num->new

=item $tree = sbtree_str_num

=item $tree = sbtreesn

Creat a new empty tree.

=item $tree->insert($key, $value)

=item $tree->insert_after($key, $value)

Insert an entry into the tree.
If there are any entries with the same key size,
insert the new one after them.

=item $tree->insert_before($key, $value)

Insert an entry into the tree.
If there are any entries with the same key size,
insert the new one before them.

=item $tree->delete($key)

=item $tree->delete_last($key)

Delete one entry whose key is equal to $key.
If there ary more than one entry with the same key size,
delete the last inserted one.

=item $tree->delete_first($key)

Delete one entry whose key is equal to $key.
If there ary more than one entry with the same key size,
delete the first inserted one.

=item $size = $tree->size

Get the number of entries in the tree

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find($key, $limit=1)

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_first($key, $limit=1)

Get entries with key sizes equal to $key,
from the first inserted one to the last inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_last($key, $limit=1)

Get entries with key sizes equal to $key,
from the last inserted one to the first inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_lt($key, $limit=1)

Get entries, whose keys are smaller than $key, from the largest entry.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_le($key, $limit=1)

Get entries, whose keys are smaller than or equal to $key, from the largest entry.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_gt($key, $limit=1)

Get entries, whose keys are greater than $key, from the smallest one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_ge($key, $limit=1)

Get entries, whose keys are greater than or equal to $key, from the smallest one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_gt_lt($lower_key, $upper_key)

Get entries, whose keys are greater than $lower_key and smaller than $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_gt_le($lower_key, $upper_key)

Get entries, whose keys are greater than $lower_key and smaller than or equal to $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_ge_lt($lower_key, $upper_key)

Get entries, whose keys are greater than or equal to $lower_key and smaller than $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_ge_le($lower_key, $upper_key)

Get entries, whose keys are greater than or equal to $lower_key and smaller than or equal to $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_min($limit=1)

Get entries from the one with smallest key.
If there are more than one entries with smallest key,
begin from the first inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_max($limit=1)

Get entries from the one with largest key.
If there are more than one entries with smallest key,
begin from the last inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = &tree->skip_l($offset, $limit=1)

Get the first entry from one with the smallest key after skipping $offset entries.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = &tree->skip_g($offset, $limit=1)

Get the first entry from one with the largest key after skipping $offset entries.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $count = $tree->count_lt($key)

Get the number of entries whose keys are smaller than $key.

=item $count = $tree->count_le($key)

Get the number of entries whose keys are smaller than or equal to $key.

=item $count = $tree->count_gt($key)

Get the number of entries whose keys are greater than $key.

=item $count = $tree->count_ge($key)

Get the number of entries whose keys are greater than or equal to $key.

=item $dump_str = $tree->dump

Get a string which represent the whole tree structure. For debug use.

=item ($order_consistent, $size_consistent, $balanced) = $tree->check

Check the tree property. For debug use.

=item $ever_height = $tree->ever_height

Get the maximum height the tree has ever been. For debug use

=back

=cut

use Tree::SizeBalanced::str_num;

sub sbtree_str_num() {
    unshift @_, 'Tree::SizeBalanced::str_num';
    goto \&Tree::SizeBalanced::str_num::new;
}

sub sbtreesn() {
    unshift @_, 'Tree::SizeBalanced::str_num';
    goto \&Tree::SizeBalanced::str_num::new;
}

push @EXPORT_OK, qw(sbtree_str_num sbtreesn);
push @{$EXPORT_TAGS{'all'}}, qw(sbtree_str_num sbtreesn);
push @{$EXPORT_TAGS{'short'}}, qw(sbtreesn);
push @{$EXPORT_TAGS{'long'}}, qw(sbtree_str_num);


=head3 Tree::SizeBalanced::str_any

Tree map with key type strings and value type any scalars.

=over 4

=item $tree = Tree::SizeBalanced::str_any->new

=item $tree = sbtree_str_any

=item $tree = sbtreesa

Creat a new empty tree.

=item $tree->insert($key, $value)

=item $tree->insert_after($key, $value)

Insert an entry into the tree.
If there are any entries with the same key size,
insert the new one after them.

=item $tree->insert_before($key, $value)

Insert an entry into the tree.
If there are any entries with the same key size,
insert the new one before them.

=item $tree->delete($key)

=item $tree->delete_last($key)

Delete one entry whose key is equal to $key.
If there ary more than one entry with the same key size,
delete the last inserted one.

=item $tree->delete_first($key)

Delete one entry whose key is equal to $key.
If there ary more than one entry with the same key size,
delete the first inserted one.

=item $size = $tree->size

Get the number of entries in the tree

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find($key, $limit=1)

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_first($key, $limit=1)

Get entries with key sizes equal to $key,
from the first inserted one to the last inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_last($key, $limit=1)

Get entries with key sizes equal to $key,
from the last inserted one to the first inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_lt($key, $limit=1)

Get entries, whose keys are smaller than $key, from the largest entry.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_le($key, $limit=1)

Get entries, whose keys are smaller than or equal to $key, from the largest entry.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_gt($key, $limit=1)

Get entries, whose keys are greater than $key, from the smallest one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_ge($key, $limit=1)

Get entries, whose keys are greater than or equal to $key, from the smallest one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_gt_lt($lower_key, $upper_key)

Get entries, whose keys are greater than $lower_key and smaller than $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_gt_le($lower_key, $upper_key)

Get entries, whose keys are greater than $lower_key and smaller than or equal to $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_ge_lt($lower_key, $upper_key)

Get entries, whose keys are greater than or equal to $lower_key and smaller than $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_ge_le($lower_key, $upper_key)

Get entries, whose keys are greater than or equal to $lower_key and smaller than or equal to $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_min($limit=1)

Get entries from the one with smallest key.
If there are more than one entries with smallest key,
begin from the first inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_max($limit=1)

Get entries from the one with largest key.
If there are more than one entries with smallest key,
begin from the last inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = &tree->skip_l($offset, $limit=1)

Get the first entry from one with the smallest key after skipping $offset entries.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = &tree->skip_g($offset, $limit=1)

Get the first entry from one with the largest key after skipping $offset entries.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $count = $tree->count_lt($key)

Get the number of entries whose keys are smaller than $key.

=item $count = $tree->count_le($key)

Get the number of entries whose keys are smaller than or equal to $key.

=item $count = $tree->count_gt($key)

Get the number of entries whose keys are greater than $key.

=item $count = $tree->count_ge($key)

Get the number of entries whose keys are greater than or equal to $key.

=item $dump_str = $tree->dump

Get a string which represent the whole tree structure. For debug use.

=item ($order_consistent, $size_consistent, $balanced) = $tree->check

Check the tree property. For debug use.

=item $ever_height = $tree->ever_height

Get the maximum height the tree has ever been. For debug use

=back

=cut

use Tree::SizeBalanced::str_any;

sub sbtree_str_any() {
    unshift @_, 'Tree::SizeBalanced::str_any';
    goto \&Tree::SizeBalanced::str_any::new;
}

sub sbtreesa() {
    unshift @_, 'Tree::SizeBalanced::str_any';
    goto \&Tree::SizeBalanced::str_any::new;
}

push @EXPORT_OK, qw(sbtree_str_any sbtreesa);
push @{$EXPORT_TAGS{'all'}}, qw(sbtree_str_any sbtreesa);
push @{$EXPORT_TAGS{'short'}}, qw(sbtreesa);
push @{$EXPORT_TAGS{'long'}}, qw(sbtree_str_any);


=head3 Tree::SizeBalanced::any_void

Tree set with key type any scalars.

=over 4

=item $tree = Tree::SizeBalanced::any_void->new sub { $a cmp $b }

=item $tree = sbtree_any_void { $a cmp $b }

=item $tree = sbtreea { $a cmp $b }

Creat a new empty tree.

=item $tree->insert($key)

=item $tree->insert_after($key)

Insert an entry into the tree.
If there are any entries with the same key size,
insert the new one after them.

=item $tree->insert_before($key)

Insert an entry into the tree.
If there are any entries with the same key size,
insert the new one before them.

=item $tree->delete($key)

=item $tree->delete_last($key)

Delete one entry whose key is equal to $key.
If there ary more than one entry with the same key size,
delete the last inserted one.

=item $tree->delete_first($key)

Delete one entry whose key is equal to $key.
If there ary more than one entry with the same key size,
delete the first inserted one.

=item $size = $tree->size

Get the number of entries in the tree

=item $key or ($key1, $key2, ...) = $tree->find($key, $limit=1)

=item $key or ($key1, $key2, ...) = $tree->find_first($key, $limit=1)

Get entries with key sizes equal to $key,
from the first inserted one to the last inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $key2, ...) = $tree->find_last($key, $limit=1)

Get entries with key sizes equal to $key,
from the last inserted one to the first inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $key2, ...) = $tree->find_lt($key, $limit=1)

Get entries, whose keys are smaller than $key, from the largest entry.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $key2, ...) = $tree->find_le($key, $limit=1)

Get entries, whose keys are smaller than or equal to $key, from the largest entry.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $key2, ...) = $tree->find_gt($key, $limit=1)

Get entries, whose keys are greater than $key, from the smallest one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $key2, ...) = $tree->find_ge($key, $limit=1)

Get entries, whose keys are greater than or equal to $key, from the smallest one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $key2, ...) = $tree->find_gt_lt($lower_key, $upper_key)

Get entries, whose keys are greater than $lower_key and smaller than $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $key2, ...) = $tree->find_gt_le($lower_key, $upper_key)

Get entries, whose keys are greater than $lower_key and smaller than or equal to $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $key2, ...) = $tree->find_ge_lt($lower_key, $upper_key)

Get entries, whose keys are greater than or equal to $lower_key and smaller than $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $key2, ...) = $tree->find_ge_le($lower_key, $upper_key)

Get entries, whose keys are greater than or equal to $lower_key and smaller than or equal to $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $key2, ...) = $tree->find_min($limit=1)

Get entries from the one with smallest key.
If there are more than one entries with smallest key,
begin from the first inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $key2, ...) = $tree->find_max($limit=1)

Get entries from the one with largest key.
If there are more than one entries with smallest key,
begin from the last inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $key2, ...) = &tree->skip_l($offset, $limit=1)

Get the first entry from one with the smallest key after skipping $offset entries.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $key2, ...) = &tree->skip_g($offset, $limit=1)

Get the first entry from one with the largest key after skipping $offset entries.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $count = $tree->count_lt($key)

Get the number of entries whose keys are smaller than $key.

=item $count = $tree->count_le($key)

Get the number of entries whose keys are smaller than or equal to $key.

=item $count = $tree->count_gt($key)

Get the number of entries whose keys are greater than $key.

=item $count = $tree->count_ge($key)

Get the number of entries whose keys are greater than or equal to $key.

=item $dump_str = $tree->dump

Get a string which represent the whole tree structure. For debug use.

=item ($order_consistent, $size_consistent, $balanced) = $tree->check

Check the tree property. For debug use.

=item $ever_height = $tree->ever_height

Get the maximum height the tree has ever been. For debug use

=back

=cut

use Tree::SizeBalanced::any_void;

sub sbtree_any_void(&) {
    unshift @_, 'Tree::SizeBalanced::any_void';
    goto \&Tree::SizeBalanced::any_void::new;
}

sub sbtreea(&) {
    unshift @_, 'Tree::SizeBalanced::any_void';
    goto \&Tree::SizeBalanced::any_void::new;
}

push @EXPORT_OK, qw(sbtree_any_void sbtreea);
push @{$EXPORT_TAGS{'all'}}, qw(sbtree_any_void sbtreea);
push @{$EXPORT_TAGS{'short'}}, qw(sbtreea);
push @{$EXPORT_TAGS{'long'}}, qw(sbtree_any_void);


=head3 Tree::SizeBalanced::any_int

Tree map with key type any scalars and value type signed integers (32bits or 64bits according to your perl version).

=over 4

=item $tree = Tree::SizeBalanced::any_int->new sub { $a cmp $b }

=item $tree = sbtree_any_int { $a cmp $b }

=item $tree = sbtreeai { $a cmp $b }

Creat a new empty tree.

=item $tree->insert($key, $value)

=item $tree->insert_after($key, $value)

Insert an entry into the tree.
If there are any entries with the same key size,
insert the new one after them.

=item $tree->insert_before($key, $value)

Insert an entry into the tree.
If there are any entries with the same key size,
insert the new one before them.

=item $tree->delete($key)

=item $tree->delete_last($key)

Delete one entry whose key is equal to $key.
If there ary more than one entry with the same key size,
delete the last inserted one.

=item $tree->delete_first($key)

Delete one entry whose key is equal to $key.
If there ary more than one entry with the same key size,
delete the first inserted one.

=item $size = $tree->size

Get the number of entries in the tree

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find($key, $limit=1)

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_first($key, $limit=1)

Get entries with key sizes equal to $key,
from the first inserted one to the last inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_last($key, $limit=1)

Get entries with key sizes equal to $key,
from the last inserted one to the first inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_lt($key, $limit=1)

Get entries, whose keys are smaller than $key, from the largest entry.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_le($key, $limit=1)

Get entries, whose keys are smaller than or equal to $key, from the largest entry.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_gt($key, $limit=1)

Get entries, whose keys are greater than $key, from the smallest one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_ge($key, $limit=1)

Get entries, whose keys are greater than or equal to $key, from the smallest one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_gt_lt($lower_key, $upper_key)

Get entries, whose keys are greater than $lower_key and smaller than $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_gt_le($lower_key, $upper_key)

Get entries, whose keys are greater than $lower_key and smaller than or equal to $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_ge_lt($lower_key, $upper_key)

Get entries, whose keys are greater than or equal to $lower_key and smaller than $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_ge_le($lower_key, $upper_key)

Get entries, whose keys are greater than or equal to $lower_key and smaller than or equal to $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_min($limit=1)

Get entries from the one with smallest key.
If there are more than one entries with smallest key,
begin from the first inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_max($limit=1)

Get entries from the one with largest key.
If there are more than one entries with smallest key,
begin from the last inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = &tree->skip_l($offset, $limit=1)

Get the first entry from one with the smallest key after skipping $offset entries.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = &tree->skip_g($offset, $limit=1)

Get the first entry from one with the largest key after skipping $offset entries.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $count = $tree->count_lt($key)

Get the number of entries whose keys are smaller than $key.

=item $count = $tree->count_le($key)

Get the number of entries whose keys are smaller than or equal to $key.

=item $count = $tree->count_gt($key)

Get the number of entries whose keys are greater than $key.

=item $count = $tree->count_ge($key)

Get the number of entries whose keys are greater than or equal to $key.

=item $dump_str = $tree->dump

Get a string which represent the whole tree structure. For debug use.

=item ($order_consistent, $size_consistent, $balanced) = $tree->check

Check the tree property. For debug use.

=item $ever_height = $tree->ever_height

Get the maximum height the tree has ever been. For debug use

=back

=cut

use Tree::SizeBalanced::any_int;

sub sbtree_any_int(&) {
    unshift @_, 'Tree::SizeBalanced::any_int';
    goto \&Tree::SizeBalanced::any_int::new;
}

sub sbtreeai(&) {
    unshift @_, 'Tree::SizeBalanced::any_int';
    goto \&Tree::SizeBalanced::any_int::new;
}

push @EXPORT_OK, qw(sbtree_any_int sbtreeai);
push @{$EXPORT_TAGS{'all'}}, qw(sbtree_any_int sbtreeai);
push @{$EXPORT_TAGS{'short'}}, qw(sbtreeai);
push @{$EXPORT_TAGS{'long'}}, qw(sbtree_any_int);


=head3 Tree::SizeBalanced::any_num

Tree map with key type any scalars and value type numeric numbers (floating point numbers).

=over 4

=item $tree = Tree::SizeBalanced::any_num->new sub { $a cmp $b }

=item $tree = sbtree_any_num { $a cmp $b }

=item $tree = sbtreean { $a cmp $b }

Creat a new empty tree.

=item $tree->insert($key, $value)

=item $tree->insert_after($key, $value)

Insert an entry into the tree.
If there are any entries with the same key size,
insert the new one after them.

=item $tree->insert_before($key, $value)

Insert an entry into the tree.
If there are any entries with the same key size,
insert the new one before them.

=item $tree->delete($key)

=item $tree->delete_last($key)

Delete one entry whose key is equal to $key.
If there ary more than one entry with the same key size,
delete the last inserted one.

=item $tree->delete_first($key)

Delete one entry whose key is equal to $key.
If there ary more than one entry with the same key size,
delete the first inserted one.

=item $size = $tree->size

Get the number of entries in the tree

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find($key, $limit=1)

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_first($key, $limit=1)

Get entries with key sizes equal to $key,
from the first inserted one to the last inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_last($key, $limit=1)

Get entries with key sizes equal to $key,
from the last inserted one to the first inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_lt($key, $limit=1)

Get entries, whose keys are smaller than $key, from the largest entry.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_le($key, $limit=1)

Get entries, whose keys are smaller than or equal to $key, from the largest entry.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_gt($key, $limit=1)

Get entries, whose keys are greater than $key, from the smallest one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_ge($key, $limit=1)

Get entries, whose keys are greater than or equal to $key, from the smallest one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_gt_lt($lower_key, $upper_key)

Get entries, whose keys are greater than $lower_key and smaller than $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_gt_le($lower_key, $upper_key)

Get entries, whose keys are greater than $lower_key and smaller than or equal to $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_ge_lt($lower_key, $upper_key)

Get entries, whose keys are greater than or equal to $lower_key and smaller than $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_ge_le($lower_key, $upper_key)

Get entries, whose keys are greater than or equal to $lower_key and smaller than or equal to $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_min($limit=1)

Get entries from the one with smallest key.
If there are more than one entries with smallest key,
begin from the first inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_max($limit=1)

Get entries from the one with largest key.
If there are more than one entries with smallest key,
begin from the last inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = &tree->skip_l($offset, $limit=1)

Get the first entry from one with the smallest key after skipping $offset entries.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = &tree->skip_g($offset, $limit=1)

Get the first entry from one with the largest key after skipping $offset entries.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $count = $tree->count_lt($key)

Get the number of entries whose keys are smaller than $key.

=item $count = $tree->count_le($key)

Get the number of entries whose keys are smaller than or equal to $key.

=item $count = $tree->count_gt($key)

Get the number of entries whose keys are greater than $key.

=item $count = $tree->count_ge($key)

Get the number of entries whose keys are greater than or equal to $key.

=item $dump_str = $tree->dump

Get a string which represent the whole tree structure. For debug use.

=item ($order_consistent, $size_consistent, $balanced) = $tree->check

Check the tree property. For debug use.

=item $ever_height = $tree->ever_height

Get the maximum height the tree has ever been. For debug use

=back

=cut

use Tree::SizeBalanced::any_num;

sub sbtree_any_num(&) {
    unshift @_, 'Tree::SizeBalanced::any_num';
    goto \&Tree::SizeBalanced::any_num::new;
}

sub sbtreean(&) {
    unshift @_, 'Tree::SizeBalanced::any_num';
    goto \&Tree::SizeBalanced::any_num::new;
}

push @EXPORT_OK, qw(sbtree_any_num sbtreean);
push @{$EXPORT_TAGS{'all'}}, qw(sbtree_any_num sbtreean);
push @{$EXPORT_TAGS{'short'}}, qw(sbtreean);
push @{$EXPORT_TAGS{'long'}}, qw(sbtree_any_num);


=head3 Tree::SizeBalanced::any_any

Tree map with key type any scalars and value type any scalars.

=over 4

=item $tree = Tree::SizeBalanced::any_any->new sub { $a cmp $b }

=item $tree = sbtree_any_any { $a cmp $b }

=item $tree = sbtreeaa { $a cmp $b }

Creat a new empty tree.

=item $tree->insert($key, $value)

=item $tree->insert_after($key, $value)

Insert an entry into the tree.
If there are any entries with the same key size,
insert the new one after them.

=item $tree->insert_before($key, $value)

Insert an entry into the tree.
If there are any entries with the same key size,
insert the new one before them.

=item $tree->delete($key)

=item $tree->delete_last($key)

Delete one entry whose key is equal to $key.
If there ary more than one entry with the same key size,
delete the last inserted one.

=item $tree->delete_first($key)

Delete one entry whose key is equal to $key.
If there ary more than one entry with the same key size,
delete the first inserted one.

=item $size = $tree->size

Get the number of entries in the tree

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find($key, $limit=1)

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_first($key, $limit=1)

Get entries with key sizes equal to $key,
from the first inserted one to the last inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_last($key, $limit=1)

Get entries with key sizes equal to $key,
from the last inserted one to the first inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_lt($key, $limit=1)

Get entries, whose keys are smaller than $key, from the largest entry.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_le($key, $limit=1)

Get entries, whose keys are smaller than or equal to $key, from the largest entry.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_gt($key, $limit=1)

Get entries, whose keys are greater than $key, from the smallest one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_ge($key, $limit=1)

Get entries, whose keys are greater than or equal to $key, from the smallest one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_gt_lt($lower_key, $upper_key)

Get entries, whose keys are greater than $lower_key and smaller than $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_gt_le($lower_key, $upper_key)

Get entries, whose keys are greater than $lower_key and smaller than or equal to $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_ge_lt($lower_key, $upper_key)

Get entries, whose keys are greater than or equal to $lower_key and smaller than $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_ge_le($lower_key, $upper_key)

Get entries, whose keys are greater than or equal to $lower_key and smaller than or equal to $upper_key,
from the smallest one to the largest one.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_min($limit=1)

Get entries from the one with smallest key.
If there are more than one entries with smallest key,
begin from the first inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = $tree->find_max($limit=1)

Get entries from the one with largest key.
If there are more than one entries with smallest key,
begin from the last inserted one.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = &tree->skip_l($offset, $limit=1)

Get the first entry from one with the smallest key after skipping $offset entries.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $key or ($key1, $value1, $key2, $value2, ...) = &tree->skip_g($offset, $limit=1)

Get the first entry from one with the largest key after skipping $offset entries.

The optional $limit (default 1) indicates the maximum entry number you will get,
$limit=-1 means unlimited.

=item $count = $tree->count_lt($key)

Get the number of entries whose keys are smaller than $key.

=item $count = $tree->count_le($key)

Get the number of entries whose keys are smaller than or equal to $key.

=item $count = $tree->count_gt($key)

Get the number of entries whose keys are greater than $key.

=item $count = $tree->count_ge($key)

Get the number of entries whose keys are greater than or equal to $key.

=item $dump_str = $tree->dump

Get a string which represent the whole tree structure. For debug use.

=item ($order_consistent, $size_consistent, $balanced) = $tree->check

Check the tree property. For debug use.

=item $ever_height = $tree->ever_height

Get the maximum height the tree has ever been. For debug use

=back

=cut

use Tree::SizeBalanced::any_any;

sub sbtree_any_any(&) {
    unshift @_, 'Tree::SizeBalanced::any_any';
    goto \&Tree::SizeBalanced::any_any::new;
}

sub sbtreeaa(&) {
    unshift @_, 'Tree::SizeBalanced::any_any';
    goto \&Tree::SizeBalanced::any_any::new;
}

push @EXPORT_OK, qw(sbtree_any_any sbtreeaa);
push @{$EXPORT_TAGS{'all'}}, qw(sbtree_any_any sbtreeaa);
push @{$EXPORT_TAGS{'short'}}, qw(sbtreeaa);
push @{$EXPORT_TAGS{'long'}}, qw(sbtree_any_any);

sub sbtree(;&) {
    if( ref() eq 'CODE' ) {
        goto \&sbtreeaa;
    } else {
        goto \&sbtreeia;
    }
}

sub new {
    shift;
    if( ref() eq 'CODE' ) {
        goto \&sbtreeaa;
    } else {
        goto \&sbtreeia;
    }
}


=head3 Default type constructors

=over 4

=item $tree = Tree::SizeBalanced->new;

equivalent to C<< $tree = Tree::SizeBalanced::int_any->new; >>

=item $tree = Tree::SizeBalanced->new sub { $a cmp $b };

equivalent to C<< $tree = Tree::SizeBalanced::any_any->new; >>

=item $tree = sbtree;

equivalent to C<$tree = sbtreeia>

=item $tree = sbtree { $a cmp $b };

equivalent to C<$tree = sbtreeaa>

=back

=head1 BENCHMARK

test result: (perl 5.22.2, Tree::SizeBalanced 2.6)

L<incremental integer query|https://github.com/CindyLinz/Perl-Tree-SizeBalanced/blob/master/benchmark/incremental_integer_query.pl> seed_count=10, data_size=100_000, verbose=0

    Benchmark: timing 1 iterations of Sorted array, Static array, tree set any, tree set int...
    Sorted array: 12 wallclock secs (12.60 usr +  0.00 sys = 12.60 CPU) @  0.08/s (n=1)
                (warning: too few iterations for a reliable count)
    ^CSIGINT!
    Static array: 737 wallclock secs (736.96 usr +  0.14 sys = 737.10 CPU) @  0.00/s (n=1)
                (warning: too few iterations for a reliable count)
    tree set any:  5 wallclock secs ( 4.70 usr +  0.01 sys =  4.71 CPU) @  0.21/s (n=1)
                (warning: too few iterations for a reliable count)
    tree set int:  1 wallclock secs ( 0.69 usr +  0.01 sys =  0.70 CPU) @  1.43/s (n=1)
                (warning: too few iterations for a reliable count)

    (Note that "Static array" didn't complete. It's interrupted)

L<incremental string query|https://github.com/CindyLinz/Perl-Tree-SizeBalanced/blob/master/benchmark/incremental_string_query.pl> seed_count=10, data_size=100_000, verbose=0

    Benchmark: timing 1 iterations of Sorted array, Static array, tree set any, tree set str...
    Sorted array: 15 wallclock secs (15.28 usr +  0.00 sys = 15.28 CPU) @  0.07/s (n=1)
                (warning: too few iterations for a reliable count)
    ^CSIGINT!
    Static array: 673 wallclock secs (672.08 usr +  0.15 sys = 672.23 CPU) @  0.00/s (n=1)
                (warning: too few iterations for a reliable count)
    tree set any:  6 wallclock secs ( 6.65 usr +  0.00 sys =  6.65 CPU) @  0.15/s (n=1)
                (warning: too few iterations for a reliable count)
    tree set str:  2 wallclock secs ( 1.88 usr +  0.00 sys =  1.88 CPU) @  0.53/s (n=1)
                (warning: too few iterations for a reliable count)

    (Note that "Static array" didn't complete. It's interrupted)

L<bulk integer query|https://github.com/CindyLinz/Perl-Tree-SizeBalanced/blob/master/benchmark/bulk_integer_query.pl> seed_count=10, data_size=100_000, verbose=0

    Benchmark: timing 1 iterations of Sorted array, Static array, tree set any, tree set int...
    Sorted array:  3 wallclock secs ( 2.99 usr +  0.00 sys =  2.99 CPU) @  0.33/s (n=1)
                (warning: too few iterations for a reliable count)
    ^CSIGINT!
    Static array: 251 wallclock secs (251.85 usr +  0.02 sys = 251.87 CPU) @  0.00/s (n=1)
                (warning: too few iterations for a reliable count)
    tree set any:  6 wallclock secs ( 5.24 usr +  0.00 sys =  5.24 CPU) @  0.19/s (n=1)
                (warning: too few iterations for a reliable count)
    tree set int:  1 wallclock secs ( 0.86 usr +  0.00 sys =  0.86 CPU) @  1.16/s (n=1)
                (warning: too few iterations for a reliable count)

    (Note that "Static array" didn't complete. It's interrupted)

L<bulk string query|https://github.com/CindyLinz/Perl-Tree-SizeBalanced/blob/master/benchmark/bulk_string_query.pl> seed_count=10, data_size=100_000, verbose=0

    Benchmark: timing 1 iterations of Sorted array, Static array, tree set any, tree set int...
    Sorted array:  5 wallclock secs ( 5.59 usr +  0.00 sys =  5.59 CPU) @  0.18/s (n=1)
                (warning: too few iterations for a reliable count)
    ^CSIGINT!
    Static array: 363 wallclock secs (361.56 usr +  0.07 sys = 361.63 CPU) @  0.00/s (n=1)
                (warning: too few iterations for a reliable count)
    tree set any:  8 wallclock secs ( 7.85 usr +  0.00 sys =  7.85 CPU) @  0.13/s (n=1)
                (warning: too few iterations for a reliable count)
    tree set int:  3 wallclock secs ( 3.27 usr +  0.01 sys =  3.28 CPU) @  0.30/s (n=1)
                (warning: too few iterations for a reliable count)

    (Note that "Static array" didn't complete. It's interrupted)

=head1 SEE ALSO

This mod's github L<https://github.com/CindyLinz/Perl-Tree-SizeBalanced>.
It's welcome to discuss with me when you encounter bugs, or
if you think that some patterns are also useful but the mod didn't provide them yet.

Introduction to Size Balanced Tree L<http://wcipeg.com/wiki/Size_Balanced_Tree>.

陈启峰's original paper L<https://drive.google.com/file/d/0B6NYSy8f6mQLOEpHdHh4U2hRcFk/view?usp=sharing>,
I found it from L<http://sunmoon-template.blogspot.tw/2015/01/b-size-balanced-tree.html>.

=head1 AUTHOR

Cindy Wang (CindyLinz) <cindy@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by CindyLinz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.22.1 or,
at your option, any later version of Perl 5 you may have available.

=head1 ACKNOWLEDGEMENT

Thank TDYa127 L<https://github.com/a127a127/> who tell me size balanced tree.

=cut

require XSLoader;
XSLoader::load('Tree::SizeBalanced', $VERSION);

1;
__END__


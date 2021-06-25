#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib/ -I.
#-------------------------------------------------------------------------------
# Multi-way tree in Pure Perl with an even or odd number of keys per node.
# Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2021
#-------------------------------------------------------------------------------
# podDocumentation
package Tree::Multi;
our $VERSION = "20210614";
use warnings FATAL => qw(all);
use strict;
use Carp qw(confess cluck);
use Data::Dump qw(dump pp);
use Data::Table::Text qw(:all);
use feature qw(say current_sub);

our $numberOfKeysPerNode = 3;                                                   # Number of keys per node which can be localized because it is ours. The number of keys can be even or odd.

#D1 Multi-way Tree                                                              # Create and use a multi-way tree.

sub new()                                                                       #P Create a new multi-way tree node.
 {my () = @_;                                                                   # Key, $data, parent node, index of link from parent node
  genHash(__PACKAGE__,                                                          # Multi tree node
    up    => undef,                                                             # Parent node
    keys  => [],                                                                # Array of key items for this node
    data  => [],                                                                # Data corresponding to each key
    node  => [],                                                                # Child nodes
   );
 }

sub minimumNumberOfKeys()                                                       #P Minimum number of keys per node.
 {int(($numberOfKeysPerNode - 1) / 2)
 }

sub maximumNumberOfKeys()                                                       #P Maximum number of keys per node.
 {$numberOfKeysPerNode
 }

sub maximumNumberOfNodes()                                                      #P Maximum number of children per parent.
 {$numberOfKeysPerNode + 1
 }

sub full($)                                                                     #P Confirm that a node is full.
 {my ($tree) = @_;                                                              # Tree
  @_ == 1 or confess;
  my $n = $tree->keys->@*;
  $n <= maximumNumberOfKeys or confess "Keys";
  $n == maximumNumberOfKeys
 }

sub halfFull($)                                                                 #P Confirm that a node is half full.
 {my ($tree) = @_;                                                              # Tree
  @_ == 1 or confess;
  my $n = $tree->keys->@*;
  $n <= maximumNumberOfKeys+1 or confess "Keys";
  $n == minimumNumberOfKeys
 }

sub root($)                                                                     # Return the root node of a tree.
 {my ($tree) = @_;                                                              # Tree
  confess unless $tree;
  for(; $tree->up; $tree = $tree->up) {}
  $tree
 }

sub leaf($)                                                                     # Confirm that the tree is a leaf.
 {my ($tree) = @_;                                                              # Tree
  @_ == 1 or confess;
  !scalar $tree->node->@*                                                       # No children so it must be a leaf
 }

sub reUp($$)                                                                    #P Reconnect the children to their new parent.
 {my ($tree, $children) = @_;                                                   # Tree, children
  @_ > 0 or confess;
  $tree->keys->@* <= maximumNumberOfKeys or confess "Keys";
  $_->up = $tree for @$children;                                                # Connect child to parent
 }

sub splitFullNode($$$)                                                          #P Split a node if it is full.
 {my ($isRoot, $isLeaf, $node) = @_;                                            # Known to be the root if true, known to be a leaf if true, node to split
  @_ == 3 or confess;

  if (1)                                                                        # Check number of keys
   {my $c = $node->keys->@*;                                                    # Number of keys
    confess if    $c  > maximumNumberOfKeys;                                    # Complain about over full nodes
    return unless $c == maximumNumberOfKeys;                                    # Only split full nodes
   }

  my ($p, $l, $r) = ($node->up // $node, new, new);                             # New child nodes
  $l->up = $r->up = $p;                                                         # Connect children to parent

  my @k = $node->keys->@*;
  my @d = $node->data->@*;

  my $N = int maximumNumberOfNodes / 2;                                         # Split points
  my $n =     maximumNumberOfKeys % 2 == 0 ? $N - 1 : $N - 2;

  $l->keys = [@k[0..$n]];                                                       # Split keys
  $l->data = [@d[0..$n]];                                                       # Split data
  $r->keys = [@k[$n+2..$#k]];
  $r->data = [@d[$n+2..$#k]];

  if (!$isLeaf)                                                                 # Not a leaf node
   {my @n = $node->node->@*;
    reUp $l, $l->node = [@n[0   ..$n+1]];
    reUp $r, $r->node = [@n[$n+2..$#n ]];
   }

  if (!$isRoot)                                                                 # Not a root node
   {my @n = $p->node->@*;                                                       # Insert new nodes in parent known to be not full
    for my $i(keys @n)                                                          # Each parent node
     {if ($n[$i] == $node)                                                      # Find the node that points from the parent to the current node
       {splice $p->keys->@*, $i, 0, $k[$n+1];                                   # Insert splitting key
        splice $p->data->@*, $i, 0, $d[$n+1];                                   # Insert data associated with splitting key
        splice $p->node->@*, $i, 1, $l, $r;                                     # Insert offsets on either side of the splitting key
        return;                                                                 #
       }
     }
    confess "Should not happen";
   }
  else                                                                          # Root node with single key after split
   {$node->keys = [$k[$n+1]];                                                   # Single key
    $node->data = [$d[$n+1]];                                                   # Data associated with single key
    $node->node = [$l, $r];                                                     # Nodes on either side of single key
   }
 }

sub findAndSplit($$)                                                            #P Find a key in a tree splitting full nodes along the path to the key.
 {my ($root, $key) = @_;                                                        # Root of tree, key
  @_ == 2 or confess;

  my $tree = $root;                                                             # Start at the root

  splitFullNode 1, !scalar($tree->node->@*), $tree;                             # Split the root node if necessary

  for(0..999)                                                                   # Step down through the tree
   {confess unless my @k = $tree->keys->@*;                                     # We should have at least one key in the tree because we do a special case insert for an empty tree

    if ($key < $k[0])                                                           # Less than smallest key in node
     {return (-1, $tree, 0)    unless my $n = $tree->node->[0];
      $tree = $n;
      next;
     }

    if ($key > $k[-1])                                                          # Greater than largest key in node
     {return (+1, $tree, $#k)  unless my $n = $tree->node->[-1];
      $tree = $n;
      next;
     }

    for my $i(keys @k)                                                          # Search the keys in this node as greater than least key and less than largest key
     {my $s = $key <=> $k[$i];                                                  # Compare key
      if ($s == 0)                                                              # Found key
       {return (0, $tree, $i);
       }
      elsif ($s < 0)                                                            # Less than current key
       {return (-1, $tree, $i) unless my $n = $tree->node->[$i];                # Step through if possible
        $tree = $n;                                                             # Step
        last;
       }
     }
   }
  continue {splitFullNode 0, 0, $tree}                                          # Split the node we have stepped to

  confess "Should not happen";
 }

sub find($$)                                                                    # Find a key in a tree returning its associated data or undef if the key does not exist.
 {my ($root, $key) = @_;                                                        # Root of tree, key
  @_ == 2 or confess;

  my $tree = $root;                                                             # Start at the root

  for(0..999)                                                                   # Step down through the tree
   {return undef unless my @k   = $tree->keys->@*;                              # Empty node

    if ($key < $k[0])                                                           # Less than smallest key in node
     {return undef unless $tree = $tree->node->[0];
      next;
     }

    if ($key > $k[-1])                                                          # Greater than largest key in node
     {return undef unless $tree = $tree->node->[-1];
      next;
     }

    for my $i(keys @k)                                                          # Search the keys in this node
     {my $s = $key <=> $k[$i];                                                  # Compare key
      return $tree->data->[$i] if $s == 0;                                      # Found key
      if ($s < 0)                                                               # Less than current key
       {return undef unless $tree = $tree->node->[$i];
        last;
       }
     }
   }

  confess "Should not happen";
 }

sub indexInParent($)                                                            #P Get the index of a node in its parent.
 {my ($tree) = @_;                                                              # Tree
  @_ == 1 or confess; confess unless my $p = $tree->up;

  my @n = $p->node->@*;  for my $i(keys @n) {return $i if $n[$i] == $tree}
  confess "Should not happen";
 }

sub fillFromLeftOrRight($$)                                                     #P Fill a node from the specified sibling.
 {my ($node, $dir) = @_;                                                        # Node to fill, node to fill from 0 for left or 1 for right
  @_ == 2 or confess;

  confess unless my $p = $node->up;                                             # Parent of leaf
  my $i = indexInParent $node;                                                  # Index of leaf in parent

  if ($dir)                                                                     # Fill from right
   {$i < $p->node->@* - 1 or confess;                                           # Cannot fill from right
    my $r = $p->node->[$i+1];                                                   # Right sibling
    push $node->keys->@*, $p->keys->[$i]; $p->keys->[$i] = shift $r->keys->@*;  # Transfer key
    push $node->data->@*, $p->data->[$i]; $p->data->[$i] = shift $r->data->@*;  # Transfer data
    if (!leaf $node)                                                            # Transfer node if not a leaf
     {push $node->node->@*, shift $r->node->@*;
      $node->node->[-1]->up = $node;
     }
   }
  else                                                                          # Fill from left
   {$i > 0 or confess;                                                          # Cannot fill from left
    my $I = $i-1;
    my $n = $p->node->[$I];                                                     # Left sibling
    my $k = $p->keys; my $d = $p->data;
    unshift $node->keys->@*, $k->[$I]; $k->[$I] = pop $n->keys->@*;             # Transfer key
    unshift $node->data->@*, $d->[$I]; $d->[$I] = pop $n->data->@*;             # Transfer data
    if (!leaf $node)                                                            # Transfer node if not a leaf
     {unshift $node->node->@*, pop $n->node->@*;
      $node->node->[0]->up = $node;
     }
   }
 }

sub mergeWithLeftOrRight($$)                                                    #P Merge two adjacent nodes.
 {my ($n, $dir) = @_;                                                           # Node to merge into, node to merge is on right if 1 else left
  @_ == 2 or confess;

  confess unless    halfFull($n);                                               # Confirm leaf is half full
  confess unless my $p = $n->up;                                                # Parent of leaf
  confess if        halfFull($p) and $p->up;                                    # Parent must have more than the minimum number of keys because we need to remove one unless it is the root of the tree

  my $i = indexInParent $n;                                                     # Index of leaf in parent

  if ($dir)                                                                     # Merge with right hand sibling
   {$i < $p->node->@* - 1 or confess;                                           # Cannot fill from right
    my $I = $i+1;
    my $r = $p->node->[$I];                                                     # Leaf on right
    confess unless halfFull($r);                                                # Confirm right leaf is half full
    push $n->keys->@*, splice($p->keys->@*, $i, 1), $r->keys->@*;               # Transfer keys
    push $n->data->@*, splice($p->data->@*, $i, 1), $r->data->@*;               # Transfer data
    if (!leaf $n)                                                               # Children of merged node
     {push $n->node->@*, $r->node->@*;                                          # Children of merged node
      reUp $n, $r->node;                                                        # Update parent of children of right node
     }
    splice $p->node->@*, $I, 1;                                                 # Remove link from parent to right child
   }
  else                                                                          # Merge with left hand sibling
   {$i > 0 or confess;                                                          # Cannot fill from left
    my $I = $i-1;
    my $l = $p->node->[$I];                                                     # Node on left
    confess unless halfFull($l);                                                # Confirm right leaf is half full
    unshift $n->keys->@*, $l->keys->@*, splice $p->keys->@*, $I, 1;             # Transfer keys
    unshift $n->data->@*, $l->data->@*, splice $p->data->@*, $I, 1;             # Transfer data
    if (!leaf $n)                                                               # Children of merged node
     {unshift $n->node->@*, $l->node->@*;                                       # Children of merged node
      reUp $n, $l->node;                                                        # Update parent of children of left node
     }
    splice $p->node->@*, $I, 1;                                                 # Remove link from parent to left child
   }
 }

sub merge($)                                                                    #P Merge the current node with its sibling.
 {my ($tree) = @_;                                                              # Tree
  if (my $i = indexInParent $tree)                                              # Merge with left node
   {my $l = $tree->up->node->[$i-1];                                            # Left node
    if (halfFull(my $r = $tree))
     {$l->halfFull ? mergeWithLeftOrRight $r, 0 : fillFromLeftOrRight $r, 0;    # Merge as left and right nodes are half full
     }
   }
  else
   {my $r = $tree->up->node->[1];                                               # Right node
    if (halfFull(my $l = $tree))
     {halfFull($r) ? mergeWithLeftOrRight $l, 1 : fillFromLeftOrRight $l, 1;    # Merge as left and right nodes are half full
     }
   }
 }

sub mergeOrFill($)                                                              #P Make a node larger than a half node.
 {my ($tree) = @_;                                                              # Tree
  @_ == 1 or confess;

  return  unless halfFull($tree);                                               # No need to merge of if not a half node
  confess unless my $p = $tree->up;                                             # Parent exists

  if ($p->up)                                                                   # Merge or fill parent which is not the root
   {__SUB__->($p);
    merge($tree);
   }
  elsif ($p->keys->@* == 1 and halfFull(my $l = $p->node->[0])                  # Parent is the root and it only has one key - merge into the child if possible
                           and halfFull(my $r = $p->node->[1]))
   {$p->keys = $tree->keys = [$l->keys->@*, $p->keys->@*, $r->keys->@*];        # Merge in place to retain addressability
    $p->data = $tree->data = [$l->data->@*, $p->data->@*, $r->data->@*];
    $p->node = $tree->node = [$l->node->@*,               $r->node->@*];

    reUp $p, $p->node;                                                          # Reconnect children to parent
   }
  else                                                                          # Parent is the root but it has too may keys to merge into both sibling so merge with a sibling if possible
   {merge($tree);
   }
 }

sub leftMost($)                                                                 # Return the left most node below the specified one.
 {my ($tree) = @_;                                                              # Tree
  for(0..999)                                                                   # Step down through tree
   {return $tree if leaf $tree;                                                 # We are on a leaf so we have arrived at the left most node
    $tree = $tree->node->[0];                                                   # Go left
   }
  confess "Should not happen";
 }

sub rightMost($)                                                                # Return the right most node below the specified one.
 {my ($tree) = @_;                                                              # Tree
  for(0..999)                                                                   # Step down through tree
   {return $tree if leaf $tree;                                                 # We are on a leaf so we have arrived at the left most node
    $tree = $tree->node->[-1];                                                  # Go right
   }
  confess "Should not happen";
 }

sub height($)                                                                   # Return the height of the tree.
 {my ($tree) = @_;                                                              # Tree
  for my $n(0..999)                                                             # Step down through tree
   {if (leaf $tree)                                                             # We are on a leaf
     {return $n + 1 if $tree->keys->@*;                                         # We are in a partially full leaf
      return $n;                                                                # We are on the root and it is empty
     }
    $tree = $tree->node->[0];
   }
  confess "Should not happen";
 }

sub depth($)                                                                    # Return the depth of a node within a tree.
 {my ($tree) = @_;                                                              # Tree
  return 0 if !$tree->up and !$tree->keys->@*;                                  # We are at the root and it is empty
  for my $n(1..999)                                                             # Step down through tree
   {return $n  unless $tree->up;                                                # We are at the root
    $tree = $tree->up;
   }
  confess "Should not happen";
 }

sub deleteLeafKey($$)                                                           #P Delete a key in a leaf.
 {my ($tree, $i) = @_;                                                          # Tree, index to delete at
  @_ == 2 or confess;
  confess "Not a leaf" unless leaf $tree;
  my $key = $tree->keys->[$i];
  mergeOrFill $tree if $tree->up;                                               # Merge and fill unless we are on the root and the root is a leaf
  my $k = $tree->keys;
  for my $j(keys @$k)                                                            # Search for key to delete
   {if ($$k[$j] == $key)
     {splice $tree->keys->@*, $j, 1;                                            # Remove keys
      splice $tree->data->@*, $j, 1;                                            # Remove data
      return;
     }
   }
 }

sub deleteKey($$)                                                               #P Delete a key.
 {my ($tree, $i) = @_;                                                          # Tree, index to delete at
  @_ == 2 or confess;
  if (leaf $tree)                                                               # Delete from a leaf
   {deleteLeafKey($tree, $i);
   }
  elsif ($i > 0)                                                                # Delete from a node
   {my $l = rightMost $tree->node->[$i];                                        # Find previous node
    splice  $tree->keys->@*, $i, 1, $l->keys->[-1];
    splice  $tree->data->@*, $i, 1, $l->data->[-1];
    deleteLeafKey $l, -1 + scalar $l->keys->@*;                                 # Remove leaf key
   }
  else                                                                          # Delete from a node
   {my $r = leftMost $tree->node->[1];                                          # Find previous node
    splice  $tree->keys->@*,  0, 1, $r->keys->[0];
    splice  $tree->data->@*,  0, 1, $r->data->[0];
    deleteLeafKey $r, 0;                                                        # Remove leaf key
   }
 }

sub delete($$)                                                                  # Find a key in a tree, delete it and return any associated data.
 {my ($root, $key) = @_;                                                        # Tree root, key
  @_ == 2 or confess;

  my $tree = $root;
  for (0..999)
   {my $k = $tree->keys;

    if ($key < $$k[0])                                                          # Less than smallest key in node
     {return undef unless $tree = $tree->node->[0];
     }
    elsif ($key > $$k[-1])                                                      # Greater than largest key in node
     {return undef unless $tree = $tree->node->[-1];
     }
    else
     {for my $i(keys @$k)                                                       # Search the keys in this node
       {if ((my  $s = $key <=> $$k[$i]) == 0)                                   # Delete found key
         {my $d = $tree->data->[$i];                                            # Save data
          deleteKey $tree, $i;                                                  # Delete the key
          return $d;                                                            # Return data associated with key
         }
        elsif ($s < 0)                                                          # Less than current key
         {return undef unless $tree = $tree->node->[$i];
          last;
         }
       }
     }
   }
  confess "Should not happen";
 }

sub insert($$$)                                                                 # Insert the specified key and data into a tree.
 {my ($tree, $key, $data) = @_;                                                 # Tree, key, data
  @_ == 3 or confess;

  if (!(my $n = $tree->keys->@*))                                               # Empty tree
   {push $tree->keys->@*, $key;
    push $tree->data->@*, $data;
    return $tree;
   }
  elsif ($n < maximumNumberOfKeys and $tree->node->@* == 0)                     # Node is root with no children and room for one more key
   {my $k = $tree->keys;
    for my $i(reverse keys @$k)                                                 # Each key - in reverse due to the preponderance of already sorted data
     {if ((my $s = $key <=> $$k[$i]) == 0)                                      # Key already present
       {$tree->data->[$i]= $data;
        return;
       }
      elsif ($s > 0)                                                            # Insert before greatest smaller key
       {my $I = $i + 1;
        splice $tree->keys->@*, $I, 0, $key;
        splice $tree->data->@*, $I, 0, $data;
        return;
       }
     }
    unshift $tree->keys->@*, $key;                                              # Insert the key at the start of the block because it is less than all the other keys in the block
    unshift $tree->data->@*, $data;
   }
  else                                                                          # Insert node
   {my ($compare, $node, $index) = findAndSplit $tree, $key;                    # Check for existing key

    if ($compare == 0)                                                          # Found an equal key whose data we can update
     {$node->data->[$index] = $data;
     }
    else                                                                        # We have room for the insert
     {++$index if $compare > 0;                                                 # Position at which to insert new key
      splice $node->keys->@*, $index, 0, $key;
      splice $node->data->@*, $index, 0, $data;
      splitFullNode 0, 1, $node                                                 # Split if the leaf is full to force keys up the tree
     }
   }
 }

sub iterator($)                                                                 # Make an iterator for a tree.
 {my ($tree) = @_;                                                              # Tree
  @_ == 1 or confess;
  my $i = genHash(__PACKAGE__.'::Iterator',                                     # Iterator
    tree  => $tree,                                                             # Tree we are iterating over
    node  => $tree,                                                             # Current node within tree
    pos   => undef,                                                             # Current position within node
    key   => undef,                                                             # Key at this position
    data  => undef,                                                             # Data at this position
    count => 0,                                                                 # Counter
    more  => 1,                                                                 # Iteration not yet finished
   );
  $i->next;                                                                     # First element if any
  $i                                                                            # Iterator
 }

sub Tree::Multi::Iterator::next($)                                              # Find the next key.
 {my ($iter) = @_;                                                              # Iterator
  @_ == 1 or confess;
  confess unless my $C = $iter->node;                                           # Current node required

  ++$iter->count;                                                               # Count the calls to the iterator

  my $new  = sub                                                                # Load iterator with latest position
   {my ($node, $pos) = @_;                                                      # Parameters
    $iter->node = $node;
    $iter->pos  = $pos //= 0;
    $iter->key  = $node->keys->[$pos];
    $iter->data = $node->data->[$pos]
   };

  my $done = sub {$iter->more = undef};                                         # The tree has been completely traversed

  if (!defined($iter->pos))                                                     # Initial descent
   {my $l = $C->node->[0];
    return $l ? &$new($l->leftMost) : $C->keys->@* ? &$new($C) : &$done;        # Start node or done if empty tree
   }

  my $up = sub                                                                  # Iterate up to next node that has not been visited
   {for(my $n = $C; my $p = $n->up; $n = $p)
     {my $i = indexInParent $n;
      return &$new($p, $i) if $i < $p->keys->@*;
     }
    &$done                                                                      # No nodes not visited
   };

  my $i = ++$iter->pos;
  if (leaf $C)                                                                  # Leaf
   {$i < $C->keys->@* ? &$new($C, $i) : &$up;
   }
  else                                                                          # Node
   {&$new($C->node->[$i]->leftMost)
   }
 }

sub reverseIterator($)                                                          # Create a reverse iterator for a tree.
 {my ($tree) = @_;                                                              # Tree
  @_ == 1 or confess;
  my $i = genHash(__PACKAGE__.'::ReverseIterator',                              # Iterator
    tree  => root($tree),                                                       # Tree we are iterating over
    node  => $tree,                                                             # Current node within tree
    pos   => undef,                                                             # Current position within node
    key   => undef,                                                             # Key at this position
    data  => undef,                                                             # Data at this position
    count => 0,                                                                 # Counter
    less  => 1,                                                                 # Iteration not yet finished
   );
  $i->prev;                                                                     # Last element if any
  $i                                                                            # Iterator
 }

sub Tree::Multi::ReverseIterator::prev($)                                       # Find the previous key.
 {my ($iter) = @_;                                                              # Iterator
  @_ == 1 or confess;
  confess unless my $C = $iter->node;                                           # Current node required

  ++$iter->count;                                                               # Count the calls to the iterator

  my $new  = sub                                                                # Load iterator with latest position
   {my ($node, $pos) = @_;                                                      # Parameters
    $iter->node = $node;
    $iter->pos  = $pos //= ($node->keys->@* - 1);
    $iter->key  = $node->keys->[$pos];
    $iter->data = $node->data->[$pos]
   };

  my $done = sub {$iter->less = undef};                                         # The tree has been completely traversed

  if (!defined($iter->pos))                                                     # Initial descent
   {my $l = $C->node->[-1];
    return $l ? &$new($l->rightMost) : $C->keys->@* ? &$new($C) : &$done;       # Start node or done if empty tree
    return;
   }

  my $up = sub                                                                  # Iterate up to next node that has not been visited
   {for(my $n = $C; my $p = $n->up; $n = $p)
     {my $i = indexInParent $n;
      return &$new($p, $i-1) if $i > 0;
     }
    &$done                                                                      # No nodes not visited
   };

  my $i = $iter->pos;
  if (leaf $C)                                                                  # Leaf
   {$i > 0 ?  &$new($C, $i-1) : &$up;
   }
  else                                                                          # Node
   {$i >= 0 ? &$new($C->node->[$i]->rightMost) : &$up
   }
 }

sub flat($@)                                                                    # Print the keys in a tree from left right to make it easier to visualize the structure of the tree.
 {my ($tree, @title) = @_;                                                      # Tree, title
  confess unless $tree;
  my @s;                                                                        # Print
  my $D;                                                                        # Deepest
  for(my $i = iterator root $tree; $i->more; $i->next)                          # Traverse tree
   {my $d = depth $i->node;
    $D = $d unless $D and $D > $d;
    $s[$d] //= '';
    $s[$d]  .= "   ".$i->key;                                                   # Add key at appropriate depth
    my $l = length $s[$d];
    for my $j(0..$D)                                                            # Pad all strings to the current position
     {my $s = $s[$j] //= '';
      $s[$j] = substr($s.(' 'x999), 0, $l) if length($s) < $l;
     }
   }
  for my $i(keys @s)                                                            # Clean up trailing blanks so that tests are not affected by spurious white space mismatches
   {$s[$i] =~ s/\s+\n/\n/gs;
    $s[$i] =~ s/\s+\Z//gs;
   }
  unshift @s, join(' ', @title) if @title;                                      # Add title
  join "\n", @s, '';
 }

sub print($;$)                                                                  # Print the keys in a tree optionally marking the active key.
 {my ($tree, $i) = @_;                                                          # Tree, optional index of active key
  confess unless $tree;
  my @s;                                                                        # Print

  my $print = sub                                                               # Print a node
   {my ($t, $in) = @_;
    return unless $t and $t->keys and $t->keys->@*;

    my @t = ('  'x$in);                                                         # Print keys staring the active key if known
    for my $j(keys $t->keys->@*)
     {push @t, $t->keys->[$j];
      push @t, '<=' if defined($i) and $i == $j and $tree == $t;
     }
    push @s, join ' ', @t;                                                      # Details of one node

    if (my $nodes = $t->node)                                                   # Each key
     {__SUB__->($_, $in+1) for $nodes->@*;
     }
   };

  &$print(root($tree), 0);                                                      # Print tree

  join "\n", @s, ''
 }

sub size($)                                                                     # Count the number of keys in a tree.
 {my ($tree) = @_;                                                              # Tree
  @_ == 1 or confess;
  my $n = 0;                                                                    # Print

  my $count = sub                                                               # Print a node
   {my ($t) = @_;
    return unless $t and $t->keys and my @k = $t->keys->@*;
    $n += @k;
    if (my $nodes = $t->node)                                                   # Each key
     {__SUB__->($_) for $nodes->@*;
     }
   };

  &$count(root $tree);                                                          # Count nodes in tree

  $n;
 }

#d
#-------------------------------------------------------------------------------
# Export - eeee
#-------------------------------------------------------------------------------

use Exporter qw(import);

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

@ISA          = qw(Exporter);
@EXPORT       = qw();
@EXPORT_OK    = qw(
 );
%EXPORT_TAGS = (all=>[@EXPORT, @EXPORT_OK]);

# podDocumentation
=pod

=encoding utf-8

=head1 Name

Tree::Multi - Multi-way tree in Pure Perl with an even or odd number of keys per node.

=head1 Synopsis

Construct and query a multi-way tree in B<100%> Pure Perl with a choice of an
odd or an even numbers of keys per node:

  local $Tree::Multi::numberOfKeysPerNode = 4;  # Number of keys per node - can be even

  my $t = Tree::Multi::new;                     # Construct tree
     $t->insert($_, 2 * $_) for reverse 1..32;  # Load tree in reverse

  is_deeply $t->print, <<END;
 15 21 27
   3 6 9 12
     1 2
     4 5
     7 8
     10 11
     13 14
   18
     16 17
     19 20
   24
     22 23
     25 26
   30
     28 29
     31 32
END

  ok  $t->height     ==  3;                     # Height

  ok  $t->find  (16) == 32;                     # Find by key
      $t->delete(16);                           # Delete a key
  ok !$t->find  (16);                           # Key no longer present


  ok  $t->find  (17) == 34;                     # Find by key
  my @k;
  for(my $i = $t->iterator; $i->more; $i->next) # Iterator
   {push @k, $i->key unless $i->key == 17;
   }

  $t->delete($_) for @k;                        # Delete

  ok $t->find(17) == 34 && $t->size == 1;       # Size

=head1 Description

Multi-way tree in Pure Perl with an even or odd number of keys per node.


Version "20210614".


The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.



=head1 Multi-way Tree

Create and use a multi-way tree.

=head2 root($tree)

Return the root node of a tree.

     Parameter  Description
  1  $tree      Tree

B<Example:>


    local $numberOfKeysPerNode = 3; my $N = 13; my $t = new;

    for my $n(1..$N)
     {$t->insert($n, $n);
     }

    ok T($t, <<END);
   4 8
     2
       1
       3
     6
       5
       7
     10 12
       9
       11
       13
  END

    is_deeply $t->leftMost ->keys, [1];
    is_deeply $t->rightMost->keys, [13];
    ok $t->leftMost ->leaf;
    ok $t->rightMost->leaf;

    ok $t->root == $t;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲



=head2 leaf($tree)

Confirm that the tree is a leaf.

     Parameter  Description
  1  $tree      Tree

B<Example:>


    local $numberOfKeysPerNode = 3; my $N = 13; my $t = new;

    for my $n(1..$N)
     {$t->insert($n, $n);
     }

    ok T($t, <<END);
   4 8
     2
       1
       3
     6
       5
       7
     10 12
       9
       11
       13
  END

    is_deeply $t->leftMost ->keys, [1];
    is_deeply $t->rightMost->keys, [13];

    ok $t->leftMost ->leaf;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    ok $t->rightMost->leaf;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    ok $t->root == $t;


=head2 find($root, $key)

Find a key in a tree returning its associated data or undef if the key does not exist.

     Parameter  Description
  1  $root      Root of tree
  2  $key       Key

B<Example:>


    local $Tree::Multi::numberOfKeysPerNode = 4;                                  # Number of keys per node - can be even

    my $t = Tree::Multi::new;                                                     # Construct tree
       $t->insert($_, 2 * $_) for reverse 1..32;                                  # Load tree in reverse

    T($t, <<END);
   17 25
     9 13
       3 5 7
         1 2
         4
         6
         8
       11
         10
         12
       15
         14
         16
     21
       19
         18
         20
       23
         22
         24
     29
       27
         26
         28
       31
         30
         32
  END

    ok  $t->size       == 32;                                                     # Size
    ok  $t->height     ==  4;                                                     # Height
    ok  $t->delete(16) == 2 * 16;                                                 # Delete a key

    ok !$t->find  (16);                                                           # Key no longer present  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    ok  $t->find  (17) == 34;                                                     # Find by key  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    my @k;
    for(my $i = $t->iterator; $i->more; $i->next)                                 # Iterator
     {push @k, $i->key unless $i->key == 17;
     }

    ok $t->delete($_) == 2 * $_ for @k;                                           # Delete


    ok $t->find(17) == 34 && $t->size == 1;                                       # Size  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    local $Tree::Multi::numberOfKeysPerNode = 3;                                  # Number of keys per node - can be even

    my $t = Tree::Multi::new;                                                     # Construct tree
       $t->insert($_, $_) for 1..8;

    T($t, <<END, 1);

                 4
         2               6
     1       3       5       7   8
  END

    local $Tree::Multi::numberOfKeysPerNode = 14;                                 # Number of keys per node - can be even

    my $t = Tree::Multi::new;                                                     # Construct tree
       $t->insert($_, $_) for 1..15;

    T($t, <<END, 1);

                                 8
     1   2   3   4   5   6   7       9   10   11   12   13   14   15
  END


=head2 leftMost($tree)

Return the left most node below the specified one.

     Parameter  Description
  1  $tree      Tree

B<Example:>


    local $numberOfKeysPerNode = 3; my $N = 13; my $t = new;

    for my $n(1..$N)
     {$t->insert($n, $n);
     }

    ok T($t, <<END);
   4 8
     2
       1
       3
     6
       5
       7
     10 12
       9
       11
       13
  END


    is_deeply $t->leftMost ->keys, [1];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply $t->rightMost->keys, [13];

    ok $t->leftMost ->leaf;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    ok $t->rightMost->leaf;
    ok $t->root == $t;


=head2 rightMost($tree)

Return the right most node below the specified one.

     Parameter  Description
  1  $tree      Tree

B<Example:>


    local $numberOfKeysPerNode = 3; my $N = 13; my $t = new;

    for my $n(1..$N)
     {$t->insert($n, $n);
     }

    ok T($t, <<END);
   4 8
     2
       1
       3
     6
       5
       7
     10 12
       9
       11
       13
  END

    is_deeply $t->leftMost ->keys, [1];

    is_deeply $t->rightMost->keys, [13];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    ok $t->leftMost ->leaf;

    ok $t->rightMost->leaf;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    ok $t->root == $t;


=head2 height($tree)

Return the height of the tree.

     Parameter  Description
  1  $tree      Tree

B<Example:>


    local $Tree::Multi::numberOfKeysPerNode = 3;

    my $t = new;      ok $t->height == 0; ok $t->leftMost->depth == 0; ok $t->size == 0;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    $t->insert(1, 1); ok $t->height == 1; ok $t->leftMost->depth == 1; ok $t->size == 1;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    $t->insert(2, 2); ok $t->height == 1; ok $t->leftMost->depth == 1; ok $t->size == 2;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    $t->insert(3, 3); ok $t->height == 1; ok $t->leftMost->depth == 1; ok $t->size == 3;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    $t->insert(4, 4); ok $t->height == 2; ok $t->leftMost->depth == 2; ok $t->size == 4;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    $t->insert(5, 5); ok $t->height == 2; ok $t->leftMost->depth == 2; ok $t->size == 5;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    $t->insert(6, 6); ok $t->height == 2; ok $t->leftMost->depth == 2; ok $t->size == 6;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    $t->insert(7, 7); ok $t->height == 2; ok $t->leftMost->depth == 2; ok $t->size == 7;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    $t->insert(8, 8); ok $t->height == 3; ok $t->leftMost->depth == 3; ok $t->size == 8;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    T($t, <<END, 1);

                 4
         2               6
     1       3       5       7   8
  END



=head2 depth($tree)

Return the depth of a node within a tree.

     Parameter  Description
  1  $tree      Tree

B<Example:>


    local $Tree::Multi::numberOfKeysPerNode = 3;

    my $t = new;      ok $t->height == 0; ok $t->leftMost->depth == 0; ok $t->size == 0;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    $t->insert(1, 1); ok $t->height == 1; ok $t->leftMost->depth == 1; ok $t->size == 1;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    $t->insert(2, 2); ok $t->height == 1; ok $t->leftMost->depth == 1; ok $t->size == 2;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    $t->insert(3, 3); ok $t->height == 1; ok $t->leftMost->depth == 1; ok $t->size == 3;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    $t->insert(4, 4); ok $t->height == 2; ok $t->leftMost->depth == 2; ok $t->size == 4;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    $t->insert(5, 5); ok $t->height == 2; ok $t->leftMost->depth == 2; ok $t->size == 5;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    $t->insert(6, 6); ok $t->height == 2; ok $t->leftMost->depth == 2; ok $t->size == 6;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    $t->insert(7, 7); ok $t->height == 2; ok $t->leftMost->depth == 2; ok $t->size == 7;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    $t->insert(8, 8); ok $t->height == 3; ok $t->leftMost->depth == 3; ok $t->size == 8;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    T($t, <<END, 1);

                 4
         2               6
     1       3       5       7   8
  END



=head2 delete($root, $key)

Find a key in a tree, delete it and return any associated data.

     Parameter  Description
  1  $root      Tree root
  2  $key       Key

B<Example:>


    local $Tree::Multi::numberOfKeysPerNode = 4;                                  # Number of keys per node - can be even

    my $t = Tree::Multi::new;                                                     # Construct tree
       $t->insert($_, 2 * $_) for reverse 1..32;                                  # Load tree in reverse

    T($t, <<END);
   17 25
     9 13
       3 5 7
         1 2
         4
         6
         8
       11
         10
         12
       15
         14
         16
     21
       19
         18
         20
       23
         22
         24
     29
       27
         26
         28
       31
         30
         32
  END

    ok  $t->size       == 32;                                                     # Size
    ok  $t->height     ==  4;                                                     # Height

    ok  $t->delete(16) == 2 * 16;                                                 # Delete a key  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    ok !$t->find  (16);                                                           # Key no longer present
    ok  $t->find  (17) == 34;                                                     # Find by key

    my @k;
    for(my $i = $t->iterator; $i->more; $i->next)                                 # Iterator
     {push @k, $i->key unless $i->key == 17;
     }


    ok $t->delete($_) == 2 * $_ for @k;                                           # Delete  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    ok $t->find(17) == 34 && $t->size == 1;                                       # Size

    local $Tree::Multi::numberOfKeysPerNode = 3;                                  # Number of keys per node - can be even

    my $t = Tree::Multi::new;                                                     # Construct tree
       $t->insert($_, $_) for 1..8;

    T($t, <<END, 1);

                 4
         2               6
     1       3       5       7   8
  END

    local $Tree::Multi::numberOfKeysPerNode = 14;                                 # Number of keys per node - can be even

    my $t = Tree::Multi::new;                                                     # Construct tree
       $t->insert($_, $_) for 1..15;

    T($t, <<END, 1);

                                 8
     1   2   3   4   5   6   7       9   10   11   12   13   14   15
  END


=head2 insert($tree, $key, $data)

Insert the specified key and data into a tree.

     Parameter  Description
  1  $tree      Tree
  2  $key       Key
  3  $data      Data

B<Example:>


    local $Tree::Multi::numberOfKeysPerNode = 4;                                  # Number of keys per node - can be even

    my $t = Tree::Multi::new;                                                     # Construct tree

       $t->insert($_, 2 * $_) for reverse 1..32;                                  # Load tree in reverse  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    T($t, <<END);
   17 25
     9 13
       3 5 7
         1 2
         4
         6
         8
       11
         10
         12
       15
         14
         16
     21
       19
         18
         20
       23
         22
         24
     29
       27
         26
         28
       31
         30
         32
  END

    ok  $t->size       == 32;                                                     # Size
    ok  $t->height     ==  4;                                                     # Height
    ok  $t->delete(16) == 2 * 16;                                                 # Delete a key
    ok !$t->find  (16);                                                           # Key no longer present
    ok  $t->find  (17) == 34;                                                     # Find by key

    my @k;
    for(my $i = $t->iterator; $i->more; $i->next)                                 # Iterator
     {push @k, $i->key unless $i->key == 17;
     }

    ok $t->delete($_) == 2 * $_ for @k;                                           # Delete

    ok $t->find(17) == 34 && $t->size == 1;                                       # Size

    local $Tree::Multi::numberOfKeysPerNode = 3;                                  # Number of keys per node - can be even

    my $t = Tree::Multi::new;                                                     # Construct tree

       $t->insert($_, $_) for 1..8;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    T($t, <<END, 1);

                 4
         2               6
     1       3       5       7   8
  END

    local $Tree::Multi::numberOfKeysPerNode = 14;                                 # Number of keys per node - can be even

    my $t = Tree::Multi::new;                                                     # Construct tree

       $t->insert($_, $_) for 1..15;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    T($t, <<END, 1);

                                 8
     1   2   3   4   5   6   7       9   10   11   12   13   14   15
  END


=head2 iterator($tree)

Make an iterator for a tree.

     Parameter  Description
  1  $tree      Tree

B<Example:>


    local $numberOfKeysPerNode = 3; my $N = 256; my $e = 0;  my $t = new;

    for my $n(0..$N)
     {$t->insert($n, $n);

      my @n; for(my $i = $t->iterator; $i->more; $i->next) {push @n, $i->key}  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ++$e unless dump(\@n) eq dump [0..$n];
     }

    is_deeply $e, 0;

    local $Tree::Multi::numberOfKeysPerNode = 4;                                  # Number of keys per node - can be even

    my $t = Tree::Multi::new;                                                     # Construct tree
       $t->insert($_, 2 * $_) for reverse 1..32;                                  # Load tree in reverse

    T($t, <<END);
   17 25
     9 13
       3 5 7
         1 2
         4
         6
         8
       11
         10
         12
       15
         14
         16
     21
       19
         18
         20
       23
         22
         24
     29
       27
         26
         28
       31
         30
         32
  END

    ok  $t->size       == 32;                                                     # Size
    ok  $t->height     ==  4;                                                     # Height
    ok  $t->delete(16) == 2 * 16;                                                 # Delete a key
    ok !$t->find  (16);                                                           # Key no longer present
    ok  $t->find  (17) == 34;                                                     # Find by key

    my @k;

    for(my $i = $t->iterator; $i->more; $i->next)                                 # Iterator  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     {push @k, $i->key unless $i->key == 17;
     }

    ok $t->delete($_) == 2 * $_ for @k;                                           # Delete

    ok $t->find(17) == 34 && $t->size == 1;                                       # Size

    local $Tree::Multi::numberOfKeysPerNode = 3;                                  # Number of keys per node - can be even

    my $t = Tree::Multi::new;                                                     # Construct tree
       $t->insert($_, $_) for 1..8;

    T($t, <<END, 1);

                 4
         2               6
     1       3       5       7   8
  END

    local $Tree::Multi::numberOfKeysPerNode = 14;                                 # Number of keys per node - can be even

    my $t = Tree::Multi::new;                                                     # Construct tree
       $t->insert($_, $_) for 1..15;

    T($t, <<END, 1);

                                 8
     1   2   3   4   5   6   7       9   10   11   12   13   14   15
  END


=head2 Tree::Multi::Iterator::next($iter)

Find the next key.

     Parameter  Description
  1  $iter      Iterator

B<Example:>


    local $numberOfKeysPerNode = 3; my $N = 256; my $e = 0;  my $t = new;

    for my $n(0..$N)
     {$t->insert($n, $n);
      my @n; for(my $i = $t->iterator; $i->more; $i->next) {push @n, $i->key}
      ++$e unless dump(\@n) eq dump [0..$n];
     }

    is_deeply $e, 0;


=head2 reverseIterator($tree)

Create a reverse iterator for a tree.

     Parameter  Description
  1  $tree      Tree

B<Example:>


    local $numberOfKeysPerNode = 3; my $N = 64;  my $e = 0;

    for my $n(0..$N)
     {my $t = new;
      for my $i(0..$n)
       {$t->insert($i, $i);
       }
      my @n;

      for(my $i = $t->reverseIterator; $i->less; $i->prev)  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       {push @n, $i->key;
       }
      ++$e unless dump(\@n) eq dump [reverse 0..$n];
     }

    is_deeply $e, 0;


=head2 Tree::Multi::ReverseIterator::prev($iter)

Find the previous key.

     Parameter  Description
  1  $iter      Iterator

B<Example:>


    local $numberOfKeysPerNode = 3; my $N = 64;  my $e = 0;

    for my $n(0..$N)
     {my $t = new;
      for my $i(0..$n)
       {$t->insert($i, $i);
       }
      my @n;
      for(my $i = $t->reverseIterator; $i->less; $i->prev)
       {push @n, $i->key;
       }
      ++$e unless dump(\@n) eq dump [reverse 0..$n];
     }

    is_deeply $e, 0;


=head2 flat($tree, @title)

Print the keys in a tree from left right to make it easier to visualize the structure of the tree.

     Parameter  Description
  1  $tree      Tree
  2  @title     Title

B<Example:>


    local $Tree::Multi::numberOfKeysPerNode = 3;
    my $t = new;      ok $t->height == 0; ok $t->leftMost->depth == 0; ok $t->size == 0;
    $t->insert(1, 1); ok $t->height == 1; ok $t->leftMost->depth == 1; ok $t->size == 1;
    $t->insert(2, 2); ok $t->height == 1; ok $t->leftMost->depth == 1; ok $t->size == 2;
    $t->insert(3, 3); ok $t->height == 1; ok $t->leftMost->depth == 1; ok $t->size == 3;
    $t->insert(4, 4); ok $t->height == 2; ok $t->leftMost->depth == 2; ok $t->size == 4;
    $t->insert(5, 5); ok $t->height == 2; ok $t->leftMost->depth == 2; ok $t->size == 5;
    $t->insert(6, 6); ok $t->height == 2; ok $t->leftMost->depth == 2; ok $t->size == 6;
    $t->insert(7, 7); ok $t->height == 2; ok $t->leftMost->depth == 2; ok $t->size == 7;
    $t->insert(8, 8); ok $t->height == 3; ok $t->leftMost->depth == 3; ok $t->size == 8;

    T($t, <<END, 1);

                 4
         2               6
     1       3       5       7   8
  END



=head2 print($tree, $i)

Print the keys in a tree optionally marking the active key.

     Parameter  Description
  1  $tree      Tree
  2  $i         Optional index of active key

B<Example:>


    local $Tree::Multi::numberOfKeysPerNode = 4;                                  # Number of keys per node - can be even

    my $t = Tree::Multi::new;                                                     # Construct tree
       $t->insert($_, 2 * $_) for reverse 1..32;                                  # Load tree in reverse

    T($t, <<END);
   17 25
     9 13
       3 5 7
         1 2
         4
         6
         8
       11
         10
         12
       15
         14
         16
     21
       19
         18
         20
       23
         22
         24
     29
       27
         26
         28
       31
         30
         32
  END

    ok  $t->size       == 32;                                                     # Size
    ok  $t->height     ==  4;                                                     # Height
    ok  $t->delete(16) == 2 * 16;                                                 # Delete a key
    ok !$t->find  (16);                                                           # Key no longer present
    ok  $t->find  (17) == 34;                                                     # Find by key

    my @k;
    for(my $i = $t->iterator; $i->more; $i->next)                                 # Iterator
     {push @k, $i->key unless $i->key == 17;
     }

    ok $t->delete($_) == 2 * $_ for @k;                                           # Delete

    ok $t->find(17) == 34 && $t->size == 1;                                       # Size

    local $Tree::Multi::numberOfKeysPerNode = 3;                                  # Number of keys per node - can be even

    my $t = Tree::Multi::new;                                                     # Construct tree
       $t->insert($_, $_) for 1..8;

    T($t, <<END, 1);

                 4
         2               6
     1       3       5       7   8
  END

    local $Tree::Multi::numberOfKeysPerNode = 14;                                 # Number of keys per node - can be even

    my $t = Tree::Multi::new;                                                     # Construct tree
       $t->insert($_, $_) for 1..15;

    T($t, <<END, 1);

                                 8
     1   2   3   4   5   6   7       9   10   11   12   13   14   15
  END


=head2 size($tree)

Count the number of keys in a tree.

     Parameter  Description
  1  $tree      Tree

B<Example:>


    local $Tree::Multi::numberOfKeysPerNode = 3;

    my $t = new;      ok $t->height == 0; ok $t->leftMost->depth == 0; ok $t->size == 0;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    $t->insert(1, 1); ok $t->height == 1; ok $t->leftMost->depth == 1; ok $t->size == 1;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    $t->insert(2, 2); ok $t->height == 1; ok $t->leftMost->depth == 1; ok $t->size == 2;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    $t->insert(3, 3); ok $t->height == 1; ok $t->leftMost->depth == 1; ok $t->size == 3;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    $t->insert(4, 4); ok $t->height == 2; ok $t->leftMost->depth == 2; ok $t->size == 4;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    $t->insert(5, 5); ok $t->height == 2; ok $t->leftMost->depth == 2; ok $t->size == 5;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    $t->insert(6, 6); ok $t->height == 2; ok $t->leftMost->depth == 2; ok $t->size == 6;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    $t->insert(7, 7); ok $t->height == 2; ok $t->leftMost->depth == 2; ok $t->size == 7;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    $t->insert(8, 8); ok $t->height == 3; ok $t->leftMost->depth == 3; ok $t->size == 8;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    T($t, <<END, 1);

                 4
         2               6
     1       3       5       7   8
  END




=head2 Tree::Multi Definition


Iterator




=head3 Output fields


=head4 count

Counter

=head4 data

Data at this position

=head4 key

Key at this position

=head4 keys

Array of key items for this node

=head4 less

Iteration not yet finished

=head4 more

Iteration not yet finished

=head4 node

Current node within tree

=head4 pos

Current position within node

=head4 tree

Tree we are iterating over

=head4 up

Parent node



=head1 Private Methods

=head2 new()

Create a new multi-way tree node.


B<Example:>


    local $Tree::Multi::numberOfKeysPerNode = 4;                                  # Number of keys per node - can be even


    my $t = Tree::Multi::new;                                                     # Construct tree  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       $t->insert($_, 2 * $_) for reverse 1..32;                                  # Load tree in reverse

    T($t, <<END);
   17 25
     9 13
       3 5 7
         1 2
         4
         6
         8
       11
         10
         12
       15
         14
         16
     21
       19
         18
         20
       23
         22
         24
     29
       27
         26
         28
       31
         30
         32
  END

    ok  $t->size       == 32;                                                     # Size
    ok  $t->height     ==  4;                                                     # Height
    ok  $t->delete(16) == 2 * 16;                                                 # Delete a key
    ok !$t->find  (16);                                                           # Key no longer present
    ok  $t->find  (17) == 34;                                                     # Find by key

    my @k;
    for(my $i = $t->iterator; $i->more; $i->next)                                 # Iterator
     {push @k, $i->key unless $i->key == 17;
     }

    ok $t->delete($_) == 2 * $_ for @k;                                           # Delete

    ok $t->find(17) == 34 && $t->size == 1;                                       # Size

    local $Tree::Multi::numberOfKeysPerNode = 3;                                  # Number of keys per node - can be even


    my $t = Tree::Multi::new;                                                     # Construct tree  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       $t->insert($_, $_) for 1..8;

    T($t, <<END, 1);

                 4
         2               6
     1       3       5       7   8
  END

    local $Tree::Multi::numberOfKeysPerNode = 14;                                 # Number of keys per node - can be even


    my $t = Tree::Multi::new;                                                     # Construct tree  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       $t->insert($_, $_) for 1..15;

    T($t, <<END, 1);

                                 8
     1   2   3   4   5   6   7       9   10   11   12   13   14   15
  END


=head2 minimumNumberOfKeys()

Minimum number of keys per node.


=head2 maximumNumberOfKeys()

Maximum number of keys per node.


=head2 maximumNumberOfNodes()

Maximum number of children per parent.


=head2 full($tree)

Confirm that a node is full.

     Parameter  Description
  1  $tree      Tree

=head2 halfFull($tree)

Confirm that a node is half full.

     Parameter  Description
  1  $tree      Tree

=head2 reUp($tree, $children)

Reconnect the children to their new parent.

     Parameter  Description
  1  $tree      Tree
  2  $children  Children

=head2 splitFullNode($isRoot, $isLeaf, $node)

Split a node if it is full.

     Parameter  Description
  1  $isRoot    Known to be the root if true
  2  $isLeaf    Known to be a leaf if true
  3  $node      Node to split

=head2 findAndSplit($root, $key)

Find a key in a tree splitting full nodes along the path to the key.

     Parameter  Description
  1  $root      Root of tree
  2  $key       Key

=head2 indexInParent($tree)

Get the index of a node in its parent.

     Parameter  Description
  1  $tree      Tree

=head2 fillFromLeftOrRight($node, $dir)

Fill a node from the specified sibling.

     Parameter  Description
  1  $node      Node to fill
  2  $dir       Node to fill from 0 for left or 1 for right

=head2 mergeWithLeftOrRight($n, $dir)

Merge two adjacent nodes.

     Parameter  Description
  1  $n         Node to merge into
  2  $dir       Node to merge is on right if 1 else left

=head2 merge($tree)

Merge the current node with its sibling.

     Parameter  Description
  1  $tree      Tree

=head2 mergeOrFill($tree)

Make a node larger than a half node.

     Parameter  Description
  1  $tree      Tree

=head2 deleteLeafKey($tree, $i)

Delete a key in a leaf.

     Parameter  Description
  1  $tree      Tree
  2  $i         Index to delete at

=head2 deleteKey($tree, $i)

Delete a key.

     Parameter  Description
  1  $tree      Tree
  2  $i         Index to delete at

=head2 T($tree, $expected, $flat)

Print a tree to the log file and check it against the expected result

     Parameter  Description
  1  $tree      Tree
  2  $expected  Expected print
  3  $flat      Optionally print in flat mode if true

=head2 F($tree, $expected)

Print a tree flatly to the log file and check its result

     Parameter  Description
  1  $tree      Tree
  2  $expected  Expected print

=head2 disordered($n, $N)

Disordered but stable insertions

     Parameter  Description
  1  $n         Keys per node
  2  $N         Nodes

=head2 disorderedCheck($t, $n, $N)

Check disordered insertions

     Parameter  Description
  1  $t         Tree to check
  2  $n         Keys per node
  3  $N         Nodes

=head2 randomCheck($n, $N, $T)

Random insertions

     Parameter  Description
  1  $n         Keys per node
  2  $N         Log 10 nodes
  3  $T         Log 10 number of tests


=head1 Index


1 L<delete|/delete> - Find a key in a tree, delete it and return any associated data.

2 L<deleteKey|/deleteKey> - Delete a key.

3 L<deleteLeafKey|/deleteLeafKey> - Delete a key in a leaf.

4 L<depth|/depth> - Return the depth of a node within a tree.

5 L<disordered|/disordered> - Disordered but stable insertions

6 L<disorderedCheck|/disorderedCheck> - Check disordered insertions

7 L<F|/F> - Print a tree flatly to the log file and check its result

8 L<fillFromLeftOrRight|/fillFromLeftOrRight> - Fill a node from the specified sibling.

9 L<find|/find> - Find a key in a tree returning its associated data or undef if the key does not exist.

10 L<findAndSplit|/findAndSplit> - Find a key in a tree splitting full nodes along the path to the key.

11 L<flat|/flat> - Print the keys in a tree from left right to make it easier to visualize the structure of the tree.

12 L<full|/full> - Confirm that a node is full.

13 L<halfFull|/halfFull> - Confirm that a node is half full.

14 L<height|/height> - Return the height of the tree.

15 L<indexInParent|/indexInParent> - Get the index of a node in its parent.

16 L<insert|/insert> - Insert the specified key and data into a tree.

17 L<iterator|/iterator> - Make an iterator for a tree.

18 L<leaf|/leaf> - Confirm that the tree is a leaf.

19 L<leftMost|/leftMost> - Return the left most node below the specified one.

20 L<maximumNumberOfKeys|/maximumNumberOfKeys> - Maximum number of keys per node.

21 L<maximumNumberOfNodes|/maximumNumberOfNodes> - Maximum number of children per parent.

22 L<merge|/merge> - Merge the current node with its sibling.

23 L<mergeOrFill|/mergeOrFill> - Make a node larger than a half node.

24 L<mergeWithLeftOrRight|/mergeWithLeftOrRight> - Merge two adjacent nodes.

25 L<minimumNumberOfKeys|/minimumNumberOfKeys> - Minimum number of keys per node.

26 L<new|/new> - Create a new multi-way tree node.

27 L<print|/print> - Print the keys in a tree optionally marking the active key.

28 L<randomCheck|/randomCheck> - Random insertions

29 L<reUp|/reUp> - Reconnect the children to their new parent.

30 L<reverseIterator|/reverseIterator> - Create a reverse iterator for a tree.

31 L<rightMost|/rightMost> - Return the right most node below the specified one.

32 L<root|/root> - Return the root node of a tree.

33 L<size|/size> - Count the number of keys in a tree.

34 L<splitFullNode|/splitFullNode> - Split a node if it is full.

35 L<T|/T> - Print a tree to the log file and check it against the expected result

36 L<Tree::Multi::Iterator::next|/Tree::Multi::Iterator::next> - Find the next key.

37 L<Tree::Multi::ReverseIterator::prev|/Tree::Multi::ReverseIterator::prev> - Find the previous key.

=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read,
comprehend, use, modify and install via B<cpan>:

  sudo cpan install Tree::Multi

=head1 Author

L<philiprbrenan@gmail.com|mailto:philiprbrenan@gmail.com>

L<http://www.appaapps.com|http://www.appaapps.com>

=head1 Copyright

Copyright (c) 2016-2021 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.

=cut



# Tests and documentation

sub test
 {my $p = __PACKAGE__;
  binmode($_, ":utf8") for *STDOUT, *STDERR;
  return if eval "eof(${p}::DATA)";
  my $s = eval "join('', <${p}::DATA>)";
  $@ and die $@;
  eval $s;
  $@ and die $@;
  1
 }

test unless caller;

1;
# podDocumentation
__DATA__
use Time::HiRes qw(time);
use Test::Most;

my $develop  = -e q(/home/phil/);                                               # Developing
my  $logFile = q(/home/phil/perl/cpan/TreeMulti/lib/Tree/zzzLog.txt);           # Log file

my $localTest = ((caller(1))[0]//'Tree::Multi') eq "Tree::Multi";               # Local testing mode

Test::More->builder->output("/dev/null") if $localTest;                         # Reduce number of confirmation messages during testing

if ($^O =~ m(bsd|linux)i)                                                       # Supported systems
 {plan tests => 84;
 }
else
 {plan skip_all =>qq(Not supported on: $^O);
 }

bail_on_fail;                                                                   # Stop if any tests fails

sub T($$;$)                                                                     #P Print a tree to the log file and check it against the expected result
 {my ($tree, $expected, $flat) = @_;                                            # Tree, expected print, optionally print in flat mode if true
  confess unless ref($tree);
  my $got = $flat ? $tree->flat : $tree->print;
  return $got eq $expected unless $develop;
  my $s = &showGotVersusWanted($got, $expected);
  return 1 unless $s;
  owf($logFile, $got);
  confess "$s\n";
 }

sub F($$)                                                                       #P Print a tree flatly to the log file and check its result
 {my ($tree, $expected) = @_;                                                   # Tree, expected print
  &T(@_, 1);
 }

sub disordered($$)                                                              #P Disordered but stable insertions
 {my ($n, $N) = @_;                                                             # Keys per node, nodes
  local $numberOfKeysPerNode = $n;

  my $t = new;
  my @t = map{$_ = scalar reverse $_; s/\A0+//r} 1..$N;
     $t->insert($_, 2 * $_) for @t;
     $t                                                                         # Tree built from disordered but stable insertions
 }

sub disorderedCheck($$$)                                                        #P Check disordered insertions
 {my ($t, $n, $N) = @_;                                                         # Tree to check, keys per node, Nodes

  my %t = map {$_=>2*$_} map{$_ = scalar reverse $_; s/\A0+//r} 1..$N;

  my $e = 0;
  my $h = $t->height;
  for my $k(sort {reverse($a) cmp reverse($b)} keys %t)
   {++$e unless     $t->find($k) == $t{$k};  $t->delete($k); delete $t{$k};
    ++$e if defined $t->find($k);
    ++$e if         $t->height > $h;
   }
  ++$e unless $t->height == 0;

  !$e;                                                                          # No errors
 }

sub randomCheck($$$)                                                            #P Random insertions
 {my ($n, $N, $T) = @_;                                                         # Keys per node, log 10 nodes, log 10 number of tests
  local $numberOfKeysPerNode = $n;
  my $e = 0;

  for(1..10**$T)                                                                # Each test
   {my %t = map {$_=>2*$_} 1..10**$N;
    my $t = new; $t->insert($_, $t{$_}) for keys %t;

    for my $k(keys %t)                                                          # Delete each key in test
     {++$e unless     $t->find($k) == $t{$k}; $t->delete($k); delete $t{$k};
      ++$e if defined $t->find($k);
     }
   }

  !$e;                                                                          # No errors
 }

my $start = time;                                                               # Tests

eval {goto latest} if !caller(0) and -e "/home/phil";                           # Go to latest test if specified

if (1) {                                                                        # Odd number of keys
  my $t = new;
  $t = disordered(       3, 256);
  ok disorderedCheck($t, 3, 256);
 }

if (1) {                                                                        # Even number of keys
  my $t = new;
  $t = disordered(       4, 256);
  ok disorderedCheck($t, 4, 256);
 }

if (1) {
  local $numberOfKeysPerNode = 15;

  my $t = new; my $N = 256;

  $t->insert($_, 2 * $_) for 1..$N;

  ok T($t, <<END);
 64 128 192
   8 16 24 32 40 48 56
     1 2 3 4 5 6 7
     9 10 11 12 13 14 15
     17 18 19 20 21 22 23
     25 26 27 28 29 30 31
     33 34 35 36 37 38 39
     41 42 43 44 45 46 47
     49 50 51 52 53 54 55
     57 58 59 60 61 62 63
   72 80 88 96 104 112 120
     65 66 67 68 69 70 71
     73 74 75 76 77 78 79
     81 82 83 84 85 86 87
     89 90 91 92 93 94 95
     97 98 99 100 101 102 103
     105 106 107 108 109 110 111
     113 114 115 116 117 118 119
     121 122 123 124 125 126 127
   136 144 152 160 168 176 184
     129 130 131 132 133 134 135
     137 138 139 140 141 142 143
     145 146 147 148 149 150 151
     153 154 155 156 157 158 159
     161 162 163 164 165 166 167
     169 170 171 172 173 174 175
     177 178 179 180 181 182 183
     185 186 187 188 189 190 191
   200 208 216 224 232 240 248
     193 194 195 196 197 198 199
     201 202 203 204 205 206 207
     209 210 211 212 213 214 215
     217 218 219 220 221 222 223
     225 226 227 228 229 230 231
     233 234 235 236 237 238 239
     241 242 243 244 245 246 247
     249 250 251 252 253 254 255 256
END

  if (1)
   {my $n = 0;
    for my $i(1..$N)
     {my $ii = $t->find($i);
       ++$n if $t->find($i) eq 2 * $i;
     }
    ok $n == $N;
   }
 }

if (1) {                                                                        # Large number of keys per node
  local $numberOfKeysPerNode = 15;

  my $t = new; my $N = 256;

  my @t = reverse map{scalar reverse; s/\A0+//r} 1..$N;
  $t->insert($_, 2 * $_) for @t;

  ok T($t, <<END);
 65 129 193
   9 17 25 33 41 49 57
     1 2 3 4 5 6 7 8
     10 11 12 13 14 15 16
     18 19 20 21 22 23 24
     26 27 28 29 30 31 32
     34 35 36 37 38 39 40
     42 43 44 45 46 47 48
     50 51 52 53 54 55 56
     58 59 60 61 62 63 64
   73 81 89 97 105 113 121
     66 67 68 69 70 71 72
     74 75 76 77 78 79 80
     82 83 84 85 86 87 88
     90 91 92 93 94 95 96
     98 99 100 101 102 103 104
     106 107 108 109 110 111 112
     114 115 116 117 118 119 120
     122 123 124 125 126 127 128
   137 145 153 161 169 177 185
     130 131 132 133 134 135 136
     138 139 140 141 142 143 144
     146 147 148 149 150 151 152
     154 155 156 157 158 159 160
     162 163 164 165 166 167 168
     170 171 172 173 174 175 176
     178 179 180 181 182 183 184
     186 187 188 189 190 191 192
   201 209 217 225 233 241 249
     194 195 196 197 198 199 200
     202 203 204 205 206 207 208
     210 211 212 213 214 215 216
     218 219 220 221 222 223 224
     226 227 228 229 230 231 232
     234 235 236 237 238 239 240
     242 243 244 245 246 247 248
     250 251 252 253 254 255 256
END

  if (1)
   {my $n = 0;
    for my $i(@t)
     {my $ii = $t->find($i);
       ++$n if $t->find($i) eq 2 * $i;
     }
    ok $n == $N;
   }
 }

if (1) {                                                                        #Titerator #TTree::Multi::Iterator::next  #TTree::Multi::Iterator::more
  local $numberOfKeysPerNode = 3; my $N = 256; my $e = 0;  my $t = new;

  for my $n(0..$N)
   {$t->insert($n, $n);
    my @n; for(my $i = $t->iterator; $i->more; $i->next) {push @n, $i->key}
    ++$e unless dump(\@n) eq dump [0..$n];
   }

  is_deeply $e, 0;
 }

if (1) {                                                                        #TleftMost #TrightMost #Tleaf #Troot
  local $numberOfKeysPerNode = 3; my $N = 13; my $t = new;

  for my $n(1..$N)
   {$t->insert($n, $n);
   }

  ok T($t, <<END);
 4 8
   2
     1
     3
   6
     5
     7
   10 12
     9
     11
     13
END

  is_deeply $t->leftMost ->keys, [1];
  is_deeply $t->rightMost->keys, [13];
  ok $t->leftMost ->leaf;
  ok $t->rightMost->leaf;
  ok $t->root == $t;
 }

if (1) {                                                                        #TreverseIterator #TTree::Multi::ReverseIterator::prev  #TTree::Multi::ReverseIterator::less
  local $numberOfKeysPerNode = 3; my $N = 64;  my $e = 0;

  for my $n(0..$N)
   {my $t = new;
    for my $i(0..$n)
     {$t->insert($i, $i);
     }
    my @n;
    for(my $i = $t->reverseIterator; $i->less; $i->prev)
     {push @n, $i->key;
     }
    ++$e unless dump(\@n) eq dump [reverse 0..$n];
   }

  is_deeply $e, 0;
 }

if (1) {                                                                        #Theight #Tdepth #Tsize #Tflat
  local $Tree::Multi::numberOfKeysPerNode = 3;
  my $t = new;      ok $t->height == 0; ok $t->leftMost->depth == 0; ok $t->size == 0;
  $t->insert(1, 1); ok $t->height == 1; ok $t->leftMost->depth == 1; ok $t->size == 1;
  $t->insert(2, 2); ok $t->height == 1; ok $t->leftMost->depth == 1; ok $t->size == 2;
  $t->insert(3, 3); ok $t->height == 1; ok $t->leftMost->depth == 1; ok $t->size == 3;
  $t->insert(4, 4); ok $t->height == 2; ok $t->leftMost->depth == 2; ok $t->size == 4;
  $t->insert(5, 5); ok $t->height == 2; ok $t->leftMost->depth == 2; ok $t->size == 5;
  $t->insert(6, 6); ok $t->height == 2; ok $t->leftMost->depth == 2; ok $t->size == 6;
  $t->insert(7, 7); ok $t->height == 2; ok $t->leftMost->depth == 2; ok $t->size == 7;
  $t->insert(8, 8); ok $t->height == 3; ok $t->leftMost->depth == 3; ok $t->size == 8;

  T($t, <<END, 1);

               4
       2               6
   1       3       5       7   8
END

 }

ok &randomCheck(3, $develop ? (2, 1) : (2, 3));                                 # Randomize and check against a Perl hash
ok &randomCheck(4, $develop ? (2, 1) : (2, 3));
ok &randomCheck(5, $develop ? (2, 1) : (2, 2));
ok &randomCheck(6, $develop ? (2, 1) : (2, 2));
ok &randomCheck(7, $develop ? (2, 1) : (3, 1));
ok &randomCheck(8, $develop ? (2, 1) : (3, 1));

if (1) {                                                                        # Synopsis #Tnew #Tinsert #Tfind #Tdelete #Tprint #Titerator
  local $Tree::Multi::numberOfKeysPerNode = 4;                                  # Number of keys per node - can be even

  my $t = Tree::Multi::new;                                                     # Construct tree
     $t->insert($_, 2 * $_) for reverse 1..32;                                  # Load tree in reverse

  T($t, <<END);
 17 25
   9 13
     3 5 7
       1 2
       4
       6
       8
     11
       10
       12
     15
       14
       16
   21
     19
       18
       20
     23
       22
       24
   29
     27
       26
       28
     31
       30
       32
END

  ok  $t->size       == 32;                                                     # Size
  ok  $t->height     ==  4;                                                     # Height
  ok  $t->delete(16) == 2 * 16;                                                 # Delete a key
  ok !$t->find  (16);                                                           # Key no longer present
  ok  $t->find  (17) == 34;                                                     # Find by key

  my @k;
  for(my $i = $t->iterator; $i->more; $i->next)                                 # Iterator
   {push @k, $i->key unless $i->key == 17;
   }

  ok $t->delete($_) == 2 * $_ for @k;                                           # Delete

  ok $t->find(17) == 34 && $t->size == 1;                                       # Size
 }

if (1) {                                                                        # Synopsis #Tnew #Tinsert #Tfind #Tdelete #Tprint #Titerator
  local $Tree::Multi::numberOfKeysPerNode = 3;                                  # Number of keys per node - can be even

  my $t = Tree::Multi::new;                                                     # Construct tree
     $t->insert($_, $_) for 1..8;

  T($t, <<END, 1);

               4
       2               6
   1       3       5       7   8
END
 }

#latest:;
if (1) {                                                                        # Synopsis #Tnew #Tinsert #Tfind #Tdelete #Tprint #Titerator
  local $Tree::Multi::numberOfKeysPerNode = 14;                                 # Number of keys per node - can be even

  my $t = Tree::Multi::new;                                                     # Construct tree
     $t->insert($_, $_) for 1..15;

  T($t, <<END, 1);

                               8
   1   2   3   4   5   6   7       9   10   11   12   13   14   15
END
 }

#latest:;
if (1) {
  local $Tree::Multi::numberOfKeysPerNode = 14;

  my $t = Tree::Multi::new;
     $t->insert($_, $_) for 1..22;

  T($t, <<END, 1);

                               8                                     16
   1   2   3   4   5   6   7       9   10   11   12   13   14   15        17   18   19   20   21   22
END
  my @k;
  for(my $i = $t->iterator; $i->more; $i->next)                                 # Iterator
   {push @k, $i->key;
   }
  is_deeply [@k], [1..22];
 }

lll "Success:", sprintf("%5.2f seconds", time - $start);

#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib/ -I.
#-------------------------------------------------------------------------------
# Bulk Tree operations
# Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2021
#-------------------------------------------------------------------------------
# podDocumentation
package Tree::Bulk;
our $VERSION = "20210302";
use warnings FATAL => qw(all);
use strict;
use Carp qw(confess cluck);
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
use feature qw(say current_sub);

sub saveLog($)                                                                  #P Save a result to the log file if we are developing
 {my ($string) = @_;                                                            # String to save
  my $l = q(/home/phil/perl/z/bulkTree/zzz.txt);                                # Log file if available

  owf($l, $string) if -e $l;
  confess "Saved to logfile:\n$l\n";
  exit
 }

sub save                                                                        # Simplified save
 {my ($t) = @_;                                                                 # Tree
  saveLog($t->printKeys);
 }

sub Left  {q(left)}                                                             # Left
sub Right {q(right)}                                                            # Right

#D1 Bulk Tree                                                                   # Bulk Tree

sub node(;$$$$)                                                                 #P Create a new bulk tree node
 {my ($key, $data, $up, $side) = @_;                                            # Key, $data, parent node, side of parent node
  my $t = genHash(__PACKAGE__,                                                  # Bulk tree node
    keysPerNode => $up ? $up->keysPerNode : 4,                                  # Maximum number of keys per node
    up          => $up,                                                         # Parent node
    left        => undef,                                                       # Left node
    right       => undef,                                                       # Right node
    height      => 1,                                                           # Height of node
    keys        => [$key  ? $key  : ()],                                        # Array of data items for this node
    data        => [$data ? $data : ()],                                        # Data corresponding to each key
   );

  if ($up)                                                                      # Install new node in tree
   {if ($side)
     {$up->{$side} = $t;
      $up->setHeights(2);
     }
    else
     {confess 'Specify side' if !$side;
     }
   }
  $t
 }

sub new {node}                                                                  # Create a new tree

sub isRoot($)                                                                   # Return the tree if it is the root
 {my ($tree) = @_;                                                              # Tree
  confess unless $tree;
  !$tree->up ? $tree : undef
 }

sub root($)                                                                     # Return the root node of a tree
 {my ($tree) = @_;                                                              # Tree
  confess unless $tree;
  for(; $tree->up; $tree = $tree->up) {}
  $tree
 }

sub leaf($)                                                                     # Return the tree if it is a leaf
 {my ($tree) = @_;                                                              # Tree
  confess unless $tree;
  $tree and !$tree->right and !$tree->left ? $tree : undef
 }

sub duplex($)                                                                   # Return the tree if it has left and right children
 {my ($tree) = @_;                                                              # Tree
  confess unless $tree;
  $tree->right and $tree->left             ? $tree : undef
 }

sub simplex($)                                                                  # Return the tree if it has either a left child or a right child but not both.
 {my ($tree) = @_;                                                              # Tree
  confess unless $tree;
  $tree->right xor $tree->left             ? $tree : undef
 }

sub simplexWithLeaf($)                                                          # Return the tree if it has either a left child or a right child but not both and the child it has a leaf.
 {my ($tree) = @_;                                                              # Tree
  confess unless $tree;
  return undef unless $tree->right xor $tree->left;
  return undef if $tree->right and !$tree->right->leaf;
  return undef if $tree->left  and !$tree->left ->leaf;
  $tree
 }

sub empty($)                                                                    # Return the tree if it is empty
 {my ($tree) = @_;                                                              # Tree
  confess unless $tree;
  $tree->leaf and !$tree->keys->@*         ? $tree : undef
 }

sub singleton($)                                                                # Return the tree if it contains only the root node and nothing else
 {my ($tree) = @_;                                                              # Tree
  confess unless $tree;
  $tree->leaf and $tree->isRoot            ? $tree : undef;
 }

sub isLeftChild($)                                                              # Return the tree if it is the left child
 {my ($tree) = @_;                                                              # Tree
  confess unless $tree;
  $tree->up and $tree->up->left and $tree->up->left   == $tree ? $tree : undef;
 }

sub isRightChild($)                                                             # Return the tree if it is the right child
 {my ($tree) = @_;                                                              # Tree
  confess unless $tree;
  $tree->up and $tree->up->right and $tree->up->right == $tree ? $tree : undef;
 }

sub name($)                                                                     # Name of a tree
 {my ($tree) = @_;                                                              # Tree
  confess unless $tree;
  join ' ', $tree->keys->@*
 }

sub names($)                                                                    # Names of all nodes in a tree in order
 {my ($tree) = @_;                                                              # Tree
  confess unless $tree;
  join ' ', map {$_->name} $tree->inorder;
 }

sub setHeights($)                                                               #P Set heights along path to root
 {my ($tree) = @_;                                                              # Tree
  confess unless $tree;
  for(my $n = $tree; $n; $n = $n->up)
   {$n->setHeight;
    $n->balance;
   }
 } # setHeights

sub actualHeight($)                                                             #P Get the height of a node
 {my ($tree) = @_;                                                              # Tree
  return 0 unless $tree;
  $tree->height
 }

sub maximum($$)                                                                 #P Maximum of two numbers
 {my ($a, $b) = @_;                                                             # First, second
  $a > $b ? $a : $b
 }

sub setHeight($)                                                                #P Set height of a tree from its left and right trees
 {my ($tree) = @_;                                                              # Tree
  confess unless $tree;
  my $l = actualHeight($tree->left);
  my $r = actualHeight($tree->right);
  $tree->height = 1 + maximum($l, $r);
 } # setHeight

# Rotate left

#    p                  p
#      n                  r
#    l   r              n   R
#       L R           l  L

sub rotateLeft($)                                                               #P Rotate a node left
 {my ($n) = @_;                                                                 # Node
  confess unless $n;
  my $p     = $n->up;
  return unless $p;
  my $r     = $n->right;
  return unless $r;
  my $L     = $r->left;
  $p->{$n->isRightChild ? Right : Left} = $r; $r->up = $p;
  $r->left  = $n; $n->up = $r;
  $n->right = $L; $L->up = $n if $L;
  setHeight $_ for  $n, $r, $p;
  $r->refill;
 } # rotateLeft

sub rotateRight($)                                                              #P Rotate a node right
 {my ($n) = @_;                                                                 # Node
  confess unless $n;
  my $p     = $n->up;
  return unless $p;
  my $l     = $n->left;
  return unless $l;
  my $R     = $l->right;
  $p->{$n->isLeftChild ? Left : Right} = $l; $l->up = $p;
  $l->right = $n; $n->up = $l;
  $n->left  = $R; $R->up = $n if $R;
  setHeight $_ for  $n, $l, $p;
  $l->refill;
 } # rotateLeft

# Balance - make the deepest sub tree one less deep

#    1                1
#      2                     5
#        6            2         6
#      5                4
#    4                    3
#  3

sub balance($)                                                                  # Balance a node
 {my ($t) = @_;                                                                 # Tree
  confess unless $t;
  my ($l, $r) = (actualHeight($t->left), actualHeight($t->right));

  if   ($l > 2 * $r + 1)                                                        # Rotate right
   {if (my $l = $t->left)                                                       # Counter balance if necessary
     {if (actualHeight($l->right) > actualHeight($l->left))
       {$l->rotateLeft
       }
     }
    $t->rotateRight;
   }
  elsif ($r > 2 * $l + 1)                                                       # Rotate left
   {if (my $r = $t->right)                                                      # Counter balance if necessary
     {if (actualHeight($r->left) > actualHeight($r->right))
       {$r->rotateRight
       }
     }
    $t->rotateLeft;
   }

  $t
 } # balance

sub insertUnchecked($$$)                                                        #P Insert a key and some data into a tree
 {my ($tree, $key, $data) = @_;                                                 # Tree, key, data
  confess unless $tree;
  confess unless defined $key;

  my sub insertIntoNode                                                         # Insert the current key into the specified node
   {my @k; my @d;                                                               # Rebuilt node
    my $low = 1;                                                                # Keys less than the key
    for my $i(keys $tree->keys->@*)                                             # Insert key and data in node
     {my $k = $tree->keys->[$i];
      confess "Duplicate key" if $k == $key;
      if ($low and $k > $key)                                                   # Insert key and data before first greater key
       {$low = undef;
        push @k, $key;
        push @d, $data;
       }
      push @k, $k;
      push @d, $tree->data->[$i];
     }
    if ($low)                                                                   # Key bigger than largest key
     {push @d, $data;
      push @k, $key;
     }
    $tree->keys = \@k; $tree->data = \@d;                                       # Keys and data in node
   } # insertIntoNode

  if    ($tree->keys->@* < $tree->keysPerNode and leaf $tree)                   # Small node so we can add within the node
   {insertIntoNode;
    return $tree;
   }

  elsif ($key < $tree->keys->[0])                                               # Less than least - Go left
   {if ($tree->left)                                                            # New node left
     {return __SUB__->($tree->left, $key, $data);
     }
    else
     {return node $key, $data, $tree, Left;                                     # Add a new node left
     }
   }

  elsif ($key > $tree->keys->[-1])                                              # Greater than most  - go right
   {if ($tree->right)                                                           # New node right
     {return __SUB__->($tree->right, $key, $data);
     }
    else
     {return node $key, $data, $tree, Right;                                    # Add a new node right
     }
   }

  else                                                                          # Full node and key is inside it
   {insertIntoNode;                                                             # Keys in node
    if ($tree->keys->@* > $tree->keysPerNode)                                   # Reinsert last key and data if the node is now to big
     {my $k = pop $tree->keys->@*;
      my $d = pop $tree->data->@*;
      if (my $r = $tree->right)
       {return $r->insertUnchecked($k, $d);
       }
      else                                                                      # Insert right in new node and balance
       {return node $k, $d, $tree, Right;
       }
     }
    return $tree;
   }
 } # insertUnchecked

sub insert($$$)                                                                 # Insert a key and some data into a tree
 {my ($tree, $key, $data) = @_;                                                 # Tree, key, data
  confess unless $tree;
  confess unless defined $key;
  $tree->insertUnchecked($key, $data);
 } # insert

sub find($$)                                                                    # Find a key in a tree and returns its data
 {my ($tree, $key) = @_;                                                        # Tree, key
  confess unless $tree;
  confess "No key" unless defined $key;
  confess "Non numeric key" unless $key =~ m(\A\d+\Z);

  sub                                                                           # Find the key in the sub-tree
   {my ($tree) = @_;                                                            # Sub-tree
    if ($tree)
     {my $keys = $tree->keys;
      confess "Empty node" unless $keys->@*;

      return __SUB__->($tree->left)  if $key < $$keys[ 0];
      return __SUB__->($tree->right) if $key > $$keys[-1];

      for my $i(keys $keys->@*)                                                 # Find key in node
       {my $v = $tree->data->[$i];
        confess "undefined data for key $key" unless defined $v;
        return $tree->data->[$i] if $key == $$keys[$i];
       }
     }
    undef
   }->($tree)
 } # find

sub first($)                                                                    # First node in a tree
 {my ($n) = @_;                                                                 # Tree
  confess unless $n;
  $n = $n->left while $n->left;
  $n
 }

sub last($)                                                                     # Last node in a tree
 {my ($n) = @_;                                                                 # Tree
  confess unless $n;
  $n = $n->right while $n->right;
  $n
 }

sub next($)                                                                     # Next node in order
 {my ($tree) = @_;                                                              # Tree
  confess unless $tree;
  if   (my $r = $tree->right)
   {return $r->left ? $r->left->first : $r;
   }
  my $p = $tree;
  for(; $p; $p = $p->up)
   {return $p->up unless $p->up and $p->up->right and $p->up->right == $p;
   }
  undef
 }

sub prev($)                                                                     # Previous node in order
 {my ($tree) = @_;                                                              # Tree
  confess unless $tree;
  if   (my $l = $tree->left)
   {return $l->right ? $l->right->last : $l;
   }
  my $p = $tree;
  for(; $p; $p = $p->up)
   {return $p->up unless $p->up and $p->up->left and $p->up->left == $p;
   }
  undef
 }

sub inorder($)                                                                  # Return a list of all the nodes in a tree in order
 {my ($tree) = @_;                                                              # Tree
  confess unless $tree;
  my @n;
  for(my $n = $tree->first; $n; $n = $n->next)
   {push @n, $n;
   }
  @n
 }

sub unchain($)                                                                  #P Remove a tree from the middle of a chain. A leaf is considered to be in the middle of a chain and so can be removed with this method
 {my ($t) = @_;                                                                 # Tree
  confess unless $t;
  confess "Duplex tree cannot be unchained" if duplex $t;
  confess        "Root cannot be unchained" unless my $p = $t->up;

  my $c = $t->left // $t->right;                                                # Not duplex so at most one of these
  $p->{$t->isLeftChild ? Left : Right} = $c;                                    # Unchain
  $c->up = $p if $c;
  $t->up = undef;

  if    (my $l = $p->left)  {$l->setHeights($l->height)}                        # Set heights from a known point
  elsif (my $r = $p->right) {$r->setHeights($r->height)}
  else                      {$p->setHeights(1)}

  $p->balance;                                                                  # Rebalance parent

  $p                                                                            # Unchained node
 } # unchain

sub refillFromRight($)                                                          #P Push a key to the target node from the next node
 {my ($target) = @_;                                                            # Target tree

  confess unless $target;
  confess "No right"  unless              $target->right;                       # Ensure source will be in this sub tree
  confess "No source" unless my $source = $target->next;                        # No source

  while ($source->keys->@* > 0 and $target->keys->@* < $target->keysPerNode)    # Transfer fill from source
   {push $target->keys->@*, shift  $source->keys->@*;
    push $target->data->@*, shift  $source->data->@*;
   }
  $source->unchain if $source->empty;
  $_->refill for $target, $source;
 } # refillFromRight

sub refillFromLeft($)                                                           #P Push a key to the target node from the previous node
 {my ($target) = @_;                                                            # Target tree

  confess unless $target;
  confess "No left"   unless              $target->left;                        # Ensure source will be in this sub tree
  confess "No source" unless my $source = $target->prev;                        # No source

  while ($source->keys->@* > 0 and $target->keys->@* < $target->keysPerNode)    # Transfer fill from source
   {unshift $target->keys->@*, pop $source->keys->@*;
    unshift $target->data->@*, pop $source->data->@*;
   }

  $source->unchain if $source->empty;
  $_->refill for $target, $source;
 } # refillFromLeft

sub refill($)                                                                   #P Refill a node so it has the expected number of keys
 {my ($tree) = @_;                                                              # Tree
  confess unless $tree;
  return if $tree->singleton;
  return if $tree->keys->@* == $tree->keysPerNode;

  if ($tree->empty)                                                             # Remove an empty leaf that is not the root
   {$tree->unchain unless $tree->isRoot;
   }

  elsif ($tree->keys->@* < $tree->keysPerNode)                                  # Refill the node from neighboring leaf nodes
   {if (!$tree->leaf)                                                           # Do not refill leaves
     {$tree->refillFromRight if $tree->right;
      $tree->refillFromLeft  if $tree->left;
     }
   }

  else
   {while($tree->keys->@* > $tree->keysPerNode)                                 # Empty node if over full
     {$tree->insertUnchecked(pop $tree->keys->@*, pop $tree->data->@*);         # Reinsert lower down
     }
   }
 } # refill

sub delete($$)                                                                  # Delete a key in a tree
 {my ($tree, $key) = @_;                                                        # Tree, key
  confess unless $tree;
  confess "No key" unless defined $key;

  sub                                                                           # Find then delete the key in the sub-tree
   {my ($tree) = @_;                                                            # Sub-tree
    return unless $tree;
    return unless $tree->keys->@*;                                              # Empty tree
    if    ($key < $tree->keys->[ 0]) {__SUB__->($tree->left)}                   # Less than least key so go left
    elsif ($key > $tree->keys->[-1]) {__SUB__->($tree->right)}                  # Greater than most key so go right
    elsif (grep {$_ == $key} $tree->keys->@*)                                   # Key present in current node
     {my @k, my @d;
      for my $i(keys $tree->keys->@*)                                           # Remove the key and corresponding data
       {next if  $tree->keys->[$i] == $key;
        push @d, $tree->data->[$i];
        push @k, $tree->keys->[$i];
       }
      $tree->keys = \@k; $tree->data = \@d;
      $tree->refill;                                                            # Refill the tree
     }
   }->($tree);
 } # delete

sub printKeys2($$$)                                                             #P print the keys for a tree
 {my ($t, $in, $g) = @_;                                                        # Tree, indentation, list of keys,
  return unless $t;
  __SUB__->($t->left, $in+1, $g);                                               # Left

  my $h = $t->height;
  my $s = $t->up && $t->up->left  && $t->up->left  == $t ? 'L' :                # Print
          $t->up && $t->up->right && $t->up->right == $t ? 'R' : 'S';
     $s .= $t->leaf ? 'z' : $t->isRoot ?  'A' : $t->left && $t->right ? 'd' : $t->left ? 'l' : 'r';
     $s .= "$in $h ".('  ' x $in);
     $s .= $t->name;
     $s .= '->'.$t->up->name if $t->up;
  push @$g, $s;

  __SUB__->($t->right, $in+1, $g);                                              # Right
 }

sub printKeys($)                                                                # Print the keys in a tree
 {my ($t) = @_;                                                                 # Tree
  confess unless $t;

  my @s;
  printKeys2 $t, 0, \@s;

  (join "\n", @s, "") =~ s(\s+\Z) (\n)sr
 } # printKeys

sub setKeysPerNode($$)                                                          # Set the number of keys for the current node
 {my ($tree, $N) = @_;                                                          # Tree, keys per node to be set
  confess unless $tree;
  confess unless $N and $N > 0;
  $tree->keysPerNode =  $N;                                                     # Set
  $tree->refill;                                                                # Refill if necessary
  $tree                                                                         # Allow chaining
 } # setKeysPerNode

sub printKeysAndData($)                                                         # Print the mapping from keys to data in a tree
 {my ($t) = @_;                                                                 # Tree
  confess unless $t;
  my @s;
  my sub print($$)
   {my ($t, $in) = @_;
    return unless $t;
    __SUB__->($t->left, $in+1);                                                 # Left
    push @s, [$t->keys->[$_], $t->data->[$_]] for keys $t->keys->@*;            # Find key in node
    __SUB__->($t->right,   $in+1);                                              # Right
   }
  print $t, 0;
  formatTableBasic(\@s)
 } # printKeysAndData

sub checkLRU($)                                                                 #P Confirm pointers in tree
 {my ($tree) = @_;                                                              # Tree
  my %seen;                                                                     # Nodes we have already seen

  sub                                                                           # Check pointers in a tree
   {my ($tree, $dir) = @_;                                                      # Tree
    return unless $tree;

    confess "Recursed $dir into: ".$tree->name if $seen{$tree->name}++;

    __SUB__->($tree->left,  Left);
    __SUB__->($tree->right, Right);
   }->($tree->root);
 }

sub check($)                                                                    #P Confirm that each node in a tree is ordered correctly
 {my ($tree) = @_;                                                              # Tree
  confess unless $tree;
  $tree->checkLRU;

  my $maxHeight = 0;

  sub
   {my ($tree) = @_;                                                            # Tree
    return unless $tree;

    __SUB__->($tree->left);
    __SUB__->($tree->right);

    confess $tree->name unless $tree->keys->@* == $tree->data->@*;              # Check key count matches data count

    if ( !$tree->leaf and !$tree->isRoot                                        # Confirm that all interior nodes  are fully filled
      and $tree->keys->@* != $tree->keysPerNode)
     {confess "Interior node not full: "
       .$tree->name."\n". $tree->root->printKeys;
     }

    confess $tree->name unless $tree->isRoot or                                 # Node is either a root  or a left or right child
      $tree->up && $tree->up->left  && $tree == $tree->up->left or
      $tree->up && $tree->up->right && $tree == $tree->up->right;

    confess 'Left:'.$tree->name if $tree->left and                              # Left child has correct parent
      !$tree->left->up || $tree->left->up != $tree;

    confess 'Right:'.$tree->name if $tree->right and                            # Right child has correct parent
      !$tree->right->up || $tree->right->up != $tree;

    if ($tree->simplex and !$tree->simplexWithLeaf and $tree->up                # Simplex children must always have duplex parents
      and !$tree->up->isRoot and !$tree->up->duplex)
     {confess "Simplex does not have duplex parent: ".$tree->name
       ."\n".$tree->root->printKeys;
     }

    $maxHeight = $tree->height if $tree->height > $maxHeight;

    my @k  = $tree->keys->@*;                                                   # Check keys
       @k <= $tree->keysPerNode or confess "Too many keys:".scalar(@k);
    for my $i(keys @k)
     {confess "undef key position $i" unless defined $k[$i];
     }

    my @d  = $tree->data->@*;                                                   # Check data
       @d <= $tree->keysPerNode or confess "Too many data:".scalar(@d);

    my %k;
    for my $i(1..$#k)
     {confess  "Out of order: ",   dump(\@k) if $k[$i-1] >= $k[$i];
      confess  "Duplicate key: ",  $k[$i] if $k{$k[$i]}++;
      confess  "Undefined data: ", $k[$i] unless defined $d[$i];
     }
   }->($tree);

  if ($tree->height < $maxHeight)                                               # Check tree heights
   {cluck "Tree height failure at: ", $tree->name;
    save($tree);
   }
 } # check

sub checkAgainstHash($%)                                                        #P Check a tree against a hash
 {my ($t, %t) = @_;                                                             # Tree, expected

  for my $k(keys %t)                                                            # Check we can find all the keys expected
   {my ($t) = @_;
    my $v = $t{$k};
    confess "Cannot find $k" unless my $f = find($t, $k);
    confess "Found $f but expected $v" unless $f == $v;
   }

  sub                                                                           # Check that the tree does not contain unexpected keys
   {my ($t) = @_;
    return unless $t;

    __SUB__->($t->left);                                                        # Left
    for($t->keys->@*)
     {confess $_ unless delete $t{$_};
     }
    __SUB__->($t->right);                                                       # Right
   }->($t);

  confess if keys %t;                                                           # They should have all been deleted
 } # checkAgainstHash
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

Tree::Bulk - Bulk Tree operations

=head1 Synopsis

Bulk trees store several (key,data) pairs in each node of a balanced tree to
reduce the number of tree pointers: up, left, right, etc. used to maintain the
tree.  This has no useful effect in Perl code, but in C code, especially C code
that uses SIMD instructions, the savings in space can be considerable which
allows the processor caches to be used more effectively. This module
demonstrates insert, find, delete operations on bulk trees as a basis for
coding these algorithms more efficiently in assembler code.

  is_deeply $t->printKeys, <<END;
SA0 4 1 2 3 4
Lz2 1     5 6 7 8->9 10 11 12
Rd1 3   9 10 11 12->1 2 3 4
Lz3 1       13 14 15 16->17 18 19 20
Rd2 2     17 18 19 20->9 10 11 12
Rz3 1       21 22->17 18 19 20
END

  for my $n($t->inorder)
   {$n->setKeysPerNode(2);
   }

  is_deeply $t->printKeys, <<END;
SA0 5 1 2
Lz3 1       3 4->5 6
Ld2 2     5 6->9 10
Rz3 1       7 8->5 6
Rd1 4   9 10->1 2
Lz4 1         11 12->13 14
Ld3 2       13 14->17 18
Rz4 1         15 16->13 14
Rd2 3     17 18->9 10
Rr3 2       19 20->17 18
Rz4 1         21 22->19 20
END

=head1 Description

Bulk Tree operations


Version "20210302".


The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.



=head1 Bulk Tree

Bulk Tree

=head2 isRoot($tree)

Return the tree if it is the root

     Parameter  Description
  1  $tree      Tree

B<Example:>


  if (1)
   {lll "Attributes";
    my  $t = Tree::Bulk::new->setKeysPerNode(1);
    my  $b = $t->insert(2,4);
    my  $a = $t->insert(1,2);
    my  $c = $t->insert(3,6);
    ok  $a->isLeftChild;
    ok  $c->isRightChild;
    ok !$a->isRightChild;
    ok !$c->isLeftChild;

    ok  $b->isRoot;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    ok !$a->isRoot;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    ok !$c->isRoot;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    ok  $a->leaf;
    ok  $c->leaf;
    ok  $b->duplex;
    ok  $c->root == $b;
    ok  $c->root != $a;
   }


=head2 root($tree)

Return the root node of a tree

     Parameter  Description
  1  $tree      Tree

B<Example:>


  if (1)
   {lll "Attributes";
    my  $t = Tree::Bulk::new->setKeysPerNode(1);
    my  $b = $t->insert(2,4);
    my  $a = $t->insert(1,2);
    my  $c = $t->insert(3,6);
    ok  $a->isLeftChild;
    ok  $c->isRightChild;
    ok !$a->isRightChild;
    ok !$c->isLeftChild;
    ok  $b->isRoot;
    ok !$a->isRoot;
    ok !$c->isRoot;
    ok  $a->leaf;
    ok  $c->leaf;
    ok  $b->duplex;

    ok  $c->root == $b;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    ok  $c->root != $a;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

   }


=head2 leaf($tree)

Return the tree if it is a leaf

     Parameter  Description
  1  $tree      Tree

B<Example:>


  if (1)
   {lll "Attributes";
    my  $t = Tree::Bulk::new->setKeysPerNode(1);
    my  $b = $t->insert(2,4);
    my  $a = $t->insert(1,2);
    my  $c = $t->insert(3,6);
    ok  $a->isLeftChild;
    ok  $c->isRightChild;
    ok !$a->isRightChild;
    ok !$c->isLeftChild;
    ok  $b->isRoot;
    ok !$a->isRoot;
    ok !$c->isRoot;

    ok  $a->leaf;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    ok  $c->leaf;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    ok  $b->duplex;
    ok  $c->root == $b;
    ok  $c->root != $a;
   }


=head2 duplex($tree)

Return the tree if it has left and right children

     Parameter  Description
  1  $tree      Tree

B<Example:>


  if (1)
   {lll "Attributes";
    my  $t = Tree::Bulk::new->setKeysPerNode(1);
    my  $b = $t->insert(2,4);
    my  $a = $t->insert(1,2);
    my  $c = $t->insert(3,6);
    ok  $a->isLeftChild;
    ok  $c->isRightChild;
    ok !$a->isRightChild;
    ok !$c->isLeftChild;
    ok  $b->isRoot;
    ok !$a->isRoot;
    ok !$c->isRoot;
    ok  $a->leaf;
    ok  $c->leaf;

    ok  $b->duplex;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    ok  $c->root == $b;
    ok  $c->root != $a;
   }


=head2 simplex($tree)

Return the tree if it has either a left child or a right child but not both.

     Parameter  Description
  1  $tree      Tree

B<Example:>


  if (1)
   {lll "SetHeights";
    my  $a = node(1,1)->setKeysPerNode(1);
    my  $b = node(2,2)->setKeysPerNode(1);
    my  $c = node(3,3)->setKeysPerNode(1);
    my  $d = node(4,4)->setKeysPerNode(1);
    my  $e = node(5,5);
    $a->right = $b; $b->up = $a;
    $b->right = $c; $c->up = $b;
    $c->right = $d; $d->up = $c;
    $d->right = $e; $e->up = $d;

    is_deeply $a->printKeys, <<END;
  SA0 1 1
  Rr1 1   2->1
  Rr2 1     3->2
  Rr3 1       4->3
  Rz4 1         5->4
  END
  #save $a;

    $e->setHeights(1);
    is_deeply $a->printKeys, <<END;
  SA0 4 1
  Rr1 3   2->1
  Lz3 1       3->4
  Rd2 2     4->2
  Rz3 1       5->4
  END
  #save $a;

    ok  $b->simplex;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    ok !$c->simplex;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    $c->balance;
    is_deeply $a->printKeys, <<END;
  SA0 4 1
  Rr1 3   2->1
  Lz3 1       3->4
  Rd2 2     4->2
  Rz3 1       5->4
  END
  #save $a;

    $b->balance;
    is_deeply $a->printKeys, <<END;
  SA0 4 1
  Lr2 2     2->4
  Rz3 1       3->2
  Rd1 3   4->1
  Rz2 1     5->4
  END
  #save $a;
   }


=head2 simplexWithLeaf($tree)

Return the tree if it has either a left child or a right child but not both and the child it has a leaf.

     Parameter  Description
  1  $tree      Tree

B<Example:>


  if (1)
   {lll "Balance";
    my  $a = node(1,1)->setKeysPerNode(1); $a->height = 5;
    my  $b = node(2,2)->setKeysPerNode(1); $b->height = 4;
    my  $c = node(3,3)->setKeysPerNode(1); $c->height = 3;
    my  $d = node(4,4)->setKeysPerNode(1); $d->height = 2;
    my  $e = node(5,5);                    $e->height = 1;
    $a->right = $b; $b->up = $a;
    $b->right = $c; $c->up = $b;
    $c->right = $d; $d->up = $c;
    $d->right = $e; $e->up = $d;

    $e->balance;
    is_deeply $a->printKeys, <<END;
  SA0 5 1
  Rr1 4   2->1
  Rr2 3     3->2
  Rr3 2       4->3
  Rz4 1         5->4
  END
  #save $a;

    ok  $d->simplexWithLeaf;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    ok !$c->simplexWithLeaf;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    $d->balance;
    is_deeply $a->printKeys, <<END;
  SA0 5 1
  Rr1 4   2->1
  Rr2 3     3->2
  Rr3 2       4->3
  Rz4 1         5->4
  END
  #save $a;

    $c->balance;
    is_deeply $a->printKeys, <<END;
  SA0 5 1
  Rr1 3   2->1
  Lz3 1       3->4
  Rd2 2     4->2
  Rz3 1       5->4
  END
  #save $a;

    $b->balance;
    is_deeply $a->printKeys, <<END;
  SA0 4 1
  Lr2 2     2->4
  Rz3 1       3->2
  Rd1 3   4->1
  Rz2 1     5->4
  END
  #save $a;
   }


=head2 empty($tree)

Return the tree if it is empty

     Parameter  Description
  1  $tree      Tree

B<Example:>


  if (1)
   {lll "Balance";
    my  $t = Tree::Bulk::new->setKeysPerNode(1);

    ok $t->empty;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    ok $t->singleton;
   }


=head2 singleton($tree)

Return the tree if it contains only the root node and nothing else

     Parameter  Description
  1  $tree      Tree

B<Example:>


  if (1)
   {lll "Balance";
    my  $t = Tree::Bulk::new->setKeysPerNode(1);
    ok $t->empty;

    ok $t->singleton;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

   }


=head2 isLeftChild($tree)

Return the tree if it is the left child

     Parameter  Description
  1  $tree      Tree

B<Example:>


  if (1)
   {lll "Attributes";
    my  $t = Tree::Bulk::new->setKeysPerNode(1);
    my  $b = $t->insert(2,4);
    my  $a = $t->insert(1,2);
    my  $c = $t->insert(3,6);

    ok  $a->isLeftChild;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    ok  $c->isRightChild;
    ok !$a->isRightChild;

    ok !$c->isLeftChild;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    ok  $b->isRoot;
    ok !$a->isRoot;
    ok !$c->isRoot;
    ok  $a->leaf;
    ok  $c->leaf;
    ok  $b->duplex;
    ok  $c->root == $b;
    ok  $c->root != $a;
   }


=head2 isRightChild($tree)

Return the tree if it is the right child

     Parameter  Description
  1  $tree      Tree

B<Example:>


  if (1)
   {lll "Attributes";
    my  $t = Tree::Bulk::new->setKeysPerNode(1);
    my  $b = $t->insert(2,4);
    my  $a = $t->insert(1,2);
    my  $c = $t->insert(3,6);
    ok  $a->isLeftChild;

    ok  $c->isRightChild;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    ok !$a->isRightChild;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    ok !$c->isLeftChild;
    ok  $b->isRoot;
    ok !$a->isRoot;
    ok !$c->isRoot;
    ok  $a->leaf;
    ok  $c->leaf;
    ok  $b->duplex;
    ok  $c->root == $b;
    ok  $c->root != $a;
   }


=head2 name($tree)

Name of a tree

     Parameter  Description
  1  $tree      Tree

B<Example:>


  if (1)
   {lll "Split and Refill";
    my $N = 22;
    my $t = Tree::Bulk::new;
    for my $k(1..$N)
     {$t->insert($k, 2 * $k);
     }


    is_deeply $t->name, "1 2 3 4";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    is_deeply $t->printKeys, <<END;
  SA0 4 1 2 3 4
  Lz2 1     5 6 7 8->9 10 11 12
  Rd1 3   9 10 11 12->1 2 3 4
  Lz3 1       13 14 15 16->17 18 19 20
  Rd2 2     17 18 19 20->9 10 11 12
  Rz3 1       21 22->17 18 19 20
  END
  #save $t;

    for my $n($t->inorder)
     {$n->setKeysPerNode(2);
     }
    is_deeply $t->printKeys, <<END;
  SA0 5 1 2
  Lz3 1       3 4->5 6
  Ld2 2     5 6->9 10
  Rz3 1       7 8->5 6
  Rd1 4   9 10->1 2
  Lz4 1         11 12->13 14
  Ld3 2       13 14->17 18
  Rz4 1         15 16->13 14
  Rd2 3     17 18->9 10
  Rr3 2       19 20->17 18
  Rz4 1         21 22->19 20
  END
  #save $t;

    for my $n($t->inorder)
     {$n->setKeysPerNode(1);
     }
    is_deeply $t->printKeys, <<END;
  SA0 6 1
  Lz4 1         2->3
  Ld3 2       3->5
  Rz4 1         4->3
  Ld2 3     5->9
  Lz4 1         6->7
  Rd3 2       7->5
  Rz4 1         8->7
  Rd1 5   9->1
  Lz5 1           10->11
  Ld4 2         11->13
  Rz5 1           12->11
  Ld3 3       13->17
  Lz5 1           14->15
  Rd4 2         15->13
  Rz5 1           16->15
  Rd2 4     17->9
  Lz4 1         18->19
  Rd3 3       19->17
  Lz5 1           20->21
  Rd4 2         21->19
  Rz5 1           22->21
  END
  #save $t;

    $_->setKeysPerNode(2) for $t->inorder;
    is_deeply $t->printKeys, <<END;
  SA0 5 1 2
  Lz3 1       3 4->5 6
  Ld2 2     5 6->9 10
  Rz3 1       7 8->5 6
  Rd1 4   9 10->1 2
  Lz4 1         11 12->13 14
  Ld3 2       13 14->17 18
  Rz4 1         15 16->13 14
  Rd2 3     17 18->9 10
  Lz4 1         19 20->21 22
  Rl3 2       21 22->17 18
  END
  #save $t;

    $_->setKeysPerNode(4) for $t->inorder;
    is_deeply $t->printKeys, <<END;
  SA0 4 1 2 3 4
  Lz2 1     5 6 7 8->9 10 11 12
  Rd1 3   9 10 11 12->1 2 3 4
  Lz3 1       13 14 15 16->17 18 19 20
  Rd2 2     17 18 19 20->9 10 11 12
  Rz3 1       21 22->17 18 19 20
  END
  #save $t;
   }


=head2 names($tree)

Names of all nodes in a tree in order

     Parameter  Description
  1  $tree      Tree

B<Example:>


  if (1)
   {my sub randomLoad($$$)                                                        # Randomly load different size nodes
     {my ($N, $keys, $height) = @_;                                               # Number of elements, number of keys per node, expected height

      lll "Random load $keys";

      srand(1);                                                                   # Same randomization
      my $t = Tree::Bulk::new->setKeysPerNode($keys);
      for my $r(randomizeArray 1..$N)
       {$debug = $r == 74;
        $t->insert($r, 2 * $r);
        $t->check;
       }

      is_deeply $t->actualHeight, $height;                                        # Check height
      confess unless $t->actualHeight == $height;

      is_deeply join(' ', 1..$N), $t->names;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


      my %t = map {$_=>2*$_}   1..$N;
      for my $r(randomizeArray 1..$N)                                             # Delete in random order
       {$t->delete   ($r);
            delete $t{$r};
        checkAgainstHash $t, %t;
        check($t);
       }

      ok $t->empty;
      is_deeply $t->actualHeight, 1;
     }

    randomLoad(222, 1, 11);
    randomLoad(222, 8, 8);
    randomLoad(222, 4, 9);
   }


=head2 balance($t)

Balance a node

     Parameter  Description
  1  $t         Tree

B<Example:>


  if (1)
   {lll "Balance";
    my  $t = Tree::Bulk::new->setKeysPerNode(1);

    my  $a = node(1,2) ->setKeysPerNode(1);
    my  $b = node(2,4) ->setKeysPerNode(1);
    my  $c = node(6,12)->setKeysPerNode(1);
    my  $d = node(5,10)->setKeysPerNode(1);
    my  $e = node(4,8) ->setKeysPerNode(1);
    my  $f = node(3,6) ->setKeysPerNode(1);
    $a->right = $b; $b->up = $a;
    $b->right = $c; $c->up = $b;
    $c->left  = $d; $d->up = $c;
    $d->left  = $e; $e->up = $d;
    $e->left  = $f; $f->up = $e;
    $f->setHeights(1);
    is_deeply $a->printKeys, <<END;
  SA0 4 1
  Lr2 2     2->4
  Rz3 1       3->2
  Rd1 3   4->1
  Lz3 1       5->6
  Rl2 2     6->4
  END
  #save $a;


    $b->balance;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply $a->printKeys, <<END;
  SA0 4 1
  Lr2 2     2->4
  Rz3 1       3->2
  Rd1 3   4->1
  Lz3 1       5->6
  Rl2 2     6->4
  END
  #save $a;
   }


=head2 insert($tree, $key, $data)

Insert a key and some data into a tree

     Parameter  Description
  1  $tree      Tree
  2  $key       Key
  3  $data      Data

B<Example:>


  if (1)
   {lll "Insert";
    my $N = 23;
    my $t = Tree::Bulk::new->setKeysPerNode(1);
    for(1..$N)

     {$t->insert($_, 2 * $_);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     }

    is_deeply $t->printKeys, <<END;
  SA0 8 1
  Lz4 1         2->3
  Ld3 2       3->5
  Rz4 1         4->3
  Ld2 3     5->9
  Lz4 1         6->7
  Rd3 2       7->5
  Rz4 1         8->7
  Rd1 7   9->1
  Lz4 1         10->11
  Ld3 2       11->13
  Rz4 1         12->11
  Rd2 6     13->9
  Lz5 1           14->15
  Ld4 2         15->17
  Rz5 1           16->15
  Rd3 5       17->13
  Lz5 1           18->19
  Rd4 4         19->17
  Lz6 1             20->21
  Rd5 3           21->19
  Rr6 2             22->21
  Rz7 1               23->22
  END
  #save $t;
    ok $t->height == 8;
   }


=head2 find($tree, $key)

Find a key in a tree and returns its data

     Parameter  Description
  1  $tree      Tree
  2  $key       Key

B<Example:>


  if (1)
   {my $t = Tree::Bulk::new;
       $t->insert($_, $_*$_)    for  1..20;

    ok !find($t,  0);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    ok !find($t, 21);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    ok  find($t, $_) == $_ * $_ for qw(1 5 10 11 15 20);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

   }


=head2 first($n)

First node in a tree

     Parameter  Description
  1  $n         Tree

B<Example:>


  if (1)
   {my $N = 220;
    my $t = Tree::Bulk::new;

    for(reverse 1..$N)
     {$t->insert($_, 2*$_);
     }

    is_deeply $t->actualHeight, 10;

    if (1)
     {my @n;

      for (my $n = $t->first; $n; $n = $n->next)  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       {push @n, $n->keys->@*
       }
      is_deeply \@n, [1..$N];
     }

    if (1)
     {my @p;
      for my $p(reverse $t->inorder)
       {push @p, reverse $p->keys->@*;
       }
      is_deeply \@p, [reverse 1..$N];
     }

    my @p;
    for(my $p = $t->last; $p; $p = $p->prev)
     {push @p, reverse $p->keys->@*
     }
    is_deeply \@p, [reverse 1..$N];

    my %t = map {$_=>2*$_} 1..$N;
    for   my $i(0..3)
     {for my $j(map {4 * $_-$i} 1..$N/4)
       {$t->delete   ($j);
            delete $t{$j};
        checkAgainstHash $t, %t;
       }
     }

    ok $t->empty;
    is_deeply $t->actualHeight, 1;
   }


=head2 last($n)

Last node in a tree

     Parameter  Description
  1  $n         Tree

B<Example:>


  if (1)
   {my $N = 220;
    my $t = Tree::Bulk::new;

    for(reverse 1..$N)
     {$t->insert($_, 2*$_);
     }

    is_deeply $t->actualHeight, 10;

    if (1)
     {my @n;
      for (my $n = $t->first; $n; $n = $n->next)
       {push @n, $n->keys->@*
       }
      is_deeply \@n, [1..$N];
     }

    if (1)
     {my @p;
      for my $p(reverse $t->inorder)
       {push @p, reverse $p->keys->@*;
       }
      is_deeply \@p, [reverse 1..$N];
     }

    my @p;

    for(my $p = $t->last; $p; $p = $p->prev)  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     {push @p, reverse $p->keys->@*
     }
    is_deeply \@p, [reverse 1..$N];

    my %t = map {$_=>2*$_} 1..$N;
    for   my $i(0..3)
     {for my $j(map {4 * $_-$i} 1..$N/4)
       {$t->delete   ($j);
            delete $t{$j};
        checkAgainstHash $t, %t;
       }
     }

    ok $t->empty;
    is_deeply $t->actualHeight, 1;
   }


=head2 next($tree)

Next node in order

     Parameter  Description
  1  $tree      Tree

B<Example:>


  if (1)
   {my $N = 220;
    my $t = Tree::Bulk::new;

    for(reverse 1..$N)
     {$t->insert($_, 2*$_);
     }

    is_deeply $t->actualHeight, 10;

    if (1)
     {my @n;

      for (my $n = $t->first; $n; $n = $n->next)  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       {push @n, $n->keys->@*
       }
      is_deeply \@n, [1..$N];
     }

    if (1)
     {my @p;
      for my $p(reverse $t->inorder)
       {push @p, reverse $p->keys->@*;
       }
      is_deeply \@p, [reverse 1..$N];
     }

    my @p;
    for(my $p = $t->last; $p; $p = $p->prev)
     {push @p, reverse $p->keys->@*
     }
    is_deeply \@p, [reverse 1..$N];

    my %t = map {$_=>2*$_} 1..$N;
    for   my $i(0..3)
     {for my $j(map {4 * $_-$i} 1..$N/4)
       {$t->delete   ($j);
            delete $t{$j};
        checkAgainstHash $t, %t;
       }
     }

    ok $t->empty;
    is_deeply $t->actualHeight, 1;
   }


=head2 prev($tree)

Previous node in order

     Parameter  Description
  1  $tree      Tree

B<Example:>


  if (1)
   {my $N = 220;
    my $t = Tree::Bulk::new;

    for(reverse 1..$N)
     {$t->insert($_, 2*$_);
     }

    is_deeply $t->actualHeight, 10;

    if (1)
     {my @n;
      for (my $n = $t->first; $n; $n = $n->next)
       {push @n, $n->keys->@*
       }
      is_deeply \@n, [1..$N];
     }

    if (1)
     {my @p;
      for my $p(reverse $t->inorder)
       {push @p, reverse $p->keys->@*;
       }
      is_deeply \@p, [reverse 1..$N];
     }

    my @p;

    for(my $p = $t->last; $p; $p = $p->prev)  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     {push @p, reverse $p->keys->@*
     }
    is_deeply \@p, [reverse 1..$N];

    my %t = map {$_=>2*$_} 1..$N;
    for   my $i(0..3)
     {for my $j(map {4 * $_-$i} 1..$N/4)
       {$t->delete   ($j);
            delete $t{$j};
        checkAgainstHash $t, %t;
       }
     }

    ok $t->empty;
    is_deeply $t->actualHeight, 1;
   }


=head2 inorder($tree)

Return a list of all the nodes in a tree in order

     Parameter  Description
  1  $tree      Tree

B<Example:>


  if (1)
   {my $N = 220;
    my $t = Tree::Bulk::new;

    for(reverse 1..$N)
     {$t->insert($_, 2*$_);
     }

    is_deeply $t->actualHeight, 10;

    if (1)
     {my @n;
      for (my $n = $t->first; $n; $n = $n->next)
       {push @n, $n->keys->@*
       }
      is_deeply \@n, [1..$N];
     }

    if (1)
     {my @p;

      for my $p(reverse $t->inorder)  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       {push @p, reverse $p->keys->@*;
       }
      is_deeply \@p, [reverse 1..$N];
     }

    my @p;
    for(my $p = $t->last; $p; $p = $p->prev)
     {push @p, reverse $p->keys->@*
     }
    is_deeply \@p, [reverse 1..$N];

    my %t = map {$_=>2*$_} 1..$N;
    for   my $i(0..3)
     {for my $j(map {4 * $_-$i} 1..$N/4)
       {$t->delete   ($j);
            delete $t{$j};
        checkAgainstHash $t, %t;
       }
     }

    ok $t->empty;
    is_deeply $t->actualHeight, 1;
   }


=head2 delete($tree, $key)

Delete a key in a tree

     Parameter  Description
  1  $tree      Tree
  2  $key       Key

B<Example:>


  if (1)
   {lll "Delete";
    my $N = 28;
    my $t = Tree::Bulk::new->setKeysPerNode(1);
    for(1..$N)
     {$t->insert($_, 2 * $_);
     }

    is_deeply $t->printKeys, <<END;
  SA0 8 1
  Lz4 1         2->3
  Ld3 2       3->5
  Rz4 1         4->3
  Ld2 3     5->9
  Lz4 1         6->7
  Rd3 2       7->5
  Rz4 1         8->7
  Rd1 7   9->1
  Lz5 1           10->11
  Ld4 2         11->13
  Rz5 1           12->11
  Ld3 3       13->17
  Lz5 1           14->15
  Rd4 2         15->13
  Rz5 1           16->15
  Rd2 6     17->9
  Lz5 1           18->19
  Ld4 2         19->21
  Rz5 1           20->19
  Rd3 5       21->17
  Lz5 1           22->23
  Rd4 4         23->21
  Lz6 1             24->25
  Rd5 3           25->23
  Lz7 1               26->27
  Rd6 2             27->25
  Rz7 1               28->27
  END
  #save $t;

    for my $k(reverse 1..$N)

     {$t->delete($k);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      is_deeply $t->printKeys, <<END if $k == 17;
  SA0 5 1
  Lz4 1         2->3
  Ld3 2       3->5
  Rz4 1         4->3
  Ld2 3     5->9
  Lz4 1         6->7
  Rd3 2       7->5
  Rz4 1         8->7
  Rd1 4   9->1
  Lz4 1         10->11
  Ld3 2       11->13
  Rz4 1         12->11
  Rd2 3     13->9
  Lz4 1         14->15
  Rd3 2       15->13
  Rz4 1         16->15
  END
  #save $t if $k == 17;

      is_deeply $t->printKeys, <<END if $k == 9;
  SA0 4 1
  Lz3 1       2->3
  Ld2 2     3->5
  Rz3 1       4->3
  Rd1 3   5->1
  Lz3 1       6->7
  Rd2 2     7->5
  Rz3 1       8->7
  END
  #save $t if $k == 9;

      is_deeply $t->printKeys, <<END if $k == 6;
  SA0 4 1
  Lz2 1     2->3
  Rd1 3   3->1
  Lz3 1       4->5
  Rl2 2     5->3
  END
  #save $t if $k == 6;

      is_deeply $t->printKeys, <<END if $k == 4;
  SA0 3 1
  Rr1 2   2->1
  Rz2 1     3->2
  END
  #save $t if $k == 4;

      is_deeply $t->printKeys, <<END if $k == 3;
  SA0 2 1
  Rz1 1   2->1
  END
  #save $t if $k == 3;

      is_deeply $t->printKeys, <<END if $k == 1;
  Sz0 1
  END
  #save $t if $k == 1;
     }
   }


=head2 printKeys($t)

Print the keys in a tree

     Parameter  Description
  1  $t         Tree

B<Example:>


  if (1)
   {lll "Insert";
    my $N = 23;
    my $t = Tree::Bulk::new->setKeysPerNode(1);
    for(1..$N)
     {$t->insert($_, 2 * $_);
     }


    is_deeply $t->printKeys, <<END;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  SA0 8 1
  Lz4 1         2->3
  Ld3 2       3->5
  Rz4 1         4->3
  Ld2 3     5->9
  Lz4 1         6->7
  Rd3 2       7->5
  Rz4 1         8->7
  Rd1 7   9->1
  Lz4 1         10->11
  Ld3 2       11->13
  Rz4 1         12->11
  Rd2 6     13->9
  Lz5 1           14->15
  Ld4 2         15->17
  Rz5 1           16->15
  Rd3 5       17->13
  Lz5 1           18->19
  Rd4 4         19->17
  Lz6 1             20->21
  Rd5 3           21->19
  Rr6 2             22->21
  Rz7 1               23->22
  END
  #save $t;
    ok $t->height == 8;
   }


=head2 setKeysPerNode($tree, $N)

Set the number of keys for the current node

     Parameter  Description
  1  $tree      Tree
  2  $N         Keys per node to be set

B<Example:>


  if (1)
   {lll "Split and Refill";
    my $N = 22;
    my $t = Tree::Bulk::new;
    for my $k(1..$N)
     {$t->insert($k, 2 * $k);
     }

    is_deeply $t->name, "1 2 3 4";

    is_deeply $t->printKeys, <<END;
  SA0 4 1 2 3 4
  Lz2 1     5 6 7 8->9 10 11 12
  Rd1 3   9 10 11 12->1 2 3 4
  Lz3 1       13 14 15 16->17 18 19 20
  Rd2 2     17 18 19 20->9 10 11 12
  Rz3 1       21 22->17 18 19 20
  END
  #save $t;

    for my $n($t->inorder)

     {$n->setKeysPerNode(2);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     }
    is_deeply $t->printKeys, <<END;
  SA0 5 1 2
  Lz3 1       3 4->5 6
  Ld2 2     5 6->9 10
  Rz3 1       7 8->5 6
  Rd1 4   9 10->1 2
  Lz4 1         11 12->13 14
  Ld3 2       13 14->17 18
  Rz4 1         15 16->13 14
  Rd2 3     17 18->9 10
  Rr3 2       19 20->17 18
  Rz4 1         21 22->19 20
  END
  #save $t;

    for my $n($t->inorder)

     {$n->setKeysPerNode(1);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     }
    is_deeply $t->printKeys, <<END;
  SA0 6 1
  Lz4 1         2->3
  Ld3 2       3->5
  Rz4 1         4->3
  Ld2 3     5->9
  Lz4 1         6->7
  Rd3 2       7->5
  Rz4 1         8->7
  Rd1 5   9->1
  Lz5 1           10->11
  Ld4 2         11->13
  Rz5 1           12->11
  Ld3 3       13->17
  Lz5 1           14->15
  Rd4 2         15->13
  Rz5 1           16->15
  Rd2 4     17->9
  Lz4 1         18->19
  Rd3 3       19->17
  Lz5 1           20->21
  Rd4 2         21->19
  Rz5 1           22->21
  END
  #save $t;


    $_->setKeysPerNode(2) for $t->inorder;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply $t->printKeys, <<END;
  SA0 5 1 2
  Lz3 1       3 4->5 6
  Ld2 2     5 6->9 10
  Rz3 1       7 8->5 6
  Rd1 4   9 10->1 2
  Lz4 1         11 12->13 14
  Ld3 2       13 14->17 18
  Rz4 1         15 16->13 14
  Rd2 3     17 18->9 10
  Lz4 1         19 20->21 22
  Rl3 2       21 22->17 18
  END
  #save $t;


    $_->setKeysPerNode(4) for $t->inorder;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply $t->printKeys, <<END;
  SA0 4 1 2 3 4
  Lz2 1     5 6 7 8->9 10 11 12
  Rd1 3   9 10 11 12->1 2 3 4
  Lz3 1       13 14 15 16->17 18 19 20
  Rd2 2     17 18 19 20->9 10 11 12
  Rz3 1       21 22->17 18 19 20
  END
  #save $t;
   }


=head2 printKeysAndData($t)

Print the mapping from keys to data in a tree

     Parameter  Description
  1  $t         Tree

B<Example:>


  if (1)
   {my $N = 22;
    my $t = Tree::Bulk::new;
    ok $t->empty;
    ok $t->leaf;

    for(1..$N)
     {$t->insert($_, 2 * $_);
     }

    ok $t->right->duplex;
    is_deeply actualHeight($t), 4;

    is_deeply $t->printKeys, <<END;
  SA0 4 1 2 3 4
  Lz2 1     5 6 7 8->9 10 11 12
  Rd1 3   9 10 11 12->1 2 3 4
  Lz3 1       13 14 15 16->17 18 19 20
  Rd2 2     17 18 19 20->9 10 11 12
  Rz3 1       21 22->17 18 19 20
  END
  #save $t;


    is_deeply $t->printKeysAndData, <<END;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

   1   2
   2   4
   3   6
   4   8
   5  10
   6  12
   7  14
   8  16
   9  18
  10  20
  11  22
  12  24
  13  26
  14  28
  15  30
  16  32
  17  34
  18  36
  19  38
  20  40
  21  42
  22  44
  END

    my %t = map {$_=>2*$_} 1..$N;

    for(map {2 * $_} 1..$N/2)
     {$t->delete($_);
      delete $t{$_};
      checkAgainstHash $t, %t;
     }

    is_deeply $t->printKeys, <<END;
  SA0 3 1 3 5 7
  Rr1 2   9 11 13 15->1 3 5 7
  Rz2 1     17 19 21->9 11 13 15
  END
  #save($t);


    is_deeply $t->printKeysAndData, <<END;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

   1   2
   3   6
   5  10
   7  14
   9  18
  11  22
  13  26
  15  30
  17  34
  19  38
  21  42
  END

    for(map {2 * $_-1} 1..$N/2)
     {$t->delete($_);
      delete $t{$_};
      checkAgainstHash $t, %t;
     }

    is_deeply $t->printKeys, <<END;
  Sz0 1
  END
  #save($t);
   }



=head2 Tree::Bulk Definition


Bulk tree node




=head3 Output fields


=head4 data

Data corresponding to each key

=head4 height

Height of node

=head4 keys

Array of data items for this node

=head4 keysPerNode

Maximum number of keys per node

=head4 left

Left node

=head4 right

Right node

=head4 up

Parent node



=head1 Attributes


The following is a list of all the attributes in this package.  A method coded
with the same name in your package will over ride the method of the same name
in this package and thus provide your value for the attribute in place of the
default value supplied for this attribute by this package.

=head2 Replaceable Attribute List


new


=head2 new

Create a new tree




=head1 Private Methods

=head2 node($key, $data, $up, $side)

Create a new bulk tree node

     Parameter  Description
  1  $key       Key
  2  $data      $data
  3  $up        Parent node
  4  $side      Side of parent node

=head2 setHeights($tree)

Set heights along path to root

     Parameter  Description
  1  $tree      Tree

B<Example:>


  if (1)
   {lll "Balance";
    my  $t = Tree::Bulk::new->setKeysPerNode(1);

    my  $a = node(1,2) ->setKeysPerNode(1);
    my  $b = node(2,4) ->setKeysPerNode(1);
    my  $c = node(6,12)->setKeysPerNode(1);
    my  $d = node(5,10)->setKeysPerNode(1);
    my  $e = node(4,8) ->setKeysPerNode(1);
    my  $f = node(3,6) ->setKeysPerNode(1);
    $a->right = $b; $b->up = $a;
    $b->right = $c; $c->up = $b;
    $c->left  = $d; $d->up = $c;
    $d->left  = $e; $e->up = $d;
    $e->left  = $f; $f->up = $e;

    $f->setHeights(1);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply $a->printKeys, <<END;
  SA0 4 1
  Lr2 2     2->4
  Rz3 1       3->2
  Rd1 3   4->1
  Lz3 1       5->6
  Rl2 2     6->4
  END
  #save $a;

    $b->balance;
    is_deeply $a->printKeys, <<END;
  SA0 4 1
  Lr2 2     2->4
  Rz3 1       3->2
  Rd1 3   4->1
  Lz3 1       5->6
  Rl2 2     6->4
  END
  #save $a;
   }


=head2 actualHeight($tree)

Get the height of a node

     Parameter  Description
  1  $tree      Tree

B<Example:>


  if (1)
   {my $N = 22;
    my $t = Tree::Bulk::new;
    ok $t->empty;
    ok $t->leaf;

    for(1..$N)
     {$t->insert($_, 2 * $_);
     }

    ok $t->right->duplex;

    is_deeply actualHeight($t), 4;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    is_deeply $t->printKeys, <<END;
  SA0 4 1 2 3 4
  Lz2 1     5 6 7 8->9 10 11 12
  Rd1 3   9 10 11 12->1 2 3 4
  Lz3 1       13 14 15 16->17 18 19 20
  Rd2 2     17 18 19 20->9 10 11 12
  Rz3 1       21 22->17 18 19 20
  END
  #save $t;

    is_deeply $t->printKeysAndData, <<END;
   1   2
   2   4
   3   6
   4   8
   5  10
   6  12
   7  14
   8  16
   9  18
  10  20
  11  22
  12  24
  13  26
  14  28
  15  30
  16  32
  17  34
  18  36
  19  38
  20  40
  21  42
  22  44
  END

    my %t = map {$_=>2*$_} 1..$N;

    for(map {2 * $_} 1..$N/2)
     {$t->delete($_);
      delete $t{$_};
      checkAgainstHash $t, %t;
     }

    is_deeply $t->printKeys, <<END;
  SA0 3 1 3 5 7
  Rr1 2   9 11 13 15->1 3 5 7
  Rz2 1     17 19 21->9 11 13 15
  END
  #save($t);

    is_deeply $t->printKeysAndData, <<END;
   1   2
   3   6
   5  10
   7  14
   9  18
  11  22
  13  26
  15  30
  17  34
  19  38
  21  42
  END

    for(map {2 * $_-1} 1..$N/2)
     {$t->delete($_);
      delete $t{$_};
      checkAgainstHash $t, %t;
     }

    is_deeply $t->printKeys, <<END;
  Sz0 1
  END
  #save($t);
   }


=head2 maximum($a, $b)

Maximum of two numbers

     Parameter  Description
  1  $a         First
  2  $b         Second

B<Example:>


  if (1)

   {is_deeply maximum(1,2), 2;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    is_deeply maximum(2,1), 2;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

   }


=head2 setHeight($tree)

Set height of a tree from its left and right trees

     Parameter  Description
  1  $tree      Tree

=head2 rotateLeft($n)

Rotate a node left

     Parameter  Description
  1  $n         Node

B<Example:>


  if (1)
   {lll "Rotate";
    my  $a = node(1,2)->setKeysPerNode(1);
    my  $b = node(2,4)->setKeysPerNode(1);
    my  $c = node(3,6)->setKeysPerNode(1);
    my  $d = node(4,8)->setKeysPerNode(1);
    $a->right = $b; $b->up = $a;
    $b->right = $c; $c->up = $b;
    $c->right = $d; $d->up = $c;
    $d->setHeights(1);

    is_deeply $a->printKeys, <<END;
  SA0 3 1
  Lz2 1     2->3
  Rd1 2   3->1
  Rz2 1     4->3
  END
  #save $a;

    $b->rotateLeft;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply $a->printKeys, <<END;
  SA0 3 1
  Lz2 1     2->3
  Rd1 2   3->1
  Rz2 1     4->3
  END
  #save $a;


    $c->rotateLeft; $c->setHeights(2);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply $a->printKeys, <<END;
  SA0 3 1
  Lz2 1     2->3
  Rd1 2   3->1
  Rz2 1     4->3
  END
  #save $a;

    $d->rotateRight; $d->setHeights(1);
    is_deeply $a->printKeys, <<END;
  SA0 3 1
  Lz2 1     2->3
  Rd1 2   3->1
  Rz2 1     4->3
  END
  #save $a;

    $c->rotateRight; $c->setHeights(2);
    is_deeply $a->printKeys, <<END;
  SA0 3 1
  Lz2 1     2->3
  Rd1 2   3->1
  Rz2 1     4->3
  END
  #save $a;
   }


=head2 rotateRight($n)

Rotate a node right

     Parameter  Description
  1  $n         Node

B<Example:>


  if (1)
   {lll "Rotate";
    my  $a = node(1,2)->setKeysPerNode(1);
    my  $b = node(2,4)->setKeysPerNode(1);
    my  $c = node(3,6)->setKeysPerNode(1);
    my  $d = node(4,8)->setKeysPerNode(1);
    $a->right = $b; $b->up = $a;
    $b->right = $c; $c->up = $b;
    $c->right = $d; $d->up = $c;
    $d->setHeights(1);

    is_deeply $a->printKeys, <<END;
  SA0 3 1
  Lz2 1     2->3
  Rd1 2   3->1
  Rz2 1     4->3
  END
  #save $a;
    $b->rotateLeft;
    is_deeply $a->printKeys, <<END;
  SA0 3 1
  Lz2 1     2->3
  Rd1 2   3->1
  Rz2 1     4->3
  END
  #save $a;

    $c->rotateLeft; $c->setHeights(2);
    is_deeply $a->printKeys, <<END;
  SA0 3 1
  Lz2 1     2->3
  Rd1 2   3->1
  Rz2 1     4->3
  END
  #save $a;


    $d->rotateRight; $d->setHeights(1);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply $a->printKeys, <<END;
  SA0 3 1
  Lz2 1     2->3
  Rd1 2   3->1
  Rz2 1     4->3
  END
  #save $a;


    $c->rotateRight; $c->setHeights(2);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply $a->printKeys, <<END;
  SA0 3 1
  Lz2 1     2->3
  Rd1 2   3->1
  Rz2 1     4->3
  END
  #save $a;
   }


=head2 insertUnchecked($tree, $key, $data)

Insert a key and some data into a tree

     Parameter  Description
  1  $tree      Tree
  2  $key       Key
  3  $data      Data

=head2 unchain($t)

Remove a tree from the middle of a chain. A leaf is considered to be in the middle of a chain and so can be removed with this method

     Parameter  Description
  1  $t         Tree

=head2 refillFromRight($target)

Push a key to the target node from the next node

     Parameter  Description
  1  $target    Target tree

=head2 refillFromLeft($target)

Push a key to the target node from the previous node

     Parameter  Description
  1  $target    Target tree

=head2 refill($tree)

Refill a node so it has the expected number of keys

     Parameter  Description
  1  $tree      Tree

=head2 printKeys2($t, $in, $g)

print the keys for a tree

     Parameter  Description
  1  $t         Tree
  2  $in        Indentation
  3  $g         List of keys

=head2 checkLRU($tree)

Confirm pointers in tree

     Parameter  Description
  1  $tree      Tree

=head2 check($tree)

Confirm that each node in a tree is ordered correctly

     Parameter  Description
  1  $tree      Tree

=head2 checkAgainstHash($t, %t)

Check a tree against a hash

     Parameter  Description
  1  $t         Tree
  2  %t         Expected


=head1 Index


1 L<actualHeight|/actualHeight> - Get the height of a node

2 L<balance|/balance> - Balance a node

3 L<check|/check> - Confirm that each node in a tree is ordered correctly

4 L<checkAgainstHash|/checkAgainstHash> - Check a tree against a hash

5 L<checkLRU|/checkLRU> - Confirm pointers in tree

6 L<delete|/delete> - Delete a key in a tree

7 L<duplex|/duplex> - Return the tree if it has left and right children

8 L<empty|/empty> - Return the tree if it is empty

9 L<find|/find> - Find a key in a tree and returns its data

10 L<first|/first> - First node in a tree

11 L<inorder|/inorder> - Return a list of all the nodes in a tree in order

12 L<insert|/insert> - Insert a key and some data into a tree

13 L<insertUnchecked|/insertUnchecked> - Insert a key and some data into a tree

14 L<isLeftChild|/isLeftChild> - Return the tree if it is the left child

15 L<isRightChild|/isRightChild> - Return the tree if it is the right child

16 L<isRoot|/isRoot> - Return the tree if it is the root

17 L<last|/last> - Last node in a tree

18 L<leaf|/leaf> - Return the tree if it is a leaf

19 L<maximum|/maximum> - Maximum of two numbers

20 L<name|/name> - Name of a tree

21 L<names|/names> - Names of all nodes in a tree in order

22 L<next|/next> - Next node in order

23 L<node|/node> - Create a new bulk tree node

24 L<prev|/prev> - Previous node in order

25 L<printKeys|/printKeys> - Print the keys in a tree

26 L<printKeys2|/printKeys2> - print the keys for a tree

27 L<printKeysAndData|/printKeysAndData> - Print the mapping from keys to data in a tree

28 L<refill|/refill> - Refill a node so it has the expected number of keys

29 L<refillFromLeft|/refillFromLeft> - Push a key to the target node from the previous node

30 L<refillFromRight|/refillFromRight> - Push a key to the target node from the next node

31 L<root|/root> - Return the root node of a tree

32 L<rotateLeft|/rotateLeft> - Rotate a node left

33 L<rotateRight|/rotateRight> - Rotate a node right

34 L<setHeight|/setHeight> - Set height of a tree from its left and right trees

35 L<setHeights|/setHeights> - Set heights along path to root

36 L<setKeysPerNode|/setKeysPerNode> - Set the number of keys for the current node

37 L<simplex|/simplex> - Return the tree if it has either a left child or a right child but not both.

38 L<simplexWithLeaf|/simplexWithLeaf> - Return the tree if it has either a left child or a right child but not both and the child it has a leaf.

39 L<singleton|/singleton> - Return the tree if it contains only the root node and nothing else

40 L<unchain|/unchain> - Remove a tree from the middle of a chain.

=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read,
comprehend, use, modify and install via B<cpan>:

  sudo cpan install Tree::Bulk

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
use Test::More;

my $localTest = ((caller(1))[0]//'Tree::Bulk') eq "Tree::Bulk";                 # Local testing mode

Test::More->builder->output("/dev/null") if $localTest;                         # Reduce number of confirmation messages during testing

if ($^O =~ m(bsd|linux)i) {plan tests => 90}                                    # Supported systems
else
 {plan skip_all =>qq(Not supported on: $^O);
 }

my $start = time;                                                               # Tests

if (1)                                                                          #Tsimplex
 {lll "SetHeights";
  my  $a = node(1,1)->setKeysPerNode(1);
  my  $b = node(2,2)->setKeysPerNode(1);
  my  $c = node(3,3)->setKeysPerNode(1);
  my  $d = node(4,4)->setKeysPerNode(1);
  my  $e = node(5,5);
  $a->right = $b; $b->up = $a;
  $b->right = $c; $c->up = $b;
  $c->right = $d; $d->up = $c;
  $d->right = $e; $e->up = $d;

  is_deeply $a->printKeys, <<END;
SA0 1 1
Rr1 1   2->1
Rr2 1     3->2
Rr3 1       4->3
Rz4 1         5->4
END
#save $a;

  $e->setHeights(1);
  is_deeply $a->printKeys, <<END;
SA0 4 1
Rr1 3   2->1
Lz3 1       3->4
Rd2 2     4->2
Rz3 1       5->4
END
#save $a;
  ok  $b->simplex;
  ok !$c->simplex;

  $c->balance;
  is_deeply $a->printKeys, <<END;
SA0 4 1
Rr1 3   2->1
Lz3 1       3->4
Rd2 2     4->2
Rz3 1       5->4
END
#save $a;

  $b->balance;
  is_deeply $a->printKeys, <<END;
SA0 4 1
Lr2 2     2->4
Rz3 1       3->2
Rd1 3   4->1
Rz2 1     5->4
END
#save $a;
 }

if (1)                                                                          #TsimplexWithLeaf
 {lll "Balance";
  my  $a = node(1,1)->setKeysPerNode(1); $a->height = 5;
  my  $b = node(2,2)->setKeysPerNode(1); $b->height = 4;
  my  $c = node(3,3)->setKeysPerNode(1); $c->height = 3;
  my  $d = node(4,4)->setKeysPerNode(1); $d->height = 2;
  my  $e = node(5,5);                    $e->height = 1;
  $a->right = $b; $b->up = $a;
  $b->right = $c; $c->up = $b;
  $c->right = $d; $d->up = $c;
  $d->right = $e; $e->up = $d;

  $e->balance;
  is_deeply $a->printKeys, <<END;
SA0 5 1
Rr1 4   2->1
Rr2 3     3->2
Rr3 2       4->3
Rz4 1         5->4
END
#save $a;
  ok  $d->simplexWithLeaf;
  ok !$c->simplexWithLeaf;

  $d->balance;
  is_deeply $a->printKeys, <<END;
SA0 5 1
Rr1 4   2->1
Rr2 3     3->2
Rr3 2       4->3
Rz4 1         5->4
END
#save $a;

  $c->balance;
  is_deeply $a->printKeys, <<END;
SA0 5 1
Rr1 3   2->1
Lz3 1       3->4
Rd2 2     4->2
Rz3 1       5->4
END
#save $a;

  $b->balance;
  is_deeply $a->printKeys, <<END;
SA0 4 1
Lr2 2     2->4
Rz3 1       3->2
Rd1 3   4->1
Rz2 1     5->4
END
#save $a;
 }

if (1)
 {lll "Leaf becomes non leaf";
  my  $a = node(14,1)->setKeysPerNode(1); $a->height = 4;
  my  $b = node(5,2) ->setKeysPerNode(1); $b->height = 3;
  my  $c = node(4,3) ->setKeysPerNode(1); $c->height = 1;
  my  $d = node(9,4) ->setKeysPerNode(1); $d->height = 1;
  my  $e = node(10,5);                    $e->height = 2;
  $a->left  = $b; $b->up = $a;
  $b->left  = $c; $c->up = $b;
  $b->right = $e; $e->up = $b;
  $e->left  = $d; $d->up = $e;

  is_deeply $a->printKeys, <<END;
Lz2 1     4->5
Ld1 3   5->14
Lz3 1       9->10
Rl2 2     10->5
SA0 4 14
END
#save $a;

  $a->delete(4);
  is_deeply $a->printKeys, <<END;
Lz2 1     5->9
Ld1 2   9->14
Rz2 1     10->9
SA0 3 14
END
#save $a;
 }

if (1)
 {lll "Unchain";
  my  $t = Tree::Bulk::new->setKeysPerNode(1);
  my  $a = node(1,2);
  my  $b = node(2,4);
  my  $c = node(3,6);
  my  $d = node(4,8);
  my  $e = node(5,10);
  $a->right = $b; $b->up = $a;
  $b->right = $d; $d->up = $b;
  $d->left  = $c; $c->up = $d;
  $d->right = $e; $e->up = $d;

  is_deeply $a->printKeys, <<END;
SA0 1 1
Rr1 1   2->1
Lz3 1       3->4
Rd2 1     4->2
Rz3 1       5->4
END
#save $a;
  $b->unchain;
  is_deeply $a->printKeys, <<END;
SA0 3 1
Lz2 1     3->4
Rd1 2   4->1
Rz2 1     5->4
END
#save $a;
 }

if (1)                                                                          #TrotateLeft #TrotateRight
 {lll "Rotate";
  my  $a = node(1,2)->setKeysPerNode(1);
  my  $b = node(2,4)->setKeysPerNode(1);
  my  $c = node(3,6)->setKeysPerNode(1);
  my  $d = node(4,8)->setKeysPerNode(1);
  $a->right = $b; $b->up = $a;
  $b->right = $c; $c->up = $b;
  $c->right = $d; $d->up = $c;
  $d->setHeights(1);

  is_deeply $a->printKeys, <<END;
SA0 3 1
Lz2 1     2->3
Rd1 2   3->1
Rz2 1     4->3
END
#save $a;
  $b->rotateLeft;
  is_deeply $a->printKeys, <<END;
SA0 3 1
Lz2 1     2->3
Rd1 2   3->1
Rz2 1     4->3
END
#save $a;

  $c->rotateLeft; $c->setHeights(2);
  is_deeply $a->printKeys, <<END;
SA0 3 1
Lz2 1     2->3
Rd1 2   3->1
Rz2 1     4->3
END
#save $a;

  $d->rotateRight; $d->setHeights(1);
  is_deeply $a->printKeys, <<END;
SA0 3 1
Lz2 1     2->3
Rd1 2   3->1
Rz2 1     4->3
END
#save $a;

  $c->rotateRight; $c->setHeights(2);
  is_deeply $a->printKeys, <<END;
SA0 3 1
Lz2 1     2->3
Rd1 2   3->1
Rz2 1     4->3
END
#save $a;
 }

if (1)                                                                          #Tmaximum
 {is_deeply maximum(1,2), 2;
  is_deeply maximum(2,1), 2;
 }

if (1)                                                                          #Tempty #Tsingleton
 {lll "Balance";
  my  $t = Tree::Bulk::new->setKeysPerNode(1);
  ok $t->empty;
  ok $t->singleton;
 }

if (1)                                                                          #Tbalance #TsetHeights
 {lll "Balance";
  my  $t = Tree::Bulk::new->setKeysPerNode(1);

  my  $a = node(1,2) ->setKeysPerNode(1);
  my  $b = node(2,4) ->setKeysPerNode(1);
  my  $c = node(6,12)->setKeysPerNode(1);
  my  $d = node(5,10)->setKeysPerNode(1);
  my  $e = node(4,8) ->setKeysPerNode(1);
  my  $f = node(3,6) ->setKeysPerNode(1);
  $a->right = $b; $b->up = $a;
  $b->right = $c; $c->up = $b;
  $c->left  = $d; $d->up = $c;
  $d->left  = $e; $e->up = $d;
  $e->left  = $f; $f->up = $e;
  $f->setHeights(1);
  is_deeply $a->printKeys, <<END;
SA0 4 1
Lr2 2     2->4
Rz3 1       3->2
Rd1 3   4->1
Lz3 1       5->6
Rl2 2     6->4
END
#save $a;

  $b->balance;
  is_deeply $a->printKeys, <<END;
SA0 4 1
Lr2 2     2->4
Rz3 1       3->2
Rd1 3   4->1
Lz3 1       5->6
Rl2 2     6->4
END
#save $a;
 }

if (1)                                                                          #TisLeftChild #TisRightChild #TisRoot #Tleaf #Tduplex #Troot
 {lll "Attributes";
  my  $t = Tree::Bulk::new->setKeysPerNode(1);
  my  $b = $t->insert(2,4);
  my  $a = $t->insert(1,2);
  my  $c = $t->insert(3,6);
  ok  $a->isLeftChild;
  ok  $c->isRightChild;
  ok !$a->isRightChild;
  ok !$c->isLeftChild;
  ok  $b->isRoot;
  ok !$a->isRoot;
  ok !$c->isRoot;
  ok  $a->leaf;
  ok  $c->leaf;
  ok  $b->duplex;
  ok  $c->root == $b;
  ok  $c->root != $a;
 }

if (1)                                                                          #Tinsert #Theight #TprintKeys
 {lll "Insert";
  my $N = 23;
  my $t = Tree::Bulk::new->setKeysPerNode(1);
  for(1..$N)
   {$t->insert($_, 2 * $_);
   }

  is_deeply $t->printKeys, <<END;
SA0 8 1
Lz4 1         2->3
Ld3 2       3->5
Rz4 1         4->3
Ld2 3     5->9
Lz4 1         6->7
Rd3 2       7->5
Rz4 1         8->7
Rd1 7   9->1
Lz4 1         10->11
Ld3 2       11->13
Rz4 1         12->11
Rd2 6     13->9
Lz5 1           14->15
Ld4 2         15->17
Rz5 1           16->15
Rd3 5       17->13
Lz5 1           18->19
Rd4 4         19->17
Lz6 1             20->21
Rd5 3           21->19
Rr6 2             22->21
Rz7 1               23->22
END
#save $t;
  ok $t->height == 8;
 }

if (1)                                                                          #Tdelete
 {lll "Delete";
  my $N = 28;
  my $t = Tree::Bulk::new->setKeysPerNode(1);
  for(1..$N)
   {$t->insert($_, 2 * $_);
   }

  is_deeply $t->printKeys, <<END;
SA0 8 1
Lz4 1         2->3
Ld3 2       3->5
Rz4 1         4->3
Ld2 3     5->9
Lz4 1         6->7
Rd3 2       7->5
Rz4 1         8->7
Rd1 7   9->1
Lz5 1           10->11
Ld4 2         11->13
Rz5 1           12->11
Ld3 3       13->17
Lz5 1           14->15
Rd4 2         15->13
Rz5 1           16->15
Rd2 6     17->9
Lz5 1           18->19
Ld4 2         19->21
Rz5 1           20->19
Rd3 5       21->17
Lz5 1           22->23
Rd4 4         23->21
Lz6 1             24->25
Rd5 3           25->23
Lz7 1               26->27
Rd6 2             27->25
Rz7 1               28->27
END
#save $t;

  for my $k(reverse 1..$N)
   {$t->delete($k);
    is_deeply $t->printKeys, <<END if $k == 17;
SA0 5 1
Lz4 1         2->3
Ld3 2       3->5
Rz4 1         4->3
Ld2 3     5->9
Lz4 1         6->7
Rd3 2       7->5
Rz4 1         8->7
Rd1 4   9->1
Lz4 1         10->11
Ld3 2       11->13
Rz4 1         12->11
Rd2 3     13->9
Lz4 1         14->15
Rd3 2       15->13
Rz4 1         16->15
END
#save $t if $k == 17;

    is_deeply $t->printKeys, <<END if $k == 9;
SA0 4 1
Lz3 1       2->3
Ld2 2     3->5
Rz3 1       4->3
Rd1 3   5->1
Lz3 1       6->7
Rd2 2     7->5
Rz3 1       8->7
END
#save $t if $k == 9;

    is_deeply $t->printKeys, <<END if $k == 6;
SA0 4 1
Lz2 1     2->3
Rd1 3   3->1
Lz3 1       4->5
Rl2 2     5->3
END
#save $t if $k == 6;

    is_deeply $t->printKeys, <<END if $k == 4;
SA0 3 1
Rr1 2   2->1
Rz2 1     3->2
END
#save $t if $k == 4;

    is_deeply $t->printKeys, <<END if $k == 3;
SA0 2 1
Rz1 1   2->1
END
#save $t if $k == 3;

    is_deeply $t->printKeys, <<END if $k == 1;
Sz0 1
END
#save $t if $k == 1;
   }
 }

if (1)                                                                          #TsetKeysPerNode #Tname
 {lll "Split and Refill";
  my $N = 22;
  my $t = Tree::Bulk::new;
  for my $k(1..$N)
   {$t->insert($k, 2 * $k);
   }

  is_deeply $t->name, "1 2 3 4";

  is_deeply $t->printKeys, <<END;
SA0 4 1 2 3 4
Lz2 1     5 6 7 8->9 10 11 12
Rd1 3   9 10 11 12->1 2 3 4
Lz3 1       13 14 15 16->17 18 19 20
Rd2 2     17 18 19 20->9 10 11 12
Rz3 1       21 22->17 18 19 20
END
#save $t;

  for my $n($t->inorder)
   {$n->setKeysPerNode(2);
   }
  is_deeply $t->printKeys, <<END;
SA0 5 1 2
Lz3 1       3 4->5 6
Ld2 2     5 6->9 10
Rz3 1       7 8->5 6
Rd1 4   9 10->1 2
Lz4 1         11 12->13 14
Ld3 2       13 14->17 18
Rz4 1         15 16->13 14
Rd2 3     17 18->9 10
Rr3 2       19 20->17 18
Rz4 1         21 22->19 20
END
#save $t;

  for my $n($t->inorder)
   {$n->setKeysPerNode(1);
   }
  is_deeply $t->printKeys, <<END;
SA0 6 1
Lz4 1         2->3
Ld3 2       3->5
Rz4 1         4->3
Ld2 3     5->9
Lz4 1         6->7
Rd3 2       7->5
Rz4 1         8->7
Rd1 5   9->1
Lz5 1           10->11
Ld4 2         11->13
Rz5 1           12->11
Ld3 3       13->17
Lz5 1           14->15
Rd4 2         15->13
Rz5 1           16->15
Rd2 4     17->9
Lz4 1         18->19
Rd3 3       19->17
Lz5 1           20->21
Rd4 2         21->19
Rz5 1           22->21
END
#save $t;

  $_->setKeysPerNode(2) for $t->inorder;
  is_deeply $t->printKeys, <<END;
SA0 5 1 2
Lz3 1       3 4->5 6
Ld2 2     5 6->9 10
Rz3 1       7 8->5 6
Rd1 4   9 10->1 2
Lz4 1         11 12->13 14
Ld3 2       13 14->17 18
Rz4 1         15 16->13 14
Rd2 3     17 18->9 10
Lz4 1         19 20->21 22
Rl3 2       21 22->17 18
END
#save $t;

  $_->setKeysPerNode(4) for $t->inorder;
  is_deeply $t->printKeys, <<END;
SA0 4 1 2 3 4
Lz2 1     5 6 7 8->9 10 11 12
Rd1 3   9 10 11 12->1 2 3 4
Lz3 1       13 14 15 16->17 18 19 20
Rd2 2     17 18 19 20->9 10 11 12
Rz3 1       21 22->17 18 19 20
END
#save $t;
 }

if (1)                                                                          #TactualHeight #TprintKeysAndData
 {my $N = 22;
  my $t = Tree::Bulk::new;
  ok $t->empty;
  ok $t->leaf;

  for(1..$N)
   {$t->insert($_, 2 * $_);
   }

  ok $t->right->duplex;
  is_deeply actualHeight($t), 4;

  is_deeply $t->printKeys, <<END;
SA0 4 1 2 3 4
Lz2 1     5 6 7 8->9 10 11 12
Rd1 3   9 10 11 12->1 2 3 4
Lz3 1       13 14 15 16->17 18 19 20
Rd2 2     17 18 19 20->9 10 11 12
Rz3 1       21 22->17 18 19 20
END
#save $t;

  is_deeply $t->printKeysAndData, <<END;
 1   2
 2   4
 3   6
 4   8
 5  10
 6  12
 7  14
 8  16
 9  18
10  20
11  22
12  24
13  26
14  28
15  30
16  32
17  34
18  36
19  38
20  40
21  42
22  44
END

  my %t = map {$_=>2*$_} 1..$N;

  for(map {2 * $_} 1..$N/2)
   {$t->delete($_);
    delete $t{$_};
    checkAgainstHash $t, %t;
   }

  is_deeply $t->printKeys, <<END;
SA0 3 1 3 5 7
Rr1 2   9 11 13 15->1 3 5 7
Rz2 1     17 19 21->9 11 13 15
END
#save($t);

  is_deeply $t->printKeysAndData, <<END;
 1   2
 3   6
 5  10
 7  14
 9  18
11  22
13  26
15  30
17  34
19  38
21  42
END

  for(map {2 * $_-1} 1..$N/2)
   {$t->delete($_);
    delete $t{$_};
    checkAgainstHash $t, %t;
   }

  is_deeply $t->printKeys, <<END;
Sz0 1
END
#save($t);
 }

if (1)
 {my $N = 230;
  my $t = Tree::Bulk::new;

  for(reverse 1..$N)
   {$t->insert($_, 2 * $_);
   }
  for(reverse 1..$N)
   {$t->delete($_);
   }
  is_deeply $t->printKeys, <<END;
Sz0 1
END
#save $t;

 }

if (1)                                                                          #Tfirst #Tnext #Tinorder #Tlast #Tprev
 {my $N = 220;
  my $t = Tree::Bulk::new;

  for(reverse 1..$N)
   {$t->insert($_, 2*$_);
   }

  is_deeply $t->actualHeight, 10;

  if (1)
   {my @n;
    for (my $n = $t->first; $n; $n = $n->next)
     {push @n, $n->keys->@*
     }
    is_deeply \@n, [1..$N];
   }

  if (1)
   {my @p;
    for my $p(reverse $t->inorder)
     {push @p, reverse $p->keys->@*;
     }
    is_deeply \@p, [reverse 1..$N];
   }

  my @p;
  for(my $p = $t->last; $p; $p = $p->prev)
   {push @p, reverse $p->keys->@*
   }
  is_deeply \@p, [reverse 1..$N];

  my %t = map {$_=>2*$_} 1..$N;
  for   my $i(0..3)
   {for my $j(map {4 * $_-$i} 1..$N/4)
     {$t->delete   ($j);
          delete $t{$j};
      checkAgainstHash $t, %t;
     }
   }

  ok $t->empty;
  is_deeply $t->actualHeight, 1;
 }

if (1)                                                                          #Tnames
 {my sub randomLoad($$$)                                                        # Randomly load different size nodes
   {my ($N, $keys, $height) = @_;                                               # Number of elements, number of keys per node, expected height

    lll "Random load $keys";

    srand(1);                                                                   # Same randomization
    my $t = Tree::Bulk::new->setKeysPerNode($keys);
    for my $r(randomizeArray 1..$N)
     {$t->insert($r, 2 * $r);
      $t->check;
     }

    is_deeply $t->actualHeight, $height;                                        # Check height
    confess unless $t->actualHeight == $height;
    is_deeply join(' ', 1..$N), $t->names;

    my %t = map {$_=>2*$_}   1..$N;
    for my $r(randomizeArray 1..$N)                                             # Delete in random order
     {$t->delete   ($r);
          delete $t{$r};
      checkAgainstHash $t, %t;
      check($t);
     }

    ok $t->empty;
    is_deeply $t->actualHeight, 1;
   }

  randomLoad(222, 1, 11);                                                       # Random loads
  randomLoad(222, 8, 8);
  randomLoad(222, 4, 9);
 }

if (1)                                                                          #Tfind
 {my $t = Tree::Bulk::new;
     $t->insert($_, $_*$_)    for  1..20;
  ok !find($t,  0);
  ok !find($t, 21);
  ok  find($t, $_) == $_ * $_ for qw(1 5 10 11 15 20);
 }

lll "Success:", time - $start;

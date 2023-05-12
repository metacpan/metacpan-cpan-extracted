#!/usr/bin/perl -I../lib/ -Ilib
#-------------------------------------------------------------------------------
# Zero assembler language implemention of a generic N-Way tree.
# Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2023
#-------------------------------------------------------------------------------
# Key compression in each node by eliminating any common prefix present in each key in each node especially useful if we were to add attributes like userid, process, string position, rwx etc to front of each key.  Data does does not need this additional information.
use v5.30;
package Zero::NWayTree;
our $VERSION = 20230515;                                                        # Version
use warnings FATAL => qw(all);
use strict;
use Carp qw(confess);
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
use Zero::Emulator qw(:all);
eval "use Test::More tests=>31" unless caller;

makeDieConfess;

my sub MaxIterations{99};                                                       # The maximum number of levels in an N-Way tree

my $Tree = sub                                                                  # The structure of an N-Way tree
 {my $t = Zero::Emulator::AreaStructure("Structure");
     $t->name(q(keys));                                                         # Number of keys in tree
     $t->name(q(nodes));                                                        # Number of nodes in tree
     $t->name(q(MaximumNumberOfKeys));                                          # The maximum number of keys in any node of this tree
     $t->name(q(root));                                                         # Root node
     $t
 }->();

my $Node = sub                                                                  # The structure of a node in an N-Way tree node
 {my $n = Zero::Emulator::AreaStructure("Node_Structure");
     $n->name(q(length));                                                       # The current number of keys in the node
     $n->name(q(id));                                                           # A number identifying this node within this tree
     $n->name(q(up));                                                           # Parent node unless at the root node
     $n->name(q(tree));                                                         # The definition of the containing tree
     $n->name(q(keys));                                                         # Keys associated with this node
     $n->name(q(data));                                                         # Data associated with each key associated with this node
     $n->name(q(down));                                                         # Next layer of nodes down from this node
     $n
 }->();

my $FindResult = sub                                                            # The structure of a find result
 {my $f = Zero::Emulator::AreaStructure("FindResult");
  $f->name(q(node));                                                            # Node found
  $f->name(q(cmp));                                                             # Result of the last comparison
  $f->name(q(index));                                                           # Index in the node of located element
  $f
 }->();

my sub FindResult_lower   {0}                                                   # Comparison result
my sub FindResult_found   {1}
my sub FindResult_higher  {2}
my sub FindResult_notFound{3}

#D1 Constructor                                                                 # Create a new N-Way tree.

sub New($)                                                                      # Create a variable referring to a new tree descriptor.
 {my ($n) = @_;                                                                 # Maximum number of keys per node in this tree

  $n > 2 && $n % 2 or confess "Number of key/data elements per node must be > 2 and odd";

  my $t = Array "Tree";                                                         # Allocate tree descriptor
  Mov [$t, $Tree->address(q(MaximumNumberOfKeys)), 'Tree'], $n;                 # Save maximum number of keys per node
  Mov [$t, $Tree->address(q(root)),                'Tree'],  0;                 # Clear root
  Mov [$t, $Tree->address(q(keys)),                'Tree'],  0;                 # Clear keys
  Mov [$t, $Tree->address(q(nodes)),               'Tree'],  0;                 # Clear nodes
  $t
 }

my sub Tree_getField($$)                                                        # Get a field from a tree descriptor
 {my ($tree, $field) = @_;                                                      # Tree, field name
  Mov [$tree, $Tree->address($field), 'Tree']                                   # Get attribute from tree descriptor
 }

my sub maximumNumberOfKeys($)                                                   # Get the maximum number of keys per node for a tree
 {my ($tree) = @_;                                                              # Tree to examine
  Tree_getField($tree, q(MaximumNumberOfKeys));                                 # Get attribute from tree descriptor
 };

my sub root($)                                                                  # Get the root node of a tree
 {my ($tree) = @_;                                                              # Tree to examine
  Tree_getField($tree, q(root));                                                # Get attribute from tree descriptor
 };

my sub setRoot($$)                                                              # Set the root node of a tree
 {my ($tree, $root) = @_;                                                       # Tree, root
  Mov [$tree, $Tree->address(q(root)), 'Tree'], $root;                          # Set root attribute
 };

sub Keys($)                                                                     # Get the number of keys in the tree..
 {my ($tree) = @_;                                                              # Tree to examine
  Tree_getField($tree, q(keys));                                                # Keys
 };

my sub incKeys($)                                                               # Increment the number of keys in a tree
 {my ($tree) = @_;                                                              # Tree
  Inc [$tree, $Tree->address(q(keys)), 'Tree'];                                 # Number of keys
 };

my sub nodes($)                                                                 # Get the number of nodes in the tree
 {my ($tree) = @_;                                                              # Tree to examine
  Tree_getField($tree, q(nodes));                                               # Nodes
 };

my sub incNodes($)                                                              # Increment the number of nodes n a tree
 {my ($tree) = @_;                                                              # Tree
  Inc [$tree, $Tree->address(q(nodes)), 'Tree'];                                # Number of nodes
 };

my sub Node_getField($$)                                                        # Get a field from a node descriptor
 {my ($node, $field) = @_;                                                      # Node, field name
  Mov [$node, $Node->address($field), 'Node'];                                  # Get attribute from node descriptor
 }

my sub Node_length($)                                                           # Get number of keys in a node
 {my ($node) = @_;                                                              # Node
  Node_getField($node, q(length));                                              # Get length
 }

my sub Node_lengthM1($)                                                         # Get number of keys in a node minus 1
 {my ($node) = @_;                                                              # Node
  Subtract [$node, $Node->address(q(length)), 'Node'], 1;                       # Get attribute from node descriptor
 }

my sub Node_setLength($$%)                                                      # Set the length of a node
 {my ($node, $length, %options) = @_;                                           # Node, length, options
  if (my $d = $options{add})
   {Add [$node, $Node->address(q(length)), 'Node'], $length, $d;                # Set length attribute
   }
  else
   {Mov [$node, $Node->address(q(length)), 'Node'], $length;                    # Set length attribute
   }
 }

my sub Node_incLength($)                                                        # Increment the length of a node
 {my ($node) = @_;                                                              # Node
  Inc [$node, $Node->address(q(length)), 'Node'];                               # Increment length attribute
 }

my sub Node_up($)                                                               # Get parent node from this node
 {my ($node) = @_;                                                              # Node
  Node_getField($node, q(up));                                                  # Get up
 }

my sub Node_setUp($$)                                                           # Set the parent of a node
 {my ($node, $parent) = @_;                                                     # Node, parent node, area containing parent node reference
  Mov [$node, $Node->address(q(up)), 'Node'], $parent;                          # Set parent
 }

my sub Node_tree($)                                                             # Get tree containing a node
 {my ($node) = @_;                                                              # Node
  Node_getField($node, q(tree));                                                # Get tree
 }

my sub Node_field($$)                                                           # Get the value of a field in a node
 {my ($node, $field) = @_;                                                      # Node, field name
  Mov [$node, $Node->address($field), 'Node'];                                  # Fields
 }

my sub Node_fieldKeys($)                                                        # Get the keys for a node
 {my ($node) = @_;                                                              # Node
  Mov [$node, $Node->address(q(keys)), 'Node'];                                 # Fields
 }

my sub Node_fieldData($)                                                        # Get the data for a node
 {my ($node) = @_;                                                              # Node
  Mov [$node, $Node->address(q(data)), 'Node'];                                 # Fields
 }

my sub Node_fieldDown($)                                                        # Get the children for a node
 {my ($node) = @_;                                                              # Node
  Mov [$node, $Node->address(q(down)), 'Node'];                                 # Fields
 }

my sub Node_getIndex($$$)                                                       # Get the indexed field from a node
 {my ($node, $index, $field) = @_;                                              # Node, index of field, field name
  my $F = Node_field($node, $field);                                            # Array
  Mov [$F, \$index, ucfirst $field];                                            # Field
 }

my sub Node_setIndex($$$$)                                                      # Set an indexed field to a specified value
 {my ($node, $index, $field, $value) = @_;                                      # Node, index, field name, value
  my $F = Node_field($node, $field);                                            # Array
  Mov [$F, \$index, ucfirst $field], $value;                                    # Set field to value
 }

my sub Node_keys($$)                                                            # Get the indexed key from a node
 {my ($node, $index) = @_;                                                      # Node, index of key
  Node_getIndex($node, $index, q(keys));                                        # Keys
 }

my sub Node_data($$)                                                            # Get the indexed data from a node
 {my ($node, $index) = @_;                                                      # Node, index of data
  Node_getIndex($node, $index, q(data));                                        # Data
 }

my sub Node_down($$)                                                            # Get the indexed child node from a node.
 {my ($node, $index) = @_;                                                      # Node, index of child
  Node_getIndex($node, $index, q(down));                                        # Child
 }

my sub Node_isLeaf($)                                                           # Put 1 in a temporary variable if a node is a leaf else 0.
 {my ($node) = @_;                                                              # Node
  Not [$node, $Node->address('down'), 'Node'];                                  # Whether the down field is present or not . 0 is never a user allocated memory area
 }

my sub Node_setKeys($$$)                                                        # Set a key by index.
 {my ($node, $index, $value) = @_;                                              # Node, index, value
  Node_setIndex($node, $index, q(keys), $value)                                 # Set indexed key
 }

my sub Node_setData($$$)                                                        # Set a data field by index.
 {my ($node, $index, $value) = @_;                                              # Node, index, value
  Node_setIndex($node, $index, q(data), $value)                                 # Set indexed key
 }

my sub Node_setDown($$$)                                                        # Set a child by index.
 {my ($node, $index, $value) = @_;                                              # Node, index, value
  Node_setIndex($node, $index, q(down), $value)                                 # Set indexed key
 }

my sub Node_new($%)                                                             # Create a variable referring to a new node descriptor.
 {my ($tree, %options) = @_;                                                    # Tree node is being created in, options
  my $n = Array "Node";                                                         # Allocate node
  my $k = Array "Keys";                                                         # Allocate keys
  my $d = Array "Data";                                                         # Allocate data

  Node_setLength $n, $options{length} // 0;                                     # Length

  Node_setUp $n, 0;                                                             # Parent

  Mov [$n, $Node->address(q(keys)), 'Node'], $k;                                # Keys area
  Mov [$n, $Node->address(q(data)), 'Node'], $d;                                # Data area
  Mov [$n, $Node->address(q(down)), 'Node'], 0;                                 # Down area
  Mov [$n, $Node->address(q(tree)), 'Node'], $tree;                             # Containing tree
  incNodes($tree);
  Mov [$n,    $Node->address(q(id)),    'Node'],                                # Assign an id to this node within the tree
      [$tree, $Tree->address(q(nodes)), 'Tree'];
  $n                                                                            # Return reference to new node
 }

my sub Node_allocDown($%)                                                       # Upgrade a leaf node to an internal node.
 {my ($node, %options) = @_;                                                    # Node to upgrade, options
  my $d = Array "Down";                                                         # Allocate down
  Mov [$node, $Node->address(q(down)), 'Node'], $d;                             # Down area
 }
my sub Node_openLeaf($$$$)                                                      # Open a gap in a leaf node
 {my ($node, $offset, $K, $D) = @_;                                             # Node

  my $k = Node_fieldKeys $node;
  my $d = Node_fieldData $node;

  ShiftUp [$k, \$offset, 'Keys'], $K;
  ShiftUp [$d, \$offset, 'Data'], $D;
  Node_incLength $node;
 }

my sub Node_open($$$$$)                                                         # Open a gap in an interior node
 {my ($node, $offset, $K, $D, $N) = @_;                                         # Node, offset of open, new key, new data, new right node

  my $k = Node_fieldKeys $node;
  my $d = Node_fieldData $node;
  my $n = Node_fieldDown $node;

  ShiftUp [$k, \$offset, 'Keys'], $K;
  ShiftUp [$d, \$offset, 'Data'], $D;
  my $o1 = Add $offset, 1;
  ShiftUp [$n, \$o1,     'Down'], $N;
  Node_incLength $node;
 }

my sub Node_copy_leaf($$$$)                                                     # Copy part of one leaf node into another node.
 {my ($t, $s, $so, $length) = @_;                                               # Target node, source node, source offset, length

  my $sk = Node_fieldKeys $s;
  my $sd = Node_fieldData $s;

  my $tk = Node_fieldKeys $t;
  my $td = Node_fieldData $t;

  MoveLong [$tk, \0, "Keys"], [$sk, \$so, "Keys"], $length;                     # Each key, data, down
  MoveLong [$td, \0, "Data"], [$sd, \$so, "Data"], $length;                     # Each key, data, down
 }

my sub Node_copy($$$$)                                                          # Copy part of one interior node into another node.
 {my ($t, $s, $so, $length) = @_;                                               # Target node, source node, source offset, length

  &Node_copy_leaf(@_);                                                          # Keys and data

  my $sn = Node_fieldDown $s;                                                   # Child nodes
  my $tn = Node_fieldDown $t;
  my $L  = Add $length, 1;
  MoveLong [$tn, \0, "Down"], [$sn, \$so, "Down"], $L;
 }

my sub Node_free($)                                                             # Free a node
 {my ($node) = @_;                                                              # Node to free

  my $K = Node_fieldKeys $node; Free $K, "Keys";
  my $D = Node_fieldData $node; Free $D, "Data";

  IfFalse Node_isLeaf($node),
  Then
   {my $N = Node_fieldDown $node; Free $N, "Down";
   };

  Free $node, "Node";
 }

#D1 Find                                                                        # Find a key in a tree.

my sub FindResult_getField($$)                                                  # Get a field from a find result.
 {my ($findResult, $field) = @_;                                                # Find result, name of field
  Mov [$findResult, $FindResult->address($field), q(FindResult)];               # Fields
 }

sub FindResult_cmp($)                                                           # Get comparison from find result.
 {my ($f) = @_;                                                                 # Find result
  FindResult_getField($f, q(cmp))                                               # Comparison
 }

my sub FindResult_index($)                                                      # Get index from find result
 {my ($f) = @_;                                                                 # Find result
  FindResult_getField($f, q(index))                                             # Index
 }

my sub FindResult_indexP1($)                                                    # Get index+1 from find result
 {my ($f) = @_;                                                                 # Find result
  Add [$f, $FindResult->address(q(index)), q(FindResult)], 1;                   # Fields
 }

my sub FindResult_node($)                                                       # Get node from find result
 {my ($f) = @_;                                                                 # Find result
  FindResult_getField($f, q(node))                                              # Node
 }

sub FindResult_data($)                                                          # Get data field from find results.
 {my ($f) = @_;                                                                 # Find result

  my $n = FindResult_node ($f);
  my $i = FindResult_index($f);
  my $d = Node_data($n, $i);
  $d
 }

sub FindResult_key($)                                                           # Get key field from find results.
 {my ($f) = @_;                                                                 # Find result

  my $n = FindResult_node ($f);
  my $i = FindResult_index($f);
  my $k = Node_keys($n, $i);
  $k
 }

my sub FindResult($$)                                                           # Convert a symbolic name for a find result comparison to an integer
 {my ($f, $cmp) = @_;                                                           # Find result, comparison result name
  return 0 if $cmp eq q(lower);
  return 1 if $cmp eq q(equal);
  return 2 if $cmp eq q(higher);
  return 3 if $cmp eq q(notFound);
 }

my sub FindResult_renew($$$$%)                                                  # Reuse an existing find result
 {my ($find, $node, $cmp, $index, %options) = @_;                               # Find result, node, comparison result, index, options

  Mov        [$find, $FindResult->address(q(node)) , 'FindResult'], $node;
  Mov        [$find, $FindResult->address(q(cmp))  , 'FindResult'], $cmp;

  if (my $d = $options{subtract})                                               # Adjust index if necessary
   {Subtract [$find, $FindResult->address(q(index)), 'FindResult'], $index, $d;
   }
  elsif (my $D = $options{add})                                                 # Adjust index if necessary
   {Add      [$find, $FindResult->address(q(index)), 'FindResult'], $index, $D;
   }
  else
   {Mov      [$find, $FindResult->address(q(index)), 'FindResult'], $index;
   }
  $find
 }

my sub FindResult_new()                                                         # Create an empty find result ready for use
 {Array "FindResult";                                                           # Find result
 }

my sub FindResult_free($)                                                       # Free a find result
 {my ($find) = @_;                                                              # Find result
  Free $find, "FindResult";                                                     # Free find result
 }

my sub ReUp($)                                                                  # Reconnect the children to their new parent.
 {my ($node) = @_;                                                              # Parameters
  my $l = Node_length($node);
  my $L = Add $l, 1;

  my $D = Node_fieldDown($node);
  For
   {my ($i, $check, $next, $end) = @_;                                          # Parameters
    my $d = Mov [$D, \$i, 'Down'];
            Node_setUp($d, $node);
   } $L;
 }

my sub Node_indexInParent($%)                                                   # Get the index of a node in its parent
 {my ($node, %options) = @_;                                                    # Node, options
  my $p = $options{parent} // Node_up($node);                                   # Parent
  AssertNe($p, 0);                                                              # Number of children as opposed to the number of keys
  my $d = Node_fieldDown($p);
  my $r = ArrayIndex $d, $node;
  Dec $r;
  $r
 }

my sub Node_indexInParentP1($%)                                                 # Get the index of a node in its parent
 {my ($node, %options) = @_;                                                    # Node, options
  my $p = $options{parent} // Node_up($node);                                   # Parent
  AssertNe($p, 0);                                                              # Number of children as opposed to the number of keys
  my $d = Node_fieldDown($p);
  ArrayIndex $d, $node;
 }

my sub Node_SplitIfFull($%)                                                     # Split a node if it is full. Return true if the node was split else false
 {my ($node, %options) = @_;                                                    # Node to split, options
  my $split = Var;

  Block                                                                         # Various splitting scenarios
   {my ($start, $good, $bad, $end) = @_;
    my $nl = Node_length($node);

    my $m = $options{maximumNumberOfKeys};                                      # Maximum number of keys supplied by caller
    Jlt $bad, $nl, $m if defined $m;                                            # Must be a full node

    my $t = Node_tree($node);                                                   # Tree we are splitting in
    my $N = $m // maximumNumberOfKeys($t);                                      # Maximum size of a node
    Jlt $bad, $nl, $N unless defined $m;                                        # Must be a full node

    my $n = $options{splitPoint};                                               # Split point supplied
    if (!defined $n)                                                            # Calculate split point
     {$n = Mov $N;
      ShiftRight $n, 1;
     }

    my $R = $options{rightStart} // Add $n, 1;                                  # Start of right hand side in a node

    my $p = Node_up($node);                                                     # Existing parent node

    IfTrue $p,
    Then                                                                        # Not a root node
     {my $r = Node_new($t, length=>$n);

      IfFalse Node_isLeaf($node),                                               # Not a leaf
      Then
       {Node_allocDown $r;                                                      # Add down area on right
        Node_copy($r, $node, $R, $n);                                           # New right node
        ReUp($r) unless $options{test};                                         # Simplify test set up
        my $N = Node_fieldDown $node; Resize $N, $R;
       },
      Else
       {Node_copy_leaf($r, $node, $R, $n);                                      # New right leaf
       };
      Node_setLength($node, $n);

      Node_setUp($r, $p);
      my $pl = Node_length($p);

      IfEq Node_down($p, $pl), $node,                                           # Splitting the last child - just add it on the end
      Then
       {my $pk = Node_keys($node, $n); Node_setKeys($p, $pl, $pk);
        my $nd = Node_data($node, $n); Node_setData($p, $pl, $nd);
        my $pl1 = Add $pl, 1;
        Node_setLength($p, $pl1);
        Node_setDown  ($p, $pl1, $r);
        my $K = Node_fieldKeys $node; Resize $K, $n;
        my $D = Node_fieldData $node; Resize $D, $n;
        Jmp $good;
       },
      Else                                                                      # Splitting elsewhere in the node
       {my $i = Node_indexInParent($node, parent=>$p, children=>$pl);           # Index of the node being split in its parent
        my $pk = Node_keys($node, $n);
        my $pd = Node_data($node, $n);
        Node_open($p, $i, $pk, $pd, $r);
        my $K = Node_fieldKeys $node; Resize $K, $n;
        my $D = Node_fieldData $node; Resize $D, $n;
        Jmp $good;
       };
     };

    my $l = Node_new($t, length=>$n);                                           # Split root node into two children
    my $r = Node_new($t, length=>$n);

    IfFalse Node_isLeaf($node),                                                 # Not a leaf
    Then
     {Node_allocDown $l;                                                        # Add down area on left
      Node_allocDown $r;                                                        # Add down area on right
      Node_copy($l, $node, 0,  $n);                                             # New left  node
      Node_copy($r, $node, $R, $n);                                             # New right node
      ReUp($l) unless $options{test};                                           # Simplify testing
      ReUp($r) unless $options{test};
     },
    Else
     {Node_allocDown $node;                                                     # Add down area
      Node_copy_leaf($l, $node, 0,  $n);                                        # New left  leaf
      Node_copy_leaf($r, $node, $R, $n);                                        # New right leaf
     };

    Node_setUp($l, $node);                                                      # Root node with single key after split
    Node_setUp($r, $node);                                                      # Connect children to parent

    my $pk = Node_keys($node, $n);                                              # Single key
    my $pd = Node_data($node, $n);                                              # Data associated with single key
    Node_setKeys  ($node, 0, $pk);
    Node_setData  ($node, 0, $pd);
    Node_setDown  ($node, 0, $l);
    Node_setDown  ($node, 1, $r);
    Node_setLength($node, 1);

    if (1)                                                                      # Resize split root node
     {my $K = Node_fieldKeys $node; Resize $K, 1;
      my $D = Node_fieldData $node; Resize $D, 1;
      my $N = Node_fieldDown $node; Resize $N, 2;
     }

    Jmp $good;
   }
  Good                                                                          # Node was split
   {Mov $split, 1;
   },
  Bad                                                                           # Node was to small to split
   {Mov $split, 0;
   };
  $split
 }

my sub FindAndSplit($$%)                                                        # Find a key in a tree splitting full nodes along the path to the key
 {my ($tree, $key, %options) = @_;                                              # Tree to search, key, options
  my $node = root($tree);

  my $find = $options{findResult} // FindResult_new;                            # Find result work area

  Node_SplitIfFull($node, %options);                                            # Split the root node if necessary

  Block                                                                         # Exit this block when we have located the key
   {my ($Start, $Good, $Bad, $Found) = @_;

    For                                                                         # Step down through the tree
     {my ($j, $check, $next, $end) = @_;                                        # Parameters
      my $nl = Node_length($node);                                              # Length of node
      my $last = Subtract $nl, 1;                                               # Greater than largest key in node. Data often gets inserted in ascending order so we do this check first rather than last.
      IfGt $key, Node_keys($node, $last),                                       # Key greater than greatest key
      Then
       {IfTrue Node_isLeaf($node),                                              # Leaf
        Then
         {FindResult_renew($find, $node, FindResult_higher, $nl, subtract=>1);
          Jmp $Found;
         };
        my $n = Node_down($node, $nl);                                          # We will be heading down through the last node so split it in advance if necessary
        IfFalse Node_SplitIfFull($n, %options),                                 # No split needed
        Then
         {Mov $node, $n;
         };
        Jmp $next;
       };

      my $K = Node_fieldKeys($node);                                            # Keys arrays
      my $e = ArrayIndex $K, $key;
      IfTrue $e,
      Then
       {FindResult_renew($find, $node, FindResult_found, $e, subtract=>1);
        Jmp $Found;
       };

      my $I = ArrayCountLess $K, $key;                                          # Index at which to step down

      IfTrue Node_isLeaf($node),
      Then
       {FindResult_renew($find, $node, FindResult_lower, $I);
        Jmp $Found;
       };

      my $n = Node_down($node, $I);
      IfFalse Node_SplitIfFull($n, %options),                                   # Split the node we have stepped to if necessary - if we do we will have to restart the descent from one level up because the key might have moved to the other  node.
      Then
       {Mov $node, $n;
       };
     }  MaxIterations;
    Assert;                                                                     # Failed to descend through the tree to the key.
   };
  $find
 }

sub Find($$%)                                                                   # Find a key in a tree returning a L<FindResult> describing the outcome of the search.
 {my ($tree, $key, %options) = @_;                                              # Tree to search, key to find, options

  my $find = $options{findResult} // FindResult_new;                            # Find result work area

  Block                                                                         # Block
   {my ($Start, $Good, $Bad, $End) = @_;                                        # Block locations

    my $node = root($tree);                                                     # Current node we are searching

    IfFalse $node,                                                              # Empty tree
    Then
     {FindResult_renew($find, $node, FindResult_notFound, 0);                   # Was -1
      Jmp $End;
     };

    For                                                                         # Step down through tree
     {my ($j, $check, $next, $end) = @_;                                        # Parameters
      my $nl1 = Node_lengthM1($node);
      my $K = Node_fieldKeys($node);                                            # Keys

      IfGt $key, [$K, \$nl1, 'Keys'],                                           # Bigger than every key
      Then
       {my $nl = Add $nl1, 1;
        IfTrue Node_isLeaf($node),                                              # Leaf
        Then
         {FindResult_renew($find, $node, FindResult_higher, $nl);
          Jmp $End;
         };
        Mov $node, Node_down($node, $nl);
        Jmp $next;
       };

      my $e = ArrayIndex $K, $key;                                              # Check for equal keys
      IfTrue $e,                                                                # Found a matching key
      Then
       {FindResult_renew($find, $node, FindResult_found, $e, subtract=>1);      # Find result
        Jmp $End;
       };

      my $i = ArrayCountLess $K, $key;                                          # Check for smaller keys
      IfTrue Node_isLeaf($node),                                                # Leaf
      Then
       {FindResult_renew($find, $node, FindResult_lower, $i);
        Jmp $End;
       };
      Mov $node, Node_down($node, $i);
     } MaxIterations;
    Assert;
   };
  $find
 }

#D1 Insert                                                                      # Create a new entry in a tree to connect a key to data.

sub Insert($$$%)                                                                # Insert a key and its associated data into a tree.
 {my ($tree, $key, $data, %options) = @_;                                       # Tree, key, data

  my $find = $options{findResult} // FindResult_new;                            # Find result work area

  Block
   {my ($Start, $Good, $Bad, $Finish) = @_;                                     # Parameters
    my $n = root($tree);                                                        # Root node of tree

    IfFalse $n,                                                                 # Empty tree
    Then
     {my $n = Node_new($tree, length=>1);
      Node_setKeys  ($n, 0, $key);
      Node_setData  ($n, 0, $data);
      incKeys($tree);
      setRoot($tree, $n);
      Jmp $Finish;
     };

    my $nl = Node_length($n);                                                   # Current length of node
    IfLt $nl, maximumNumberOfKeys($tree),                                       # Node has room for another key
    Then
     {IfFalse Node_up($n),                                                      # Root node
      Then
       {IfTrue Node_isLeaf($n),                                                 # Leaf root node
        Then
         {my $K = Node_fieldKeys($n);                                           # Keys arrays
          my $e = ArrayIndex $K, $key;
          IfTrue $e,                                                            # Key already exists in leaf root node
          Then
           {Dec $e;
            Node_setData($n, $e, $data);  ## Needs -1
            Jmp $Finish;
           };

          my $I = ArrayCountGreater $K, $key;                                   # Greater than all keys in leaf root node
          IfFalse $I,
          Then
           {Node_setKeys($n, $nl, $key);                                        # Append the key at the end of the leaf root node because it is greater than all the other keys in the block and there is room for it
            Node_setData($n, $nl, $data);
            Node_setLength($n, $nl, add=>1);
            incKeys($tree);
            Jmp $Finish;
           };

          my $i = ArrayCountLess $K, $key;                                      # Insert position
          Node_openLeaf($n, $i, $key, $data);                                   # Insert into the root leaf node
          incKeys($tree);
          Jmp $Finish;
         };
       };
     };
                                                                                # Insert node
    my $r = FindAndSplit($tree, $key, %options, findResult=>$find);             # Check for existing key
    my $N = FindResult_node($r);
    my $c = FindResult_cmp($r);
    my $i = FindResult_index($r);

    IfEq $c, FindResult_found,                                                  # Found an equal key whose data we can update
    Then
     {Node_setData($N, $i, $data);
      Jmp $Finish;
     };

    IfEq $c, FindResult_higher,                                                 # Found a key that is greater than the one being inserted
    Then
     {my $i1 = Add $i, 1;
      Node_openLeaf($N, $i1, $key, $data);
     },
    Else
     {Node_openLeaf($N, $i, $key, $data);
     };

    incKeys($tree);
    Node_SplitIfFull($N, %options);                                             # Split if the leaf is full to force keys up the tree
   };
  FindResult_free($find) unless $options{findResult};                           # Free the find result now we are finished with it unless we are using a global one
 }

#D1 Iteration                                                                   # Iterate over the keys and their associated data held in a tree.

my sub GoAllTheWayLeft($$)                                                      # Go as left as possible from the current node
 {my ($find, $node) = @_;                                                       # Find result, Node

  IfFalse $node,                                                                # Empty tree
  Then
   {FindResult_renew($find, $node, FindResult_notFound, 0);
   },
  Else
   {For                                                                         # Step down through tree
     {my ($i, $check, $next, $end) = @_;                                        # Parameters
      JTrue $end, Node_isLeaf($node);                                           # Reached leaf
      Mov $node, Node_down($node, 0);
     } MaxIterations;
    FindResult_renew($find, $node, FindResult_found, 0);                        # Leaf - place us on the first key
   };
  $find
 }

my sub GoUpAndAround($)                                                         # Go up until it is possible to go right or we can go no further
 {my ($find) = @_;                                                              # Find

  Block
   {my ($Start, $Good, $Bad, $Finish) = @_;                                     # Parameters
    my $node = FindResult_node($find);

    IfTrue Node_isLeaf($node),                                                  # Leaf
    Then
     {my $I = FindResult_indexP1($find);
      my $L = Node_length($node);
      IfLt $I, $L,                                                              # More keys in leaf
      Then
       {FindResult_renew($find, $node, FindResult_found, $I);
        Jmp $Finish;
       };

      my $parent = Node_up($node);                                              # Parent
      IfTrue $parent,
      Then
       {For                                                                     # Go up until we can go right
         {my ($j, $check, $next, $end) = @_;                                    # Parameters
          my $pl = Node_length($parent);                                        # Number of children
          my $i = Node_indexInParent($node, parent=>$parent, children=>$pl);    # Index in parent

          IfEq $i, $pl,                                                         # Last key - continue up
          Then
           {Mov $node, $parent;
            Mov $parent, [$node, $Node->address(q(up)), 'Node'];                # Parent
            JFalse $end, $parent;
           },
          Else
           {FindResult_renew($find, $parent,  FindResult_found, $i);            # Not the last key
            Jmp $Finish;
           };
         } MaxIterations;
       };
      FindResult_renew($find, $node, FindResult_notFound, 0);                   # Last key of root
      Jmp $Finish;
     };

    my $i = FindResult_indexP1($find);                                          # Not a leaf so on an interior key so we can go right then all the way left
    my $d = Node_down($node, $i);
    GoAllTheWayLeft($find, $d);
   };
  $find
 }

sub Iterate(&$)                                                                 # Iterate over a tree.
 {my ($block, $tree) = @_;                                                      # Block of code to execute for each key in tree, tree
  my $n = root($tree);
  my $f = FindResult_new;
  GoAllTheWayLeft($f, $n);

  For
   {my ($i, $check, $next, $end) = @_;                                          # Parameters
    Jeq $end, FindResult_cmp($f), FindResult_notFound;
    &$block($f);

    GoUpAndAround($f);
   } 1e99;
  FindResult_free($f);
 }

#D1 Print                                                                       # Print trees horizontally.

my sub printNode($$$$$)                                                         # Print the keys or data in a node in memory
 {my ($memory, $node, $indent, $out, $keyNotData) = @_;
  ref($node) =~ m(Node) or confess "Not a node: ".dump($node);
  my $k = $$node[$Node->offset(q(keys))];
  my $d = $$node[$Node->offset(q(data))];
  my $n = $$node[$Node->offset(q(down))];

  if ($n)                                                                       # Interior node
   {my $K = $$memory{$k};
    my $D = $$memory{$d};
    my $N = $$memory{$n};
    my $l = $$node[$Node->offset(q(length))];

    for my $i(0..$l-1)
     {my $c = $$memory{$$N[$i]};                                                # Child node
      my $p = $$memory{$$c[$Node->offset(q(up))]};

      __SUB__->($memory, $c, $indent+1, $out, $keyNotData);
      push @$out, [$indent, $keyNotData ? $$K[$i] : $$D[$i]];
     }

    __SUB__->($memory,   $$memory{$$N[$l]}, $indent+1, $out, $keyNotData);
   }

  else                                                                          # Leaf node
   {my $K = $$memory{$k};
    my $D = $$memory{$d};
    my $l = $$node[$Node->offset(q(length))];

    for my $i(0..$l-1)
     {my $k = $$K[$i];
      my $d = $$D[$i];
      push @$out, [$indent, $keyNotData ? $k : $d];
     }
   }
  $out
 }

my sub printTree($$)                                                            # Print a tree
 {my ($m, $keyNotData) = @_;                                                    # Memory, key or data
  my $t = $$m{1};
  my $r = $$m{$$t[$Tree->offset(q(root))]};
  my $o = printNode($m, $r, 0, [], $keyNotData);

  my $C = $#$o;                                                                 # Number of columns
  my $R = max(map {$$o[$_][0]} keys @$o);                                       # Number of rows

  my $W = 3;                                                                    # Field width for each key
  my @o;                                                                        # Output area
  for   my $r(0..$R)
   {for my $c(0..$C)
     {$o[$r][$c] = ' ' x $W;
     }
   }

  for   my $p(keys @$o)                                                         # Write tree horizontally
   {next unless defined(my $v = $$o[$p][1]);
    my $r = $$o[$p][0];
    my $c = $p;

    $o[$r][$c] = sprintf("%${W}d", $v);
   }

  join "\n", (map { (join "", $o[$_]->@*) =~ s(\s+\Z) ()r;} keys @o), '';       # As a single string after removing trailing spaces on each line
 }

sub printTreeKeys($)                                                            # Print the keys held in a tree.
 {my ($m) = @_;                                                                 # Memory
  printTree($m, 1);
 }

sub printTreeData($)                                                            # Print the data held in a tree.
 {my ($m) = @_;                                                                 # Memory
  printTree($m, 0);
 }

#D1 Utilities                                                                   # Utility functions.

sub randomArray($)                                                              # Create a random array.
 {my ($N) = @_;                                                                 # Size of array

  my @r = 1..$N;
  srand(1);

  for my $i(keys @r)                                                            # Disarrange the array
   {my $s = int rand @r;
    my $t = int rand @r;
    ($r[$t], $r[$s]) = ($r[$s], $r[$t]);
   }
  @r
 }

use Exporter qw(import);
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

@ISA         = qw(Exporter);
@EXPORT      = qw();
@EXPORT_OK   = qw(Find FindResult_cmp FindResult_data FindResult_key Insert Iterate New printTreeKeys printTreeData randomArray);
#say STDERR '@EXPORT_OK   = qw(', (join ' ', sort @EXPORT_OK), ');'; exit;
%EXPORT_TAGS = (all=>[@EXPORT, @EXPORT_OK]);

return 1 if caller;

# Tests

Test::More->builder->output("/dev/null");                                       # Reduce number of confirmation messages during testing

my $debug = -e q(/home/phil/);                                                  # Assume debugging if testing locally
eval {goto latest if $debug};

sub is_deeply;
sub ok($;$);
sub done_testing;
sub x {exit if $debug}                                                          # Stop if debugging.

#latest:;
if (1)                                                                          ##New
 {Start 1;
  Out New(3);
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, [1];
  is_deeply $e->memory, { 1 => bless([0, 0, 3, 0], "Tree") };
 }

#latest:;
if (1)                                                                          ##setRoot ##root ##incKeys
 {Start 1;
  my $t = New(3);
  my $r = root($t);

  setRoot($t, 1);
  my $R = root($t);

  my $n = maximumNumberOfKeys($t);

  incKeys($t) for 1..3;
  Out [$t, $Tree->address(q(keys)), 'Tree'];

  incNodes($t) for 1..5;
  Out nodes($t);

  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out,    [3, 5];
  is_deeply $e->memory, { 1 => bless([3, 5, 3, 1], "Tree") };
 }

#latest:;
if (1)                                                                          ##Node_new
 {Start 1;
  my $t = New(7);                                                               # Create tree
  my $n = Node_new($t);                                                         # Create node
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->memory, {
  1 => bless([0, 1, 7, 0], "Tree"),
  2 => bless([0, 1, 0, 1, 3, 4, 0], "Node"),
  3 => bless([], "Keys"),
  4 => bless([], "Data")};
 }

#latest:;
if (1)                                                                          # Set up to test Node_open
 {Start 1;
  my $N = 7;
  my $t = New($N);                                                              # Create tree
  my $n = Node_new($t);                                                         # Create node

  Node_allocDown $n;
  Node_setLength $n, $N;

  for my $i(0..$N-1)
   {my $I = $i + 1;
    Node_setKeys($n, $i,  10  *$I);
    Node_setData($n, $i,  100 *$I);
    Node_setDown($n, $i,  1000*$I);
   }

  Node_setDown($n, $N, 8000);

  my $e = Execute(suppressOutput=>1);

  is_deeply $e->memory, {
  1 => bless([0, 1, 7, 0], "Tree"),
  2 => bless([7, 1, 0, 1, 3, 4, 5], "Node"),
  3 => bless([  10,   20,   30,   40,   50,   60,   70],       "Keys"),
  4 => bless([ 100,  200,  300,  400,  500,  600,  700],       "Data"),
  5 => bless([1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000], "Down")};
 }

#latest:;
if (1)                                                                          ##Node_open
 {Start 1;
  my $N = 7;
  my $t = New($N);                                                              # Create tree
  my $n = Node_new($t);                                                         # Create node

  Node_allocDown $n;
  Node_setLength $n, $N;

  for my $i(0..$N-1)
   {my $I = $i + 1;
    Node_setKeys($n, $i,  10*$I);
    Node_setData($n, $i,  10*$I);
    Node_setDown($n, $i,  10*$i+5);
   }

  Node_setDown($n, $N, 75);

  Node_open($n, 2, 26, 26, 26);
  my $e = Execute(suppressOutput=>1);

  is_deeply $e->memory, {
  1 => bless([0, 1, 7, 0], "Tree"),
  2 => bless([8, 1, 0, 1, 3, 4, 5], "Node"),
  3 => bless([  10, 20, 26, 30, 40, 50, 60, 70],   "Keys"),
  4 => bless([  10, 20, 26, 30, 40, 50, 60, 70],   "Data"),
  5 => bless([ 5, 15, 25, 26, 35, 45, 55, 65, 75], "Down")};
 }

#latest:;
if (1)                                                                          # Set up for Node_SplitIfFull at start non root
 {Start 1;
  my $N = 7;
  my $t = New($N);                                                              # Create tree
  my $n = Node_new($t);                                                         # Create node
          Node_allocDown $n;
  my $o = Node_new($t);                                                         # Create node
          Node_allocDown $o;

  Node_setLength $_, $N for $n, $o;

  for my $i(0..$N-1)
   {my $I = $i + 1;
    Node_setKeys($n, $i, 1000*$I);     Node_setKeys($o, $i, 2000+10*$I);
    Node_setData($n, $i, 1000*$I);     Node_setData($o, $i, 2000+10*$I);
    Node_setDown($n, $i, 1000*$i+50);  Node_setDown($o, $i, 2000+10*$i+5);
   }

  Node_setUp  ($o, $n);
  Node_setDown($n, $N, 7500); Node_setDown($n, 0, 6);
  Node_setDown($o, $N, 2075);

  my $e = Execute(suppressOutput=>1);

  is_deeply $e->memory, {
  1 => bless([0, 2, 7, 0], "Tree"),
  2 => bless([7, 1, 0, 1, 3, 4, 5], "Node"),
  3 => bless([1000, 2000, 3000, 4000, 5000, 6000, 7000], "Keys"),
  4 => bless([1000, 2000, 3000, 4000, 5000, 6000, 7000], "Data"),
  5 => bless([6, 1050, 2050, 3050, 4050, 5050, 6050, 7500], "Down"),
  6 => bless([7, 2, 2, 1, 7, 8, 9], "Node"),
  7 => bless([2010, 2020, 2030, 2040, 2050, 2060, 2070], "Keys"),
  8 => bless([2010, 2020, 2030, 2040, 2050, 2060, 2070], "Data"),
  9 => bless([2005, 2015, 2025, 2035, 2045, 2055, 2065, 2075], "Down")};
 }


#latest:;
if (1)                                                                          ##Node_SplitIfFull split at start non root
 {Start 1;
  my $N = 7;
  my $t = New($N);                                                              # Create tree
  my $n = Node_new($t);                                                         # Create node
          Node_allocDown $n;
  my $o = Node_new($t);                                                         # Create node
          Node_allocDown $o;

  Node_setLength $_, $N for $n, $o;

  for my $i(0..$N-1)
   {my $I = $i + 1;
    Node_setKeys($n, $i, 1000*$I);     Node_setKeys($o, $i, 2000+10*$I);
    Node_setData($n, $i, 1000*$I);     Node_setData($o, $i, 2000+10*$I);
    Node_setDown($n, $i, 1000*$i+50);  Node_setDown($o, $i, 2000+10*$i+5);
   }


  Node_setUp  ($o, $n);
  Node_setDown($n, $N, 7500); Node_setDown($n, 0, 6);
  Node_setDown($o, $N, 2075);

  Node_SplitIfFull($o, test=>1);

  my $e = Execute(suppressOutput=>1);

  is_deeply $e->memory, {
  1  => bless([0, 3, 7, 0], "Tree"),
  2  => bless([8, 1, 0, 1, 3, 4, 5], "Node"),
  3  => bless([2040, 1000, 2000, 3000, 4000, 5000, 6000, 7000], "Keys"),
  4  => bless([2040, 1000, 2000, 3000, 4000, 5000, 6000, 7000], "Data"),
  5  => bless([6, 10, 1050, 2050, 3050, 4050, 5050, 6050, 7500], "Down"),
  6  => bless([3, 2, 2, 1, 7, 8, 9], "Node"),
  7  => bless([2010, 2020, 2030], "Keys"),
  8  => bless([2010, 2020, 2030], "Data"),
  9  => bless([2005, 2015, 2025, 2035], "Down"),
  10 => bless([3, 3, 2, 1, 11, 12, 13], "Node"),
  11 => bless([2050, 2060, 2070], "Keys"),
  12 => bless([2050, 2060, 2070], "Data"),
  13 => bless([2045, 2055, 2065, 2075], "Down")};
 }

#latest:;
if (1)                                                                          # Set up for Node_SplitIfFull in middle non root
 {Start 1;
  my $N = 7;
  my $t = New($N);                                                              # Create tree
  my $n = Node_new($t);                                                         # Create node
          Node_allocDown $n;
  my $o = Node_new($t);                                                         # Create node
          Node_allocDown $o;

  Node_setLength $_, $N for $n, $o;

  for my $i(0..$N-1)
   {my $I = $i + 1;
    Node_setKeys($n, $i, 1000*$I);     Node_setKeys($o, $i, 2000+10*$I);
    Node_setData($n, $i, 1000*$I);     Node_setData($o, $i, 2000+10*$I);
    Node_setDown($n, $i, 1000*$i+50);  Node_setDown($o, $i, 2000+10*$i+5);
   }

  Node_setUp  ($o, $n);
  Node_setDown($n, $N, 7500); Node_setDown($n, 2, 6);
  Node_setDown($o, $N, 2075);

  my $e = Execute(suppressOutput=>1);

  is_deeply $e->memory, {
  1 => bless([0, 2, 7, 0], "Tree"),
  2 => bless([7, 1, 0, 1, 3, 4, 5], "Node"),
  3 => bless([1000, 2000, 3000, 4000, 5000, 6000, 7000], "Keys"),
  4 => bless([1000, 2000, 3000, 4000, 5000, 6000, 7000], "Data"),
  5 => bless([50, 1050, 6, 3050, 4050, 5050, 6050, 7500], "Down"),
  6 => bless([7, 2, 2, 1, 7, 8, 9], "Node"),
  7 => bless([2010, 2020, 2030, 2040, 2050, 2060, 2070], "Keys"),
  8 => bless([2010, 2020, 2030, 2040, 2050, 2060, 2070], "Data"),
  9 => bless([2005, 2015, 2025, 2035, 2045, 2055, 2065, 2075], "Down")};
 }

#latest:;
if (1)                                                                          ##Node_SplitIfFull split in middle non root
 {Start 1;
  my $N = 7;
  my $t = New($N);                                                              # Create tree
  my $n = Node_new($t);                                                         # Create node
          Node_allocDown $n;
  my $o = Node_new($t);                                                         # Create node
          Node_allocDown $o;

  Node_setLength $_, $N for $n, $o;

  for my $i(0..$N-1)
   {my $I = $i + 1;
    Node_setKeys($n, $i, 1000*$I);     Node_setKeys($o, $i, 2000+10*$I);
    Node_setData($n, $i, 1000*$I);     Node_setData($o, $i, 2000+10*$I);
    Node_setDown($n, $i, 1000*$i+50);  Node_setDown($o, $i, 2000+10*$i+5);
   }

  Node_setUp  ($o, $n);
  Node_setDown($n, $N, 7500); Node_setDown($n, 2, 6);
  Node_setDown($o, $N, 2075);

  Node_SplitIfFull($o, test=>1);

  my $e = Execute(suppressOutput=>0);
  is_deeply $e->memory, {
  1  => bless([0, 3, 7, 0], "Tree"),
  2  => bless([8, 1, 0, 1, 3, 4, 5], "Node"),
  3  => bless([1000, 2000, 2040, 3000, 4000, 5000, 6000, 7000], "Keys"),
  4  => bless([1000, 2000, 2040, 3000, 4000, 5000, 6000, 7000], "Data"),
  5  => bless([50, 1050, 6, 10, 3050, 4050, 5050, 6050, 7500], "Down"),
  6  => bless([3, 2, 2, 1, 7, 8, 9], "Node"),
  7  => bless([2010, 2020, 2030], "Keys"),
  8  => bless([2010, 2020, 2030], "Data"),
  9  => bless([2005, 2015, 2025, 2035], "Down"),
  10 => bless([3, 3, 2, 1, 11, 12, 13], "Node"),
  11 => bless([2050, 2060, 2070], "Keys"),
  12 => bless([2050, 2060, 2070], "Data"),
  13 => bless([2045, 2055, 2065, 2075], "Down")};
 }

#latest:;
if (1)                                                                          # Set up for Node_SplitIfFull at end non root
 {Start 1;
  my $N = 7;
  my $t = New($N);                                                              # Create tree
  my $n = Node_new($t);                                                         # Create node
          Node_allocDown $n;
  my $o = Node_new($t);                                                         # Create node
          Node_allocDown $o;

  Node_setLength $_, $N for $n, $o;

  for my $i(0..$N-1)
   {my $I = $i + 1;
    Node_setKeys($n, $i, 1000*$I);     Node_setKeys($o, $i, 2000+10*$I);
    Node_setData($n, $i, 1000*$I);     Node_setData($o, $i, 2000+10*$I);
    Node_setDown($n, $i, 1000*$i+50);  Node_setDown($o, $i, 2000+10*$i+5);
   }

  Node_setUp  ($o, $n);
  Node_setDown($n, $N, 7500); Node_setDown($n, 7, 6);
  Node_setDown($o, $N, 2075);

  my $e = Execute(suppressOutput=>1);

  is_deeply $e->memory, {
  1 => bless([0, 2, 7, 0], "Tree"),
  2 => bless([7, 1, 0, 1, 3, 4, 5], "Node"),
  3 => bless([1000, 2000, 3000, 4000, 5000, 6000, 7000], "Keys"),
  4 => bless([1000, 2000, 3000, 4000, 5000, 6000, 7000], "Data"),
  5 => bless([50, 1050, 2050, 3050, 4050, 5050, 6050, 6], "Down"),
  6 => bless([7, 2, 2, 1, 7, 8, 9], "Node"),
  7 => bless([2010, 2020, 2030, 2040, 2050, 2060, 2070], "Keys"),
  8 => bless([2010, 2020, 2030, 2040, 2050, 2060, 2070], "Data"),
  9 => bless([2005, 2015, 2025, 2035, 2045, 2055, 2065, 2075], "Down")};
 }

#latest:;
if (1)                                                                          ##Node_SplitIfFull at end non root
 {Start 1;
  my $N = 7;
  my $t = New($N);                                                              # Create tree
  my $n = Node_new($t); Node_allocDown $n;                                      # Create node
  my $o = Node_new($t); Node_allocDown $o;                                      # Create node

  Node_setLength $_, $N for $n, $o;

  for my $i(0..$N-1)
   {my $I = $i + 1;
    Node_setKeys($n, $i, 1000*$I);     Node_setKeys($o, $i, 2000+10*$I);
    Node_setData($n, $i, 1000*$I);     Node_setData($o, $i, 2000+10*$I);
    Node_setDown($n, $i, 1000*$i+50);  Node_setDown($o, $i, 2000+10*$i+5);
   }

  Node_setUp  ($o, $n);
  Node_setDown($n, $N, 7500); Node_setDown($n, 7, 6);
  Node_setDown($o, $N, 2075);

  Node_SplitIfFull($o, test=>1);
  my $e = Execute(suppressOutput=>1);

  is_deeply $e->memory, {
  1  => bless([0, 3, 7, 0], "Tree"),
  2  => bless([8, 1, 0, 1, 3, 4, 5], "Node"),
  3  => bless([1000, 2000, 3000, 4000, 5000, 6000, 7000, 2040], "Keys"),
  4  => bless([1000, 2000, 3000, 4000, 5000, 6000, 7000, 2040], "Data"),
  5  => bless([50, 1050, 2050, 3050, 4050, 5050, 6050, 6, 10], "Down"),
  6  => bless([3, 2, 2, 1, 7, 8, 9], "Node"),
  7  => bless([2010, 2020, 2030], "Keys"),
  8  => bless([2010, 2020, 2030], "Data"),
  9  => bless([2005, 2015, 2025, 2035], "Down"),
  10 => bless([3, 3, 2, 1, 11, 12, 13], "Node"),
  11 => bless([2050, 2060, 2070], "Keys"),
  12 => bless([2050, 2060, 2070], "Data"),
  13 => bless([2045, 2055, 2065, 2075], "Down")};
 }

#latest:;
if (1)                                                                          ##Node_copy
 {Start 1;
  my $t = New(7);                                                               # Create tree
  my $p = Node_new($t); Node_allocDown($p);                                     # Create a node
  my $q = Node_new($t); Node_allocDown($q);                                     # Create a node

  for my $i(0..6)
   {Node_setKeys($p, $i, 11+$i);
    Node_setData($p, $i, 21+$i);
    Node_setDown($p, $i, 31+$i);
    Node_setKeys($q, $i, 41+$i);
    Node_setData($q, $i, 51+$i);
    Node_setDown($q, $i, 61+$i);
   }

  Node_setDown($p, 7, 97);
  Node_setDown($q, 7, 99);

  Node_copy($q, $p, 3, 2);

  my $e = Execute(suppressOutput=>1);

  is_deeply $e->memory, {
  1 => bless([0, 2, 7, 0], "Tree"),
  2 => bless([0, 1, 0, 1, 3, 4, 5], "Node"),
  3 => bless([11 .. 17], "Keys"),
  4 => bless([21 .. 27], "Data"),
  5 => bless([31 .. 37, 97], "Down"),
  6 => bless([0, 2, 0, 1, 7, 8, 9], "Node"),
  7 => bless([14, 15, 43 .. 47], "Keys"),
  8 => bless([24, 25, 53 .. 57], "Data"),
  9 => bless([34, 35, 36, 64..67, 99], "Down")}
 }

#latest:;
if (1)                                                                          ##Insert
 {Start 1;
  my $t = New(3);                                                               # Create tree
  my $f = Find($t, 1);
  my $c = FindResult_cmp($f);
  AssertEq($c, FindResult_notFound);
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, [];
 }

#latest:;
if (1)                                                                          ##Insert
 {Start 1;
  my $t = New(3);
  Insert($t, 1, 11);
  my $e = Execute(suppressOutput=>1);

  is_deeply $e->memory, {
  1 => bless([1, 1, 3, 3], "Tree"),
  3 => bless([1, 1, 0, 1, 4, 5, 0], "Node"),
  4 => bless([1], "Keys"),
  5 => bless([11], "Data")};
 }

#latest:;
if (1)                                                                          ##Insert
 {Start 1;
  my $t = New(3);
  Insert($t, 1, 11);
  Insert($t, 2, 22);
  my $e = Execute(suppressOutput=>1);

  is_deeply $e->memory, {
  1 => bless([2, 1, 3, 3], "Tree"),
  3 => bless([2, 1, 0, 1, 4, 5, 0], "Node"),
  4 => bless([1, 2], "Keys"),
  5 => bless([11, 22], "Data")};
 }

#latest:;
if (1)                                                                          ##Insert
 {Start 1;
  my $t = New(3);
  Insert($t, $_, "$_$_") for 1..3;
  my $e = Execute(suppressOutput=>1);

  is_deeply $e->memory, {
  1 => bless([3, 1, 3, 3], "Tree"),
  3 => bless([3, 1, 0, 1, 4, 5, 0], "Node"),
  4 => bless([1, 2, 3], "Keys"),
  5 => bless([11, 22, 33], "Data")};
 }

#latest:;
if (1)                                                                          ##Insert
 {Start 1;
  my $t = New(3);
  Insert($t, $_, "$_$_") for 1..4;
  my $e = Execute(suppressOutput=>1);

  is_deeply $e->memory, {
  1  => bless([4, 3, 3, 3], "Tree"),
  3  => bless([1, 1, 0, 1, 4, 5, 15], "Node"),
  4  => bless([2], "Keys"),
  5  => bless([22], "Data"),
  9  => bless([1, 2, 3, 1, 10, 11, 0], "Node"),
  10 => bless([1], "Keys"),
  11 => bless([11], "Data"),
  12 => bless([2, 3, 3, 1, 13, 14, 0], "Node"),
  13 => bless([3, 4], "Keys"),
  14 => bless([33, 44], "Data"),
  15 => bless([9, 12], "Down")};
 }

#latest:;
if (1)                                                                          ##Insert
 {Start 1;
  my $t = New(3);
  Insert($t, $_, "$_$_") for 1..5;

  my $e = Execute(suppressOutput=>1);
  is_deeply $e->memory, {
  1  => bless([5, 4, 3, 3], "Tree"),
  3  => bless([2, 1, 0, 1, 4, 5, 15], "Node"),
  4  => bless([2, 4], "Keys"),
  5  => bless([22, 44], "Data"),
  9  => bless([1, 2, 3, 1, 10, 11, 0], "Node"),
  10 => bless([1], "Keys"),
  11 => bless([11], "Data"),
  12 => bless([1, 3, 3, 1, 13, 14, 0], "Node"),
  13 => bless([3], "Keys"),
  14 => bless([33], "Data"),
  15 => bless([9, 12, 17], "Down"),
  17 => bless([1, 4, 3, 1, 18, 19, 0], "Node"),
  18 => bless([5], "Keys"),
  19 => bless([55], "Data")};
 }

#latest:;
if (1)                                                                          ##Insert
 {Start 1;
  my $t = New(3);
  Insert($t, $_, "$_$_") for 1..6;
  my $e = Execute(suppressOutput=>1);

  is_deeply $e->memory, {
  1  => bless([6, 4, 3, 3], "Tree"),
  3  => bless([2, 1, 0, 1, 4, 5, 15], "Node"),
  4  => bless([2, 4], "Keys"),
  5  => bless([22, 44], "Data"),
  9  => bless([1, 2, 3, 1, 10, 11, 0], "Node"),
  10 => bless([1], "Keys"),
  11 => bless([11], "Data"),
  12 => bless([1, 3, 3, 1, 13, 14, 0], "Node"),
  13 => bless([3], "Keys"),
  14 => bless([33], "Data"),
  15 => bless([9, 12, 17], "Down"),
  17 => bless([2, 4, 3, 1, 18, 19, 0], "Node"),
  18 => bless([5, 6], "Keys"),
  19 => bless([55, 66], "Data")};
 }

#latest:;
if (1)                                                                          ##New ##Insert ##Find ##FindResult_cmp
 {my $W = 3; my $N = 66;

  Start 1;
  my $t = New($W);

  For
   {my ($i, $check, $next, $end) = @_;                                          # Insert
    my $d = Add $i, $i;

    Insert($t, $i, $d);
   } $N;

  For                                                                           # Find each prior element
   {my ($j, $check, $next, $end) = @_;
    my $d = Add $j, $j;
    AssertEq $d, FindResult_data(Find($t, $j));
   } $N;
  AssertNe FindResult_found, FindResult_cmp(Find($t, -1));                      # Should not be present
  AssertNe FindResult_found, FindResult_cmp(Find($t, $N));

  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, [];                                                        # No asserts
 }


#latest:;
if (1)                                                                          ##randomArray
 {my $W = 3; my $N = 76; my @r = randomArray $N;

  Start 1;
  my $t = New($W);

  for my $i(0..$N-1)
   {Insert($t, $r[$i], $r[$i]);
   }

  Iterate                                                                       # Iterate tree
   {my ($find) = @_;                                                            # Find result
    my $k = FindResult_key($find);
    Out $k;
   } $t;

  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, [1..$N];
 }

#latest:;
if (1)                                                                          ##Iterate ##Keys ##FindResult_key ##FindResult_data ##Find ##printTreeKeys ##printTreeData
 {my $W = 3; my $N = 107; my @r = randomArray $N;

  Start 1;
  my $t = New($W);                                                              # Create tree at expected location in memory

  my $a = Array "aaa";
  for my $I(1..$N)                                                              # Load array
   {my $i = $I-1;
    Mov [$a, $i, "aaa"], $r[$i];
   }

  my $f = FindResult_new;

  ForArray                                                                      # Create tree
   {my ($i, $k) = @_;
    my $n = Keys($t);
    AssertEq $n, $i;                                                            # Check tree size
    my $K = Add $k, $k;
    Tally 1;
    Insert($t, $k, $K,                                                          # Insert a new node
      findResult=>          $f,
      maximumNumberOfKeys=> $W,
      splitPoint=>          int($W/2),
      rightStart=>          int($W/2)+1,
    );
    Tally 0;
   } $a, q(aaa);

  Iterate                                                                       # Iterate tree
   {my ($find) = @_;                                                            # Find result
    my $k = FindResult_key($find);
    Out $k;
    Tally 2;
    my $f = Find($t, $k, findResult=>$f);                                       # Find
    Tally 0;
    my $d = FindResult_data($f);
    my $K = Add $k, $k;
    AssertEq $K, $d;                                                            # Check result
   } $t;

  Tally 3;
  Iterate {} $t;                                                                # Iterate tree
  Tally 0;

  my $e = Execute(suppressOutput=>1);

  is_deeply $e->out, [1..$N];                                                   # Expected sequence

  #say STDERR dump $e->tallyCount;
  is_deeply $e->tallyCount,  24502;                                             # Insertion instruction counts

  #say STDERR dump $e->tallyTotal;
  is_deeply $e->tallyTotal, { 1 => 15456, 2 => 6294, 3 => 2752};

  #say STDERR dump $e->tallyCounts->{1};
  is_deeply $e->tallyCounts->{1}, {                                             # Insert tally
  add               => 159,
  array             => 247,
  arrayCountGreater => 2,
  arrayCountLess    => 262,
  arrayIndex        => 293,
  dec               => 30,
  inc               => 726,
  jEq               => 894,
  jGe               => 648,
  jLe               => 461,
  jLt               => 565,
  jmp               => 878,
  jNe               => 908,
  mov               => 7619,
  moveLong          => 171,
  not               => 631,
  resize            => 161,
  shiftUp           => 300,
  subtract          => 501};

  #say STDERR dump $e->tallyCounts->{2};
  is_deeply $e->tallyCounts->{2}, {                                             # Find tally
  add => 137,
  arrayCountLess => 223,
  arrayIndex => 330,
  inc => 360,
  jEq => 690,
  jGe => 467,
  jLe => 467,
  jmp => 604,
  jNe => 107,
  mov => 1975,
  not => 360,
  subtract => 574};

  #say STDERR dump $e->tallyCounts->{3};
  is_deeply $e->tallyCounts->{3}, {                                             # Iterate tally
  add        => 107,
  array      => 1,
  arrayIndex => 72,
  dec        => 72,
  free       => 1,
  inc        => 162,
  jEq        => 260,
  jFalse     => 28,
  jGe        => 316,
  jmp        => 252,
  jNe        => 117,
  jTrue      => 73,
  mov        => 1111,
  not        => 180};

  #say STDERR printTreeKeys($e->memory); x;
  is_deeply printTreeKeys($e->memory), <<END;
                                                                                                                38                                                                                                    72
                                                             21                                                                                                       56                                                                                                 89
                            10             15                                     28             33                                  45                   52                                     65                                     78             83                               94          98            103
        3        6     8             13          17    19          23       26             31             36          40    42             47    49             54          58    60    62             67    69                75                81             86             91             96            101         105
  1  2     4  5     7     9    11 12    14    16    18    20    22    24 25    27    29 30    32    34 35    37    39    41    43 44    46    48    50 51    53    55    57    59    61    63 64    66    68    70 71    73 74    76 77    79 80    82    84 85    87 88    90    92 93    95    97    99100   102   104   106107
END

  #say STDERR printTreeData($e->memory); x;
  is_deeply printTreeData($e->memory), <<END;
                                                                                                                76                                                                                                   144
                                                             42                                                                                                      112                                                                                                178
                            20             30                                     56             66                                  90                  104                                    130                                    156            166                              188         196            206
        6       12    16             26          34    38          46       52             62             72          80    84             94    98            108         116   120   124            134   138               150               162            172            182            192            202         210
  2  4     8 10    14    18    22 24    28    32    36    40    44    48 50    54    58 60    64    68 70    74    78    82    86 88    92    96   100102   106   110   114   118   122   126128   132   136   140142   146148   152154   158160   164   168170   174176   180   184186   190   194   198200   204   208   212214
END

 }

# (\A.{80})\s+(#.*\Z) \1\2

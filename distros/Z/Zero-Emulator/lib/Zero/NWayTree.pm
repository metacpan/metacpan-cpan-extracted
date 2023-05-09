#!/usr/bin/perl -I/home/phil/perl/cpan/ZeroEmulator/lib/ -Ilib
#-------------------------------------------------------------------------------
# Zero assembler language implemention of a generic N-Way tree.
# Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2023
#-------------------------------------------------------------------------------
# Key compression in each node by eliminating any common prefix present in each key in each node especially useful if we were to add attributes like userid, process, string position, rwx etc to front of each key.  Data does does not need this additional information.
use v5.30;
package Zero::NWayTree;
our $VERSION = 20230513;                                                        # Version
use warnings FATAL => qw(all);
use strict;
use Carp qw(cluck confess);
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
use Zero::Emulator qw(:all);
eval "use Test::More tests=>30" unless caller;

makeDieConfess;

my sub MaxIterations{99};                                                       # The maximum number of levels in a tree

my $Tree = sub                                                                  # The structure of an n-way tree
 {my $t = Zero::Emulator::AreaStructure("Structure");
     $t->name(q(keys));                                                         # Number of keys in tree
     $t->name(q(nodes));                                                        # Number of nodes in tree
     $t->name(q(NumberOfKeysPerNode));                                          # The maximum number of keys in a node of this tree
     $t->name(q(root));                                                         # Root node
     $t
 }->();

my $Node = sub                                                                  # The structure of an n-way tree node
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
  $f->name(q(key));                                                             # Key searched for
  $f->name(q(index));                                                           # Index in the node of located element
  $f
 }->();

my sub FindResult_lower   {0}                                                   # Comparison result
my sub FindResult_found   {1}
my sub FindResult_higher  {2}
my sub FindResult_notFound{3}

#D1 Constructor                                                                 # Create a new tree.

sub New($)                                                                      # Create a variable referring to a new tree descriptor.
 {my ($n) = @_;                                                                 # Maximum number of keys per node in this tree

  $n > 2 && $n % 2 or confess "Number of key/data elements per node must be > 2 and odd";

  my $t = Array "Tree";                                                         # Allocate tree descriptor
  Mov [$t, $Tree->address(q(NumberOfKeysPerNode)), 'Tree'], $n;                 # Save maximum number of keys per node
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
  Tree_getField($tree, q(NumberOfKeysPerNode));                                 # Get attribute from tree descriptor
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

my sub Node_setLength($$)                                                       # Set the length of a node
 {my ($node, $length) = @_;                                                     # Node, length
  Mov [$node, $Node->address(q(length)), 'Node'], $length;                      # Set length attribute
 }

my sub Node_incLength($)                                                        # Increment the length of a node
 {my ($node) = @_;                                                              # Node
  Inc [$node, $Node->address(q(length)), 'Node'];                               # Increment length attribute
 }

my sub Node_id($)                                                               # Get id of a node
 {my ($node) = @_;                                                              # Node
  Node_getField($node, q(id));                                                  # Get id
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

my sub Node_down($$)                                                            # Get the indexed child node from a node
 {my ($node, $index) = @_;                                                      # Node, index of child
  Node_getIndex($node, $index, q(down));                                        # Child
 }

my sub Node_isLeaf($)                                                           # Put 1 in a temporary variable if a node is a leaf else 0
 {my ($node) = @_;                                                              # Node
  Not [$node, $Node->address('down'), 'Node'];                                  # Whether the down field is present or not . 0 is never a user allocated memory area
 }

my sub Node_setKeys($$$)                                                        # Set a key by index
 {my ($node, $index, $value) = @_;                                              # Node, index, value
  Node_setIndex($node, $index, q(keys), $value)                                 # Set indexed key
 }

my sub Node_setData($$$)                                                        # Set a data field by index
 {my ($node, $index, $value) = @_;                                              # Node, index, value
  Node_setIndex($node, $index, q(data), $value)                                 # Set indexed key
 }

my sub Node_setDown($$$)                                                        # Set a child by index
 {my ($node, $index, $value) = @_;                                              # Node, index, value
  Node_setIndex($node, $index, q(down), $value)                                 # Set indexed key
 }

my sub Node_new($%)                                                             # Create a variable referring to a new node descriptor
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
  my $N = maximumNumberOfKeys($tree);                                           # Get the maximum number of keys per node for a tree
  $n                                                                            # Return reference to new node
 }

my sub Node_allocDown($%)                                                       # Upgrade a leaf node to an internal node
 {my ($node, %options) = @_;                                                    # Node to upgrade, options
  my $d = Array "Down";                                                         # Allocate down
  Mov [$node, $Node->address(q(down)), 'Node'], $d;                             # Down area
 }

my sub FindResult_getField($$)                                                  # Get a field from a find result
 {my ($findResult, $field) = @_;                                                # Find result, name of field
  Mov [$findResult, $FindResult->address($field), q(FindResult)];               # Fields
 }

sub FindResult_key($)                                                           # Get key from find result..
 {my ($f) = @_;                                                                 # Find result
  FindResult_getField($f, q(key))                                               # Key
 }

sub FindResult_cmp($)                                                           # Get comparison from find result..
 {my ($f) = @_;                                                                 # Find result
  FindResult_getField($f, q(cmp))                                               # Comparison
 }

my sub FindResult_index($)                                                      # Get index from find result
 {my ($f) = @_;                                                                 # Find result
  FindResult_getField($f, q(index))                                             # Index
 }

my sub FindResult_node($)                                                       # Get node from find result
 {my ($f) = @_;                                                                 # Find result
  FindResult_getField($f, q(node))                                              # Node
 }

sub FindResult_data($)                                                          # Get data field from find results..
 {my ($f) = @_;                                                                 # Find result

  my $n = FindResult_node ($f);
  my $i = FindResult_index($f);
  my $d = Node_data($n, $i);
  $d
 }

my sub FindResult($$)                                                           # Convert a symbolic name for a find result comparison to an integer
 {my ($f, $cmp) = @_;                                                           # Find result, comparison result name
  return 0 if $cmp eq q(lower);
  return 1 if $cmp eq q(equal);
  return 2 if $cmp eq q(higher);
  return 3 if $cmp eq q(notFound);
 }

my sub Node_open($$$$$)                                                         # Open a gap in an interior node
 {my ($node, $offset, $length, $K, $D) = @_;                                    # Node

  my $k = Mov [$node, \$Node->offset(qw(keys)), 'Node'];
  my $d = Mov [$node, \$Node->offset(qw(data)), 'Node'];
  my $n = Mov [$node, \$Node->offset(qw(down)), 'Node'];

  ShiftUp [$k, \$offset, 'Keys'], $K;
  ShiftUp [$d, \$offset, 'Data'], $D;
  my $o1 = Add $offset, 1;
  ShiftUp [$n, \$o1, 'Down'], 0;
  Node_incLength $node;
 }

my sub Node_openLeaf($$$$$)                                                     # Open a gap in a leaf node
 {my ($node, $offset, $length, $K, $D) = @_;                                    # Node

  my $k = Mov [$node, \$Node->offset(qw(keys)), 'Node'];
  my $d = Mov [$node, \$Node->offset(qw(data)), 'Node'];

  ShiftUp [$k, \$offset, 'Keys'], $K;
  ShiftUp [$d, \$offset, 'Data'], $D;
  Node_incLength $node;
 }

my sub Node_copy($$$$$)                                                         # Copy part of one interior node into another node.
 {my ($t, $s, $to, $so, $length) = @_;                                          # Target node, source node, target offset, source offset, length

  For                                                                           # Each key, data, down
   {my ($i, $check, $next, $end) = @_;
    my $S = Add $so, $i;
    my $T = Add $to, $i;

    my $k = Node_keys   ($s, $S);
    my $d = Node_data   ($s, $S);
    my $n = Node_down   ($s, $S);
            Node_setKeys($t, $T, $k);
            Node_setData($t, $T, $d);
            Node_setDown($t, $T, $n);
   } $length;

  my $S = Add $so, $length;
  my $T = Add $to, $length;

  my $n = Node_down($s, $S);
  Node_setDown($t, $T, $n);
 }

my sub Node_copy_leaf($$$$$)                                                    # Copy part of one leaf node into another node.
 {my ($t, $s, $to, $so, $length) = @_;                                          # Target node, source node, target offset, source offset, length

  For                                                                           # Each key, data, down
   {my ($i, $check, $next, $end) = @_;
    my $S = Add $so, $i;
    my $T = Add $to, $i;

    my $k = Node_keys   ($s, $S);
    my $d = Node_data   ($s, $S);
            Node_setKeys($t, $T, $k);
            Node_setData($t, $T, $d);
   } $length;
 }

my sub Node_free($)                                                             # Free a node
 {my ($node) = @_;                                                              # Node to free
  IfFalse Node_isLeaf($node),
  Then
   {my $K = Mov [$node, $Node->address(q(keys)), 'Node'];
    my $D = Mov [$node, $Node->address(q(data)), 'Node'];
    my $N = Mov [$node, $Node->address(q(down)), 'Node'];
    Free $K, "Keys";
    Free $D, "Data";
    Free $N, "Down";
   };
  Free $node, "Node";
 }

my sub FindResult_renew($$$$$)                                                  # Reuse an existing find result
 {my ($find, $node, $key, $cmp, $index) = @_;                                   # Find result, node, search key, comparison result, index
  my $f = $find;

  Mov [$f, $FindResult->address(q(node)) , 'FindResult'], $node;
  Mov [$f, $FindResult->address(q(key))  , 'FindResult'], $key;
  Mov [$f, $FindResult->address(q(cmp))  , 'FindResult'], $cmp;
  Mov [$f, $FindResult->address(q(index)), 'FindResult'], $index;
  $f
 }

my sub FindResult_create()                                                      # Create an empty find result ready for use
 {Array "FindResult";                                                           # Find result
 }

my sub FindResult_free($)                                                       # Free a find result
 {my ($find) = @_;                                                              # Find result
  Free $find, "FindResult";                                                     # Free find result
 }

my sub FindResult_new($$$$)                                                     # New find result
 {my ($node, $key, $cmp, $index) = @_;                                          # Node,search key, comparison result, index
  FindResult_renew(FindResult_create, $node, $key, $cmp, $index)                # Load find result
 }

my sub ReUp($)                                                                  # Reconnect the children to their new parent.
 {my ($node) = @_;                                                              # Parameters
  my $l = Node_length($node);
  my $L = Add $l, 1;

  For
   {my ($i, $check, $next, $end) = @_;                                          # Parameters
    my $d = Node_down ($node, $i);
            Node_setUp($d, $node);
   } $L;
 }

my sub Node_indexInParent($%)                                                   # Get the index of a node in its parent.
 {my ($node, %options) = @_;                                                    # Node, options
  my $p = $options{parent} // Node_up($node);                                   # Parent
  AssertNe($p, 0);                                                              # Number of children as opposed to the number of keys
  my $d = Node_field($p, 'down');
  my $r = ArrayIndex $d, $node;
  Dec $r;
  $r
 }

my sub Node_indexInParent222222222222($%)                                       # Get the index of a node in its parent.
 {my ($node, %options) = @_;                                                    # Node, options
  my $p = $options{parent} // Node_up($node);                                   # Parent
  AssertNe($p, 0);                                                              # Number of children as opposed to the number of keys
  my $l = $options{children} // Node_length($p);                                # Number of children
  AssertNe($l, 0);                                                              # Number of children as opposed to the number of keys
  my $L = Add $l, 1;
  my $r = Var;                                                                  # Index of child

  Block
   {my ($Start, $Good, $Bad, $End) = @_;
    For                                                                         # Loop through each child looking for the one specified
     {my ($i, $check, $next, $end) = @_;
      IfEq Node_down($p, $i), $node,
      Then
       {Mov $r, $i;
        Jmp $End;
       };
     } $L;
    Assert;                                                                     # Something has gone seriously wrong if we cannot find the node within its parent
   };
  my $R = Node_indexInParent2($node, %options);
  Out "AAAAA11";
  Out $r;
  Out $R;
  Out "AAAAA22";
  #AssertEq $r, $R;
  $r
 }

my sub Node_SplitIfFull($)                                                      # Split a node if it is full. Return true if the node was split else false
 {my ($node) = @_;                                                              # Node to split
  my $nl = Node_length($node);
  my $t = Node_tree($node);                                                     # Associated tree
  my $m = maximumNumberOfKeys($t);
  my $split = Var;

  Block                                                                         # Various splitting scenarios
   {my ($start, $good, $bad, $end) = @_;
    Jlt $bad, $nl, $m;                                                          # Must be a full node

    my $N = maximumNumberOfKeys($t);                                            # Split points
    my $n = Mov $N;                                                             # Copy
    ShiftRight $n, 1;                                                           # Index of key that will be placed in parent

    my $L = Add $n, 1;
    my $R = Subtract $N, $L;

    my $l = Node_new($t, length=>$n);                                           # New child nodes
    my $r = Node_new($t, length=>$R);

    IfFalse Node_isLeaf($node),                                                 # Not a leaf
    Then
     {Node_allocDown $l;                                                        # Add down area on left
      Node_allocDown $r;                                                        # Add down area on right
      Node_copy($l, $node, 0, 0,  $n);                                          # New left  node
      Node_copy($r, $node, 0, $L, $R);                                          # New right node
      ReUp($l);
      ReUp($r);
     },
    Else
     {Node_allocDown $node;                                                     # Add down area
      Node_copy_leaf($l, $node, 0, 0,  $n);                                     # New left  leaf
      Node_copy_leaf($r, $node, 0, $L, $R);                                     # New right leaf
     };

    my $p = Node_up($node);                                                     # Existing parent node
    IfTrue $p,
    Then                                                                        # Not a root node
     {my $pl = Node_length($p);
      Node_setUp($l, $p);                                                       # Connect children to parent
      Node_setUp($r, $p);

      IfEq Node_down($p, 0), $node,
      Then                                                                      # Splitting the first child - move everything up
       {my $nk = Node_keys($node, $n);
        my $nd = Node_data($node, $n);
        Node_open   ($p, 0, $pl, $nk, $nd);
        Node_setDown($p, 0, $l);
        Node_setDown($p, 1, $r);
        Node_free($node);
        Jmp $good;
       };

      IfEq Node_down($p, $pl), $node,                                           # Splitting the last child - just add it on the end
      Then
       {my $pk = Node_keys($node, $n);
        my $pd = Node_data($node, $n);
        Node_setKeys  ($p, $pl, $pk);
        Node_setDown  ($p, $pl, $l);
        my $nd = Node_data($node, $n);
        Node_setData  ($p, $pl, $nd);
        my $pl1 = Add $pl, 1;
        Node_setLength($p, $pl1);
        Node_setDown  ($p, $pl1, $r);
        Node_free     ($node);
        Jmp $good;
       };

      my $i = Node_indexInParent($node, parent=>$p, children=>$pl);             # Index of the node being split in its parent
      my $pli = Subtract $pl, $i;
      my $pk = Node_keys($node, $n);
      my $pd = Node_data($node, $n);
      Node_open     ($p, $i, $pli, $pk, $pd);
      Node_setDown  ($p, $i,  $l);
      my $i1  = Add $i,  1;
      Node_setDown  ($p, $i1, $r);
      Node_free     ($node);
      Jmp $good;
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

    if (1)                                                                      # Resize split node
     {my $K = Mov [$node, $Node->address(q(keys)), 'Node'];
      my $D = Mov [$node, $Node->address(q(data)), 'Node'];
      my $N = Mov [$node, $Node->address(q(down)), 'Node'];
      Resize $K, 1;
      Resize $D, 1;
      Resize $N, 2;
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

#D1 Find                                                                        # Find a key in a tree.

my sub FindAndSplit($$)                                                         # Find a key in a tree splitting full nodes along the path to the key.
 {my ($tree, $key) = @_;                                                        # Parameters (NWayTree(Tree) * const tree,                                                  # Tree to search
  my $node = root($tree);

  Node_SplitIfFull($node);                                                      # Split the root node if necessary
  my $F = Var;

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
         {Mov $F, FindResult_new($node, $key, FindResult_higher, $last);
          Jmp $Found;
         };
        my $last1 = Add $last, 1;
        my $n = Node_down($node, $last1);                                       # We will be heading down through the last node so split it in advance if necessary
        IfFalse Node_SplitIfFull($n),                                           # No split needed
        Then
         {Mov $node, $n;
         };
        Jmp $next;
       };

      For                                                                       # Search the keys in this node as greater than least key and less than largest key
       {my ($i, $check, $next, $end) = @_;                                      # Parameters
        my $k = Node_keys($node, $i);                                           # Current key

        IfLt $key, $k,                                                          # Greater than current key
        Then
         {IfTrue Node_isLeaf($node),
          Then
           {Mov $F, FindResult_new($node, $key, FindResult_lower, $i);
            Jmp $Found;
           };

          my $n = Node_down($node, $i);
          IfFalse Node_SplitIfFull($n),                                         # Split the node we have stepped to if necessary - if we do we will have to restart the descent from one level up because the key might have moved to the other  node.
          Then
           {Mov $node, $n;
           };
          Jmp $end;
         };

        IfEq $key, $k,                                                          # Found key
        Then
         {Mov $F, FindResult_new($node, $key, FindResult_found, $i);
          Jmp $Found;
         };
       } $nl;
     }  MaxIterations;
    Assert;                                                                     # Failed to descend through the tree to the key.
   };
  $F                                                                            # Results of find
 }

sub Find($$%)                                                                   # Find a key in a tree returning a L<FindResult> describing the outcome of the search.
 {my ($tree, $key, %options) = @_;                                              # Tree to search, key to find, options

  my $p = Procedure 'NWayTree_Find', sub
   {my ($p) = @_;                                                               # Procedure description
    my $tree = ParamsGet 0;
    my $key  = ParamsGet 1;

    my $node = root($tree);                                                     # Current node we are searching

    IfFalse $node,                                                              # Empty tree
    Then
     {ReturnPut 0, FindResult_new($node, $key, FindResult_notFound, -1);
      Return;
     };

    For                                                                         # Step down through tree
     {my ($j, $check, $next, $end) = @_;                                        # Parameters
      my $nl = Node_length($node);
      my $nl1 = Subtract $nl, 1;

      IfGt $key, Node_keys($node, $nl1),                                        # Bigger than every key
      Then
       {IfTrue Node_isLeaf($node),                                              # Leaf
        Then
         {ReturnPut 0, FindResult_new($node, $key, FindResult_higher, $nl);
          Return;
         };
        Mov $node, Node_down($node, $nl);
        Jmp $next;
       };

      For                                                                       # Search the keys in this node as less than largest key
       {my ($i, $check, $next, $end) = @_;                                      # Parameters
        my $k = Node_keys($node, $i);                                           # Key from tree
        IfEq $key, $k,                                                          # Found key
        Then
         {ReturnPut 0, FindResult_new($node, $key, FindResult_found, $i);
          Return;
         };
        IfLt $key, $k,                                                          # Lower than current key
        Then
         {IfTrue Node_isLeaf($node),                                            # Leaf
          Then
           {ReturnPut 0, FindResult_new($node, $key, FindResult_lower, $i);
            Return;
           };
          Mov $node, Node_down($node, $i);
          Jmp $end;
         };
       } $nl;
     } MaxIterations;
    Assert;
   };

  ParamsPut 0, $tree;                                                           # Set parameters and call insert procedure
  ParamsPut 1, $key;
  Call $p;
  ReturnGet 0;
 }

#D1 Insert                                                                      # Create a new entry ina tree connecting a key to data.

sub Insert($$$%)                                                                # Insert a key and its associated data into a tree.
 {my ($tree, $key, $data, %options) = @_;                                       # Tree, key, data

  my $p = Procedure 'NWayTree_Insert', sub
   {my ($p) = @_;                                                               # Procedure description

    Block
     {my ($Start, $Good, $Bad, $Finish) = @_;                                   # Parameters

      my $tree = ParamsGet 0;
      my $key  = ParamsGet 1;
      my $data = ParamsGet 2;
      my $n = root($tree);                                                      # Root node of tree

      IfFalse $n,                                                               # Empty tree
      Then
       {my $n = Node_new($tree, length=>1);
        Node_setKeys  ($n, 0, $key);
        Node_setData  ($n, 0, $data);
        incKeys($tree);
        setRoot($tree, $n);
        Jmp $Finish;
       };

      my $nl = Node_length($n);                                                 # Current length of node
      IfLt $nl, maximumNumberOfKeys($tree),                                     # Node has room for another key
      Then
       {IfFalse Node_up($n),                                                    # Root node
        Then
         {IfTrue Node_isLeaf($n),
          Then
           {For                                                                 # Each key
             {my ($i, $check, $next, $end) = @_;                                # Parameters
              my $k = Node_keys($n, $i);                                        # Key to check
              IfEq $key, $k,                                                    # Key already present
              Then
               {Node_setData($n, $i, $data);
                Jmp $Finish;
               };
              IfLt $key, $k,                                                    # We have reached the insertion point
              Then
               {my $nli = Subtract $nl, $i;
                Node_openLeaf($n, $i, $nli, $key, $data);
                incKeys($tree);
                Jmp $Finish;
               };
             } $nl;
            Node_setKeys($n, $nl, $key);                                        # Insert the key at the end of the block because it is greater than all the other keys in the block
            Node_setData($n, $nl, $data);
            my $nl1 = Add $nl, 1;
            Node_setLength($n, $nl1);
            incKeys($tree);
            Jmp $Finish;
           };
         };
       };
                                                                                # Insert node
      my $r = FindAndSplit($tree, $key);                                        # Check for existing key
      my $N = FindResult_node($r);
      my $c = FindResult_cmp($r);
      my $i = FindResult_index($r);
      FindResult_free($r);

      IfEq $c, FindResult_found,                                                # Found an equal key whose data we can update
      Then
       {Node_setData($N, $i, $data);
        Jmp $Finish;
       };

      my $Nl  = Node_length($N);
      my $Nl1 = Add $Nl, 1;
      IfEq $c, FindResult_higher,                                               # Found a key that is greater than the one being inserted
      Then
       {my $i1 = Add $i, 1;
        my $l = Subtract $Nl, $i1;
        Node_openLeaf($N, $i1, $l, $key, $data);
       },
      Else
       {my $l = Subtract $Nl, $i;
        Node_openLeaf($N, $i, $l, $key, $data);
       };

      incKeys($tree);
      Node_SplitIfFull($N);                                                     # Split if the leaf is full to force keys up the tree
     };
    Return;
   };

  ParamsPut 0, $tree;                                                           # Set parameters and call insert procedure.  As the tree parameter does not change very often the user has the option of setting it themselves out side of a loop.
  ParamsPut 1, $key;
  ParamsPut 2, $data;
  Call $p;
 }

#D1 Iteration                                                                   # Iterate over the keys and their associated data held in a tree.

my sub GoAllTheWayLeft($$)                                                      # Go as left as possible from the current node
 {my ($find, $node) = @_;                                                       # Find result, Node

  IfFalse $node,                                                                # Empty tree
  Then
   {FindResult_renew($find, $node, 0, FindResult_notFound, 0);
   },
  Else
   {For                                                                         # Step down through tree
     {my ($i, $check, $next, $end) = @_;                                        # Parameters
      JTrue $end, Node_isLeaf($node);                                           # Reached leaf
      Mov $node, Node_down($node, 0);
     } MaxIterations;
    FindResult_renew($find, $node, Node_keys($node, 0), FindResult_found,0);    # Leaf - place us on the first key
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
     {my $I = FindResult_index($find);
      my $L = Node_length($node);
      my $L1 = Subtract $L, 1;
      IfLt $I, $L1,                                                             # More keys in leaf
      Then
       {my $i = Add $I, 1;
        FindResult_renew($find, $node, Node_keys($node, $i),
          FindResult_found, $i);
        Jmp $Finish;
       };

      my $parent = Node_up($node);                                              # Parent
      IfTrue $parent,
      Then
       {For                                                                     # Not the only node in the tree
         {my ($j, $check, $next, $end) = @_;                                    # Parameters
          my $pl = Node_length($parent);                                        # Number of children
          my $i = Node_indexInParent($node, parent=>$parent, children=>$pl);    # Index in parent

          IfEq $i, $pl,                                                         # Last key - continue up
          Then
           {Mov $node, $parent;
            my $Parent = Node_up($parent);                                      # Parent
            Mov $parent, $Parent;
            JFalse $end, $parent;
           },
          Else
           {FindResult_renew($find, $parent, Node_keys($parent, $i),            # Not the last key
              FindResult_found, $i);
            Jmp $Finish;
           };
         } MaxIterations;
       };
      FindResult_renew($find, $node, 0, FindResult_notFound, 0);                # Last key of root
      Jmp $Finish;
     };

    my $i = FindResult_index($find);                                            # Not a leaf so on an interior key so we can go right then all the way left
    my $I = Add $i, 1;
    my $d = Node_down($node, $I);
    GoAllTheWayLeft($find, $d);
   };
  $find
 }

my sub IterStart($)                                                             # Start an iterator
 {my ($tree) = @_;                                                              # Tree to iterate
  my $n = root($tree);
  my $f = FindResult_create;
  GoAllTheWayLeft($f, $n);
 }

my sub IterCheck($)                                                             # True if we can continue to iterate
 {my ($F) = @_;                                                                 # Parameters (NWayTree(FindResult) const find)                                              # Find result of last iteration
  my $r = Var;
  IfEq FindResult_cmp($F), FindResult_notFound,
  Then
   {Mov $r, 0;
   },
  Else
   {Mov $r, 1;
   };
  $r
 }

my sub IterNext($)                                                              # Next element of an iteration
 {my ($F) = @_;                                                                 # Parameters (NWayTree(FindResult) const find)                                              # Find result of last iteration
  GoUpAndAround($F);
 }

sub Iterate(&$)                                                                 # Iterate over a tree.
 {my ($block, $tree) = @_;                                                      # Block of code to execute for each key in tree, tree
  my $f = IterStart($tree);

  For
   {my ($i, $check, $next, $end) = @_;                                          # Parameters
    JFalse $end, IterCheck($f);
    &$block($f);

    IterNext($f);
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

#D0 Tests

Test::More->builder->output("/dev/null");                                       # Reduce number of confirmation messages during testing

my $debug = -e q(/home/phil/);                                                  # Assume debugging if testing locally
eval {goto latest if $debug};

sub is_deeply;
sub ok($;$);
sub done_testing;
sub x {exit if $debug}                                                          # Stop if debugging.

#latest:;
if (1)                                                                          #TNew
 {Start 1;
  Out New(3);
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, [1];
  is_deeply $e->memory, { 1 => bless([0, 0, 3, 0], "Tree") };
 }

#latest:;
if (1)                                                                          #TsetRoot #Troot #TincKeys
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
if (1)                                                                          #TNode_open
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
if (1)                                                                          #TNode_open
 {Start 1;
  my $N = 7;
  my $t = New($N);                                                              # Create tree
  my $n = Node_new($t);                                                         # Create node

  Node_allocDown $n;

  for my $i(0..$N-1)
   {Node_setKeys($n, $i,  1+$i);
    Node_setData($n, $i,  11+$i);
    Node_setDown($n, $i,  21+$i);
   }

  Node_setDown($n, $N, 28);

  Node_open($n, 2, 4, 3, 13);
  my $e = Execute(suppressOutput=>1);

  is_deeply $e->memory, {
  1 => bless([0, 1, 7, 0], "Tree"),
  2 => bless([1, 1, 0, 1, 3, 4, 5], "Node"),
  3 => bless([1, 2, 3, 3 .. 7], "Keys"),
  4 => bless([11, 12, 13, 13 .. 17], "Data"),
  5 => bless([21, 22, 23, 0, 24 .. 28], "Down")};
 }

#latest:;
if (1)                                                                          #TNode_copy
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

  Node_copy(   $q, $p, 1, 3, 2);

  my $e = Execute(suppressOutput=>1);

  is_deeply $e->memory, {
  1 => bless([0, 2, 7, 0], "Tree"),
  2 => bless([0, 1, 0, 1, 3, 4, 5], "Node"),
  3 => bless([11 .. 17], "Keys"),
  4 => bless([21 .. 27], "Data"),
  5 => bless([31 .. 37, 97], "Down"),
  6 => bless([0, 2, 0, 1, 7, 8, 9], "Node"),
  7 => bless([41, 14, 15, 44 .. 47], "Keys"),
  8 => bless([51, 24, 25, 54 .. 57], "Data"),
  9 => bless([61, 34, 35, 36, 65, 66, 67, 99], "Down")}
 }

#latest:;
if (1)                                                                          #TFindResult_new #TFindResult_cmp
 {Start 1;
  my $f = FindResult_new(1, 2, 3, 4);
  my $n = FindResult_node($f);
  my $k = FindResult_key($f);
  my $c = FindResult_cmp($f);
  my $i = FindResult_index($f);
  Out $_ for $n, $c, $k, $i;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out,    [1, 3, 2, 4];
  is_deeply $e->memory, {1=>[1, 3, 2, 4]};
 }

#latest:;
if (1)                                                                          #TInsert
 {Start 1;
  my $t = New(3);                                                               # Create tree
  my $f = Find($t, 1);
  my $c = FindResult_cmp($f);
  AssertEq($c, FindResult_notFound);
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, [];
 }

#latest:;
if (1)                                                                          #TInsert
 {Start 1;
  my $t = New(3);
  Insert($t, 1, 11);
  my $e = Execute(suppressOutput=>1);

  is_deeply $e->memory, {
  1 => bless([1, 1, 3, 2], "Tree"),
  2 => bless([1, 1, 0, 1, 3, 4, 0], "Node"),
  3 => bless([1], "Keys"),
  4 => bless([11], "Data")};
 }

#latest:;
if (1)                                                                          #TInsert
 {Start 1;
  my $t = New(3);
  Insert($t, 1, 11);
  Insert($t, 2, 22);
  my $e = Execute(suppressOutput=>1);

  is_deeply $e->memory, {
  1 => bless([2, 1, 3, 2], "Tree"),
  2 => bless([2, 1, 0, 1, 3, 4, 0], "Node"),
  3 => bless([1, 2], "Keys"),
  4 => bless([11, 22], "Data")};
 }

#latest:;
if (1)                                                                          #TInsert
 {Start 1;
  my $t = New(3);
  Insert($t, $_, "$_$_") for 1..3;
  my $e = Execute(suppressOutput=>1);

  is_deeply $e->memory, {
  1 => bless([3, 1, 3, 2], "Tree"),
  2 => bless([3, 1, 0, 1, 3, 4, 0], "Node"),
  3 => bless([1, 2, 3], "Keys"),
  4 => bless([11, 22, 33], "Data")}
 }

#latest:;
if (1)                                                                          #TInsert
 {Start 1;
  my $t = New(3);
  Insert($t, $_, "$_$_") for 1..4;
  my $e = Execute(suppressOutput=>1);

  is_deeply $e->memory, {
  1  => bless([4, 3, 3, 2], "Tree"),
  2  => bless([1, 1, 0, 1, 3, 4, 11], "Node"),
  3  => bless([2], "Keys"),
  4  => bless([22], "Data"),
  5  => bless([1, 2, 2, 1, 6, 7, 0], "Node"),
  6  => bless([1], "Keys"),
  7  => bless([11], "Data"),
  8  => bless([2, 3, 2, 1, 9, 10, 0], "Node"),
  9  => bless([3, 4], "Keys"),
  10 => bless([33, 44], "Data"),
  11 => bless([5, 8], "Down"),
};
 }

#latest:;
if (1)                                                                          #TInsert
 {Start 1;
  my $t = New(3);
  Insert($t, $_, "$_$_") for 1..5;

  my $e = Execute(suppressOutput=>1);

  is_deeply $e->memory, {
  1  => bless([5, 5, 3, 2], "Tree"),
  2  => bless([2, 1, 0, 1, 3, 4, 11], "Node"),
  3  => bless([2, 4], "Keys"),
  4  => bless([22, 44], "Data"),
  5  => bless([1, 2, 2, 1, 6, 7, 0], "Node"),
  6  => bless([1], "Keys"),
  7  => bless([11], "Data"),
  11 => bless([5, 14, 17], "Down"),
  14 => bless([1, 4, 2, 1, 15, 16, 0], "Node"),
  15 => bless([3], "Keys"),
  16 => bless([33], "Data"),
  17 => bless([1, 5, 2, 1, 18, 19, 0], "Node"),
  18 => bless([5], "Keys"),
  19 => bless([55], "Data")}
 }

#latest:;
if (1)                                                                          #TInsert
 {Start 1;
  my $t = New(3);
  Insert($t, $_, "$_$_") for 1..6;
  my $e = Execute(suppressOutput=>1);

  is_deeply $e->memory, {
  1  => bless([6, 5, 3, 2], "Tree"),
  2  => bless([2, 1, 0, 1, 3, 4, 11], "Node"),
  3  => bless([2, 4], "Keys"),
  4  => bless([22, 44], "Data"),
  5  => bless([1, 2, 2, 1, 6, 7, 0], "Node"),
  6  => bless([1], "Keys"),
  7  => bless([11], "Data"),
  11 => bless([5, 14, 17], "Down"),
  14 => bless([1, 4, 2, 1, 15, 16, 0], "Node"),
  15 => bless([3], "Keys"),
  16 => bless([33], "Data"),
  17 => bless([2, 5, 2, 1, 18, 19, 0], "Node"),
  18 => bless([5, 6], "Keys"),
  19 => bless([55, 66], "Data")};
 }

#latest:;
if (1)                                                                          #TNew #TInsert #TFind
 {my $W = 3; my $N = 66;

  Start 1;
  my $t = New($W);

  for my $i(1..$N)
   {Insert($t, $i, my $d = $i+$i);
    for my $j(1..$i)
     {AssertEq $j+$j, FindResult_data(Find($t, $j));
     }
    AssertNe FindResult_found, FindResult_cmp(Find($t, 0));
    AssertNe FindResult_found, FindResult_cmp(Find($t, $i+1));
   }

  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, [];
 }

#latest:;
if (1)                                                                          #TNew #TInsert #TFind
 {my $W = 3; my $N = 66; my @r = randomArray $N;

  Start 1;
  my $t = New($W);

  for my $i(1..$N)
   {my $k = $r[$i-1]; my $d = $k*2;
    Insert($t, $k, $d);
    AssertEq $d, FindResult_data(Find($t, $k));
   }

  my $e = Execute(suppressOutput=>1);
  is_deeply printTreeKeys($e->memory), <<END;
                                                                                        30
                                     13                                                                                           44                               55
                    7                                     20             25                                  37                                     50                               61
     2     4              9    11          15    17                23          27                33    35          39    41                47             52                58             63    65
  1     3     5  6     8    10    12    14    16    18 19    21 22    24    26    28 29    31 32    34    36    38    40    42 43    45 46    48 49    51    53 54    56 57    59 60    62    64    66
END
 }

#latest:;
if (1)                                                                          # Print tree - random - 5
 {my $W = 5; my $N = 66; my @r = randomArray $N;

  Start 1;
  my $t = New($W);

  for my $i(1..$N)
   {Insert($t, $r[$i-1], $r[$i-1]);
   }

  my $e = Execute(suppressOutput=>1);
  is_deeply printTreeKeys($e->memory), <<END;
                                                                   23                                              39                                  51
           4        7             12             17       20                   27       30       33       36                   43          47                      55       58          62
  1  2  3     5  6     8  9 10 11    13 14 15 16    18 19    21 22    24 25 26    28 29    31 32    34 35    37 38    40 41 42    44 45 46    48 49 50    52 53 54    56 57    59 60 61    63 64 65 66
END
 }

#latest:;
if (1)                                                                          # Print tree keys
 {my $W = 3; my $N = 65;

  Start 1;
  my $t = New($W);

  for my $i(1..$N)
   {Insert($t, $i, $i);
   }

  my $e = Execute(suppressOutput=>1);
  is_deeply printTreeKeys($e->memory), <<END;
                                              16                                              32
                       8                                              24                                              40                      48                      56
           4                      12                      20                      28                      36                      44                      52                      60
     2           6          10          14          18          22          26          30          34          38          42          46          50          54          58          62    64
  1     3     5     7     9    11    13    15    17    19    21    23    25    27    29    31    33    35    37    39    41    43    45    47    49    51    53    55    57    59    61    63    65
END
 }

#latest:;
if (1)                                                                          # Print tree keys - reverse
 {my $W = 3; my $N = 65;

  Start 1;
  my $t = New($W);

  for my $i(reverse 1..$N)
   {Insert($t, $i, $i);
   }

  my $e = Execute(suppressOutput=>1);
  is_deeply printTreeKeys($e->memory), <<END;
                                                                                                    34                                              50
                            10                      18                      26                                              42                                              58
                 6                      14                      22                      30                      38                      46                      54                      62
     2     4           8          12          16          20          24          28          32          36          40          44          48          52          56          60          64
  1     3     5     7     9    11    13    15    17    19    21    23    25    27    29    31    33    35    37    39    41    43    45    47    49    51    53    55    57    59    61    63    65
END
 }

#latest:;
if (1)                                                                          # Print tree data
 {my $W = 3; my $N = 65;

  Start 1;
  my $t = New($W);

  for my $i(1..$N)
   {Insert($t, $i, $i);
   }

  my $e = Execute(suppressOutput=>1);
  is_deeply printTreeKeys($e->memory), <<END;
                                              16                                              32
                       8                                              24                                              40                      48                      56
           4                      12                      20                      28                      36                      44                      52                      60
     2           6          10          14          18          22          26          30          34          38          42          46          50          54          58          62    64
  1     3     5     7     9    11    13    15    17    19    21    23    25    27    29    31    33    35    37    39    41    43    45    47    49    51    53    55    57    59    61    63    65
END
 }

#latest:;
if (1)                                                                          # Print tree data - reverse
 {my $W = 3; my $N = 65;

  Start 1;
  my $t = New($W);

  for my $i(reverse 1..$N)
   {Insert($t, $i, $i);
   }

  my $e = Execute(suppressOutput=>1);
  is_deeply printTreeData($e->memory), <<END;
                                                                                                    34                                              50
                            10                      18                      26                                              42                                              58
                 6                      14                      22                      30                      38                      46                      54                      62
     2     4           8          12          16          20          24          28          32          36          40          44          48          52          56          60          64
  1     3     5     7     9    11    13    15    17    19    21    23    25    27    29    31    33    35    37    39    41    43    45    47    49    51    53    55    57    59    61    63    65
END
 }

#latest:;
if (1)                                                                          # Compare trees of keys and data
 {my $W = 3; my $N = 165; my @r = randomArray $N;

  Start 1;
  my $t = New($W);

  for my $i(0..$N-1)
   {Insert($t, $r[$i], $r[$i]);
   }

  my $e = Execute(suppressOutput=>1);
  is_deeply printTreeKeys($e->memory),
            printTreeData($e->memory);
 }

#latest:;
if (1)                                                                          #TprintTreeKeys #TprintTreeData
 {my $W = 7; my $N = 165; my @r = randomArray $N;

  Start 1;
  my $t = New($W);

  for my $i(0..$N-1)
   {Insert($t, $r[$i], $r[$i]);
   }

  my $e = Execute(suppressOutput=>1);
  is_deeply printTreeKeys($e->memory),
            printTreeData($e->memory);
 }

#latest:;
if (1)                                                                          # Compare trees of keys and data
 {my $W = 3; my $N = 75; my @r = randomArray $N;

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
if (1)                                                                          #TrandomArray
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
if (1)                                                                          #TIterate #TKeys #TFindResult_key #TFindResult_data #TFind
 {my $W = 3; my $N = 107; my @r = randomArray $N;

  Start 1;
  my $t = New($W);                                                              # Create tree at expected location in memory

  my $a = Array "aaa";
  for my $I(1..$N)                                                              # Load array
   {my $i = $I-1;
    Mov [$a, $i, "aaa"], $r[$i];
   }

  ForArray                                                                      # Create tree
   {my ($i, $k) = @_;
    my $n = Keys($t);
    AssertEq $n, $i;                                                            # Check tree size
    my $K = Add $k, $k;
    Tally 1;
    Insert($t, $k, $K);                                                         # Insert a new node
    Tally 0;
   } $a, q(aaa);

  Iterate                                                                       # Iterate tree
   {my ($find) = @_;                                                            # Find result
    my $k = FindResult_key($find);
    Out $k;
    my $f = Find($t, $k);                                                       # Find
    my $d = FindResult_data($f);
    my $K = Add $k, $k;
    AssertEq $K, $d;                                                            # Check result
   } $t;

  my $e = Execute(suppressOutput=>1);

  is_deeply $e->out, [1..$N];                                                   # Expected sequence

  is_deeply $e->tallyCount,  23612;                                             # Insertion instruction counts

  #say STDERR "AAAA\n", dump($e->tallyCounts->{1});

  is_deeply $e->tallyCounts->{1}, {
  add => 860,
  array => 607,
  arrayIndex => 7,
  call => 107,
  dec => 7,
  free => 360,
  inc => 1044,
  jEq => 631,
  jGe => 1660,
  jLe => 461,
  jLt => 565,
  jmp => 1436,
  jNe => 1088,
  mov => 12314,
  not => 695,
  paramsGet => 321,
  paramsPut => 321,
  resize => 12,
  return => 107,
  shiftRight => 68,
  shiftUp => 300,
  subtract => 641,
};
 }

done_testing;

# (\A.{80})\s+(#.*\Z) \1\2

#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib
#-------------------------------------------------------------------------------
# Tree operations
# Philip R Brenan at gmail dot com, Appa Apps Ltd Inc., 2020
#-------------------------------------------------------------------------------
# podDocumentation
package Tree::Ops;
our $VERSION = 20201030;
require v5.26;
use warnings FATAL => qw(all);
use strict;
use Carp;
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
use feature qw(current_sub say);
use experimental qw(smartmatch);

my $logFile = q(/home/phil/z/z/z/zzz.txt);                                      # Log printed results if developing

#D1 Build                                                                       # Create a tree.  There is no implicit ordering applied to the tree, the relationships between parents and children within the tree are as established by the user and can be reorganized at will using the methods in this module.

sub new(;$$)                                                                    #S Create a new child optionally recording the specified key or value.
 {my ($key, $value) = @_;                                                       # Key, value
  genHash(__PACKAGE__,                                                          # Child in the tree.
    children   => [],                                                           # Children of this child.
    key        => $key,                                                         # Key for this child - any thing that can be compared with the L<smartmatch> operator.
    value      => $value,                                                       # Value for this child.
    parent     => undef,                                                        # Parent for this child.
    lastChild  => undef,                                                        # Last active child chain - enables us to find the currently open scope from the start if the tree.
   );
 }

sub activeScope($)                                                              # Locate the active scope in a tree.
 {my ($tree) = @_;                                                              # Tree
  my $active;                                                                   # Latest active child
  for(my $l = $tree; $l; $l = $l->lastChild) {$active = $l}                     # Skip down edge of parse tree to deepest active child.
  $active
 }

sub setParentOfChild($$)                                                        #P Set the parent of a child and return the child.
 {my ($child, $parent) = @_;                                                    # Child, parent
  $child->parent = $parent;                                                     # Parent child
  $child
 }

sub open($;$$)                                                                  # Add a child and make it the currently active scope into which new children will be added.
 {my ($tree, $key, $value) = @_;                                                # Tree, key, value to be recorded in the interior child being opened
  my $parent = activeScope $tree;                                               # Active parent
  my $child  = new $key, $value;                                                # New child
  push $parent->children->@*, $child;                                           # Place new child last under parent
  $parent->lastChild = $child;                                                  # Make child active
  setParentOfChild $child, $parent                                              # Parent child
 }

sub close($)                                                                    # Close the current scope returning to the previous scope.
 {my ($tree) = @_;                                                              # Tree
  my $parent = activeScope $tree;                                               # Locate active scope
  delete $parent->parent->{lastChild} if $parent->parent;                       # Close scope
  $parent
 }

sub single($;$$)                                                                # Add one child in the current scope.
 {my ($tree, $key, $value) = @_;                                                # Tree, key, value to be recorded in the child being created
  $tree->open($key, $value);                                                    # Open scope
  $tree->close;                                                                 # Close scope immediately
 }

sub include($$)                                                                 # Include the specified tree in the currently open scope.
 {my ($tree, $include) = @_;                                                    # Tree being built, tree to include
  my $parent = activeScope $tree;                                               # Active parent
  my $n = new $include->key, $include->value;                                   # New intermediate child
     $n->children = $include->children;                                         # Include children
     $n->parent   = $parent;                                                    # Parent new node
  $parent->putLast($n)                                                          # Include node
 }

sub fromLetters($)                                                              # Create a tree from a string of letters returning the children created in alphabetic order  - useful for testing.
 {my ($letters) = @_;                                                           # String of letters and ( ).
  my $t = new(my $s = 'a');
  my @l = split //, $letters;

  my @c;                                                                        # Last letter seen
  for my $l(split(//, $letters), '')                                            # Each letter
   {my $c = shift @c;                                                           # Last letter
    if    ($l eq '(') {$t->open  ($c) if $c}                                    # Open new scope
    elsif ($l eq ')') {$t->single($c) if $c; $t->close}                         # Close scope
    else              {$t->single($c) if $c; @c = $l}                           # Save current letter as last letter
   }

  sort {$a->key cmp $b->key} $t->by                                             # Sorted results
 }

#D1 Navigation                                                                  # Navigate through a tree.

sub first($)                                                                    # Get the first child under the specified parent.
 {my ($parent) = @_;                                                            # Parent
  $parent->children->[0]
 }

sub last($)                                                                     # Get the last child under the specified parent.
 {my ($parent) = @_;                                                            # Parent
  $parent->children->[-1]
 }

sub indexOfChildInParent($)                                                     #P Get the index of a child within the specified parent.
 {my ($child) = @_;                                                             # Child
  return undef unless my $parent = $child->parent;                              # Parent
  my $c = $parent->children;                                                    # Siblings
  for(keys @$c) {return $_ if $$c[$_] == $child}                                # Locate child and return index
  undef                                                                         # Root has no index
 }

sub next($)                                                                     # Get the next sibling following the specified child.
 {my ($child) = @_;                                                             # Child
  return undef unless my $parent = $child->parent;                              # Parent
  my $c = $parent->children;                                                    # Siblings
  return undef if @$c == 0 or $$c[-1] == $child;                                # No next child
  $$c[+1 + indexOfChildInParent $child]                                         # Next child
 }

sub prev($)                                                                     # Get the previous sibling of the specified child.
 {my ($child) = @_;                                                             # Child
  return undef unless my $parent = $child->parent;                              # Parent
  my $c = $parent->children;                                                    # Siblings
  return undef if @$c == 0 or $$c[0] == $child;                                 # No previous child
  $$c[-1 + indexOfChildInParent $child]                                         # Previous child
 }

sub firstMost($)                                                                # Return the first most descendant child in the tree starting at this parent or else return B<undef> if this parent has no children.
 {my ($parent) = @_;                                                            # Parent
  my $f;
  for(my $p = $parent; $p; $p = $p->first) {$f = $p}                            # Go first most
  $f
 }

sub nextMost($)                                                                 # Return the next child with no children, i.e. the next leaf of the tree, else return B<undef> if there is no such child.
 {my ($child) = @_;                                                             # Current leaf
  return firstMost $child if $child->children->@*;                              # First most child if we are not starting on a child with no children - i.e. on a leaf.
  my   $p = $child;                                                             # Traverse upwards and then right
  $p = $p->parent while $p->isLast;                                             # Traverse upwards
  return undef unless $p = $p->next;                                            # Traverse right else we are at the root
  firstMost $p                                                                  # First most child
 }

sub prevMost($)                                                                 # Return the previous child with no children, i.e. the previous leaf of the tree, else return B<undef> if there is no such child.
 {my ($child) = @_;                                                             # Current leaf
  my   $p = $child;                                                             # Traverse upwards and then left
  $p = $p->parent while $p->isFirst;                                            # Traverse upwards
  return undef unless $p = $p->prev;                                            # Traverse left else we are at the root
  lastMost $p                                                                   # Last most child
 }

sub lastMost($)                                                                 # Return the last most descendant child in the tree starting at this parent or else return B<undef> if this parent has no children.
 {my ($parent) = @_;                                                            # Parent
  my $f;
  for(my $p = $parent; $p; $p = $p->last) {$f = $p}                             # Go last most
  $f
 }

sub topMost($)                                                                  # Return the top most parent in the tree containing the specified child.
 {my ($child) = @_;                                                             # Child
  for(my $p = $child; $p;) {return $p unless my $q = $p->parent; $p = $q}       # Go up
  confess "Child required";
 }

sub mostRecentCommonAncestor($$)                                                # Find the most recent common ancestor of the specified children.
 {my ($first, $second) = @_;                                                    # First child, second child
  return $first if $first == $second;                                           # Same first and second child
  my @f = context $first;                                                       # Context of first child
  my @s = context $second;                                                      # Context of second child
  my $c; $c = pop @f, pop @s while @f and @s and $f[-1] == $s[-1];              # Remove common ancestors
  $c
 }

sub go($@)                                                                      # Return the child at the end of the path starting at the specified parent. A path is a list of zero based children numbers. Return B<undef> if the path is not valid.
 {my ($parent, @path) = @_;                                                     # Parent, list of zero based children numbers
  my $p = $parent;                                                              # Start
  my $q; defined($q = $p->children->[$_]) ? $p = $q : return undef for @path;   # Down                                                             # Same first and second child
  $p
 }

#D1 Location                                                                    # Verify the current location.

sub context($)                                                                  # Get the context of the current child.
 {my ($child) = @_;                                                             # Child
  my @c;                                                                        # Context
  for(my $c = $child; $c; $c = $c->parent) {push @c, $c}                        # Walk up
  @c
 }

sub isFirst($)                                                                  # Return the specified child if that child is first under its parent, else return B<undef>.
 {my ($child) = @_;                                                             # Child
  return undef unless my $parent = $child->parent;                              # Parent
  $parent->children->[0] == $child ? $child : undef                             # There will be at least one child
 }

sub isLast($)                                                                   # Return the specified child if that child is last under its parent, else return B<undef>.
 {my ($child) = @_;                                                             # Child
  return undef unless my $parent = $child->parent;                              # Parent
  my $c = $parent->children;
  $parent->children->[-1] == $child ? $child : undef                            # There will be at least one child
 }

sub isTop($)                                                                    # Return the specified parent if that parent is the top most parent in the tree.
 {my ($parent) = @_;                                                            # Parent
  $parent->parent ? undef : $parent
 }

sub singleChildOfParent($)                                                      # Return the only child of this parent if the parent has an only child, else B<undef>
 {my ($parent) = @_;                                                            # Parent
  $parent->children->@* == 1 ? $parent->children->[0] : undef                   # Return only child if it exists
 }

sub empty($)                                                                    # Return the specified parent if it has no children else B<undef>
 {my ($parent) = @_;                                                            # Parent
  $parent->children->@* == 0 ? $parent : undef
 }

#D1 Put                                                                         # Insert children into a tree.

sub putFirst($$)                                                                # Place a new child first under the specified parent and return the child.
 {my ($parent, $child) = @_;                                                    # Parent, child
  unshift $parent->children->@*, $child;                                        # Place child
  setParentOfChild $child, $parent                                              # Parent child
 }

sub putLast($$)                                                                 # Place a new child last under the specified parent and return the child.
 {my ($parent, $child) = @_;                                                    # Parent, child
  push $parent->children->@*, $child;                                           # Place child
  setParentOfChild $child, $parent                                              # Parent child
 }

sub putNext($$)                                                                 # Place a new child after the specified child.
 {my ($child, $new) = @_;                                                       # Existing child, new child
  return undef unless defined(my $i = indexOfChildInParent $child);             # Locate child within parent
  splice $child->parent->children->@*, $i, 1, $child, $new;                     # Place new child
  setParentOfChild $new, $child->parent                                         # Parent child
 }

sub putPrev($$)                                                                 # Place a new child before the specified child.
 {my ($child, $new) = @_;                                                       # Child, new child
  return undef unless defined(my $i = indexOfChildInParent($child));            # Locate child within parent
  splice $child->parent->children->@*, $i, 1, $new, $child;                     # Place new child
  setParentOfChild $new, $child->parent                                         # Parent child
 }

#D1 Steps                                                                       # Move the start or end of a scope forwards or backwards as suggested by Alex Monroe.

sub step($)                                                                     # Make the first child of the specified parent the parents previous sibling and return the parent. In effect this moves the start of the parent one step forwards.
 {my ($parent) = @_;                                                            # Parent
  return undef unless my $f = $parent->first;                                   # First child
  putPrev $parent, cut $f;                                                      # Place first child
  $parent
 }

sub stepEnd($)                                                                  # Make the next sibling of the specified parent the parents last child and return the parent. In effect this moves the end of the parent one step forwards.
 {my ($parent) = @_;                                                            # Parent
  return undef unless my $n = $parent->next;                                    # Next sibling
  putLast $parent, cut $n;                                                      # Place next sibling as first child
  $parent
 }

sub stepBack                                                                    # Make the previous sibling of the specified parent the parents first child and return the parent. In effect this moves the start of the parent one step backwards.
 {my ($parent) = @_;                                                            # Parent
  return undef unless my $p = $parent->prev;                                    # Previous sibling
  putFirst $parent, cut $p;                                                     # Place previous sibling as first child
  $parent
 }

sub stepEndBack                                                                 # Make the last child of the specified parent the parents next sibling and return the parent. In effect this moves the end of the parent one step backwards.
 {my ($parent) = @_;                                                            # Parent
  return undef unless my $l = $parent->last;                                    # Last child sibling
  putNext $parent, cut $l;                                                      # Place last child as first sibling
  $parent
 }

#D1 Edit                                                                        # Edit a tree in situ.

sub cut($)                                                                      # Cut out a child and all its content and children, return it ready for reinsertion else where.
 {my ($child) = @_;                                                             # Child
  return $child unless my $parent = $child->parent;                             # The whole tree
  splice $parent->children->@*, indexOfChildInParent($child), 1;                # Remove child
  $child
 }

sub dup($)                                                                      # Duplicate a specified parent and all its descendants returning the root of the resulting tree.
 {my ($parent) = @_;                                                            # Parent

  sub                                                                           # Duplicate a child
   {my ($old)  = @_;                                                            # Existing child
    my $new    = new $old->key, $old->value;                                    # New child
    push $new->children->@*, __SUB__->($_) for $old->children->@*;              # Duplicate children of child
    $new
   }->($parent)                                                                 # Start duplication at parent
 }

sub transcribe($)                                                               # Duplicate a specified parent and all its descendants recording the mapping in a temporary {transcribed} field in the tree being transcribed. Returns the root parent of the tree being duplicated.
 {my ($parent) = @_;                                                            # Parent

  sub                                                                           # Duplicate a child
   {my ($old) = @_;                                                             # Existing child
    my $new   = new $old->key, $old->value;                                     # New child
    $old->{transcribedTo}   = $new;                                             # To where we went
    $new->{transcribedFrom} = $old;                                             # From where we came
    push $new->children->@*, __SUB__->($_) for $old->children->@*;              # Duplicate children of child and record transcription
    $new
   }->($parent)                                                                 # Start duplication at parent
 }

sub unwrap($)                                                                   # Unwrap the specified child and return that child.
 {my ($child) = @_;                                                             # Child
  return undef unless defined(my $i = indexOfChildInParent $child);             # Locate child within parent
  my $parent = $child->parent;                                                  # Parent
  $_->parent = $parent for $child->children->@*;                                # Reparent unwrapped children of child
  delete $child ->{parent};                                                     # Remove parent of unwrapped child
  splice $parent->children->@*, $i, 1, $child->children->@*;                    # Remove child
  $parent
 }

sub wrap($;$$)                                                                  # Wrap the specified child with a new parent and return the new parent optionally setting its L[key] and L[value].
 {my ($child, $key, $value) = @_;                                               # Child to wrap, optional key, optional value
  return undef unless defined(my $i = indexOfChildInParent $child);             # Locate child within existing parent
  my $parent     = $child->parent;                                              # Existing parent
  my $new        = new $key, $value;                                            # Create new parent
  $new->parent   = $parent;                                                     # Parent new parent
  $new->children = [$child];                                                    # Set children for new parent
  splice $parent->children->@*, $i, 1, $new;                                    # Place new parent in existing parent
  $child->parent = $new                                                         # Reparent child to new parent
 }

sub wrapChildren($;$$)                                                          # Wrap the children of the specified parent with a new intermediate parent that becomes the child of the specified parent, optionally setting the L[key] and the L[value] for the new parent.  Return the new parent.
 {my ($parent, $key, $value) = @_;                                              # Child to wrap, optional key for new wrapping parent, optional value for new wrapping parent
  my $new           = new $key, $value;                                         # Create new parent
  $new->children    = $parent->children;                                        # Move children;
  $parent->children = [$new];                                                   # Grand parent
  $new->parent      = $parent;                                                  # Parent new parent
  $_->parent = $new for $new->children->@*;                                     # Reparent new children
  $new                                                                          # New parent
 }

sub merge($)                                                                    # Unwrap the children of the specified parent with the whose L[key] fields L<smartmatch> that of their parent. Returns the specified parent regardless.
 {my ($parent) = @_;                                                            # Merging parent
  for my $c($parent->children->@*)                                              # Children of parent
   {unwrap $c if $c->key ~~ $parent->key;                                       # Unwrap child if like parent
   }
  $parent
 }

sub mergeLikePrev($)                                                            # Merge the preceding sibling of the specified child  if that sibling exists and the L[key] data of the two siblings L<smartmatch>. Returns the specified child regardless. From a proposal made by Micaela Monroe.
 {my ($child) = @_;                                                             # Child
  return $child unless my $prev = $child->prev;                                 # No merge possible if child is first
  $child->putFirst($prev->cut)->unwrap                                          # Children to be merged
 }

sub mergeLikeNext($)                                                            # Merge the following sibling of the specified child  if that sibling exists and the L[key] data of the two siblings L<smartmatch>. Returns the specified child regardless. From a proposal made by Micaela Monroe.
 {my ($child) = @_;                                                             # Child
  return $child unless my $next = $child->next;                                 # No merge possible if child is last
  $child->putLast($next->cut)->unwrap                                           # Children to be merged
 }

sub split($)                                                                    # Make the specified parent a grandparent of each of its children by interposing a copy of the specified parent between the specified parent and each of its children. Return the specified parent.
 {my ($parent) = @_;                                                            # Parent to make into a grand parent
  wrap $_, $parent->key for $parent->children->@*;                              # Grandparent each child
  $parent
 }

#D1 Traverse                                                                    # Traverse a tree.

sub by($;$)                                                                     # Traverse a tree in post-order to process each child with the specified sub and return an array of the results of processing each child. If no sub sub is specified, the children are returned in tree order.
 {my ($tree, $sub) = @_;                                                        # Tree, optional sub to process each child
             $sub //= sub{@_};                                                  # Default sub

  my @r;                                                                        # Results
  sub                                                                           # Traverse
   {my ($child) = @_;                                                           # Child
    __SUB__->($_) for $child->children->@*;                                     # Children of child
    push @r, &$sub($child);                                                     # Process child saving result
   }->($tree);                                                                  # Start at root of tree

  @r
 }

sub select($$)                                                                  # Select matching children in a tree in post-order. A child can be selected via named value, array of values, a hash of values, a regular expression or a sub reference.
 {my ($tree, $select) = @_;                                                     # Tree, method to select a child
  my $ref = ref $select;                                                        # Selector type
  my $sel =                                                                     # Selection method
             $ref =~ m(array)i ? sub{grep{$_[0] eq $_} @$select} :              # Array
             $ref =~ m(hash)i  ? sub{$$select{$_[0]}}            :              # Hash
             $ref =~ m(exp)i   ? sub{$_[0] =~ m($select)}        :              # Regular expression
             $ref =~ m(code)i  ? sub{&$select($_[0])}            :              # Sub
                                 sub{$_[0] eq $select};                         # Scalar
  my @s;                                                                        # Selection

  sub                                                                           # Traverse
   {my ($child) = @_;                                                           # Child
    push @s, $child if &$sel($child->key);                                      # Select child if it matches
    __SUB__->($_) for $child->children->@*;                                     # Each child
   }->($tree);                                                                  # Start at root

  @s
 }

#D1 Partitions                                                                  # Various partitions of the tree

sub leaves($)                                                                   # The set of all children without further children, i.e. each leaf of the tree.
 {my ($tree) = @_;                                                              # Tree
  my @leaves;                                                                   # Leaves
  sub                                                                           # Traverse
   {my ($child) = @_;                                                           # Child
    if (my @c = $child->children->@*)                                           # Children of child
     {__SUB__->($_) for @c;                                                     # Process children of child
     }
    else
     {push @leaves, $child;                                                     # Save leaf
     }
   }->($tree);                                                                  # Start at root of tree

  @leaves
 }

sub parentsOrdered($$$)                                                         #P The set of all parents in the tree, i.e. each non leaf of the tree, i.e  the interior of the tree in the specified order.
 {my ($tree, $preorder, $reverse) = @_;                                         # Tree, pre-order if true else post-order, reversed if true
  my @parents;                                                                  # Parents
  sub                                                                           # Traverse
   {my ($child) = @_;                                                           # Child
    if (my @c = $child->children->@*)                                           # Children of child
     {@c = reverse @c if $reverse;                                              # Reverse if requested
      push @parents, $child if $preorder;                                       # Pre-order
       __SUB__->($_) for @c;                                                    # Process children of child
      push @parents, $child unless $preorder;                                   # Post-order
     }
   }->($tree);                                                                  # Start at root of tree

  @parents
 }

sub parentsPreOrder($)                                                          # The set of all parents in the tree, i.e. each non leaf of the tree, i.e  the interior of the tree in normal pre-order.
 {my ($tree) = @_;                                                              # Tree
  parentsOrdered($tree, 1, 0);
 }

sub parentsPostOrder($)                                                         # The set of all parents in the tree, i.e. each non leaf of the tree, i.e  the interior of the tree in normal post-order.
 {my ($tree) = @_;                                                              # Tree
  parentsOrdered($tree, 0, 0);
 }

sub parentsReversePreOrder($)                                                   # The set of all parents in the tree, i.e. each non leaf of the tree, i.e  the interior of the tree in reverse pre-order.
 {my ($tree) = @_;                                                              # Tree
  parentsOrdered($tree, 1, 1);
 }

sub parentsReversePostOrder($)                                                  # The set of all parents in the tree, i.e. each non leaf of the tree, i.e  the interior of the tree in reverse post-order.
 {my ($tree) = @_;                                                              # Tree
  &parentsOrdered($tree, 0, 1);
 }

sub parents($)                                                                  # The set of all parents in the tree, i.e. each non leaf of the tree, i.e  the interior of the tree in normal post-order.
 {my ($tree) = @_;                                                              # Tree
  &parentsPostOrder(@_);
 }

#D1 Order                                                                       # Check the order and relative position of children in a tree.

sub above($$)                                                                   # Return the first child if it is above the second child else return B<undef>.
 {my ($first, $second) = @_;                                                    # First child, second child
  return undef if $first == $second;                                            # A child cannot be above itself
  my @f = context $first;                                                       # Context of first child
  my @s = context $second;                                                      # Context of second child
  pop @f, pop @s while @f and @s and $f[-1] == $s[-1];                          # Find first different ancestor
  !@f ? $first : undef                                                          # First is above second if the ancestors of first are also ancestors of second
 }

sub below($$)                                                                   # Return the first child if it is below the second child else return B<undef>.
 {my ($first, $second) = @_;                                                    # First child, second child
  above($second, $first) ? $first : undef
 }

sub after($$)                                                                   # Return the first child if it occurs strictly after the second child in the tree or else B<undef> if the first child is L[above], L[below] or L[before] the second child.
 {my ($first, $second) = @_;                                                    # First child, second child
  my @f = context $first;                                                       # Context of first child
  my @s = context $second;                                                      # Context of second child
  pop @f, pop @s while @f and @s and $f[-1] == $s[-1];                          # Find first different ancestor
  return undef unless @f and @s;                                                # Not strictly after
  indexOfChildInParent($f[-1]) > indexOfChildInParent($s[-1]) ? $first : undef  # First child relative to second child at first common ancestor
 }

sub before($$)                                                                  # Return the first child if it occurs strictly before the second child in the tree or else B<undef> if the first child is L[above], L[below] or L[after] the second child.
 {my ($first, $second) = @_;                                                    # First child, second child
  after($second, $first)  ? $first : undef
 }

#D1 Paths                                                                       # Find paths between nodes

sub path($)                                                                     # Return the list of zero based child indexes for the path from the root of the tree containing the specified child to the specified child for use by the L[go] method.
 {my ($child) = @_;                                                             # Child
  my @p;                                                                        # Path
  for(my $p = $child; my $q = $p->parent; $p = $q)                              # Go up
   {unshift @p, indexOfChildInParent $p                                         # Record path
   }
  @p
 }

sub pathFrom($$)                                                                # Return the list of zero based child indexes for the path from the specified ancestor to the specified child for use by the L[go] method else confess if the ancestor is not, in fact, an ancestor.
 {my ($child, $ancestor) = @_;                                                  # Child, ancestor
  return () if $child == $ancestor;                                             # Easy case
  my @p;                                                                        # Path
  for(my $p = $child; my $q = $p->parent; $p = $q)                              # Go up
   {unshift @p, indexOfChildInParent $p;                                        # Record path
    return @p if $q == $ancestor;                                               # Stop at ancestor
   }
  confess "Not an ancestor"
 }

sub siblingsBefore($)                                                           # Return a list of siblings before the specified child.
 {my ($child) = @_;                                                             # Child
  return () unless my $parent = $child->parent;                                 # Parent
  my @c = $parent->children->@*;                                                # Children
  my $i = indexOfChildInParent $child;                                          # Our position
  @c[0..$i-1]
 }

sub siblingsAfter($)                                                            # Return a list of siblings after the specified child.
 {my ($child) = @_;                                                             # Child
  return () unless my $parent = $child->parent;                                 # Parent
  my @c = $parent->children->@*;                                                # Children
  my $i = indexOfChildInParent $child;                                          # Our position
  @c[$i+1..$#c]
 }

sub siblingsStrictlyBetween($$)                                                 # Return a list of the siblings strictly between two children of the same parent else return B<undef>.
 {my ($start, $finish) = @_;                                                    # Start child, finish child
  return () unless my $parent = $start->parent;                                 # Parent
  confess "Must be siblings" unless $parent == $finish->parent;                 # Check both children have the same parent
  my @c = $parent->children->@*;                                                # All siblings
  shift @c while @c and $c[0]  != $start;                                       # Remove all siblings up to the start child
  pop   @c while @c and $c[-1] != $finish;                                      # Remove all siblings after the finish child
  shift @c; pop @c if @c;                                                       # Remove first and last child to make range strictly between
  @c                                                                            # Siblings strictly between start and finish
 }

sub lineage($$)                                                                 # Return the path from the specified child to the specified ancestor else return B<undef> if the child is not a descendant of the ancestor.
 {my ($child, $ancestor) = @_;                                                  # Child, ancestor
  my @p;                                                                        # Path
  for(my $p = $child; $p; $p = $p->parent)                                      # Go up
   {push @p, $p;                                                                # Record path
    last if $p == $ancestor                                                     # Stop if we encounter the specified ancestor
   }
  return @p if !@p or $p[-1] == $ancestor;                                      # Found the ancestor
  undef                                                                         # No such ancestor
 }

sub nextPreOrderPath($)                                                         # Return a list of children visited between the specified child and the next child in pre-order.
 {my ($start) = @_;                                                             # The child at the start of the path
  return ($start->first) if $start->children->@*;                               # First child if possible
  my   $p = $start;                                                             # Traverse upwards and then right
  my   @p;                                                                      # Path
  push @p, $p = $p->parent while $p->isLast;                                    # Traverse upwards
  $p->next ? (@p, $p->next) : ()                                                # Traverse right else we are at the root
 }

sub nextPostOrderPath($)                                                        # Return a list of children visited between the specified child and the next child in post-order.
 {my ($start) = @_;                                                             # The child at the start of the path
  my   $p = $start;                                                             # Traverse upwards and then right, then first most
  my   @p;                                                                      # Path
  if (!$p->parent)                                                              # Starting at the root which is last in a post order traversal
   {push @p, $p while $p = $p->first;
    return @p
   }
  return (@p, $p->parent) if $p->isLast;                                        # Traverse upwards
  if (my $q = $p->next)                                                         # Traverse right
   {for(              ; $q; $q = $q->first) {push @p, $q}                       # Traverse first most
    return @p
   }
  ($p)                                                                          # Back at the root
 }

sub prevPostOrderPath($)                                                        # Return a list of children visited between the specified child and the previous child in post-order.
 {my ($start) = @_;                                                             # The child at the start of the path
  return ($start->last) if $start->children->@*;                                # Last child if possible
  my   $p = $start;                                                             # Traverse upwards and then left
  my   @p;                                                                      # Path
  push @p, $p = $p->parent while $p->isFirst;                                   # Traverse upwards
  $p->prev ? (@p, $p->prev) : ()                                                # Traverse left else we are at the root
 }

sub prevPreOrderPath($)                                                         # Return a list of children visited between the specified child and the previous child in pre-order.
 {my ($start) = @_;                                                             # The child at the start of the path
  my   $p = $start;                                                             # Traverse upwards and then left, then last most
  my   @p;                                                                      # Path
  if (!$p->parent)                                                              # Starting at the root which is last in a post order traversal
   {push @p, $p while $p = $p->last;
    return @p
   }
  return (@p, $p->parent) if $p->isFirst;                                       # Traverse upwards
  if (my $q = $p->prev)                                                         # Traverse left
   {for(              ; $q; $q = $q->last) {push @p, $q}                        # Traverse last most
    return @p
   }
  ($p)                                                                          # Back at the root
 }

#D1 Print                                                                       # Print a tree.

sub printTree($$$$)                                                             #P String representation as a horizontal tree.
 {my ($tree, $print, $preorder, $reverse) = @_;                                 # Tree, optional print method, pre-order, reverse
  my @s;                                                                        # String representation

  sub                                                                           # Print a child
   {my ($child, $depth) = @_;                                                   # Child, depth
    my $key   = $child->key;                                                    # Key
    my $value = $child->value;                                                  # Value
    my $k = join '', '  ' x $depth, $print ? &$print($key) : $key;              # Print key
    my $v = !defined($value) ? '' : ref($value) ? dump($value) : $value;        # Print value
    push @s, [$k, $v] if     $preorder;
    my @c = $child->children->@*; @c = reverse @c if $reverse;
    __SUB__->($_, $depth+1) for @c;                                             # Print children of child
    push @s, [$k, $v] unless $preorder;
   }->($tree, 0);                                                               # Print root

  my $r = formatTableBasic [[qw(Key Value)], @s];                               # Print tree
  owf($logFile, $r) if -e $logFile;                                             # Log the result if requested
  $r
 }

sub printPreOrder($;$)                                                          # Print tree in normal pre-order.
 {my ($tree, $print) = @_;                                                      # Tree, optional print method
  printTree($tree, $print, 1, 0);
 }

sub printPostOrder($;$)                                                         # Print tree in normal post-order.
 {my ($tree, $print) = @_;                                                      # Tree, optional print method
  printTree($tree, $print, 0, 0);
 }

sub printReversePreOrder($;$)                                                   # Print tree in reverse pre-order
 {my ($tree, $print) = @_;                                                      # Tree, optional print method
  printTree($tree, $print, 1, 1);
 }

sub printReversePostOrder($;$)                                                  # Print tree in reverse post-order
 {my ($tree, $print) = @_;                                                      # Tree, optional print method
  printTree($tree, $print, 0, 1);
 }

sub print($;$)                                                                  # Print tree in normal pre-order.
 {my ($tree, $print) = @_;                                                      # Tree, optional print method
  &printPreOrder(@_);
 }

sub brackets($;$$)                                                              # Bracketed string representation of a tree.
 {my ($tree, $print, $separator) = @_;                                          # Tree, optional print method, optional child separator
  my $t = $separator // '';                                                     # Default child separator
  sub                                                                           # Print a child
   {my ($child) = @_;                                                           # Child
    my $key = $child->key;                                                      # Key
    my $p = $print ? &$print($key) : $key;                                      # Printed child
    my $c = $child->children;                                                   # Children of child
    return $p unless @$c;                                                       # Return child immediately if no children to format
    join '', $p, '(', join($t, map {__SUB__->($_)} @$c), ')'                    # String representation
   }->($tree)                                                                   # Print root
 }

sub xml($;$)                                                                    # Print a tree as as xml.
 {my ($tree, $print) = @_;                                                      # Tree, optional print method
  sub                                                                           # Print a child
   {my ($child) = @_;                                                           # Child
    my $key = $child->key;                                                      # Key
    my $p = $print ? &$print($key) : $key;                                      # Printed child
    my $c = $child->children;                                                   # Children of child
    return "<$p/>" unless @$c;                                                  # Singleton
    join '', "<$p>", (map {__SUB__->($_)} @$c), "</$p>"                         # String representation
   }->($tree)                                                                   # Print root
 }

#D1 Data Structures                                                             # Data structures use by this package.

#D0
#-------------------------------------------------------------------------------
# Export
#-------------------------------------------------------------------------------

use Exporter qw(import);

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

@ISA          = qw(Exporter);
@EXPORT_OK    = qw(
);
%EXPORT_TAGS  = (all=>[@EXPORT, @EXPORT_OK]);

# podDocumentation

=pod

=encoding utf-8

=head1 Name

Tree::Ops - Tree operations.

=head1 Synopsis

Create a tree:

  my $a = Tree::Ops::new 'a', 'A';

  for(1..2)
   {$a->open  ('b', "B$_");
    $a->single('c', "C$_");
    $a->close;
   }
  $a->single  ('d', 'D');
  $a->single  ('e', 'E');

Print it:

  is_deeply $a->print, <<END;
Key    Value
a      A
  b    B1
    c  C1
  b    B2
    c  C2
  d    D
  e    E
END

Navigate through the tree:

  is_deeply $a->lastMost->prev->prev->first->key,           'c';
  is_deeply $a->first->next->last->parent->first->value,    'C2';

Traverse the tree:

  is_deeply [map{$_->value} $a->by], [qw(C1 B1 C2 B2 D E A)];

Select items from the tree:

  is_deeply [map{$_->value} $a->select('b')],               [qw(B1 B2)];
  is_deeply [map{$_->value} $a->select(qr(b|c))],           [qw(B1 C1 B2 C2)];
  is_deeply [map{$_->value} $a->select(sub{$_[0] eq 'd'})], [qw(D)];

Reorganize the tree:

  $a->first->next->stepEnd->stepEnd->first->next->stepBack;
  is_deeply $a->print, <<END;
Key      Value
a        A
  b      B1
    c    C1
  b      B2
    d    D
      c  C2
    e    E
END

=head1 Description

Tree operations.


Version 20201030.


The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.



=head1 Build

Create a tree.  There is no implicit ordering applied to the tree, the relationships between parents and children within the tree are as established by the user and can be reorganized at will using the methods in this module.

=head2 new($key, $value)

Create a new child optionally recording the specified key or value.

     Parameter  Description
  1  $key       Key
  2  $value     Value

B<Example:>


  
    my $a = Tree::Ops::new 'a', 'A';  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    for(1..2)
     {$a->open  ('b', "B$_");
      $a->single('c', "C$_");
      ok $a->activeScope->key eq 'b';
      $a->close;
     }
    $a->single  ('d', 'D');
    $a->single  ('e', 'E');
    is_deeply $a->print, <<END;
  Key    Value
  a      A
    b    B1
      c  C1
    b    B2
      c  C2
    d    D
    e    E
  END
  
    is_deeply [map{$_->value} $a->by], [qw(C1 B1 C2 B2 D E A)];
  
    is_deeply $a->lastMost->prev->prev->first->key,           'c';
    is_deeply $a->first->next->last->parent->first->value,    'C2';
  
    is_deeply [map{$_->value} $a->select('b')],               [qw(B1 B2)];
    is_deeply [map{$_->value} $a->select(qr(b|c))],           [qw(B1 C1 B2 C2)];
    is_deeply [map{$_->value} $a->select(sub{$_[0] eq 'd'})], [qw(D)];
  
    $a->first->next->stepEnd->stepEnd->first->next->stepBack;
    is_deeply $a->print, <<END;
  Key      Value
  a        A
    b      B1
      c    C1
    b      B2
      d    D
        c  C2
      e    E
  END
  

This is a static method and so should either be imported or invoked as:

  Tree::Ops::new


=head2 activeScope($tree)

Locate the active scope in a tree.

     Parameter  Description
  1  $tree      Tree

B<Example:>


    my $a = Tree::Ops::new 'a', 'A';
    for(1..2)
     {$a->open  ('b', "B$_");
      $a->single('c', "C$_");
  
      ok $a->activeScope->key eq 'b';  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      $a->close;
     }
    $a->single  ('d', 'D');
    $a->single  ('e', 'E');
    is_deeply $a->print, <<END;
  Key    Value
  a      A
    b    B1
      c  C1
    b    B2
      c  C2
    d    D
    e    E
  END
  
    is_deeply [map{$_->value} $a->by], [qw(C1 B1 C2 B2 D E A)];
  
    is_deeply $a->lastMost->prev->prev->first->key,           'c';
    is_deeply $a->first->next->last->parent->first->value,    'C2';
  
    is_deeply [map{$_->value} $a->select('b')],               [qw(B1 B2)];
    is_deeply [map{$_->value} $a->select(qr(b|c))],           [qw(B1 C1 B2 C2)];
    is_deeply [map{$_->value} $a->select(sub{$_[0] eq 'd'})], [qw(D)];
  
    $a->first->next->stepEnd->stepEnd->first->next->stepBack;
    is_deeply $a->print, <<END;
  Key      Value
  a        A
    b      B1
      c    C1
    b      B2
      d    D
        c  C2
      e    E
  END
  

=head2 open($tree, $key, $value)

Add a child and make it the currently active scope into which new children will be added.

     Parameter  Description
  1  $tree      Tree
  2  $key       Key
  3  $value     Value to be recorded in the interior child being opened

B<Example:>


    my $a = Tree::Ops::new 'a', 'A';
    for(1..2)
  
     {$a->open  ('b', "B$_");  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      $a->single('c', "C$_");
      ok $a->activeScope->key eq 'b';
      $a->close;
     }
    $a->single  ('d', 'D');
    $a->single  ('e', 'E');
    is_deeply $a->print, <<END;
  Key    Value
  a      A
    b    B1
      c  C1
    b    B2
      c  C2
    d    D
    e    E
  END
  
    is_deeply [map{$_->value} $a->by], [qw(C1 B1 C2 B2 D E A)];
  
    is_deeply $a->lastMost->prev->prev->first->key,           'c';
    is_deeply $a->first->next->last->parent->first->value,    'C2';
  
    is_deeply [map{$_->value} $a->select('b')],               [qw(B1 B2)];
    is_deeply [map{$_->value} $a->select(qr(b|c))],           [qw(B1 C1 B2 C2)];
    is_deeply [map{$_->value} $a->select(sub{$_[0] eq 'd'})], [qw(D)];
  
    $a->first->next->stepEnd->stepEnd->first->next->stepBack;
    is_deeply $a->print, <<END;
  Key      Value
  a        A
    b      B1
      c    C1
    b      B2
      d    D
        c  C2
      e    E
  END
  

=head2 close($tree)

Close the current scope returning to the previous scope.

     Parameter  Description
  1  $tree      Tree

B<Example:>


    my $a = Tree::Ops::new 'a', 'A';
    for(1..2)
     {$a->open  ('b', "B$_");
      $a->single('c', "C$_");
      ok $a->activeScope->key eq 'b';
  
      $a->close;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     }
    $a->single  ('d', 'D');
    $a->single  ('e', 'E');
    is_deeply $a->print, <<END;
  Key    Value
  a      A
    b    B1
      c  C1
    b    B2
      c  C2
    d    D
    e    E
  END
  
    is_deeply [map{$_->value} $a->by], [qw(C1 B1 C2 B2 D E A)];
  
    is_deeply $a->lastMost->prev->prev->first->key,           'c';
    is_deeply $a->first->next->last->parent->first->value,    'C2';
  
    is_deeply [map{$_->value} $a->select('b')],               [qw(B1 B2)];
    is_deeply [map{$_->value} $a->select(qr(b|c))],           [qw(B1 C1 B2 C2)];
    is_deeply [map{$_->value} $a->select(sub{$_[0] eq 'd'})], [qw(D)];
  
    $a->first->next->stepEnd->stepEnd->first->next->stepBack;
    is_deeply $a->print, <<END;
  Key      Value
  a        A
    b      B1
      c    C1
    b      B2
      d    D
        c  C2
      e    E
  END
  

=head2 single($tree, $key, $value)

Add one child in the current scope.

     Parameter  Description
  1  $tree      Tree
  2  $key       Key
  3  $value     Value to be recorded in the child being created

B<Example:>


    my $a = Tree::Ops::new 'a', 'A';
    for(1..2)
     {$a->open  ('b', "B$_");
  
      $a->single('c', "C$_");  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ok $a->activeScope->key eq 'b';
      $a->close;
     }
  
    $a->single  ('d', 'D');  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    $a->single  ('e', 'E');  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply $a->print, <<END;
  Key    Value
  a      A
    b    B1
      c  C1
    b    B2
      c  C2
    d    D
    e    E
  END
  
    is_deeply [map{$_->value} $a->by], [qw(C1 B1 C2 B2 D E A)];
  
    is_deeply $a->lastMost->prev->prev->first->key,           'c';
    is_deeply $a->first->next->last->parent->first->value,    'C2';
  
    is_deeply [map{$_->value} $a->select('b')],               [qw(B1 B2)];
    is_deeply [map{$_->value} $a->select(qr(b|c))],           [qw(B1 C1 B2 C2)];
    is_deeply [map{$_->value} $a->select(sub{$_[0] eq 'd'})], [qw(D)];
  
    $a->first->next->stepEnd->stepEnd->first->next->stepBack;
    is_deeply $a->print, <<END;
  Key      Value
  a        A
    b      B1
      c    C1
    b      B2
      d    D
        c  C2
      e    E
  END
  

=head2 include($tree, $include)

Include the specified tree in the currently open scope.

     Parameter  Description
  1  $tree      Tree being built
  2  $include   Tree to include

B<Example:>


    my ($i) = fromLetters 'b(cd)';
  
    my $a = Tree::Ops::new 'A';
       $a->open ('B');
  
       $a->include($i);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       $a->close;
  
    is_deeply $a->print, <<END;
  Key        Value
  A
    B
      a
        b
          c
          d
  END
  

=head2 fromLetters($letters)

Create a tree from a string of letters returning the children created in alphabetic order  - useful for testing.

     Parameter  Description
  1  $letters   String of letters and ( ).

B<Example:>


  
    my ($a) = fromLetters(q(bc(d)e));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    is_deeply $a->print, <<END;
  Key    Value
  a
    b
    c
      d
    e
  END
  

=head1 Navigation

Navigate through a tree.

=head2 first($parent)

Get the first child under the specified parent.

     Parameter  Description
  1  $parent    Parent

B<Example:>


    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j) = fromLetters 'b(c)d(efgh(i(j)))';
    is_deeply $c->parent,   $b;
  
    is_deeply $a->first,    $b;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply $a->last,     $d;
    is_deeply $e->next,     $f;
    is_deeply $f->prev,     $e;
  

=head2 last($parent)

Get the last child under the specified parent.

     Parameter  Description
  1  $parent    Parent

B<Example:>


    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j) = fromLetters 'b(c)d(efgh(i(j)))';
    is_deeply $c->parent,   $b;
    is_deeply $a->first,    $b;
  
    is_deeply $a->last,     $d;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply $e->next,     $f;
    is_deeply $f->prev,     $e;
  

=head2 next($child)

Get the next sibling following the specified child.

     Parameter  Description
  1  $child     Child

B<Example:>


    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j) = fromLetters 'b(c)d(efgh(i(j)))';
    is_deeply $c->parent,   $b;
    is_deeply $a->first,    $b;
    is_deeply $a->last,     $d;
  
    is_deeply $e->next,     $f;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply $f->prev,     $e;
  

=head2 prev($child)

Get the previous sibling of the specified child.

     Parameter  Description
  1  $child     Child

B<Example:>


    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j) = fromLetters 'b(c)d(efgh(i(j)))';
    is_deeply $c->parent,   $b;
    is_deeply $a->first,    $b;
    is_deeply $a->last,     $d;
    is_deeply $e->next,     $f;
  
    is_deeply $f->prev,     $e;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  

=head2 firstMost($parent)

Return the first most descendant child in the tree starting at this parent or else return B<undef> if this parent has no children.

     Parameter  Description
  1  $parent    Parent

B<Example:>


    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j, $x, $y) =
      fromLetters 'b(c)y(x)d(efgh(i(j)))';
  
    is_deeply $a->print, <<END;
  Key        Value
  a
    b
      c
    y
      x
    d
      e
      f
      g
      h
        i
          j
  END
  
    is_deeply $a->xml,
     '<a><b><c/></b><y><x/></y><d><e/><f/><g/><h><i><j/></i></h></d></a>';
  
    is_deeply [$c, $x, $e, $f, $g, $j], [$a->leaves];
    is_deeply [$a, $b, $y, $d, $h, $i], [$a->parentsPreOrder];
    is_deeply [$b, $y, $i, $h, $d, $a], [$a->parentsPostOrder];
    is_deeply [$a->parents],            [$a->parentsPostOrder];
  
    is_deeply [$a, $d, $h, $i, $y, $b], [$a->parentsReversePreOrder];
    is_deeply [$i, $h, $d, $y, $b, $a], [$a->parentsReversePostOrder];
  
    ok !$j->parents;
  
    ok  $a->lastMost  == $j;
    ok !$a->prevMost;
    ok  $j->prevMost  == $g;
    ok  $i->prevMost  == $g;
    ok  $h->prevMost  == $g;
    ok  $g->prevMost  == $f;
    ok  $f->prevMost  == $e;
    ok  $e->prevMost  == $x;
    ok  $d->prevMost  == $x;
    ok  $x->prevMost  == $c;
    ok  $y->prevMost  == $c;
    ok !$c->prevMost;
    ok !$b->prevMost;
    ok !$a->prevMost;
  
  
    ok  $a->firstMost == $c;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    ok  $a->nextMost  == $c;
    ok  $b->nextMost  == $c;
    ok  $c->nextMost  == $x;
    ok  $y->nextMost  == $x;
    ok  $x->nextMost  == $e;
    ok  $d->nextMost  == $e;
    ok  $e->nextMost  == $f;
    ok  $f->nextMost  == $g;
    ok  $g->nextMost  == $j;
    ok  $h->nextMost  == $j;
    ok  $i->nextMost  == $j;
    ok !$j->nextMost;
  
    ok  $i->topMost   == $a;
  

=head2 nextMost($child)

Return the next child with no children, i.e. the next leaf of the tree, else return B<undef> if there is no such child.

     Parameter  Description
  1  $child     Current leaf

B<Example:>


    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j, $x, $y) =
      fromLetters 'b(c)y(x)d(efgh(i(j)))';
  
    is_deeply $a->print, <<END;
  Key        Value
  a
    b
      c
    y
      x
    d
      e
      f
      g
      h
        i
          j
  END
  
    is_deeply $a->xml,
     '<a><b><c/></b><y><x/></y><d><e/><f/><g/><h><i><j/></i></h></d></a>';
  
    is_deeply [$c, $x, $e, $f, $g, $j], [$a->leaves];
    is_deeply [$a, $b, $y, $d, $h, $i], [$a->parentsPreOrder];
    is_deeply [$b, $y, $i, $h, $d, $a], [$a->parentsPostOrder];
    is_deeply [$a->parents],            [$a->parentsPostOrder];
  
    is_deeply [$a, $d, $h, $i, $y, $b], [$a->parentsReversePreOrder];
    is_deeply [$i, $h, $d, $y, $b, $a], [$a->parentsReversePostOrder];
  
    ok !$j->parents;
  
    ok  $a->lastMost  == $j;
    ok !$a->prevMost;
    ok  $j->prevMost  == $g;
    ok  $i->prevMost  == $g;
    ok  $h->prevMost  == $g;
    ok  $g->prevMost  == $f;
    ok  $f->prevMost  == $e;
    ok  $e->prevMost  == $x;
    ok  $d->prevMost  == $x;
    ok  $x->prevMost  == $c;
    ok  $y->prevMost  == $c;
    ok !$c->prevMost;
    ok !$b->prevMost;
    ok !$a->prevMost;
  
    ok  $a->firstMost == $c;
  
    ok  $a->nextMost  == $c;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok  $b->nextMost  == $c;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok  $c->nextMost  == $x;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok  $y->nextMost  == $x;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok  $x->nextMost  == $e;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok  $d->nextMost  == $e;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok  $e->nextMost  == $f;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok  $f->nextMost  == $g;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok  $g->nextMost  == $j;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok  $h->nextMost  == $j;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok  $i->nextMost  == $j;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok !$j->nextMost;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok  $i->topMost   == $a;
  

=head2 prevMost($child)

Return the previous child with no children, i.e. the previous leaf of the tree, else return B<undef> if there is no such child.

     Parameter  Description
  1  $child     Current leaf

B<Example:>


    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j, $x, $y) =
      fromLetters 'b(c)y(x)d(efgh(i(j)))';
  
    is_deeply $a->print, <<END;
  Key        Value
  a
    b
      c
    y
      x
    d
      e
      f
      g
      h
        i
          j
  END
  
    is_deeply $a->xml,
     '<a><b><c/></b><y><x/></y><d><e/><f/><g/><h><i><j/></i></h></d></a>';
  
    is_deeply [$c, $x, $e, $f, $g, $j], [$a->leaves];
    is_deeply [$a, $b, $y, $d, $h, $i], [$a->parentsPreOrder];
    is_deeply [$b, $y, $i, $h, $d, $a], [$a->parentsPostOrder];
    is_deeply [$a->parents],            [$a->parentsPostOrder];
  
    is_deeply [$a, $d, $h, $i, $y, $b], [$a->parentsReversePreOrder];
    is_deeply [$i, $h, $d, $y, $b, $a], [$a->parentsReversePostOrder];
  
    ok !$j->parents;
  
    ok  $a->lastMost  == $j;
  
    ok !$a->prevMost;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok  $j->prevMost  == $g;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok  $i->prevMost  == $g;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok  $h->prevMost  == $g;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok  $g->prevMost  == $f;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok  $f->prevMost  == $e;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok  $e->prevMost  == $x;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok  $d->prevMost  == $x;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok  $x->prevMost  == $c;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok  $y->prevMost  == $c;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok !$c->prevMost;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok !$b->prevMost;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok !$a->prevMost;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok  $a->firstMost == $c;
    ok  $a->nextMost  == $c;
    ok  $b->nextMost  == $c;
    ok  $c->nextMost  == $x;
    ok  $y->nextMost  == $x;
    ok  $x->nextMost  == $e;
    ok  $d->nextMost  == $e;
    ok  $e->nextMost  == $f;
    ok  $f->nextMost  == $g;
    ok  $g->nextMost  == $j;
    ok  $h->nextMost  == $j;
    ok  $i->nextMost  == $j;
    ok !$j->nextMost;
  
    ok  $i->topMost   == $a;
  

=head2 lastMost($parent)

Return the last most descendant child in the tree starting at this parent or else return B<undef> if this parent has no children.

     Parameter  Description
  1  $parent    Parent

B<Example:>


    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j, $x, $y) =
      fromLetters 'b(c)y(x)d(efgh(i(j)))';
  
    is_deeply $a->print, <<END;
  Key        Value
  a
    b
      c
    y
      x
    d
      e
      f
      g
      h
        i
          j
  END
  
    is_deeply $a->xml,
     '<a><b><c/></b><y><x/></y><d><e/><f/><g/><h><i><j/></i></h></d></a>';
  
    is_deeply [$c, $x, $e, $f, $g, $j], [$a->leaves];
    is_deeply [$a, $b, $y, $d, $h, $i], [$a->parentsPreOrder];
    is_deeply [$b, $y, $i, $h, $d, $a], [$a->parentsPostOrder];
    is_deeply [$a->parents],            [$a->parentsPostOrder];
  
    is_deeply [$a, $d, $h, $i, $y, $b], [$a->parentsReversePreOrder];
    is_deeply [$i, $h, $d, $y, $b, $a], [$a->parentsReversePostOrder];
  
    ok !$j->parents;
  
  
    ok  $a->lastMost  == $j;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    ok !$a->prevMost;
    ok  $j->prevMost  == $g;
    ok  $i->prevMost  == $g;
    ok  $h->prevMost  == $g;
    ok  $g->prevMost  == $f;
    ok  $f->prevMost  == $e;
    ok  $e->prevMost  == $x;
    ok  $d->prevMost  == $x;
    ok  $x->prevMost  == $c;
    ok  $y->prevMost  == $c;
    ok !$c->prevMost;
    ok !$b->prevMost;
    ok !$a->prevMost;
  
    ok  $a->firstMost == $c;
    ok  $a->nextMost  == $c;
    ok  $b->nextMost  == $c;
    ok  $c->nextMost  == $x;
    ok  $y->nextMost  == $x;
    ok  $x->nextMost  == $e;
    ok  $d->nextMost  == $e;
    ok  $e->nextMost  == $f;
    ok  $f->nextMost  == $g;
    ok  $g->nextMost  == $j;
    ok  $h->nextMost  == $j;
    ok  $i->nextMost  == $j;
    ok !$j->nextMost;
  
    ok  $i->topMost   == $a;
  

=head2 topMost($child)

Return the top most parent in the tree containing the specified child.

     Parameter  Description
  1  $child     Child

B<Example:>


    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j, $x, $y) =
      fromLetters 'b(c)y(x)d(efgh(i(j)))';
  
    is_deeply $a->print, <<END;
  Key        Value
  a
    b
      c
    y
      x
    d
      e
      f
      g
      h
        i
          j
  END
  
    is_deeply $a->xml,
     '<a><b><c/></b><y><x/></y><d><e/><f/><g/><h><i><j/></i></h></d></a>';
  
    is_deeply [$c, $x, $e, $f, $g, $j], [$a->leaves];
    is_deeply [$a, $b, $y, $d, $h, $i], [$a->parentsPreOrder];
    is_deeply [$b, $y, $i, $h, $d, $a], [$a->parentsPostOrder];
    is_deeply [$a->parents],            [$a->parentsPostOrder];
  
    is_deeply [$a, $d, $h, $i, $y, $b], [$a->parentsReversePreOrder];
    is_deeply [$i, $h, $d, $y, $b, $a], [$a->parentsReversePostOrder];
  
    ok !$j->parents;
  
    ok  $a->lastMost  == $j;
    ok !$a->prevMost;
    ok  $j->prevMost  == $g;
    ok  $i->prevMost  == $g;
    ok  $h->prevMost  == $g;
    ok  $g->prevMost  == $f;
    ok  $f->prevMost  == $e;
    ok  $e->prevMost  == $x;
    ok  $d->prevMost  == $x;
    ok  $x->prevMost  == $c;
    ok  $y->prevMost  == $c;
    ok !$c->prevMost;
    ok !$b->prevMost;
    ok !$a->prevMost;
  
    ok  $a->firstMost == $c;
    ok  $a->nextMost  == $c;
    ok  $b->nextMost  == $c;
    ok  $c->nextMost  == $x;
    ok  $y->nextMost  == $x;
    ok  $x->nextMost  == $e;
    ok  $d->nextMost  == $e;
    ok  $e->nextMost  == $f;
    ok  $f->nextMost  == $g;
    ok  $g->nextMost  == $j;
    ok  $h->nextMost  == $j;
    ok  $i->nextMost  == $j;
    ok !$j->nextMost;
  
  
    ok  $i->topMost   == $a;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  

=head2 mostRecentCommonAncestor($first, $second)

Find the most recent common ancestor of the specified children.

     Parameter  Description
  1  $first     First child
  2  $second    Second child

B<Example:>


    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j, $k) =
      fromLetters 'b(c(d(e))f(g(h)i)j)k';
  
    is_deeply $a->print, <<END;
  Key        Value
  a
    b
      c
        d
          e
      f
        g
          h
        i
      j
    k
  END
  
  
    ok $e->mostRecentCommonAncestor($h) == $b;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok $e->mostRecentCommonAncestor($k) == $a;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  

=head2 go($parent, @path)

Return the child at the end of the path starting at the specified parent. A path is a list of zero based children numbers. Return B<undef> if the path is not valid.

     Parameter  Description
  1  $parent    Parent
  2  @path      List of zero based children numbers

B<Example:>


    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j) = fromLetters 'b(cd(e(fg)h)i)j';
  
    is_deeply $a->print, <<END;
  Key        Value
  a
    b
      c
      d
        e
          f
          g
        h
      i
    j
  END
  
  
    ok $a->go(0,1,0,1) == $g;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok $d->go(0,0)     == $f;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    is_deeply [$e->path],         [0,1,0];
    is_deeply [$g->pathFrom($d)], [0,1];
  
    is_deeply $b->dup->print, <<END;
  Key      Value
  b
    c
    d
      e
        f
        g
      h
    i
  END
  
    my $B = $b->transcribe;
  
    $b->by(sub
     {my ($c) = @_;
      my @path = $c->pathFrom($b);
  
      my $C = $B->go(@path);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      is_deeply $c->key, $C->key;
      is_deeply $c->{transcribedTo},   $C;
      is_deeply $C->{transcribedFrom}, $c;
     });
  
    is_deeply $B->print, <<END;
  Key      Value
  b
    c
    d
      e
        f
        g
      h
    i
  END
  

=head1 Location

Verify the current location.

=head2 context($child)

Get the context of the current child.

     Parameter  Description
  1  $child     Child

B<Example:>


    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j, $s, $t, $x, $y, $z) =
      fromLetters 'b(c)y(x)z(st)d(efgh(i(j))))';
  
  
    is_deeply [$x->context], [$x, $y, $a];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    is_deeply join(' ', $a->by(sub{$_[0]->key})), "c b x y s t z e f g j i h d a";
    is_deeply join(' ', map{$_->key} $a->by),     "c b x y s t z e f g j i h d a";
  
    is_deeply $a->print, <<END;
  Key        Value
  a
    b
      c
    y
      x
    z
      s
      t
    d
      e
      f
      g
      h
        i
          j
  END
  
    $z->cut;
    is_deeply $a->print, <<END;
  Key        Value
  a
    b
      c
    y
      x
    d
      e
      f
      g
      h
        i
          j
  END
  

=head2 isFirst($child)

Return the specified child if that child is first under its parent, else return B<undef>.

     Parameter  Description
  1  $child     Child

B<Example:>


    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j) = fromLetters 'b(c)d(efgh(i(j)))';
  
    is_deeply $a->print, <<END;
  Key        Value
  a
    b
      c
    d
      e
      f
      g
      h
        i
          j
  END
  
    is_deeply $b->singleChildOfParent, $c;
  
    is_deeply $e->isFirst, $e;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok !$f->isFirst;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    ok !$g->isLast;
    is_deeply $h->isLast, $h;
    ok  $j->empty;
    ok !$i->empty;
    ok  $a->isTop;
    ok !$b->isTop;
  

=head2 isLast($child)

Return the specified child if that child is last under its parent, else return B<undef>.

     Parameter  Description
  1  $child     Child

B<Example:>


    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j) = fromLetters 'b(c)d(efgh(i(j)))';
  
    is_deeply $a->print, <<END;
  Key        Value
  a
    b
      c
    d
      e
      f
      g
      h
        i
          j
  END
  
    is_deeply $b->singleChildOfParent, $c;
    is_deeply $e->isFirst, $e;
    ok !$f->isFirst;
  
    ok !$g->isLast;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    is_deeply $h->isLast, $h;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    ok  $j->empty;
    ok !$i->empty;
    ok  $a->isTop;
    ok !$b->isTop;
  

=head2 isTop($parent)

Return the specified parent if that parent is the top most parent in the tree.

     Parameter  Description
  1  $parent    Parent

B<Example:>


    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j) = fromLetters 'b(c)d(efgh(i(j)))';
  
    is_deeply $a->print, <<END;
  Key        Value
  a
    b
      c
    d
      e
      f
      g
      h
        i
          j
  END
  
    is_deeply $b->singleChildOfParent, $c;
    is_deeply $e->isFirst, $e;
    ok !$f->isFirst;
    ok !$g->isLast;
    is_deeply $h->isLast, $h;
    ok  $j->empty;
    ok !$i->empty;
  
    ok  $a->isTop;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok !$b->isTop;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  

=head2 singleChildOfParent($parent)

Return the only child of this parent if the parent has an only child, else B<undef>

     Parameter  Description
  1  $parent    Parent

B<Example:>


    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j) = fromLetters 'b(c)d(efgh(i(j)))';
  
    is_deeply $a->print, <<END;
  Key        Value
  a
    b
      c
    d
      e
      f
      g
      h
        i
          j
  END
  
  
    is_deeply $b->singleChildOfParent, $c;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply $e->isFirst, $e;
    ok !$f->isFirst;
    ok !$g->isLast;
    is_deeply $h->isLast, $h;
    ok  $j->empty;
    ok !$i->empty;
    ok  $a->isTop;
    ok !$b->isTop;
  

=head2 empty($parent)

Return the specified parent if it has no children else B<undef>

     Parameter  Description
  1  $parent    Parent

B<Example:>


    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j) = fromLetters 'b(c)d(efgh(i(j)))';
  
    is_deeply $a->print, <<END;
  Key        Value
  a
    b
      c
    d
      e
      f
      g
      h
        i
          j
  END
  
    is_deeply $b->singleChildOfParent, $c;
    is_deeply $e->isFirst, $e;
    ok !$f->isFirst;
    ok !$g->isLast;
    is_deeply $h->isLast, $h;
  
    ok  $j->empty;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok !$i->empty;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    ok  $a->isTop;
    ok !$b->isTop;
  

=head1 Put

Insert children into a tree.

=head2 putFirst($parent, $child)

Place a new child first under the specified parent and return the child.

     Parameter  Description
  1  $parent    Parent
  2  $child     Child

B<Example:>


    my ($a, $b, $c, $d, $e) = fromLetters 'b(c)d(e)';
  
    is_deeply $a->print, <<END;
  Key    Value
  a
    b
      c
    d
      e
  END
  
    my $z = $b->putNext(new 'z');
    is_deeply $a->print, <<END;
  Key    Value
  a
    b
      c
    z
    d
      e
  END
  
    my $y = $d->putPrev(new 'y');
    is_deeply $a->print, <<END;
  Key    Value
  a
    b
      c
    z
    y
    d
      e
  END
  
    $z->putLast(new 't');
    is_deeply $a->print, <<END;
  Key    Value
  a
    b
      c
    z
      t
    y
    d
      e
  END
  
  
    $z->putFirst(new 's');  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply $a->print, <<END;
  Key    Value
  a
    b
      c
    z
      s
      t
    y
    d
      e
  END
  

=head2 putLast($parent, $child)

Place a new child last under the specified parent and return the child.

     Parameter  Description
  1  $parent    Parent
  2  $child     Child

B<Example:>


    my ($a, $b, $c, $d, $e) = fromLetters 'b(c)d(e)';
  
    is_deeply $a->print, <<END;
  Key    Value
  a
    b
      c
    d
      e
  END
  
    my $z = $b->putNext(new 'z');
    is_deeply $a->print, <<END;
  Key    Value
  a
    b
      c
    z
    d
      e
  END
  
    my $y = $d->putPrev(new 'y');
    is_deeply $a->print, <<END;
  Key    Value
  a
    b
      c
    z
    y
    d
      e
  END
  
  
    $z->putLast(new 't');  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply $a->print, <<END;
  Key    Value
  a
    b
      c
    z
      t
    y
    d
      e
  END
  
    $z->putFirst(new 's');
    is_deeply $a->print, <<END;
  Key    Value
  a
    b
      c
    z
      s
      t
    y
    d
      e
  END
  

=head2 putNext($child, $new)

Place a new child after the specified child.

     Parameter  Description
  1  $child     Existing child
  2  $new       New child

B<Example:>


    my ($a, $b, $c, $d, $e) = fromLetters 'b(c)d(e)';
  
    is_deeply $a->print, <<END;
  Key    Value
  a
    b
      c
    d
      e
  END
  
  
    my $z = $b->putNext(new 'z');  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply $a->print, <<END;
  Key    Value
  a
    b
      c
    z
    d
      e
  END
  
    my $y = $d->putPrev(new 'y');
    is_deeply $a->print, <<END;
  Key    Value
  a
    b
      c
    z
    y
    d
      e
  END
  
    $z->putLast(new 't');
    is_deeply $a->print, <<END;
  Key    Value
  a
    b
      c
    z
      t
    y
    d
      e
  END
  
    $z->putFirst(new 's');
    is_deeply $a->print, <<END;
  Key    Value
  a
    b
      c
    z
      s
      t
    y
    d
      e
  END
  

=head2 putPrev($child, $new)

Place a new child before the specified child.

     Parameter  Description
  1  $child     Child
  2  $new       New child

B<Example:>


    my ($a, $b, $c, $d, $e) = fromLetters 'b(c)d(e)';
  
    is_deeply $a->print, <<END;
  Key    Value
  a
    b
      c
    d
      e
  END
  
    my $z = $b->putNext(new 'z');
    is_deeply $a->print, <<END;
  Key    Value
  a
    b
      c
    z
    d
      e
  END
  
  
    my $y = $d->putPrev(new 'y');  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply $a->print, <<END;
  Key    Value
  a
    b
      c
    z
    y
    d
      e
  END
  
    $z->putLast(new 't');
    is_deeply $a->print, <<END;
  Key    Value
  a
    b
      c
    z
      t
    y
    d
      e
  END
  
    $z->putFirst(new 's');
    is_deeply $a->print, <<END;
  Key    Value
  a
    b
      c
    z
      s
      t
    y
    d
      e
  END
  

=head1 Steps

Move the start or end of a scope forwards or backwards as suggested by Alex Monroe.

=head2 step($parent)

Make the first child of the specified parent the parents previous sibling and return the parent. In effect this moves the start of the parent one step forwards.

     Parameter  Description
  1  $parent    Parent

B<Example:>


    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j) = fromLetters 'b(c)d(efgh(i(j)))';
  
    is_deeply $a->brackets, 'a(b(c)d(efgh(i(j))))';
  
  
    $d->step;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply $a->brackets, 'a(b(c)ed(fgh(i(j))))';
  
    $d->stepBack;
    is_deeply $a->brackets, 'a(b(c)d(efgh(i(j))))';
  
    $b->stepEnd;
    is_deeply $a->brackets, 'a(b(cd(efgh(i(j)))))';
  
    $b->stepEndBack;
    is_deeply $a->brackets, 'a(b(c)d(efgh(i(j))))';
  

=head2 stepEnd($parent)

Make the next sibling of the specified parent the parents last child and return the parent. In effect this moves the end of the parent one step forwards.

     Parameter  Description
  1  $parent    Parent

B<Example:>


    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j) = fromLetters 'b(c)d(efgh(i(j)))';
  
    is_deeply $a->brackets, 'a(b(c)d(efgh(i(j))))';
  
    $d->step;
    is_deeply $a->brackets, 'a(b(c)ed(fgh(i(j))))';
  
    $d->stepBack;
    is_deeply $a->brackets, 'a(b(c)d(efgh(i(j))))';
  
  
    $b->stepEnd;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply $a->brackets, 'a(b(cd(efgh(i(j)))))';
  
    $b->stepEndBack;
    is_deeply $a->brackets, 'a(b(c)d(efgh(i(j))))';
  

=head2 stepBack()

Make the previous sibling of the specified parent the parents first child and return the parent. In effect this moves the start of the parent one step backwards.


B<Example:>


    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j) = fromLetters 'b(c)d(efgh(i(j)))';
  
    is_deeply $a->brackets, 'a(b(c)d(efgh(i(j))))';
  
    $d->step;
    is_deeply $a->brackets, 'a(b(c)ed(fgh(i(j))))';
  
  
    $d->stepBack;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply $a->brackets, 'a(b(c)d(efgh(i(j))))';
  
    $b->stepEnd;
    is_deeply $a->brackets, 'a(b(cd(efgh(i(j)))))';
  
    $b->stepEndBack;
    is_deeply $a->brackets, 'a(b(c)d(efgh(i(j))))';
  

=head2 stepEndBack()

Make the last child of the specified parent the parents next sibling and return the parent. In effect this moves the end of the parent one step backwards.


B<Example:>


    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j) = fromLetters 'b(c)d(efgh(i(j)))';
  
    is_deeply $a->brackets, 'a(b(c)d(efgh(i(j))))';
  
    $d->step;
    is_deeply $a->brackets, 'a(b(c)ed(fgh(i(j))))';
  
    $d->stepBack;
    is_deeply $a->brackets, 'a(b(c)d(efgh(i(j))))';
  
    $b->stepEnd;
    is_deeply $a->brackets, 'a(b(cd(efgh(i(j)))))';
  
  
    $b->stepEndBack;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply $a->brackets, 'a(b(c)d(efgh(i(j))))';
  

=head1 Edit

Edit a tree in situ.

=head2 cut($child)

Cut out a child and all its content and children, return it ready for reinsertion else where.

     Parameter  Description
  1  $child     Child

B<Example:>


    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j, $s, $t, $x, $y, $z) =
      fromLetters 'b(c)y(x)z(st)d(efgh(i(j))))';
  
    is_deeply [$x->context], [$x, $y, $a];
  
    is_deeply join(' ', $a->by(sub{$_[0]->key})), "c b x y s t z e f g j i h d a";
    is_deeply join(' ', map{$_->key} $a->by),     "c b x y s t z e f g j i h d a";
  
    is_deeply $a->print, <<END;
  Key        Value
  a
    b
      c
    y
      x
    z
      s
      t
    d
      e
      f
      g
      h
        i
          j
  END
  
  
    $z->cut;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply $a->print, <<END;
  Key        Value
  a
    b
      c
    y
      x
    d
      e
      f
      g
      h
        i
          j
  END
  

=head2 dup($parent)

Duplicate a specified parent and all its descendants returning the root of the resulting tree.

     Parameter  Description
  1  $parent    Parent

B<Example:>


    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j) = fromLetters 'b(cd(e(fg)h)i)j';
  
    is_deeply $a->print, <<END;
  Key        Value
  a
    b
      c
      d
        e
          f
          g
        h
      i
    j
  END
  
    ok $a->go(0,1,0,1) == $g;
    ok $d->go(0,0)     == $f;
  
    is_deeply [$e->path],         [0,1,0];
    is_deeply [$g->pathFrom($d)], [0,1];
  
  
    is_deeply $b->dup->print, <<END;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  Key      Value
  b
    c
    d
      e
        f
        g
      h
    i
  END
  
    my $B = $b->transcribe;
  
    $b->by(sub
     {my ($c) = @_;
      my @path = $c->pathFrom($b);
      my $C = $B->go(@path);
      is_deeply $c->key, $C->key;
      is_deeply $c->{transcribedTo},   $C;
      is_deeply $C->{transcribedFrom}, $c;
     });
  
    is_deeply $B->print, <<END;
  Key      Value
  b
    c
    d
      e
        f
        g
      h
    i
  END
  

=head2 transcribe($parent)

Duplicate a specified parent and all its descendants recording the mapping in a temporary {transcribed} field in the tree being transcribed. Returns the root parent of the tree being duplicated.

     Parameter  Description
  1  $parent    Parent

B<Example:>


    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j) = fromLetters 'b(cd(e(fg)h)i)j';
  
    is_deeply $a->print, <<END;
  Key        Value
  a
    b
      c
      d
        e
          f
          g
        h
      i
    j
  END
  
    ok $a->go(0,1,0,1) == $g;
    ok $d->go(0,0)     == $f;
  
    is_deeply [$e->path],         [0,1,0];
    is_deeply [$g->pathFrom($d)], [0,1];
  
    is_deeply $b->dup->print, <<END;
  Key      Value
  b
    c
    d
      e
        f
        g
      h
    i
  END
  
  
    my $B = $b->transcribe;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    $b->by(sub
     {my ($c) = @_;
      my @path = $c->pathFrom($b);
      my $C = $B->go(@path);
      is_deeply $c->key, $C->key;
      is_deeply $c->{transcribedTo},   $C;
      is_deeply $C->{transcribedFrom}, $c;
     });
  
    is_deeply $B->print, <<END;
  Key      Value
  b
    c
    d
      e
        f
        g
      h
    i
  END
  

=head2 unwrap($child)

Unwrap the specified child and return that child.

     Parameter  Description
  1  $child     Child

B<Example:>


    my ($a, $b, $c, $d, $e, $f, $g) = fromLetters 'b(c(de)f)g';
  
    is_deeply $a->print, <<END;
  Key      Value
  a
    b
      c
        d
        e
      f
    g
  END
  
    $c->wrap('z');
  
    is_deeply $a->print, <<END;
  Key        Value
  a
    b
      z
        c
          d
          e
      f
    g
  END
  
  
    $c->parent->unwrap;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    is_deeply $a->print, <<END;
  Key      Value
  a
    b
      c
        d
        e
      f
    g
  END
  
    $c->wrapChildren("Z");
  
    is_deeply $a->print, <<END;
  Key        Value
  a
    b
      c
        Z
          d
          e
      f
    g
  END
  

=head2 wrap($child, $key, $value)

Wrap the specified child with a new parent and return the new parent optionally setting its L<key|/"key"> and L<value|/"value">.

     Parameter  Description
  1  $child     Child to wrap
  2  $key       Optional key
  3  $value     Optional value

B<Example:>


    my ($a, $b, $c, $d, $e, $f, $g) = fromLetters 'b(c(de)f)g';
  
    is_deeply $a->print, <<END;
  Key      Value
  a
    b
      c
        d
        e
      f
    g
  END
  
  
    $c->wrap('z');  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    is_deeply $a->print, <<END;
  Key        Value
  a
    b
      z
        c
          d
          e
      f
    g
  END
  
    $c->parent->unwrap;
  
    is_deeply $a->print, <<END;
  Key      Value
  a
    b
      c
        d
        e
      f
    g
  END
  
    $c->wrapChildren("Z");
  
    is_deeply $a->print, <<END;
  Key        Value
  a
    b
      c
        Z
          d
          e
      f
    g
  END
  

=head2 wrapChildren($parent, $key, $value)

Wrap the children of the specified parent with a new intermediate parent that becomes the child of the specified parent, optionally setting the L<key|/"key"> and the L<value|/"value"> for the new parent.  Return the new parent.

     Parameter  Description
  1  $parent    Child to wrap
  2  $key       Optional key for new wrapping parent
  3  $value     Optional value for new wrapping parent

B<Example:>


    my ($a, $b, $c, $d, $e, $f, $g) = fromLetters 'b(c(de)f)g';
  
    is_deeply $a->print, <<END;
  Key      Value
  a
    b
      c
        d
        e
      f
    g
  END
  
    $c->wrap('z');
  
    is_deeply $a->print, <<END;
  Key        Value
  a
    b
      z
        c
          d
          e
      f
    g
  END
  
    $c->parent->unwrap;
  
    is_deeply $a->print, <<END;
  Key      Value
  a
    b
      c
        d
        e
      f
    g
  END
  
  
    $c->wrapChildren("Z");  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    is_deeply $a->print, <<END;
  Key        Value
  a
    b
      c
        Z
          d
          e
      f
    g
  END
  

=head2 merge($parent)

Unwrap the children of the specified parent with the whose L<key|/"key"> fields L<smartmatch|https://perldoc.perl.org/perlop.html#Smartmatch-Operator> that of their parent. Returns the specified parent regardless.

     Parameter  Description
  1  $parent    Merging parent

B<Example:>


    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j) = fromLetters 'b(c)d(efgh(i(j)))';
  
    is_deeply $a->print, <<END;
  Key        Value
  a
    b
      c
    d
      e
      f
      g
      h
        i
          j
  END
  
    $d->split;
    is_deeply $a->print, <<END;
  Key          Value
  a
    b
      c
    d
      d
        e
      d
        f
      d
        g
      d
        h
          i
            j
  END
  
    $f->parent->mergeLikePrev;
    is_deeply $a->print, <<END;
  Key          Value
  a
    b
      c
    d
      d
        e
        f
      d
        g
      d
        h
          i
            j
  END
  
    $g->parent->mergeLikeNext;
    is_deeply $a->print, <<END;
  Key          Value
  a
    b
      c
    d
      d
        e
        f
      d
        g
        h
          i
            j
  END
  
  
    $d->merge;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply $a->print, <<END;
  Key        Value
  a
    b
      c
    d
      e
      f
      g
      h
        i
          j
  END
  

=head2 mergeLikePrev($child)

Merge the preceding sibling of the specified child  if that sibling exists and the L<key|/"key"> data of the two siblings L<smartmatch|https://perldoc.perl.org/perlop.html#Smartmatch-Operator>. Returns the specified child regardless. From a proposal made by Micaela Monroe.

     Parameter  Description
  1  $child     Child

B<Example:>


    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j) = fromLetters 'b(c)d(efgh(i(j)))';
  
    is_deeply $a->print, <<END;
  Key        Value
  a
    b
      c
    d
      e
      f
      g
      h
        i
          j
  END
  
    $d->split;
    is_deeply $a->print, <<END;
  Key          Value
  a
    b
      c
    d
      d
        e
      d
        f
      d
        g
      d
        h
          i
            j
  END
  
  
    $f->parent->mergeLikePrev;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply $a->print, <<END;
  Key          Value
  a
    b
      c
    d
      d
        e
        f
      d
        g
      d
        h
          i
            j
  END
  
    $g->parent->mergeLikeNext;
    is_deeply $a->print, <<END;
  Key          Value
  a
    b
      c
    d
      d
        e
        f
      d
        g
        h
          i
            j
  END
  
    $d->merge;
    is_deeply $a->print, <<END;
  Key        Value
  a
    b
      c
    d
      e
      f
      g
      h
        i
          j
  END
  

=head2 mergeLikeNext($child)

Merge the following sibling of the specified child  if that sibling exists and the L<key|/"key"> data of the two siblings L<smartmatch|https://perldoc.perl.org/perlop.html#Smartmatch-Operator>. Returns the specified child regardless. From a proposal made by Micaela Monroe.

     Parameter  Description
  1  $child     Child

B<Example:>


    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j) = fromLetters 'b(c)d(efgh(i(j)))';
  
    is_deeply $a->print, <<END;
  Key        Value
  a
    b
      c
    d
      e
      f
      g
      h
        i
          j
  END
  
    $d->split;
    is_deeply $a->print, <<END;
  Key          Value
  a
    b
      c
    d
      d
        e
      d
        f
      d
        g
      d
        h
          i
            j
  END
  
    $f->parent->mergeLikePrev;
    is_deeply $a->print, <<END;
  Key          Value
  a
    b
      c
    d
      d
        e
        f
      d
        g
      d
        h
          i
            j
  END
  
  
    $g->parent->mergeLikeNext;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply $a->print, <<END;
  Key          Value
  a
    b
      c
    d
      d
        e
        f
      d
        g
        h
          i
            j
  END
  
    $d->merge;
    is_deeply $a->print, <<END;
  Key        Value
  a
    b
      c
    d
      e
      f
      g
      h
        i
          j
  END
  

=head2 split($parent)

Make the specified parent a grandparent of each of its children by interposing a copy of the specified parent between the specified parent and each of its children. Return the specified parent.

     Parameter  Description
  1  $parent    Parent to make into a grand parent

B<Example:>


    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j) = fromLetters 'b(c)d(efgh(i(j)))';
  
    is_deeply $a->print, <<END;
  Key        Value
  a
    b
      c
    d
      e
      f
      g
      h
        i
          j
  END
  
  
    $d->split;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply $a->print, <<END;
  Key          Value
  a
    b
      c
    d
      d
        e
      d
        f
      d
        g
      d
        h
          i
            j
  END
  
    $f->parent->mergeLikePrev;
    is_deeply $a->print, <<END;
  Key          Value
  a
    b
      c
    d
      d
        e
        f
      d
        g
      d
        h
          i
            j
  END
  
    $g->parent->mergeLikeNext;
    is_deeply $a->print, <<END;
  Key          Value
  a
    b
      c
    d
      d
        e
        f
      d
        g
        h
          i
            j
  END
  
    $d->merge;
    is_deeply $a->print, <<END;
  Key        Value
  a
    b
      c
    d
      e
      f
      g
      h
        i
          j
  END
  

=head1 Traverse

Traverse a tree.

=head2 by($tree, $sub)

Traverse a tree in post-order to process each child with the specified sub and return an array of the results of processing each child. If no sub sub is specified, the children are returned in tree order.

     Parameter  Description
  1  $tree      Tree
  2  $sub       Optional sub to process each child

B<Example:>


    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j, $s, $t, $x, $y, $z) =
      fromLetters 'b(c)y(x)z(st)d(efgh(i(j))))';
  
    is_deeply [$x->context], [$x, $y, $a];
  
  
    is_deeply join(' ', $a->by(sub{$_[0]->key})), "c b x y s t z e f g j i h d a";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    is_deeply join(' ', map{$_->key} $a->by),     "c b x y s t z e f g j i h d a";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    is_deeply $a->print, <<END;
  Key        Value
  a
    b
      c
    y
      x
    z
      s
      t
    d
      e
      f
      g
      h
        i
          j
  END
  
    $z->cut;
    is_deeply $a->print, <<END;
  Key        Value
  a
    b
      c
    y
      x
    d
      e
      f
      g
      h
        i
          j
  END
  

=head2 select($tree, $select)

Select matching children in a tree in post-order. A child can be selected via named value, array of values, a hash of values, a regular expression or a sub reference.

     Parameter  Description
  1  $tree      Tree
  2  $select    Method to select a child

B<Example:>


    my $a = Tree::Ops::new 'a', 'A';
    for(1..2)
     {$a->open  ('b', "B$_");
      $a->single('c', "C$_");
      ok $a->activeScope->key eq 'b';
      $a->close;
     }
    $a->single  ('d', 'D');
    $a->single  ('e', 'E');
    is_deeply $a->print, <<END;
  Key    Value
  a      A
    b    B1
      c  C1
    b    B2
      c  C2
    d    D
    e    E
  END
  
    is_deeply [map{$_->value} $a->by], [qw(C1 B1 C2 B2 D E A)];
  
    is_deeply $a->lastMost->prev->prev->first->key,           'c';
    is_deeply $a->first->next->last->parent->first->value,    'C2';
  
  
    is_deeply [map{$_->value} $a->select('b')],               [qw(B1 B2)];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    is_deeply [map{$_->value} $a->select(qr(b|c))],           [qw(B1 C1 B2 C2)];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    is_deeply [map{$_->value} $a->select(sub{$_[0] eq 'd'})], [qw(D)];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    $a->first->next->stepEnd->stepEnd->first->next->stepBack;
    is_deeply $a->print, <<END;
  Key      Value
  a        A
    b      B1
      c    C1
    b      B2
      d    D
        c  C2
      e    E
  END
  

=head1 Partitions

Various partitions of the tree

=head2 leaves($tree)

The set of all children without further children, i.e. each leaf of the tree.

     Parameter  Description
  1  $tree      Tree

B<Example:>


    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j, $x, $y) =
      fromLetters 'b(c)y(x)d(efgh(i(j)))';
  
    is_deeply $a->print, <<END;
  Key        Value
  a
    b
      c
    y
      x
    d
      e
      f
      g
      h
        i
          j
  END
  
    is_deeply $a->xml,
     '<a><b><c/></b><y><x/></y><d><e/><f/><g/><h><i><j/></i></h></d></a>';
  
  
    is_deeply [$c, $x, $e, $f, $g, $j], [$a->leaves];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply [$a, $b, $y, $d, $h, $i], [$a->parentsPreOrder];
    is_deeply [$b, $y, $i, $h, $d, $a], [$a->parentsPostOrder];
    is_deeply [$a->parents],            [$a->parentsPostOrder];
  
    is_deeply [$a, $d, $h, $i, $y, $b], [$a->parentsReversePreOrder];
    is_deeply [$i, $h, $d, $y, $b, $a], [$a->parentsReversePostOrder];
  
    ok !$j->parents;
  
    ok  $a->lastMost  == $j;
    ok !$a->prevMost;
    ok  $j->prevMost  == $g;
    ok  $i->prevMost  == $g;
    ok  $h->prevMost  == $g;
    ok  $g->prevMost  == $f;
    ok  $f->prevMost  == $e;
    ok  $e->prevMost  == $x;
    ok  $d->prevMost  == $x;
    ok  $x->prevMost  == $c;
    ok  $y->prevMost  == $c;
    ok !$c->prevMost;
    ok !$b->prevMost;
    ok !$a->prevMost;
  
    ok  $a->firstMost == $c;
    ok  $a->nextMost  == $c;
    ok  $b->nextMost  == $c;
    ok  $c->nextMost  == $x;
    ok  $y->nextMost  == $x;
    ok  $x->nextMost  == $e;
    ok  $d->nextMost  == $e;
    ok  $e->nextMost  == $f;
    ok  $f->nextMost  == $g;
    ok  $g->nextMost  == $j;
    ok  $h->nextMost  == $j;
    ok  $i->nextMost  == $j;
    ok !$j->nextMost;
  
    ok  $i->topMost   == $a;
  

=head2 parentsPreOrder($tree)

The set of all parents in the tree, i.e. each non leaf of the tree, i.e  the interior of the tree in normal pre-order.

     Parameter  Description
  1  $tree      Tree

B<Example:>


    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j, $x, $y) =
      fromLetters 'b(c)y(x)d(efgh(i(j)))';
  
    is_deeply $a->print, <<END;
  Key        Value
  a
    b
      c
    y
      x
    d
      e
      f
      g
      h
        i
          j
  END
  
    is_deeply $a->xml,
     '<a><b><c/></b><y><x/></y><d><e/><f/><g/><h><i><j/></i></h></d></a>';
  
    is_deeply [$c, $x, $e, $f, $g, $j], [$a->leaves];
  
    is_deeply [$a, $b, $y, $d, $h, $i], [$a->parentsPreOrder];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply [$b, $y, $i, $h, $d, $a], [$a->parentsPostOrder];
    is_deeply [$a->parents],            [$a->parentsPostOrder];
  
    is_deeply [$a, $d, $h, $i, $y, $b], [$a->parentsReversePreOrder];
    is_deeply [$i, $h, $d, $y, $b, $a], [$a->parentsReversePostOrder];
  
    ok !$j->parents;
  
    ok  $a->lastMost  == $j;
    ok !$a->prevMost;
    ok  $j->prevMost  == $g;
    ok  $i->prevMost  == $g;
    ok  $h->prevMost  == $g;
    ok  $g->prevMost  == $f;
    ok  $f->prevMost  == $e;
    ok  $e->prevMost  == $x;
    ok  $d->prevMost  == $x;
    ok  $x->prevMost  == $c;
    ok  $y->prevMost  == $c;
    ok !$c->prevMost;
    ok !$b->prevMost;
    ok !$a->prevMost;
  
    ok  $a->firstMost == $c;
    ok  $a->nextMost  == $c;
    ok  $b->nextMost  == $c;
    ok  $c->nextMost  == $x;
    ok  $y->nextMost  == $x;
    ok  $x->nextMost  == $e;
    ok  $d->nextMost  == $e;
    ok  $e->nextMost  == $f;
    ok  $f->nextMost  == $g;
    ok  $g->nextMost  == $j;
    ok  $h->nextMost  == $j;
    ok  $i->nextMost  == $j;
    ok !$j->nextMost;
  
    ok  $i->topMost   == $a;
  

=head2 parentsPostOrder($tree)

The set of all parents in the tree, i.e. each non leaf of the tree, i.e  the interior of the tree in normal post-order.

     Parameter  Description
  1  $tree      Tree

B<Example:>


    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j, $x, $y) =
      fromLetters 'b(c)y(x)d(efgh(i(j)))';
  
    is_deeply $a->print, <<END;
  Key        Value
  a
    b
      c
    y
      x
    d
      e
      f
      g
      h
        i
          j
  END
  
    is_deeply $a->xml,
     '<a><b><c/></b><y><x/></y><d><e/><f/><g/><h><i><j/></i></h></d></a>';
  
    is_deeply [$c, $x, $e, $f, $g, $j], [$a->leaves];
    is_deeply [$a, $b, $y, $d, $h, $i], [$a->parentsPreOrder];
  
    is_deeply [$b, $y, $i, $h, $d, $a], [$a->parentsPostOrder];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    is_deeply [$a->parents],            [$a->parentsPostOrder];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    is_deeply [$a, $d, $h, $i, $y, $b], [$a->parentsReversePreOrder];
    is_deeply [$i, $h, $d, $y, $b, $a], [$a->parentsReversePostOrder];
  
    ok !$j->parents;
  
    ok  $a->lastMost  == $j;
    ok !$a->prevMost;
    ok  $j->prevMost  == $g;
    ok  $i->prevMost  == $g;
    ok  $h->prevMost  == $g;
    ok  $g->prevMost  == $f;
    ok  $f->prevMost  == $e;
    ok  $e->prevMost  == $x;
    ok  $d->prevMost  == $x;
    ok  $x->prevMost  == $c;
    ok  $y->prevMost  == $c;
    ok !$c->prevMost;
    ok !$b->prevMost;
    ok !$a->prevMost;
  
    ok  $a->firstMost == $c;
    ok  $a->nextMost  == $c;
    ok  $b->nextMost  == $c;
    ok  $c->nextMost  == $x;
    ok  $y->nextMost  == $x;
    ok  $x->nextMost  == $e;
    ok  $d->nextMost  == $e;
    ok  $e->nextMost  == $f;
    ok  $f->nextMost  == $g;
    ok  $g->nextMost  == $j;
    ok  $h->nextMost  == $j;
    ok  $i->nextMost  == $j;
    ok !$j->nextMost;
  
    ok  $i->topMost   == $a;
  

=head2 parentsReversePreOrder($tree)

The set of all parents in the tree, i.e. each non leaf of the tree, i.e  the interior of the tree in reverse pre-order.

     Parameter  Description
  1  $tree      Tree

B<Example:>


    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j, $x, $y) =
      fromLetters 'b(c)y(x)d(efgh(i(j)))';
  
    is_deeply $a->print, <<END;
  Key        Value
  a
    b
      c
    y
      x
    d
      e
      f
      g
      h
        i
          j
  END
  
    is_deeply $a->xml,
     '<a><b><c/></b><y><x/></y><d><e/><f/><g/><h><i><j/></i></h></d></a>';
  
    is_deeply [$c, $x, $e, $f, $g, $j], [$a->leaves];
    is_deeply [$a, $b, $y, $d, $h, $i], [$a->parentsPreOrder];
    is_deeply [$b, $y, $i, $h, $d, $a], [$a->parentsPostOrder];
    is_deeply [$a->parents],            [$a->parentsPostOrder];
  
  
    is_deeply [$a, $d, $h, $i, $y, $b], [$a->parentsReversePreOrder];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply [$i, $h, $d, $y, $b, $a], [$a->parentsReversePostOrder];
  
    ok !$j->parents;
  
    ok  $a->lastMost  == $j;
    ok !$a->prevMost;
    ok  $j->prevMost  == $g;
    ok  $i->prevMost  == $g;
    ok  $h->prevMost  == $g;
    ok  $g->prevMost  == $f;
    ok  $f->prevMost  == $e;
    ok  $e->prevMost  == $x;
    ok  $d->prevMost  == $x;
    ok  $x->prevMost  == $c;
    ok  $y->prevMost  == $c;
    ok !$c->prevMost;
    ok !$b->prevMost;
    ok !$a->prevMost;
  
    ok  $a->firstMost == $c;
    ok  $a->nextMost  == $c;
    ok  $b->nextMost  == $c;
    ok  $c->nextMost  == $x;
    ok  $y->nextMost  == $x;
    ok  $x->nextMost  == $e;
    ok  $d->nextMost  == $e;
    ok  $e->nextMost  == $f;
    ok  $f->nextMost  == $g;
    ok  $g->nextMost  == $j;
    ok  $h->nextMost  == $j;
    ok  $i->nextMost  == $j;
    ok !$j->nextMost;
  
    ok  $i->topMost   == $a;
  

=head2 parentsReversePostOrder($tree)

The set of all parents in the tree, i.e. each non leaf of the tree, i.e  the interior of the tree in reverse post-order.

     Parameter  Description
  1  $tree      Tree

B<Example:>


    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j, $x, $y) =
      fromLetters 'b(c)y(x)d(efgh(i(j)))';
  
    is_deeply $a->print, <<END;
  Key        Value
  a
    b
      c
    y
      x
    d
      e
      f
      g
      h
        i
          j
  END
  
    is_deeply $a->xml,
     '<a><b><c/></b><y><x/></y><d><e/><f/><g/><h><i><j/></i></h></d></a>';
  
    is_deeply [$c, $x, $e, $f, $g, $j], [$a->leaves];
    is_deeply [$a, $b, $y, $d, $h, $i], [$a->parentsPreOrder];
    is_deeply [$b, $y, $i, $h, $d, $a], [$a->parentsPostOrder];
    is_deeply [$a->parents],            [$a->parentsPostOrder];
  
    is_deeply [$a, $d, $h, $i, $y, $b], [$a->parentsReversePreOrder];
  
    is_deeply [$i, $h, $d, $y, $b, $a], [$a->parentsReversePostOrder];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok !$j->parents;
  
    ok  $a->lastMost  == $j;
    ok !$a->prevMost;
    ok  $j->prevMost  == $g;
    ok  $i->prevMost  == $g;
    ok  $h->prevMost  == $g;
    ok  $g->prevMost  == $f;
    ok  $f->prevMost  == $e;
    ok  $e->prevMost  == $x;
    ok  $d->prevMost  == $x;
    ok  $x->prevMost  == $c;
    ok  $y->prevMost  == $c;
    ok !$c->prevMost;
    ok !$b->prevMost;
    ok !$a->prevMost;
  
    ok  $a->firstMost == $c;
    ok  $a->nextMost  == $c;
    ok  $b->nextMost  == $c;
    ok  $c->nextMost  == $x;
    ok  $y->nextMost  == $x;
    ok  $x->nextMost  == $e;
    ok  $d->nextMost  == $e;
    ok  $e->nextMost  == $f;
    ok  $f->nextMost  == $g;
    ok  $g->nextMost  == $j;
    ok  $h->nextMost  == $j;
    ok  $i->nextMost  == $j;
    ok !$j->nextMost;
  
    ok  $i->topMost   == $a;
  

=head2 parents($tree)

The set of all parents in the tree, i.e. each non leaf of the tree, i.e  the interior of the tree in normal post-order.

     Parameter  Description
  1  $tree      Tree

B<Example:>


    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j, $x, $y) =
      fromLetters 'b(c)y(x)d(efgh(i(j)))';
  
    is_deeply $a->print, <<END;
  Key        Value
  a
    b
      c
    y
      x
    d
      e
      f
      g
      h
        i
          j
  END
  
    is_deeply $a->xml,
     '<a><b><c/></b><y><x/></y><d><e/><f/><g/><h><i><j/></i></h></d></a>';
  
    is_deeply [$c, $x, $e, $f, $g, $j], [$a->leaves];
    is_deeply [$a, $b, $y, $d, $h, $i], [$a->parentsPreOrder];
    is_deeply [$b, $y, $i, $h, $d, $a], [$a->parentsPostOrder];
  
    is_deeply [$a->parents],            [$a->parentsPostOrder];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    is_deeply [$a, $d, $h, $i, $y, $b], [$a->parentsReversePreOrder];
    is_deeply [$i, $h, $d, $y, $b, $a], [$a->parentsReversePostOrder];
  
  
    ok !$j->parents;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok  $a->lastMost  == $j;
    ok !$a->prevMost;
    ok  $j->prevMost  == $g;
    ok  $i->prevMost  == $g;
    ok  $h->prevMost  == $g;
    ok  $g->prevMost  == $f;
    ok  $f->prevMost  == $e;
    ok  $e->prevMost  == $x;
    ok  $d->prevMost  == $x;
    ok  $x->prevMost  == $c;
    ok  $y->prevMost  == $c;
    ok !$c->prevMost;
    ok !$b->prevMost;
    ok !$a->prevMost;
  
    ok  $a->firstMost == $c;
    ok  $a->nextMost  == $c;
    ok  $b->nextMost  == $c;
    ok  $c->nextMost  == $x;
    ok  $y->nextMost  == $x;
    ok  $x->nextMost  == $e;
    ok  $d->nextMost  == $e;
    ok  $e->nextMost  == $f;
    ok  $f->nextMost  == $g;
    ok  $g->nextMost  == $j;
    ok  $h->nextMost  == $j;
    ok  $i->nextMost  == $j;
    ok !$j->nextMost;
  
    ok  $i->topMost   == $a;
  

=head1 Order

Check the order and relative position of children in a tree.

=head2 above($first, $second)

Return the first child if it is above the second child else return B<undef>.

     Parameter  Description
  1  $first     First child
  2  $second    Second child

B<Example:>


    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j, $k, $l, $m, $n) =
      fromLetters('b(c(d(efgh(i(j)k)l)m)n');
  
    is_deeply $a->print, <<END;
  Key            Value
  a
    b
      c
        d
          e
          f
          g
          h
            i
              j
            k
          l
        m
      n
  END
  
  
    ok  $c->above($j)  == $c;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok !$m->above($j);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok  $i->below($b)  == $i;
    ok !$i->below($n);
  
    ok  $n->after($e)  == $n;
    ok !$k->after($c);
  
    ok  $c->before($n) == $c;
    ok !$c->before($m);
  
    is_deeply [map{$_->key} $j->lineage($d)], [qw(j i h d)];
    ok !$d->lineage($m);
  

=head2 below($first, $second)

Return the first child if it is below the second child else return B<undef>.

     Parameter  Description
  1  $first     First child
  2  $second    Second child

B<Example:>


    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j, $k, $l, $m, $n) =
      fromLetters('b(c(d(efgh(i(j)k)l)m)n');
  
    is_deeply $a->print, <<END;
  Key            Value
  a
    b
      c
        d
          e
          f
          g
          h
            i
              j
            k
          l
        m
      n
  END
  
    ok  $c->above($j)  == $c;
    ok !$m->above($j);
  
  
    ok  $i->below($b)  == $i;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok !$i->below($n);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok  $n->after($e)  == $n;
    ok !$k->after($c);
  
    ok  $c->before($n) == $c;
    ok !$c->before($m);
  
    is_deeply [map{$_->key} $j->lineage($d)], [qw(j i h d)];
    ok !$d->lineage($m);
  

=head2 after($first, $second)

Return the first child if it occurs strictly after the second child in the tree or else B<undef> if the first child is L<above|/"above($first, $second)">, L<below|/"below($first, $second)"> or L<before|/"before($first, $second)"> the second child.

     Parameter  Description
  1  $first     First child
  2  $second    Second child

B<Example:>


    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j, $k, $l, $m, $n) =
      fromLetters('b(c(d(efgh(i(j)k)l)m)n');
  
    is_deeply $a->print, <<END;
  Key            Value
  a
    b
      c
        d
          e
          f
          g
          h
            i
              j
            k
          l
        m
      n
  END
  
    ok  $c->above($j)  == $c;
    ok !$m->above($j);
  
    ok  $i->below($b)  == $i;
    ok !$i->below($n);
  
  
    ok  $n->after($e)  == $n;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok !$k->after($c);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok  $c->before($n) == $c;
    ok !$c->before($m);
  
    is_deeply [map{$_->key} $j->lineage($d)], [qw(j i h d)];
    ok !$d->lineage($m);
  

=head2 before($first, $second)

Return the first child if it occurs strictly before the second child in the tree or else B<undef> if the first child is L<above|/"above($first, $second)">, L<below|/"below($first, $second)"> or L<after|/"after($first, $second)"> the second child.

     Parameter  Description
  1  $first     First child
  2  $second    Second child

B<Example:>


    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j, $k, $l, $m, $n) =
      fromLetters('b(c(d(efgh(i(j)k)l)m)n');
  
    is_deeply $a->print, <<END;
  Key            Value
  a
    b
      c
        d
          e
          f
          g
          h
            i
              j
            k
          l
        m
      n
  END
  
    ok  $c->above($j)  == $c;
    ok !$m->above($j);
  
    ok  $i->below($b)  == $i;
    ok !$i->below($n);
  
    ok  $n->after($e)  == $n;
    ok !$k->after($c);
  
  
    ok  $c->before($n) == $c;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok !$c->before($m);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    is_deeply [map{$_->key} $j->lineage($d)], [qw(j i h d)];
    ok !$d->lineage($m);
  

=head1 Paths

Find paths between nodes

=head2 path($child)

Return the list of zero based child indexes for the path from the root of the tree containing the specified child to the specified child for use by the L<go|/"go($parent, @path)"> method.

     Parameter  Description
  1  $child     Child

B<Example:>


    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j) = fromLetters 'b(cd(e(fg)h)i)j';
  
    is_deeply $a->print, <<END;
  Key        Value
  a
    b
      c
      d
        e
          f
          g
        h
      i
    j
  END
  
    ok $a->go(0,1,0,1) == $g;
    ok $d->go(0,0)     == $f;
  
  
    is_deeply [$e->path],         [0,1,0];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply [$g->pathFrom($d)], [0,1];
  
    is_deeply $b->dup->print, <<END;
  Key      Value
  b
    c
    d
      e
        f
        g
      h
    i
  END
  
    my $B = $b->transcribe;
  
    $b->by(sub
     {my ($c) = @_;
  
      my @path = $c->pathFrom($b);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
      my $C = $B->go(@path);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      is_deeply $c->key, $C->key;
      is_deeply $c->{transcribedTo},   $C;
      is_deeply $C->{transcribedFrom}, $c;
     });
  
    is_deeply $B->print, <<END;
  Key      Value
  b
    c
    d
      e
        f
        g
      h
    i
  END
  

=head2 pathFrom($child, $ancestor)

Return the list of zero based child indexes for the path from the specified ancestor to the specified child for use by the L<go|/"go($parent, @path)"> method else confess if the ancestor is not, in fact, an ancestor.

     Parameter  Description
  1  $child     Child
  2  $ancestor  Ancestor

B<Example:>


    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j) = fromLetters 'b(cd(e(fg)h)i)j';
  
    is_deeply $a->print, <<END;
  Key        Value
  a
    b
      c
      d
        e
          f
          g
        h
      i
    j
  END
  
    ok $a->go(0,1,0,1) == $g;
    ok $d->go(0,0)     == $f;
  
    is_deeply [$e->path],         [0,1,0];
  
    is_deeply [$g->pathFrom($d)], [0,1];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    is_deeply $b->dup->print, <<END;
  Key      Value
  b
    c
    d
      e
        f
        g
      h
    i
  END
  
    my $B = $b->transcribe;
  
    $b->by(sub
     {my ($c) = @_;
  
      my @path = $c->pathFrom($b);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $C = $B->go(@path);
      is_deeply $c->key, $C->key;
      is_deeply $c->{transcribedTo},   $C;
      is_deeply $C->{transcribedFrom}, $c;
     });
  
    is_deeply $B->print, <<END;
  Key      Value
  b
    c
    d
      e
        f
        g
      h
    i
  END
  

=head2 siblingsBefore($child)

Return a list of siblings before the specified child.

     Parameter  Description
  1  $child     Child

B<Example:>


    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j) = fromLetters 'b(cde(f)ghi)j';
    is_deeply $a->print, <<END;
  Key      Value
  a
    b
      c
      d
      e
        f
      g
      h
      i
    j
  END
  
    is_deeply [$d->siblingsStrictlyBetween($h)], [$e, $g];
    is_deeply [$d->siblingsAfter],               [$e, $g, $h, $i];
  
    is_deeply [$g->siblingsBefore],              [$c, $d, $e];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    eval {$e->siblingsStrictlyBetween($f)};
    ok $@ =~ m(Must be siblings);
  

=head2 siblingsAfter($child)

Return a list of siblings after the specified child.

     Parameter  Description
  1  $child     Child

B<Example:>


    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j) = fromLetters 'b(cde(f)ghi)j';
    is_deeply $a->print, <<END;
  Key      Value
  a
    b
      c
      d
      e
        f
      g
      h
      i
    j
  END
  
    is_deeply [$d->siblingsStrictlyBetween($h)], [$e, $g];
  
    is_deeply [$d->siblingsAfter],               [$e, $g, $h, $i];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply [$g->siblingsBefore],              [$c, $d, $e];
    eval {$e->siblingsStrictlyBetween($f)};
    ok $@ =~ m(Must be siblings);
  

=head2 siblingsStrictlyBetween($start, $finish)

Return a list of the siblings strictly between two children of the same parent else return B<undef>.

     Parameter  Description
  1  $start     Start child
  2  $finish    Finish child

B<Example:>


    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j) = fromLetters 'b(cde(f)ghi)j';
    is_deeply $a->print, <<END;
  Key      Value
  a
    b
      c
      d
      e
        f
      g
      h
      i
    j
  END
  
  
    is_deeply [$d->siblingsStrictlyBetween($h)], [$e, $g];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply [$d->siblingsAfter],               [$e, $g, $h, $i];
    is_deeply [$g->siblingsBefore],              [$c, $d, $e];
  
    eval {$e->siblingsStrictlyBetween($f)};  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    ok $@ =~ m(Must be siblings);
  

=head2 lineage($child, $ancestor)

Return the path from the specified child to the specified ancestor else return B<undef> if the child is not a descendant of the ancestor.

     Parameter  Description
  1  $child     Child
  2  $ancestor  Ancestor

B<Example:>


    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j, $k, $l, $m, $n) =
      fromLetters('b(c(d(efgh(i(j)k)l)m)n');
  
    is_deeply $a->print, <<END;
  Key            Value
  a
    b
      c
        d
          e
          f
          g
          h
            i
              j
            k
          l
        m
      n
  END
  
    ok  $c->above($j)  == $c;
    ok !$m->above($j);
  
    ok  $i->below($b)  == $i;
    ok !$i->below($n);
  
    ok  $n->after($e)  == $n;
    ok !$k->after($c);
  
    ok  $c->before($n) == $c;
    ok !$c->before($m);
  
  
    is_deeply [map{$_->key} $j->lineage($d)], [qw(j i h d)];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok !$d->lineage($m);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  

=head2 nextPreOrderPath($start)

Return a list of children visited between the specified child and the next child in pre-order.

     Parameter  Description
  1  $start     The child at the start of the path

B<Example:>


    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j, $k, $l, $m, $n, $o, $p, $q, $r) =
      fromLetters 'b(c(d(e(fg)hi(j(kl)m)n)op)q)r';
    my @p = [$a];
  
    for(1..99)
  
     {my @n = $p[-1][-1]->nextPreOrderPath;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      last unless @n;
      push @p, [@n];
     }
  
    is_deeply $a->print, <<END;
  Key            Value
  a
    b
      c
        d
          e
            f
            g
          h
          i
            j
              k
              l
            m
          n
        o
        p
      q
    r
  END
  
    my @pre = map{[map{$_->key} @$_]} @p;
    is_deeply scalar(@pre), scalar(['a'..'r']->@*);
    is_deeply [@pre],
     [["a"],
      ["b"],
      ["c"],
      ["d"],
      ["e"],
      ["f"],
      ["g"],
      ["e", "h"],
      ["i"],
      ["j"],
      ["k"],
      ["l"],
      ["j", "m"],
      ["i", "n"],
      ["d", "o"],
      ["p"],
      ["c", "q"],
      ["b", "r"]];
  

=head2 nextPostOrderPath($start)

Return a list of children visited between the specified child and the next child in post-order.

     Parameter  Description
  1  $start     The child at the start of the path

B<Example:>


    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j, $k, $l, $m, $n, $o, $p, $q, $r) =
      fromLetters 'b(c(d(e(fg)hi(j(kl)m)n)op)q)r';
  
    my @n = $a;
    my @p;
    for(1..99)
  
     {@n = $n[-1]->nextPostOrderPath;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      last unless @n;
      push @p, [@n];
      last if $n[-1] == $a;
     }
  
    is_deeply $a->print, <<END;
  Key            Value
  a
    b
      c
        d
          e
            f
            g
          h
          i
            j
              k
              l
            m
          n
        o
        p
      q
    r
  END
  
    my @post = map{[map{$_->key} @$_]} @p;
    is_deeply scalar(@post), scalar(['a'..'r']->@*);
    is_deeply [@post],
   [["b" .. "f"],
    ["g"],
    ["e"],
    ["h"],
    ["i", "j", "k"],
    ["l"],
    ["j"],
    ["m"],
    ["i"],
    ["n"],
    ["d"],
    ["o"],
    ["p"],
    ["c"],
    ["q"],
    ["b"],
    ["r"],
    ["a"]];
  

=head2 prevPostOrderPath($start)

Return a list of children visited between the specified child and the previous child in post-order.

     Parameter  Description
  1  $start     The child at the start of the path

B<Example:>


    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j, $k, $l, $m, $n, $o, $p, $q, $r) =
      fromLetters 'b(c(d(e(fg)hi(j(kl)m)n)op)q)r';
    my @p = [$a];
  
    for(1..99)
  
     {my @n = $p[-1][-1]->prevPostOrderPath;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      last unless @n;
      push @p, [@n];
     }
  
    is_deeply $a->print, <<END;
  Key            Value
  a
    b
      c
        d
          e
            f
            g
          h
          i
            j
              k
              l
            m
          n
        o
        p
      q
    r
  END
  
    my @post = map{[map{$_->key} @$_]} @p;
    is_deeply scalar(@post), scalar(['a'..'r']->@*);
    is_deeply [@post],
     [["a"],
      ["r"],
      ["b"],
      ["q"],
      ["c"],
      ["p"],
      ["o"],
      ["d"],
      ["n"],
      ["i"],
      ["m"],
      ["j"],
      ["l"],
      ["k"],
      ["j", "i", "h"],
      ["e"],
      ["g"],
      ["f"]];
  

=head2 prevPreOrderPath($start)

Return a list of children visited between the specified child and the previous child in pre-order.

     Parameter  Description
  1  $start     The child at the start of the path

B<Example:>


    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j, $k, $l, $m, $n, $o, $p, $q, $r) =
      fromLetters 'b(c(d(e(fg)hi(j(kl)m)n)op)q)r';
  
    my @n = $a;
    my @p;
    for(1..99)
  
     {@n = $n[-1]->prevPreOrderPath;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      last unless @n;
      push @p, [@n];
      last if $n[-1] == $a;
     }
  
    is_deeply $a->print, <<END;
  Key            Value
  a
    b
      c
        d
          e
            f
            g
          h
          i
            j
              k
              l
            m
          n
        o
        p
      q
    r
  END
  
    my @pre = map{[map{$_->key} @$_]} @p;
    is_deeply scalar(@pre), scalar(['a'..'r']->@*);
    is_deeply [@pre],
     [["r"],
      ["b", "q"],
      ["c", "p"],
      ["o"],
      ["d", "n"],
      ["i", "m"],
      ["j", "l"],
      ["k"],
      ["j"],
      ["i"],
      ["h"],
      ["e", "g"],
      ["f"],
      ["e"],
      ["d"],
      ["c"],
      ["b"],
      ["a"]];
  

=head1 Print

Print a tree.

=head2 printPreOrder($tree, $print)

Print tree in normal pre-order.

     Parameter  Description
  1  $tree      Tree
  2  $print     Optional print method

B<Example:>


    my ($a, $b, $c, $d) = fromLetters 'b(c)d';
    my sub test(@) {join ' ', map{join '', $_->key} @_}
  
  
    is_deeply $a->printPreOrder, <<END;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  Key    Value
  a
    b
      c
    d
  END
  
    is_deeply test($a->nextPreOrderPath), 'b';
    is_deeply test($b->nextPreOrderPath), 'c';
    is_deeply test($c->nextPreOrderPath), 'b d';
    is_deeply test($d->nextPreOrderPath), '';
  
    is_deeply $a->printPostOrder, <<END;
  Key    Value
      c
    b
    d
  a
  END
  
    is_deeply test($a->nextPostOrderPath), 'b c';
    is_deeply test($c->nextPostOrderPath), 'b';
    is_deeply test($b->nextPostOrderPath), 'd';
    is_deeply test($d->nextPostOrderPath), 'a';
  
    is_deeply $a->printReversePreOrder, <<END;
  Key    Value
  a
    d
    b
      c
  END
    is_deeply test($a->prevPreOrderPath), 'd';
    is_deeply test($d->prevPreOrderPath), 'b c';
    is_deeply test($c->prevPreOrderPath), 'b';
    is_deeply test($b->prevPreOrderPath), 'a';
  
    is_deeply $a->printReversePostOrder, <<END;
  Key    Value
    d
      c
    b
  a
  END
  
    is_deeply test($a->prevPostOrderPath), 'd';
    is_deeply test($d->prevPostOrderPath), 'b';
    is_deeply test($b->prevPostOrderPath), 'c';
    is_deeply test($c->prevPostOrderPath), '';
  

=head2 printPostOrder($tree, $print)

Print tree in normal post-order.

     Parameter  Description
  1  $tree      Tree
  2  $print     Optional print method

B<Example:>


    my ($a, $b, $c, $d) = fromLetters 'b(c)d';
    my sub test(@) {join ' ', map{join '', $_->key} @_}
  
    is_deeply $a->printPreOrder, <<END;
  Key    Value
  a
    b
      c
    d
  END
  
    is_deeply test($a->nextPreOrderPath), 'b';
    is_deeply test($b->nextPreOrderPath), 'c';
    is_deeply test($c->nextPreOrderPath), 'b d';
    is_deeply test($d->nextPreOrderPath), '';
  
  
    is_deeply $a->printPostOrder, <<END;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  Key    Value
      c
    b
    d
  a
  END
  
    is_deeply test($a->nextPostOrderPath), 'b c';
    is_deeply test($c->nextPostOrderPath), 'b';
    is_deeply test($b->nextPostOrderPath), 'd';
    is_deeply test($d->nextPostOrderPath), 'a';
  
    is_deeply $a->printReversePreOrder, <<END;
  Key    Value
  a
    d
    b
      c
  END
    is_deeply test($a->prevPreOrderPath), 'd';
    is_deeply test($d->prevPreOrderPath), 'b c';
    is_deeply test($c->prevPreOrderPath), 'b';
    is_deeply test($b->prevPreOrderPath), 'a';
  
    is_deeply $a->printReversePostOrder, <<END;
  Key    Value
    d
      c
    b
  a
  END
  
    is_deeply test($a->prevPostOrderPath), 'd';
    is_deeply test($d->prevPostOrderPath), 'b';
    is_deeply test($b->prevPostOrderPath), 'c';
    is_deeply test($c->prevPostOrderPath), '';
  

=head2 printReversePreOrder($tree, $print)

Print tree in reverse pre-order

     Parameter  Description
  1  $tree      Tree
  2  $print     Optional print method

B<Example:>


    my ($a, $b, $c, $d) = fromLetters 'b(c)d';
    my sub test(@) {join ' ', map{join '', $_->key} @_}
  
    is_deeply $a->printPreOrder, <<END;
  Key    Value
  a
    b
      c
    d
  END
  
    is_deeply test($a->nextPreOrderPath), 'b';
    is_deeply test($b->nextPreOrderPath), 'c';
    is_deeply test($c->nextPreOrderPath), 'b d';
    is_deeply test($d->nextPreOrderPath), '';
  
    is_deeply $a->printPostOrder, <<END;
  Key    Value
      c
    b
    d
  a
  END
  
    is_deeply test($a->nextPostOrderPath), 'b c';
    is_deeply test($c->nextPostOrderPath), 'b';
    is_deeply test($b->nextPostOrderPath), 'd';
    is_deeply test($d->nextPostOrderPath), 'a';
  
  
    is_deeply $a->printReversePreOrder, <<END;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  Key    Value
  a
    d
    b
      c
  END
    is_deeply test($a->prevPreOrderPath), 'd';
    is_deeply test($d->prevPreOrderPath), 'b c';
    is_deeply test($c->prevPreOrderPath), 'b';
    is_deeply test($b->prevPreOrderPath), 'a';
  
    is_deeply $a->printReversePostOrder, <<END;
  Key    Value
    d
      c
    b
  a
  END
  
    is_deeply test($a->prevPostOrderPath), 'd';
    is_deeply test($d->prevPostOrderPath), 'b';
    is_deeply test($b->prevPostOrderPath), 'c';
    is_deeply test($c->prevPostOrderPath), '';
  

=head2 printReversePostOrder($tree, $print)

Print tree in reverse post-order

     Parameter  Description
  1  $tree      Tree
  2  $print     Optional print method

B<Example:>


    my ($a, $b, $c, $d) = fromLetters 'b(c)d';
    my sub test(@) {join ' ', map{join '', $_->key} @_}
  
    is_deeply $a->printPreOrder, <<END;
  Key    Value
  a
    b
      c
    d
  END
  
    is_deeply test($a->nextPreOrderPath), 'b';
    is_deeply test($b->nextPreOrderPath), 'c';
    is_deeply test($c->nextPreOrderPath), 'b d';
    is_deeply test($d->nextPreOrderPath), '';
  
    is_deeply $a->printPostOrder, <<END;
  Key    Value
      c
    b
    d
  a
  END
  
    is_deeply test($a->nextPostOrderPath), 'b c';
    is_deeply test($c->nextPostOrderPath), 'b';
    is_deeply test($b->nextPostOrderPath), 'd';
    is_deeply test($d->nextPostOrderPath), 'a';
  
    is_deeply $a->printReversePreOrder, <<END;
  Key    Value
  a
    d
    b
      c
  END
    is_deeply test($a->prevPreOrderPath), 'd';
    is_deeply test($d->prevPreOrderPath), 'b c';
    is_deeply test($c->prevPreOrderPath), 'b';
    is_deeply test($b->prevPreOrderPath), 'a';
  
  
    is_deeply $a->printReversePostOrder, <<END;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  Key    Value
    d
      c
    b
  a
  END
  
    is_deeply test($a->prevPostOrderPath), 'd';
    is_deeply test($d->prevPostOrderPath), 'b';
    is_deeply test($b->prevPostOrderPath), 'c';
    is_deeply test($c->prevPostOrderPath), '';
  

=head2 print($tree, $print)

Print tree in normal pre-order.

     Parameter  Description
  1  $tree      Tree
  2  $print     Optional print method

B<Example:>


    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j, $x, $y) =
      fromLetters 'b(c)y(x)d(efgh(i(j)))';
  
  
    is_deeply $a->print, <<END;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  Key        Value
  a
    b
      c
    y
      x
    d
      e
      f
      g
      h
        i
          j
  END
  
    is_deeply $a->xml,
     '<a><b><c/></b><y><x/></y><d><e/><f/><g/><h><i><j/></i></h></d></a>';
  
    is_deeply [$c, $x, $e, $f, $g, $j], [$a->leaves];
    is_deeply [$a, $b, $y, $d, $h, $i], [$a->parentsPreOrder];
    is_deeply [$b, $y, $i, $h, $d, $a], [$a->parentsPostOrder];
    is_deeply [$a->parents],            [$a->parentsPostOrder];
  
    is_deeply [$a, $d, $h, $i, $y, $b], [$a->parentsReversePreOrder];
    is_deeply [$i, $h, $d, $y, $b, $a], [$a->parentsReversePostOrder];
  
    ok !$j->parents;
  
    ok  $a->lastMost  == $j;
    ok !$a->prevMost;
    ok  $j->prevMost  == $g;
    ok  $i->prevMost  == $g;
    ok  $h->prevMost  == $g;
    ok  $g->prevMost  == $f;
    ok  $f->prevMost  == $e;
    ok  $e->prevMost  == $x;
    ok  $d->prevMost  == $x;
    ok  $x->prevMost  == $c;
    ok  $y->prevMost  == $c;
    ok !$c->prevMost;
    ok !$b->prevMost;
    ok !$a->prevMost;
  
    ok  $a->firstMost == $c;
    ok  $a->nextMost  == $c;
    ok  $b->nextMost  == $c;
    ok  $c->nextMost  == $x;
    ok  $y->nextMost  == $x;
    ok  $x->nextMost  == $e;
    ok  $d->nextMost  == $e;
    ok  $e->nextMost  == $f;
    ok  $f->nextMost  == $g;
    ok  $g->nextMost  == $j;
    ok  $h->nextMost  == $j;
    ok  $i->nextMost  == $j;
    ok !$j->nextMost;
  
    ok  $i->topMost   == $a;
  

=head2 brackets($tree, $print, $separator)

Bracketed string representation of a tree.

     Parameter   Description
  1  $tree       Tree
  2  $print      Optional print method
  3  $separator  Optional child separator

B<Example:>


    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j, $x, $y) =
      fromLetters 'b(c)y(x)d(efgh(i(j)))';
  
    is_deeply $a->print, <<END;
  Key        Value
  a
    b
      c
    y
      x
    d
      e
      f
      g
      h
        i
          j
  END
  
    is_deeply $a->xml,
     '<a><b><c/></b><y><x/></y><d><e/><f/><g/><h><i><j/></i></h></d></a>';
  
    is_deeply [$c, $x, $e, $f, $g, $j], [$a->leaves];
    is_deeply [$a, $b, $y, $d, $h, $i], [$a->parentsPreOrder];
    is_deeply [$b, $y, $i, $h, $d, $a], [$a->parentsPostOrder];
    is_deeply [$a->parents],            [$a->parentsPostOrder];
  
    is_deeply [$a, $d, $h, $i, $y, $b], [$a->parentsReversePreOrder];
    is_deeply [$i, $h, $d, $y, $b, $a], [$a->parentsReversePostOrder];
  
    ok !$j->parents;
  
    ok  $a->lastMost  == $j;
    ok !$a->prevMost;
    ok  $j->prevMost  == $g;
    ok  $i->prevMost  == $g;
    ok  $h->prevMost  == $g;
    ok  $g->prevMost  == $f;
    ok  $f->prevMost  == $e;
    ok  $e->prevMost  == $x;
    ok  $d->prevMost  == $x;
    ok  $x->prevMost  == $c;
    ok  $y->prevMost  == $c;
    ok !$c->prevMost;
    ok !$b->prevMost;
    ok !$a->prevMost;
  
    ok  $a->firstMost == $c;
    ok  $a->nextMost  == $c;
    ok  $b->nextMost  == $c;
    ok  $c->nextMost  == $x;
    ok  $y->nextMost  == $x;
    ok  $x->nextMost  == $e;
    ok  $d->nextMost  == $e;
    ok  $e->nextMost  == $f;
    ok  $f->nextMost  == $g;
    ok  $g->nextMost  == $j;
    ok  $h->nextMost  == $j;
    ok  $i->nextMost  == $j;
    ok !$j->nextMost;
  
    ok  $i->topMost   == $a;
  

=head2 xml($tree, $print)

Print a tree as as xml.

     Parameter  Description
  1  $tree      Tree
  2  $print     Optional print method

B<Example:>


    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j, $x, $y) =
      fromLetters 'b(c)y(x)d(efgh(i(j)))';
  
    is_deeply $a->print, <<END;
  Key        Value
  a
    b
      c
    y
      x
    d
      e
      f
      g
      h
        i
          j
  END
  
  
    is_deeply $a->xml,  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     '<a><b><c/></b><y><x/></y><d><e/><f/><g/><h><i><j/></i></h></d></a>';
  
    is_deeply [$c, $x, $e, $f, $g, $j], [$a->leaves];
    is_deeply [$a, $b, $y, $d, $h, $i], [$a->parentsPreOrder];
    is_deeply [$b, $y, $i, $h, $d, $a], [$a->parentsPostOrder];
    is_deeply [$a->parents],            [$a->parentsPostOrder];
  
    is_deeply [$a, $d, $h, $i, $y, $b], [$a->parentsReversePreOrder];
    is_deeply [$i, $h, $d, $y, $b, $a], [$a->parentsReversePostOrder];
  
    ok !$j->parents;
  
    ok  $a->lastMost  == $j;
    ok !$a->prevMost;
    ok  $j->prevMost  == $g;
    ok  $i->prevMost  == $g;
    ok  $h->prevMost  == $g;
    ok  $g->prevMost  == $f;
    ok  $f->prevMost  == $e;
    ok  $e->prevMost  == $x;
    ok  $d->prevMost  == $x;
    ok  $x->prevMost  == $c;
    ok  $y->prevMost  == $c;
    ok !$c->prevMost;
    ok !$b->prevMost;
    ok !$a->prevMost;
  
    ok  $a->firstMost == $c;
    ok  $a->nextMost  == $c;
    ok  $b->nextMost  == $c;
    ok  $c->nextMost  == $x;
    ok  $y->nextMost  == $x;
    ok  $x->nextMost  == $e;
    ok  $d->nextMost  == $e;
    ok  $e->nextMost  == $f;
    ok  $f->nextMost  == $g;
    ok  $g->nextMost  == $j;
    ok  $h->nextMost  == $j;
    ok  $i->nextMost  == $j;
    ok !$j->nextMost;
  
    ok  $i->topMost   == $a;
  

=head1 Data Structures

Data structures use by this package.


=head2 Tree::Ops Definition


Child in the tree.




=head3 Output fields


=head4 children

Children of this child.

=head4 key

Key for this child - any thing that can be compared with the L<smartmatch|https://perldoc.perl.org/perlop.html#Smartmatch-Operator> operator.

=head4 lastChild

Last active child chain - enables us to find the currently open scope from the start if the tree.

=head4 parent

Parent for this child.

=head4 value

Value for this child.



=head1 Private Methods

=head2 setParentOfChild($child, $parent)

Set the parent of a child and return the child.

     Parameter  Description
  1  $child     Child
  2  $parent    Parent

=head2 indexOfChildInParent($child)

Get the index of a child within the specified parent.

     Parameter  Description
  1  $child     Child

=head2 parentsOrdered($tree, $preorder, $reverse)

The set of all parents in the tree, i.e. each non leaf of the tree, i.e  the interior of the tree in the specified order.

     Parameter  Description
  1  $tree      Tree
  2  $preorder  Pre-order if true else post-order
  3  $reverse   Reversed if true

=head2 printTree($tree, $print, $preorder, $reverse)

String representation as a horizontal tree.

     Parameter  Description
  1  $tree      Tree
  2  $print     Optional print method
  3  $preorder  Pre-order
  4  $reverse   Reverse


=head1 Index


1 L<above|/above> - Return the first child if it is above the second child else return B<undef>.

2 L<activeScope|/activeScope> - Locate the active scope in a tree.

3 L<after|/after> - Return the first child if it occurs strictly after the second child in the tree or else B<undef> if the first child is L<above|/"above($first, $second)">, L<below|/"below($first, $second)"> or L<before|/"before($first, $second)"> the second child.

4 L<before|/before> - Return the first child if it occurs strictly before the second child in the tree or else B<undef> if the first child is L<above|/"above($first, $second)">, L<below|/"below($first, $second)"> or L<after|/"after($first, $second)"> the second child.

5 L<below|/below> - Return the first child if it is below the second child else return B<undef>.

6 L<brackets|/brackets> - Bracketed string representation of a tree.

7 L<by|/by> - Traverse a tree in post-order to process each child with the specified sub and return an array of the results of processing each child.

8 L<close|/close> - Close the current scope returning to the previous scope.

9 L<context|/context> - Get the context of the current child.

10 L<cut|/cut> - Cut out a child and all its content and children, return it ready for reinsertion else where.

11 L<dup|/dup> - Duplicate a specified parent and all its descendants returning the root of the resulting tree.

12 L<empty|/empty> - Return the specified parent if it has no children else B<undef>

13 L<first|/first> - Get the first child under the specified parent.

14 L<firstMost|/firstMost> - Return the first most descendant child in the tree starting at this parent or else return B<undef> if this parent has no children.

15 L<fromLetters|/fromLetters> - Create a tree from a string of letters returning the children created in alphabetic order  - useful for testing.

16 L<go|/go> - Return the child at the end of the path starting at the specified parent.

17 L<include|/include> - Include the specified tree in the currently open scope.

18 L<indexOfChildInParent|/indexOfChildInParent> - Get the index of a child within the specified parent.

19 L<isFirst|/isFirst> - Return the specified child if that child is first under its parent, else return B<undef>.

20 L<isLast|/isLast> - Return the specified child if that child is last under its parent, else return B<undef>.

21 L<isTop|/isTop> - Return the specified parent if that parent is the top most parent in the tree.

22 L<last|/last> - Get the last child under the specified parent.

23 L<lastMost|/lastMost> - Return the last most descendant child in the tree starting at this parent or else return B<undef> if this parent has no children.

24 L<leaves|/leaves> - The set of all children without further children, i.

25 L<lineage|/lineage> - Return the path from the specified child to the specified ancestor else return B<undef> if the child is not a descendant of the ancestor.

26 L<merge|/merge> - Unwrap the children of the specified parent with the whose L<key|/"key"> fields L<smartmatch|https://perldoc.perl.org/perlop.html#Smartmatch-Operator> that of their parent.

27 L<mergeLikeNext|/mergeLikeNext> - Merge the following sibling of the specified child  if that sibling exists and the L<key|/"key"> data of the two siblings L<smartmatch|https://perldoc.perl.org/perlop.html#Smartmatch-Operator>.

28 L<mergeLikePrev|/mergeLikePrev> - Merge the preceding sibling of the specified child  if that sibling exists and the L<key|/"key"> data of the two siblings L<smartmatch|https://perldoc.perl.org/perlop.html#Smartmatch-Operator>.

29 L<mostRecentCommonAncestor|/mostRecentCommonAncestor> - Find the most recent common ancestor of the specified children.

30 L<new|/new> - Create a new child optionally recording the specified key or value.

31 L<next|/next> - Get the next sibling following the specified child.

32 L<nextMost|/nextMost> - Return the next child with no children, i.

33 L<nextPostOrderPath|/nextPostOrderPath> - Return a list of children visited between the specified child and the next child in post-order.

34 L<nextPreOrderPath|/nextPreOrderPath> - Return a list of children visited between the specified child and the next child in pre-order.

35 L<open|/open> - Add a child and make it the currently active scope into which new children will be added.

36 L<parents|/parents> - The set of all parents in the tree, i.

37 L<parentsOrdered|/parentsOrdered> - The set of all parents in the tree, i.

38 L<parentsPostOrder|/parentsPostOrder> - The set of all parents in the tree, i.

39 L<parentsPreOrder|/parentsPreOrder> - The set of all parents in the tree, i.

40 L<parentsReversePostOrder|/parentsReversePostOrder> - The set of all parents in the tree, i.

41 L<parentsReversePreOrder|/parentsReversePreOrder> - The set of all parents in the tree, i.

42 L<path|/path> - Return the list of zero based child indexes for the path from the root of the tree containing the specified child to the specified child for use by the L<go|/"go($parent, @path)"> method.

43 L<pathFrom|/pathFrom> - Return the list of zero based child indexes for the path from the specified ancestor to the specified child for use by the L<go|/"go($parent, @path)"> method else confess if the ancestor is not, in fact, an ancestor.

44 L<prev|/prev> - Get the previous sibling of the specified child.

45 L<prevMost|/prevMost> - Return the previous child with no children, i.

46 L<prevPostOrderPath|/prevPostOrderPath> - Return a list of children visited between the specified child and the previous child in post-order.

47 L<prevPreOrderPath|/prevPreOrderPath> - Return a list of children visited between the specified child and the previous child in pre-order.

48 L<print|/print> - Print tree in normal pre-order.

49 L<printPostOrder|/printPostOrder> - Print tree in normal post-order.

50 L<printPreOrder|/printPreOrder> - Print tree in normal pre-order.

51 L<printReversePostOrder|/printReversePostOrder> - Print tree in reverse post-order

52 L<printReversePreOrder|/printReversePreOrder> - Print tree in reverse pre-order

53 L<printTree|/printTree> - String representation as a horizontal tree.

54 L<putFirst|/putFirst> - Place a new child first under the specified parent and return the child.

55 L<putLast|/putLast> - Place a new child last under the specified parent and return the child.

56 L<putNext|/putNext> - Place a new child after the specified child.

57 L<putPrev|/putPrev> - Place a new child before the specified child.

58 L<select|/select> - Select matching children in a tree in post-order.

59 L<setParentOfChild|/setParentOfChild> - Set the parent of a child and return the child.

60 L<siblingsAfter|/siblingsAfter> - Return a list of siblings after the specified child.

61 L<siblingsBefore|/siblingsBefore> - Return a list of siblings before the specified child.

62 L<siblingsStrictlyBetween|/siblingsStrictlyBetween> - Return a list of the siblings strictly between two children of the same parent else return B<undef>.

63 L<single|/single> - Add one child in the current scope.

64 L<singleChildOfParent|/singleChildOfParent> - Return the only child of this parent if the parent has an only child, else B<undef>

65 L<split|/split> - Make the specified parent a grandparent of each of its children by interposing a copy of the specified parent between the specified parent and each of its children.

66 L<step|/step> - Make the first child of the specified parent the parents previous sibling and return the parent.

67 L<stepBack|/stepBack> - Make the previous sibling of the specified parent the parents first child and return the parent.

68 L<stepEnd|/stepEnd> - Make the next sibling of the specified parent the parents last child and return the parent.

69 L<stepEndBack|/stepEndBack> - Make the last child of the specified parent the parents next sibling and return the parent.

70 L<topMost|/topMost> - Return the top most parent in the tree containing the specified child.

71 L<transcribe|/transcribe> - Duplicate a specified parent and all its descendants recording the mapping in a temporary {transcribed} field in the tree being transcribed.

72 L<unwrap|/unwrap> - Unwrap the specified child and return that child.

73 L<wrap|/wrap> - Wrap the specified child with a new parent and return the new parent optionally setting its L<key|/"key"> and L<value|/"value">.

74 L<wrapChildren|/wrapChildren> - Wrap the children of the specified parent with a new intermediate parent that becomes the child of the specified parent, optionally setting the L<key|/"key"> and the L<value|/"value"> for the new parent.

75 L<xml|/xml> - Print a tree as as xml.

=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read,
comprehend, use, modify and install via B<cpan>:

  sudo cpan install Tree::Ops

=head1 Author

L<philiprbrenan@gmail.com|mailto:philiprbrenan@gmail.com>

L<http://www.appaapps.com|http://www.appaapps.com>

=head1 Copyright

Copyright (c) 2016-2019 Philip R Brenan.

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
use warnings FATAL=>qw(all);
use strict;
require v5.26;
use Time::HiRes qw(time);
use Test::More tests => 217;

my $startTime = time();
my $localTest = ((caller(1))[0]//'Tree::Ops') eq "Tree::Ops";                   # Local testing mode
Test::More->builder->output("/dev/null") if $localTest;                         # Suppress output in local testing mode
makeDieConfess;

#goto latestTest;

if (1) {                                                                        #Tnew #Topen #Tsingle #Tclose #Tselect #TactiveScope
  my $a = Tree::Ops::new 'a', 'A';
  for(1..2)
   {$a->open  ('b', "B$_");
    $a->single('c', "C$_");
    ok $a->activeScope->key eq 'b';
    $a->close;
   }
  $a->single  ('d', 'D');
  $a->single  ('e', 'E');
  is_deeply $a->print, <<END;
Key    Value
a      A
  b    B1
    c  C1
  b    B2
    c  C2
  d    D
  e    E
END

  is_deeply [map{$_->value} $a->by], [qw(C1 B1 C2 B2 D E A)];

  is_deeply $a->lastMost->prev->prev->first->key,           'c';
  is_deeply $a->first->next->last->parent->first->value,    'C2';

  is_deeply [map{$_->value} $a->select('b')],               [qw(B1 B2)];
  is_deeply [map{$_->value} $a->select(qr(b|c))],           [qw(B1 C1 B2 C2)];
  is_deeply [map{$_->value} $a->select(sub{$_[0] eq 'd'})], [qw(D)];

  $a->first->next->stepEnd->stepEnd->first->next->stepBack;
  is_deeply $a->print, <<END;
Key      Value
a        A
  b      B1
    c    C1
  b      B2
    d    D
      c  C2
    e    E
END
 }

if (1) {                                                                        #TfromLetters
  my ($a) = fromLetters(q(bc(d)e));

  is_deeply $a->print, <<END;
Key    Value
a
  b
  c
    d
  e
END
 }

if (1) {
  my $a = Tree::Ops::new('a');  is_deeply $a->key, 'a';
  my $b = $a->open      ('b');  is_deeply $b->key, 'b';
  my $c = $a->single    ('c');  is_deeply $c->key, 'c';
  my $B = $a->close;            is_deeply $B->brackets, 'b(c)'; ok $b == $B;
  my $d = $a->open      ('d');  is_deeply $d->key, 'd';
  my $e = $a->single    ('e');  is_deeply $e->key, 'e';
  my $f = $a->single    ('f');  is_deeply $f->key, 'f';
  my $g = $a->single    ('g');  is_deeply $g->key, 'g';
  my $h = $a->open      ('h');  is_deeply $h->key, 'h';
  my $i = $a->open      ('i');  is_deeply $i->key, 'i';
  my $j = $a->single    ('j');  is_deeply $j->key, 'j';

  is_deeply [map {$_->key} $a->select(['b', 'c'])],        ['b', 'c'];
  is_deeply [map {$_->key} $a->select({e=>1})],            ['e'];
  is_deeply [map {$_->key} $a->select(qr(b|d))],           ['b', 'd'];
  is_deeply [map {$_->key} $a->select(sub{$_[0] eq 'c'})], ['c'];

  is_deeply $a->brackets, 'a(b(c)d(efgh(i(j))))';
  is_deeply $b->parent,  $a;
  is_deeply $c->parent,  $b;
  is_deeply $d->parent,  $a;
  is_deeply $d->first,   $e;
  is_deeply $d->last,    $h;
  is_deeply $e->next,    $f;
  is_deeply $f->prev,    $e;

  ok !$c->first;
  ok !$e->last;
  ok !$h->next;
  ok !$e->prev;
 }

if (1) {                                                                        #Tparent #Tfirst #Tlast #Tnext #Tprev
  my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j) = fromLetters 'b(c)d(efgh(i(j)))';
  is_deeply $c->parent,   $b;
  is_deeply $a->first,    $b;
  is_deeply $a->last,     $d;
  is_deeply $e->next,     $f;
  is_deeply $f->prev,     $e;
 }

if (1) {                                                                        #TsingleChildOfParent #TisFirst #TisLast #TisTop #Tempty
  my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j) = fromLetters 'b(c)d(efgh(i(j)))';

  is_deeply $a->print, <<END;
Key        Value
a
  b
    c
  d
    e
    f
    g
    h
      i
        j
END

  is_deeply $b->singleChildOfParent, $c;
  is_deeply $e->isFirst, $e;
  ok !$f->isFirst;
  ok !$g->isLast;
  is_deeply $h->isLast, $h;
  ok  $j->empty;
  ok !$i->empty;
  ok  $a->isTop;
  ok !$b->isTop;
 }

if (1) {                                                                        #TputFirst #TputLast #TputNext #TputPrev
  my ($a, $b, $c, $d, $e) = fromLetters 'b(c)d(e)';

  is_deeply $a->print, <<END;
Key    Value
a
  b
    c
  d
    e
END

  my $z = $b->putNext(new 'z');
  is_deeply $a->print, <<END;
Key    Value
a
  b
    c
  z
  d
    e
END

  my $y = $d->putPrev(new 'y');
  is_deeply $a->print, <<END;
Key    Value
a
  b
    c
  z
  y
  d
    e
END

  $z->putLast(new 't');
  is_deeply $a->print, <<END;
Key    Value
a
  b
    c
  z
    t
  y
  d
    e
END

  $z->putFirst(new 's');
  is_deeply $a->print, <<END;
Key    Value
a
  b
    c
  z
    s
    t
  y
  d
    e
END
 }

if (1) {                                                                        #Tcut #Tcontext #Tby
  my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j, $s, $t, $x, $y, $z) =
    fromLetters 'b(c)y(x)z(st)d(efgh(i(j))))';

  is_deeply [$x->context], [$x, $y, $a];

  is_deeply join(' ', $a->by(sub{$_[0]->key})), "c b x y s t z e f g j i h d a";
  is_deeply join(' ', map{$_->key} $a->by),     "c b x y s t z e f g j i h d a";

  is_deeply $a->print, <<END;
Key        Value
a
  b
    c
  y
    x
  z
    s
    t
  d
    e
    f
    g
    h
      i
        j
END

  $z->cut;
  is_deeply $a->print, <<END;
Key        Value
a
  b
    c
  y
    x
  d
    e
    f
    g
    h
      i
        j
END
 }

if (1) {                                                                        #Tdup #Ttranscribe #Tgo #Tpath #TpathFrom
  my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j) = fromLetters 'b(cd(e(fg)h)i)j';

  is_deeply $a->print, <<END;
Key        Value
a
  b
    c
    d
      e
        f
        g
      h
    i
  j
END

  ok $a->go(0,1,0,1) == $g;
  ok $d->go(0,0)     == $f;

  is_deeply [$e->path],         [0,1,0];
  is_deeply [$g->pathFrom($d)], [0,1];

  is_deeply $b->dup->print, <<END;
Key      Value
b
  c
  d
    e
      f
      g
    h
  i
END

  my $B = $b->transcribe;

  $b->by(sub
   {my ($c) = @_;
    my @path = $c->pathFrom($b);
    my $C = $B->go(@path);
    is_deeply $c->key, $C->key;
    is_deeply $c->{transcribedTo},   $C;
    is_deeply $C->{transcribedFrom}, $c;
   });

  is_deeply $B->print, <<END;
Key      Value
b
  c
  d
    e
      f
      g
    h
  i
END
 }

if (1) {                                                                        #Tunwrap #Twrap #TwrapChildren
  my ($a, $b, $c, $d, $e, $f, $g) = fromLetters 'b(c(de)f)g';

  is_deeply $a->print, <<END;
Key      Value
a
  b
    c
      d
      e
    f
  g
END

  $c->wrap('z');

  is_deeply $a->print, <<END;
Key        Value
a
  b
    z
      c
        d
        e
    f
  g
END

  $c->parent->unwrap;

  is_deeply $a->print, <<END;
Key      Value
a
  b
    c
      d
      e
    f
  g
END

  $c->wrapChildren("Z");

  is_deeply $a->print, <<END;
Key        Value
a
  b
    c
      Z
        d
        e
    f
  g
END
 }

if (1) {                                                                        #TsiblingsStrictlyBetween #TsiblingsBefore #TsiblingsAfter
  my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j) = fromLetters 'b(cde(f)ghi)j';
  is_deeply $a->print, <<END;
Key      Value
a
  b
    c
    d
    e
      f
    g
    h
    i
  j
END

  is_deeply [$d->siblingsStrictlyBetween($h)], [$e, $g];
  is_deeply [$d->siblingsAfter],               [$e, $g, $h, $i];
  is_deeply [$g->siblingsBefore],              [$c, $d, $e];
  eval {$e->siblingsStrictlyBetween($f)};
  ok $@ =~ m(Must be siblings);
 }

if (1) {                                                                        #Tbrackets #TfirstMost #TlastMost #TtopMost #TnextMost #TprevMost #Tprint #Txml #Tleaves #Tparents #TparentsPreOrder #TparentsPostOrder #TparentsReversePreOrder #TparentsReversePostOrder
  my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j, $x, $y) =
    fromLetters 'b(c)y(x)d(efgh(i(j)))';

  is_deeply $a->print, <<END;
Key        Value
a
  b
    c
  y
    x
  d
    e
    f
    g
    h
      i
        j
END

  is_deeply $a->xml,
   '<a><b><c/></b><y><x/></y><d><e/><f/><g/><h><i><j/></i></h></d></a>';

  is_deeply [$c, $x, $e, $f, $g, $j], [$a->leaves];
  is_deeply [$a, $b, $y, $d, $h, $i], [$a->parentsPreOrder];
  is_deeply [$b, $y, $i, $h, $d, $a], [$a->parentsPostOrder];
  is_deeply [$a->parents],            [$a->parentsPostOrder];

  is_deeply [$a, $d, $h, $i, $y, $b], [$a->parentsReversePreOrder];
  is_deeply [$i, $h, $d, $y, $b, $a], [$a->parentsReversePostOrder];

  ok !$j->parents;

  ok  $a->lastMost  == $j;
  ok !$a->prevMost;
  ok  $j->prevMost  == $g;
  ok  $i->prevMost  == $g;
  ok  $h->prevMost  == $g;
  ok  $g->prevMost  == $f;
  ok  $f->prevMost  == $e;
  ok  $e->prevMost  == $x;
  ok  $d->prevMost  == $x;
  ok  $x->prevMost  == $c;
  ok  $y->prevMost  == $c;
  ok !$c->prevMost;
  ok !$b->prevMost;
  ok !$a->prevMost;

  ok  $a->firstMost == $c;
  ok  $a->nextMost  == $c;
  ok  $b->nextMost  == $c;
  ok  $c->nextMost  == $x;
  ok  $y->nextMost  == $x;
  ok  $x->nextMost  == $e;
  ok  $d->nextMost  == $e;
  ok  $e->nextMost  == $f;
  ok  $f->nextMost  == $g;
  ok  $g->nextMost  == $j;
  ok  $h->nextMost  == $j;
  ok  $i->nextMost  == $j;
  ok !$j->nextMost;

  ok  $i->topMost   == $a;
 }

if (1) {
  my ($a, $b, $c, $d, $e, $f, $g, $h) = fromLetters 'bc(d(e))f(g(h))';
  is_deeply $a->print, <<END;
Key      Value
a
  b
  c
    d
      e
  f
    g
      h
END

  is_deeply [$b, $e, $h], [$a->leaves];
  is_deeply $g->key, 'g';

  ok  $a->nextMost == $b;
  ok  $b->nextMost == $e;
  ok  $c->nextMost == $e;
  ok  $d->nextMost == $e;
  ok  $e->nextMost == $h;
  ok  $f->nextMost == $h;
  ok  $g->nextMost == $h;
  ok !$h->nextMost;

  ok !$a->prevMost;
  ok !$b->prevMost;
  ok  $c->prevMost == $b;
  ok  $d->prevMost == $b;
  ok  $e->prevMost == $b;
  ok  $f->prevMost == $e;
  ok  $g->prevMost == $e;
  ok  $h->prevMost == $e
 }

if (1) {                                                                        #Tstep #TstepBack #TstepEnd #TstepEndBack
  my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j) = fromLetters 'b(c)d(efgh(i(j)))';

  is_deeply $a->brackets, 'a(b(c)d(efgh(i(j))))';

  $d->step;
  is_deeply $a->brackets, 'a(b(c)ed(fgh(i(j))))';

  $d->stepBack;
  is_deeply $a->brackets, 'a(b(c)d(efgh(i(j))))';

  $b->stepEnd;
  is_deeply $a->brackets, 'a(b(cd(efgh(i(j)))))';

  $b->stepEndBack;
  is_deeply $a->brackets, 'a(b(c)d(efgh(i(j))))';
 }

if (1) {                                                                        #Tabove #Tbelow #Tbefore #Tafter #Tlineage
  my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j, $k, $l, $m, $n) =
    fromLetters('b(c(d(efgh(i(j)k)l)m)n');

  is_deeply $a->print, <<END;
Key            Value
a
  b
    c
      d
        e
        f
        g
        h
          i
            j
          k
        l
      m
    n
END

  ok  $c->above($j)  == $c;
  ok !$m->above($j);

  ok  $i->below($b)  == $i;
  ok !$i->below($n);

  ok  $n->after($e)  == $n;
  ok !$k->after($c);

  ok  $c->before($n) == $c;
  ok !$c->before($m);

  is_deeply [map{$_->key} $j->lineage($d)], [qw(j i h d)];
  ok !$d->lineage($m);
 }

if (1) {                                                                        #TmostRecentCommonAncestor
  my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j, $k) =
    fromLetters 'b(c(d(e))f(g(h)i)j)k';

  is_deeply $a->print, <<END;
Key        Value
a
  b
    c
      d
        e
    f
      g
        h
      i
    j
  k
END

  ok $e->mostRecentCommonAncestor($h) == $b;
  ok $e->mostRecentCommonAncestor($k) == $a;
 }

if (1) {                                                                        #Tsplit #Tmerge #TmergeLikeNext #TmergeLikePrev
  my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j) = fromLetters 'b(c)d(efgh(i(j)))';

  is_deeply $a->print, <<END;
Key        Value
a
  b
    c
  d
    e
    f
    g
    h
      i
        j
END

  $d->split;
  is_deeply $a->print, <<END;
Key          Value
a
  b
    c
  d
    d
      e
    d
      f
    d
      g
    d
      h
        i
          j
END

  $f->parent->mergeLikePrev;
  is_deeply $a->print, <<END;
Key          Value
a
  b
    c
  d
    d
      e
      f
    d
      g
    d
      h
        i
          j
END

  $g->parent->mergeLikeNext;
  is_deeply $a->print, <<END;
Key          Value
a
  b
    c
  d
    d
      e
      f
    d
      g
      h
        i
          j
END

  $d->merge;
  is_deeply $a->print, <<END;
Key        Value
a
  b
    c
  d
    e
    f
    g
    h
      i
        j
END
 }

if (1) {                                                                        #TnextPreOrderPath
  my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j, $k, $l, $m, $n, $o, $p, $q, $r) =
    fromLetters 'b(c(d(e(fg)hi(j(kl)m)n)op)q)r';
  my @p = [$a];

  for(1..99)
   {my @n = $p[-1][-1]->nextPreOrderPath;
    last unless @n;
    push @p, [@n];
   }

  is_deeply $a->print, <<END;
Key            Value
a
  b
    c
      d
        e
          f
          g
        h
        i
          j
            k
            l
          m
        n
      o
      p
    q
  r
END

  my @pre = map{[map{$_->key} @$_]} @p;
  is_deeply scalar(@pre), scalar(['a'..'r']->@*);
  is_deeply [@pre],
   [["a"],
    ["b"],
    ["c"],
    ["d"],
    ["e"],
    ["f"],
    ["g"],
    ["e", "h"],
    ["i"],
    ["j"],
    ["k"],
    ["l"],
    ["j", "m"],
    ["i", "n"],
    ["d", "o"],
    ["p"],
    ["c", "q"],
    ["b", "r"]];
 }

if (1) {                                                                        #TprevPreOrderPath
  my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j, $k, $l, $m, $n, $o, $p, $q, $r) =
    fromLetters 'b(c(d(e(fg)hi(j(kl)m)n)op)q)r';

  my @n = $a;
  my @p;
  for(1..99)
   {@n = $n[-1]->prevPreOrderPath;
    last unless @n;
    push @p, [@n];
    last if $n[-1] == $a;
   }

  is_deeply $a->print, <<END;
Key            Value
a
  b
    c
      d
        e
          f
          g
        h
        i
          j
            k
            l
          m
        n
      o
      p
    q
  r
END

  my @pre = map{[map{$_->key} @$_]} @p;
  is_deeply scalar(@pre), scalar(['a'..'r']->@*);
  is_deeply [@pre],
   [["r"],
    ["b", "q"],
    ["c", "p"],
    ["o"],
    ["d", "n"],
    ["i", "m"],
    ["j", "l"],
    ["k"],
    ["j"],
    ["i"],
    ["h"],
    ["e", "g"],
    ["f"],
    ["e"],
    ["d"],
    ["c"],
    ["b"],
    ["a"]];
 }

latestTest:;

if (1) {                                                                        #TnextPostOrderPath
  my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j, $k, $l, $m, $n, $o, $p, $q, $r) =
    fromLetters 'b(c(d(e(fg)hi(j(kl)m)n)op)q)r';

  my @n = $a;
  my @p;
  for(1..99)
   {@n = $n[-1]->nextPostOrderPath;
    last unless @n;
    push @p, [@n];
    last if $n[-1] == $a;
   }

  is_deeply $a->print, <<END;
Key            Value
a
  b
    c
      d
        e
          f
          g
        h
        i
          j
            k
            l
          m
        n
      o
      p
    q
  r
END

  my @post = map{[map{$_->key} @$_]} @p;
  is_deeply scalar(@post), scalar(['a'..'r']->@*);
  is_deeply [@post],
 [["b" .. "f"],
  ["g"],
  ["e"],
  ["h"],
  ["i", "j", "k"],
  ["l"],
  ["j"],
  ["m"],
  ["i"],
  ["n"],
  ["d"],
  ["o"],
  ["p"],
  ["c"],
  ["q"],
  ["b"],
  ["r"],
  ["a"]];
 }

if (1) {                                                                        #TprevPostOrderPath
  my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j, $k, $l, $m, $n, $o, $p, $q, $r) =
    fromLetters 'b(c(d(e(fg)hi(j(kl)m)n)op)q)r';
  my @p = [$a];

  for(1..99)
   {my @n = $p[-1][-1]->prevPostOrderPath;
    last unless @n;
    push @p, [@n];
   }

  is_deeply $a->print, <<END;
Key            Value
a
  b
    c
      d
        e
          f
          g
        h
        i
          j
            k
            l
          m
        n
      o
      p
    q
  r
END

  my @post = map{[map{$_->key} @$_]} @p;
  is_deeply scalar(@post), scalar(['a'..'r']->@*);
  is_deeply [@post],
   [["a"],
    ["r"],
    ["b"],
    ["q"],
    ["c"],
    ["p"],
    ["o"],
    ["d"],
    ["n"],
    ["i"],
    ["m"],
    ["j"],
    ["l"],
    ["k"],
    ["j", "i", "h"],
    ["e"],
    ["g"],
    ["f"]];
 }

if (1) {                                                                        #TprintPreOrder #TprintPostOrder #TprintReversePreOrder #TprintReversePostOrder
  my ($a, $b, $c, $d) = fromLetters 'b(c)d';
  my sub test(@) {join ' ', map{join '', $_->key} @_}

  is_deeply $a->printPreOrder, <<END;
Key    Value
a
  b
    c
  d
END

  is_deeply test($a->nextPreOrderPath), 'b';
  is_deeply test($b->nextPreOrderPath), 'c';
  is_deeply test($c->nextPreOrderPath), 'b d';
  is_deeply test($d->nextPreOrderPath), '';

  is_deeply $a->printPostOrder, <<END;
Key    Value
    c
  b
  d
a
END

  is_deeply test($a->nextPostOrderPath), 'b c';
  is_deeply test($c->nextPostOrderPath), 'b';
  is_deeply test($b->nextPostOrderPath), 'd';
  is_deeply test($d->nextPostOrderPath), 'a';

  is_deeply $a->printReversePreOrder, <<END;
Key    Value
a
  d
  b
    c
END
  is_deeply test($a->prevPreOrderPath), 'd';
  is_deeply test($d->prevPreOrderPath), 'b c';
  is_deeply test($c->prevPreOrderPath), 'b';
  is_deeply test($b->prevPreOrderPath), 'a';

  is_deeply $a->printReversePostOrder, <<END;
Key    Value
  d
    c
  b
a
END

  is_deeply test($a->prevPostOrderPath), 'd';
  is_deeply test($d->prevPostOrderPath), 'b';
  is_deeply test($b->prevPostOrderPath), 'c';
  is_deeply test($c->prevPostOrderPath), '';
 }

if (1) {                                                                        #Tinclude
  my ($i) = fromLetters 'b(cd)';

  my $a = Tree::Ops::new 'A';
     $a->open ('B');
     $a->include($i);
     $a->close;

  is_deeply $a->print, <<END;
Key        Value
A
  B
    a
      b
        c
        d
END
 }

done_testing;

if ($localTest)
 {say "TO finished in ", (time() - $startTime), " seconds";
 }

#   owf(q(/home/phil/z/z/z/zzz.txt), $dfa->dumpAsJson);

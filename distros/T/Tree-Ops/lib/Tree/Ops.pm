#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib
#-------------------------------------------------------------------------------
# Tree operations
# Philip R Brenan at gmail dot com, Appa Apps Ltd Inc., 2020
#-------------------------------------------------------------------------------
# podDocumentation
package Tree::Ops;
our $VERSION = 20200709;
require v5.26;
use warnings FATAL => qw(all);
use strict;
use Carp qw(confess cluck);
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

sub activeScope($)                                                              #P Locate the active scope in a tree.
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

sub fromLetters($)                                                              # Create a tree from a string of letters - useful for testing.
 {my ($letters) = @_;                                                           # String of letters and ( ).
  my $t = new(my $s = 'a');
  my @l = split //, $letters;
  my @c;
  for my $l(split(//, $letters), '')
   {my $c = shift @c;
    if    ($l eq '(') {$t->open  ($c) if $c}
    elsif ($l eq ')') {$t->single($c) if $c; $t->close}
    else              {$t->single($c) if $c; @c = $l}
   }
  $t
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
  confess 'Child not found in parent'
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
 {my ($parent) = @_;                                                            # Child
  my $f;
  for(my $p = $parent; $p; $p = $p->first) {$f = $p}                            # Go first most
  $f
 }

sub lastMost($)                                                                 # Return the last most descendant child in the tree starting at this parent or else return B<undef> if this parent has no children.
 {my ($parent) = @_;                                                            # Child
  my $f;
  for(my $p = $parent; $p; $p = $p->last) {$f = $p}                             # Go last most
  $f
 }

sub mostRecentCommonAncestor($$)                                                # Find the most recent common ancestor of the specified children.
 {my ($first, $second) = @_;                                                    # First child, second child
  return $first if $first == $second;                                           # Same first and second child
  my @f = context $first;                                                       # Context of first child
  my @s = context $second;                                                      # Context of second child
  my $c; $c = pop @f, pop @s while @f and @s and $f[-1] == $s[-1];              # Remove common ancestors
  $c
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
  splice $child->parent->children->@*, indexOfChildInParent($child), 1;          # Remove child
  $child
 }

sub dup($)                                                                      # Duplicate a parent and all its descendants.
 {my ($parent) = @_;                                                            # Parent

  sub                                                                           # Duplicate a child
   {my ($old)  = @_;                                                            # Existing child
    my $new    = new $old->key;                                                # New child
    push $new->children->@*, __SUB__->($_) for $old->children->@*;              # Duplicate children of child
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

sub wrap($$)                                                                    # Wrap the specified child with a new parent and return the new parent.
 {my ($child, $key) = @_;                                                      # Child to wrap, user data for new wrapping parent
  return undef unless defined(my $i = indexOfChildInParent $child);             # Locate child within existing parent
  my $parent     = $child->parent;                                              # Existing parent
  my $new        = new $key;                                                   # Create new parent
  $new->parent   = $parent;                                                     # Parent new parent
  $new->children = [$child];                                                    # Set children for new parent
  splice $parent->children->@*, $i, 1, $new;                                    # Place new parent in existing parent
  $child->parent = $new                                                         # Reparent child to new parent
 }

sub merge($)                                                                    # Merge the children of the specified parent with those of the surrounding parents if the L<user> data of those parents L<smartmatch> that of the specified parent. Merged parents are unwrapped. Returns the specified parent regardless. From a proposal made by Micaela Monroe.
 {my ($parent) = @_;                                                            # Merging parent
  while(my $p = $parent->prev)                                                  # Preceding siblings of a parent
   {last unless $p->key ~~ $parent->key;                                      # Preceding parents that carry the same data
    putFirst $parent, cut $p;                                                   # Place merged parent first under merging parent
    unwrap $p;                                                                  # Unwrapped merged parent
   }
  while(my $p = $parent->next)                                                  # Following siblings of a parent
   {last unless $p->key ~~ $parent->key;                                      # Following parents that carry the same data
    putLast $parent, cut $p;                                                    # Place merged parent last under merging parent
    unwrap $p;                                                                  # Unwrap merged parent
   }
  $parent
 }

sub split($)                                                                    # Make the specified parent a grandparent of each of its children by interposing a copy of the specified parent between the specified parent and each of its children. Return the specified parent.
 {my ($parent) = @_;                                                            # Parent to make into a grand parent
  wrap $_, $parent->key for $parent->children->@*;                             # Grandparent each child
  $parent
 }

#D1 Traverse                                                                    # Traverse a tree.

sub by($;$)                                                                     # Traverse a tree in order to process each child with the specified sub and return an array of the results of processing each child. If no sub sub is specified, the children are returned in tree order.
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

sub select($$)                                                                  # Select matching children in a tree. A child can be selected via named value, array of values, a hash of values, a regular expression or a sub reference.
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

sub siblingsBefore($)                                                           # Return a list of siblings before the specified child.
 {my ($child) = @_;                                                             # Child
  my $i = indexOfChildInParent $child;                                          # Our position
  my $parent = $child->parent;                                                  # Parent
  my @c = $parent->children->@*;                                                # Children
  @c[0..$i-1]
 }

sub siblingsAfter($)                                                            # Return a list of siblings after the specified child.
 {my ($child) = @_;                                                             # Child
  my $i = indexOfChildInParent $child;                                          # Our position
  my $parent = $child->parent;                                                  # Parent
  my @c = $parent->children->@*;                                                # Children
  @c[$i+1, $#c]
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

sub after($$)                                                                   # Return the first child if it occurs strictly after the second child in the tree or else B<undef> if the first child is L<above>, L<below> or L<before> the second child.
 {my ($first, $second) = @_;                                                    # First child, second child
  my @f = context $first;                                                       # Context of first child
  my @s = context $second;                                                      # Context of second child
  pop @f, pop @s while @f and @s and $f[-1] == $s[-1];                          # Find first different ancestor
  return undef unless @f and @s;                                                # Not strictly after
  indexOfChildInParent($f[-1]) > indexOfChildInParent($s[-1]) ? $first : undef  # First child relative to second child at first common ancestor
 }

sub before($$)                                                                  # Return the first child if it occurs strictly before the second child in the tree or else B<undef> if the first child is L<above>, L<below> or L<after> the second child.
 {my ($first, $second) = @_;                                                    # First child, second child
  after($second, $first)  ? $first : undef
 }

#D1 Paths                                                                       # Find paths between nodes

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


Version 20200708.


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


=head2 fromLetters($letters)

Create a tree from a string of letters - useful for testing.

     Parameter  Description
  1  $letters   String of letters and ( ).

B<Example:>



    my $a = fromLetters(q(bc(d)e));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


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


    my %l = map{$_->key=>$_} fromLetters('b(c)d(efgh(i(j)))')->by;
    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j) = @l{'a'..'j'};
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


    my %l = map{$_->key=>$_} fromLetters('b(c)d(efgh(i(j)))')->by;
    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j) = @l{'a'..'j'};
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


    my %l = map{$_->key=>$_} fromLetters('b(c)d(efgh(i(j)))')->by;
    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j) = @l{'a'..'j'};
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


    my %l = map{$_->key=>$_} fromLetters('b(c)d(efgh(i(j)))')->by;
    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j) = @l{'a'..'j'};
    is_deeply $c->parent,   $b;
    is_deeply $a->first,    $b;
    is_deeply $a->last,     $d;
    is_deeply $e->next,     $f;

    is_deeply $f->prev,     $e;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲



=head2 firstMost($parent)

Return the first most descendant child in the tree starting at this parent or else return B<undef> if this parent has no children.

     Parameter  Description
  1  $parent    Child

B<Example:>


    my $a = fromLetters('b(c)y(x)d(efgh(i(j)))');
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


    is_deeply $a->firstMost->brackets, 'c';  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply $a-> lastMost->brackets, 'j';


=head2 lastMost($parent)

Return the last most descendant child in the tree starting at this parent or else return B<undef> if this parent has no children.

     Parameter  Description
  1  $parent    Child

B<Example:>


    my $a = fromLetters('b(c)y(x)d(efgh(i(j)))');
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

    is_deeply $a->firstMost->brackets, 'c';

    is_deeply $a-> lastMost->brackets, 'j';  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲



=head2 mostRecentCommonAncestor($first, $second)

Find the most recent common ancestor of the specified children.

     Parameter  Description
  1  $first     First child
  2  $second    Second child

B<Example:>


    my %l = map{$_->key=>$_} fromLetters('b(c(d(e))f(g(h)i)j)k')->by;
    my ($a, $b, $e, $h, $k) = @l{qw(a b e h k)};

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



=head1 Location

Verify the current location.

=head2 context($child)

Get the context of the current child.

     Parameter  Description
  1  $child     Child

B<Example:>


    my %l = map{$_->key=>$_} fromLetters('b(c)y(x)z(st)d(efgh(i(j))))')->by;
    my ($a, $x, $y, $z) = @l{qw(a x y z)};


    is_deeply [map {$_->key} $x->context], [qw(x y a)];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    is_deeply join(' ', $a->by(sub{$_[0]->key})), "c b x y s t z e f g j i h d a";
    is_deeply join(' ', map{$_->key} $a->by),     "c b x y s t z e f g j i h d a";

    $z->cut;
    is_deeply $a->brackets, 'a(b(c)y(x)d(efgh(i(j))))';

    $y->unwrap;
    is_deeply $a->brackets, 'a(b(c)xd(efgh(i(j))))';

    $y = $x->wrap('y');
    is_deeply $y->brackets, 'y(x)';
    is_deeply $a->brackets, 'a(b(c)y(x)d(efgh(i(j))))';

    $y->putNext($y->dup);
    is_deeply $a->brackets, 'a(b(c)y(x)y(x)d(efgh(i(j))))';


=head2 isFirst($child)

Return the specified child if that child is first under its parent, else return B<undef>.

     Parameter  Description
  1  $child     Child

B<Example:>


    my %l = map{$_->key=>$_} fromLetters('b(c)d(efgh(i(j)))')->by;
    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j) = @l{'a'..'j'};

    is_deeply $a->brackets, 'a(b(c)d(efgh(i(j))))';
    is_deeply $b->singleChildOfParent, $c;

    is_deeply $e->isFirst, $e;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    ok !$f->isFirst;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    ok !$g->isLast;
    is_deeply $h->isLast, $h;
    ok  $j->empty;
    ok !$i->empty;


=head2 isLast($child)

Return the specified child if that child is last under its parent, else return B<undef>.

     Parameter  Description
  1  $child     Child

B<Example:>


    my %l = map{$_->key=>$_} fromLetters('b(c)d(efgh(i(j)))')->by;
    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j) = @l{'a'..'j'};

    is_deeply $a->brackets, 'a(b(c)d(efgh(i(j))))';
    is_deeply $b->singleChildOfParent, $c;
    is_deeply $e->isFirst, $e;
    ok !$f->isFirst;

    ok !$g->isLast;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    is_deeply $h->isLast, $h;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    ok  $j->empty;
    ok !$i->empty;


=head2 singleChildOfParent($parent)

Return the only child of this parent if the parent has an only child, else B<undef>

     Parameter  Description
  1  $parent    Parent

B<Example:>


    my %l = map{$_->key=>$_} fromLetters('b(c)d(efgh(i(j)))')->by;
    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j) = @l{'a'..'j'};

    is_deeply $a->brackets, 'a(b(c)d(efgh(i(j))))';

    is_deeply $b->singleChildOfParent, $c;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply $e->isFirst, $e;
    ok !$f->isFirst;
    ok !$g->isLast;
    is_deeply $h->isLast, $h;
    ok  $j->empty;
    ok !$i->empty;


=head2 empty($parent)

Return the specified parent if it has no children else B<undef>

     Parameter  Description
  1  $parent    Parent

B<Example:>


    my %l = map{$_->key=>$_} fromLetters('b(c)d(efgh(i(j)))')->by;
    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j) = @l{'a'..'j'};

    is_deeply $a->brackets, 'a(b(c)d(efgh(i(j))))';
    is_deeply $b->singleChildOfParent, $c;
    is_deeply $e->isFirst, $e;
    ok !$f->isFirst;
    ok !$g->isLast;
    is_deeply $h->isLast, $h;

    ok  $j->empty;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    ok !$i->empty;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲



=head1 Put

Insert children into a tree.

=head2 putFirst($parent, $child)

Place a new child first under the specified parent and return the child.

     Parameter  Description
  1  $parent    Parent
  2  $child     Child

B<Example:>


    my %l = map{$_->key=>$_} fromLetters('b(c)d(e)')->by;
    my ($a, $b, $d) = @l{qw(a b d)};

    my $z = $b->putNext(new 'z');
    is_deeply $z->brackets, 'z';
    is_deeply $a->brackets, 'a(b(c)zd(e))';

    my $y = $d->putPrev(new 'y');
    is_deeply $y->brackets, 'y';
    is_deeply $a->brackets, 'a(b(c)zyd(e))';

    $z->putLast(new 't');
    is_deeply $z->brackets, 'z(t)';
    is_deeply $a->brackets, 'a(b(c)z(t)yd(e))';


    $z->putFirst(new 's');  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply $a->brackets, 'a(b(c)z(st)yd(e))';


=head2 putLast($parent, $child)

Place a new child last under the specified parent and return the child.

     Parameter  Description
  1  $parent    Parent
  2  $child     Child

B<Example:>


    my %l = map{$_->key=>$_} fromLetters('b(c)d(e)')->by;
    my ($a, $b, $d) = @l{qw(a b d)};

    my $z = $b->putNext(new 'z');
    is_deeply $z->brackets, 'z';
    is_deeply $a->brackets, 'a(b(c)zd(e))';

    my $y = $d->putPrev(new 'y');
    is_deeply $y->brackets, 'y';
    is_deeply $a->brackets, 'a(b(c)zyd(e))';


    $z->putLast(new 't');  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply $z->brackets, 'z(t)';
    is_deeply $a->brackets, 'a(b(c)z(t)yd(e))';

    $z->putFirst(new 's');
    is_deeply $a->brackets, 'a(b(c)z(st)yd(e))';


=head2 putNext($child, $new)

Place a new child after the specified child.

     Parameter  Description
  1  $child     Existing child
  2  $new       New child

B<Example:>


    my %l = map{$_->key=>$_} fromLetters('b(c)d(e)')->by;
    my ($a, $b, $d) = @l{qw(a b d)};


    my $z = $b->putNext(new 'z');  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply $z->brackets, 'z';
    is_deeply $a->brackets, 'a(b(c)zd(e))';

    my $y = $d->putPrev(new 'y');
    is_deeply $y->brackets, 'y';
    is_deeply $a->brackets, 'a(b(c)zyd(e))';

    $z->putLast(new 't');
    is_deeply $z->brackets, 'z(t)';
    is_deeply $a->brackets, 'a(b(c)z(t)yd(e))';

    $z->putFirst(new 's');
    is_deeply $a->brackets, 'a(b(c)z(st)yd(e))';


=head2 putPrev($child, $new)

Place a new child before the specified child.

     Parameter  Description
  1  $child     Child
  2  $new       New child

B<Example:>


    my %l = map{$_->key=>$_} fromLetters('b(c)d(e)')->by;
    my ($a, $b, $d) = @l{qw(a b d)};

    my $z = $b->putNext(new 'z');
    is_deeply $z->brackets, 'z';
    is_deeply $a->brackets, 'a(b(c)zd(e))';


    my $y = $d->putPrev(new 'y');  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply $y->brackets, 'y';
    is_deeply $a->brackets, 'a(b(c)zyd(e))';

    $z->putLast(new 't');
    is_deeply $z->brackets, 'z(t)';
    is_deeply $a->brackets, 'a(b(c)z(t)yd(e))';

    $z->putFirst(new 's');
    is_deeply $a->brackets, 'a(b(c)z(st)yd(e))';


=head1 Steps

Move the start or end of a scope forwards or backwards as suggested by Alex Monroe.

=head2 step($parent)

Make the first child of the specified parent the parents previous sibling and return the parent. In effect this moves the start of the parent one step forwards.

     Parameter  Description
  1  $parent    Parent

B<Example:>


    my %l = map{$_->key=>$_} fromLetters('b(c)d(efgh(i(j)))')->by;
    my ($a, $b, $d) = @l{qw(a b d)};

    is_deeply $a->brackets, 'a(b(c)d(efgh(i(j))))';


    $d->step;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply $a->brackets, 'a(b(c)ed(fgh(i(j))))';


    $d->stepBack;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply $a->brackets, 'a(b(c)d(efgh(i(j))))';


    $b->stepEnd;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply $a->brackets, 'a(b(cd(efgh(i(j)))))';


    $b->stepEndBack;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply $a->brackets, 'a(b(c)d(efgh(i(j))))';


=head2 stepEnd($parent)

Make the next sibling of the specified parent the parents last child and return the parent. In effect this moves the end of the parent one step forwards.

     Parameter  Description
  1  $parent    Parent

B<Example:>


    my %l = map{$_->key=>$_} fromLetters('b(c)d(efgh(i(j)))')->by;
    my ($a, $b, $d) = @l{qw(a b d)};

    is_deeply $a->brackets, 'a(b(c)d(efgh(i(j))))';

    $d->step;
    is_deeply $a->brackets, 'a(b(c)ed(fgh(i(j))))';

    $d->stepBack;
    is_deeply $a->brackets, 'a(b(c)d(efgh(i(j))))';


    $b->stepEnd;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply $a->brackets, 'a(b(cd(efgh(i(j)))))';


    $b->stepEndBack;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply $a->brackets, 'a(b(c)d(efgh(i(j))))';


=head2 stepBack()

Make the previous sibling of the specified parent the parents first child and return the parent. In effect this moves the start of the parent one step backwards.


B<Example:>


    my %l = map{$_->key=>$_} fromLetters('b(c)d(efgh(i(j)))')->by;
    my ($a, $b, $d) = @l{qw(a b d)};

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


    my %l = map{$_->key=>$_} fromLetters('b(c)d(efgh(i(j)))')->by;
    my ($a, $b, $d) = @l{qw(a b d)};

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


    my %l = map{$_->key=>$_} fromLetters('b(c)y(x)z(st)d(efgh(i(j))))')->by;
    my ($a, $x, $y, $z) = @l{qw(a x y z)};

    is_deeply [map {$_->key} $x->context], [qw(x y a)];

    is_deeply join(' ', $a->by(sub{$_[0]->key})), "c b x y s t z e f g j i h d a";
    is_deeply join(' ', map{$_->key} $a->by),     "c b x y s t z e f g j i h d a";


    $z->cut;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply $a->brackets, 'a(b(c)y(x)d(efgh(i(j))))';

    $y->unwrap;
    is_deeply $a->brackets, 'a(b(c)xd(efgh(i(j))))';

    $y = $x->wrap('y');
    is_deeply $y->brackets, 'y(x)';
    is_deeply $a->brackets, 'a(b(c)y(x)d(efgh(i(j))))';

    $y->putNext($y->dup);
    is_deeply $a->brackets, 'a(b(c)y(x)y(x)d(efgh(i(j))))';


=head2 dup($parent)

Duplicate a parent and all its descendants.

     Parameter  Description
  1  $parent    Parent

B<Example:>


    my %l = map{$_->key=>$_} fromLetters('b(c)y(x)z(st)d(efgh(i(j))))')->by;
    my ($a, $x, $y, $z) = @l{qw(a x y z)};

    is_deeply [map {$_->key} $x->context], [qw(x y a)];

    is_deeply join(' ', $a->by(sub{$_[0]->key})), "c b x y s t z e f g j i h d a";
    is_deeply join(' ', map{$_->key} $a->by),     "c b x y s t z e f g j i h d a";

    $z->cut;
    is_deeply $a->brackets, 'a(b(c)y(x)d(efgh(i(j))))';

    $y->unwrap;
    is_deeply $a->brackets, 'a(b(c)xd(efgh(i(j))))';

    $y = $x->wrap('y');
    is_deeply $y->brackets, 'y(x)';
    is_deeply $a->brackets, 'a(b(c)y(x)d(efgh(i(j))))';


    $y->putNext($y->dup);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply $a->brackets, 'a(b(c)y(x)y(x)d(efgh(i(j))))';


=head2 unwrap($child)

Unwrap the specified child and return that child.

     Parameter  Description
  1  $child     Child

B<Example:>


    my %l = map{$_->key=>$_} fromLetters('b(c)y(x)z(st)d(efgh(i(j))))')->by;
    my ($a, $x, $y, $z) = @l{qw(a x y z)};

    is_deeply [map {$_->key} $x->context], [qw(x y a)];

    is_deeply join(' ', $a->by(sub{$_[0]->key})), "c b x y s t z e f g j i h d a";
    is_deeply join(' ', map{$_->key} $a->by),     "c b x y s t z e f g j i h d a";

    $z->cut;
    is_deeply $a->brackets, 'a(b(c)y(x)d(efgh(i(j))))';


    $y->unwrap;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply $a->brackets, 'a(b(c)xd(efgh(i(j))))';

    $y = $x->wrap('y');
    is_deeply $y->brackets, 'y(x)';
    is_deeply $a->brackets, 'a(b(c)y(x)d(efgh(i(j))))';

    $y->putNext($y->dup);
    is_deeply $a->brackets, 'a(b(c)y(x)y(x)d(efgh(i(j))))';


=head2 wrap($child, $key)

Wrap the specified child with a new parent and return the new parent.

     Parameter  Description
  1  $child     Child to wrap
  2  $key       User data for new wrapping parent

B<Example:>


    my %l = map{$_->key=>$_} fromLetters('b(c)y(x)z(st)d(efgh(i(j))))')->by;
    my ($a, $x, $y, $z) = @l{qw(a x y z)};

    is_deeply [map {$_->key} $x->context], [qw(x y a)];

    is_deeply join(' ', $a->by(sub{$_[0]->key})), "c b x y s t z e f g j i h d a";
    is_deeply join(' ', map{$_->key} $a->by),     "c b x y s t z e f g j i h d a";

    $z->cut;
    is_deeply $a->brackets, 'a(b(c)y(x)d(efgh(i(j))))';


    $y->unwrap;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply $a->brackets, 'a(b(c)xd(efgh(i(j))))';


    $y = $x->wrap('y');  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply $y->brackets, 'y(x)';
    is_deeply $a->brackets, 'a(b(c)y(x)d(efgh(i(j))))';

    $y->putNext($y->dup);
    is_deeply $a->brackets, 'a(b(c)y(x)y(x)d(efgh(i(j))))';


=head2 merge($parent)

Merge the children of the specified parent with those of the surrounding parents if the L<user|https://en.wikipedia.org/wiki/User_(computing)> data of those parents L<smartmatch> that of the specified parent. Merged parents are unwrapped. Returns the specified parent regardless. From a proposal made by Micaela Monroe.

     Parameter  Description
  1  $parent    Merging parent

B<Example:>


    my %l = map{$_->key=>$_} fromLetters('b(c)d(efgh(i(j)))')->by;
    my ($a, $d) = @l{qw(a d)};

    $d->split;
    is_deeply $d->brackets,       'd(d(e)d(f)d(g)d(h(i(j))))';
    is_deeply $a->brackets, 'a(b(c)d(d(e)d(f)d(g)d(h(i(j)))))';


    $d->first->merge;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply $d->brackets,       'd(d(efgh(i(j))))';
    is_deeply $a->brackets, 'a(b(c)d(d(efgh(i(j)))))';

    $d->first->unwrap;
    is_deeply $d->brackets,       'd(efgh(i(j)))';
    is_deeply $a->brackets, 'a(b(c)d(efgh(i(j))))';


=head2 split($parent)

Make the specified parent a grandparent of each of its children by interposing a copy of the specified parent between the specified parent and each of its children. Return the specified parent.

     Parameter  Description
  1  $parent    Parent to make into a grand parent

B<Example:>


    my %l = map{$_->key=>$_} fromLetters('b(c)d(efgh(i(j)))')->by;
    my ($a, $d) = @l{qw(a d)};


    $d->split;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply $d->brackets,       'd(d(e)d(f)d(g)d(h(i(j))))';
    is_deeply $a->brackets, 'a(b(c)d(d(e)d(f)d(g)d(h(i(j)))))';

    $d->first->merge;
    is_deeply $d->brackets,       'd(d(efgh(i(j))))';
    is_deeply $a->brackets, 'a(b(c)d(d(efgh(i(j)))))';

    $d->first->unwrap;
    is_deeply $d->brackets,       'd(efgh(i(j)))';
    is_deeply $a->brackets, 'a(b(c)d(efgh(i(j))))';


=head1 Traverse

Traverse a tree.

=head2 by($tree, $sub)

Traverse a tree in order to process each child with the specified sub and return an array of the results of processing each child. If no sub sub is specified, the children are returned in tree order.

     Parameter  Description
  1  $tree      Tree
  2  $sub       Optional sub to process each child

B<Example:>



    my %l = map{$_->key=>$_} fromLetters('b(c)y(x)z(st)d(efgh(i(j))))')->by;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    my ($a, $x, $y, $z) = @l{qw(a x y z)};

    is_deeply [map {$_->key} $x->context], [qw(x y a)];


    is_deeply join(' ', $a->by(sub{$_[0]->key})), "c b x y s t z e f g j i h d a";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    is_deeply join(' ', map{$_->key} $a->by),     "c b x y s t z e f g j i h d a";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    $z->cut;
    is_deeply $a->brackets, 'a(b(c)y(x)d(efgh(i(j))))';

    $y->unwrap;
    is_deeply $a->brackets, 'a(b(c)xd(efgh(i(j))))';

    $y = $x->wrap('y');
    is_deeply $y->brackets, 'y(x)';
    is_deeply $a->brackets, 'a(b(c)y(x)d(efgh(i(j))))';

    $y->putNext($y->dup);
    is_deeply $a->brackets, 'a(b(c)y(x)y(x)d(efgh(i(j))))';


=head2 select($tree, $select)

Select matching children in a tree. A child can be selected via named value, array of values, a hash of values, a regular expression or a sub reference.

     Parameter  Description
  1  $tree      Tree
  2  $select    Method to select a child

B<Example:>


    my $a = Tree::Ops::new 'a', 'A';
    for(1..2)
     {$a->open  ('b', "B$_");
      $a->single('c', "C$_");
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


=head2 siblingsBefore($child)

Return a list of siblings before the specified child.

     Parameter  Description
  1  $child     Child

B<Example:>


    my ($c, $d, $e, $f, $g, $b, $a) = fromLetters('b(cdefg)')->by;

    ok eval qq(\$$_->key eq '$_') for 'a'..'g';

    is_deeply [map {$_->key} $e->siblingsBefore], ["c", "d"];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply [map {$_->key} $e->siblingsAfter ], ["f", "g"];


=head2 siblingsAfter($child)

Return a list of siblings after the specified child.

     Parameter  Description
  1  $child     Child

B<Example:>


    my ($c, $d, $e, $f, $g, $b, $a) = fromLetters('b(cdefg)')->by;

    ok eval qq(\$$_->key eq '$_') for 'a'..'g';
    is_deeply [map {$_->key} $e->siblingsBefore], ["c", "d"];

    is_deeply [map {$_->key} $e->siblingsAfter ], ["f", "g"];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲



=head1 Order

Check the order and relative position of children in a tree.

=head2 above($first, $second)

Return the first child if it is above the second child else return B<undef>.

     Parameter  Description
  1  $first     First child
  2  $second    Second child

B<Example:>


    my %l = map{$_->key=>$_} fromLetters('b(c(d(efgh(i(j)k)l)m)n')->by;
    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j, $k, $l, $m, $n) = @l{'a'..'n'};

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


=head2 below($first, $second)

Return the first child if it is below the second child else return B<undef>.

     Parameter  Description
  1  $first     First child
  2  $second    Second child

B<Example:>


    my %l = map{$_->key=>$_} fromLetters('b(c(d(efgh(i(j)k)l)m)n')->by;
    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j, $k, $l, $m, $n) = @l{'a'..'n'};

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


=head2 after($first, $second)

Return the first child if it occurs strictly after the second child in the tree or else B<undef> if the first child is L<above>, L<below> or L<before> the second child.

     Parameter  Description
  1  $first     First child
  2  $second    Second child

B<Example:>


    my %l = map{$_->key=>$_} fromLetters('b(c(d(efgh(i(j)k)l)m)n')->by;
    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j, $k, $l, $m, $n) = @l{'a'..'n'};

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


=head2 before($first, $second)

Return the first child if it occurs strictly before the second child in the tree or else B<undef> if the first child is L<above>, L<below> or L<after> the second child.

     Parameter  Description
  1  $first     First child
  2  $second    Second child

B<Example:>


    my %l = map{$_->key=>$_} fromLetters('b(c(d(efgh(i(j)k)l)m)n')->by;
    my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j, $k, $l, $m, $n) = @l{'a'..'n'};

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



=head1 Paths

Find paths between nodes

=head2 nextPreOrderPath($start)

Return a list of children visited between the specified child and the next child in pre-order.

     Parameter  Description
  1  $start     The child at the start of the path

B<Example:>


    my @p = [my $a = fromLetters('b(c(d(e(fg)hi(j(kl)m)n)op)q)r')];

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


    my @n = my $a = fromLetters('b(c(d(e(fg)hi(j(kl)m)n)op)q)r');
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


    my @p = [my $a = fromLetters('b(c(d(e(fg)hi(j(kl)m)n)op)q)r')];

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


    my @n = my $a = fromLetters('b(c(d(e(fg)hi(j(kl)m)n)op)q)r');
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


    my ($c, $b, $d, $a) = fromLetters('b(c)d')->by;
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


    my ($c, $b, $d, $a) = fromLetters('b(c)d')->by;
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


    my ($c, $b, $d, $a) = fromLetters('b(c)d')->by;
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


    my ($c, $b, $d, $a) = fromLetters('b(c)d')->by;
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


    my $a = fromLetters('b(c)y(x)d(efgh(i(j)))');

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

    is_deeply $a->firstMost->brackets, 'c';
    is_deeply $a-> lastMost->brackets, 'j';


=head2 brackets($tree, $print, $separator)

Bracketed string representation of a tree.

     Parameter   Description
  1  $tree       Tree
  2  $print      Optional print method
  3  $separator  Optional child separator

B<Example:>


    my $a = fromLetters('b(c)y(x)d(efgh(i(j)))');
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


    is_deeply $a->firstMost->brackets, 'c';  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    is_deeply $a-> lastMost->brackets, 'j';  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲



=head2 xml($tree, $print)

Print a tree as as xml.

     Parameter  Description
  1  $tree      Tree
  2  $print     Optional print method

B<Example:>


    my $a = fromLetters('b(c)y(x)d(efgh(i(j)))');
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

    is_deeply $a->firstMost->brackets, 'c';
    is_deeply $a-> lastMost->brackets, 'j';


=head1 Data Structures

Data structures use by this package.


=head2 Tree::Ops Definition


Child in the tree.




=head3 Output fields


B<children> - Children of this child.

B<key> - Key for this child - any thing that can be compared with the L<smartmatch> operator.

B<lastChild> - Last active child chain - enables us to find the currently open scope from the start if the tree.

B<parent> - Parent for this child.

B<value> - Value for this child.



=head1 Private Methods

=head2 activeScope($tree)

Locate the active scope in a tree.

     Parameter  Description
  1  $tree      Tree

=head2 setParentOfChild($child, $parent)

Set the parent of a child and return the child.

     Parameter  Description
  1  $child     Child
  2  $parent    Parent

=head2 indexOfChildInParent($child)

Get the index of a child within the specified parent.

     Parameter  Description
  1  $child     Child

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

3 L<after|/after> - Return the first child if it occurs strictly after the second child in the tree or else B<undef> if the first child is L<above>, L<below> or L<before> the second child.

4 L<before|/before> - Return the first child if it occurs strictly before the second child in the tree or else B<undef> if the first child is L<above>, L<below> or L<after> the second child.

5 L<below|/below> - Return the first child if it is below the second child else return B<undef>.

6 L<brackets|/brackets> - Bracketed string representation of a tree.

7 L<by|/by> - Traverse a tree in order to process each child with the specified sub and return an array of the results of processing each child.

8 L<close|/close> - Close the current scope returning to the previous scope.

9 L<context|/context> - Get the context of the current child.

10 L<cut|/cut> - Cut out a child and all its content and children, return it ready for reinsertion else where.

11 L<dup|/dup> - Duplicate a parent and all its descendants.

12 L<empty|/empty> - Return the specified parent if it has no children else B<undef>

13 L<first|/first> - Get the first child under the specified parent.

14 L<firstMost|/firstMost> - Return the first most descendant child in the tree starting at this parent or else return B<undef> if this parent has no children.

15 L<fromLetters|/fromLetters> - Create a tree from a string of letters - useful for testing.

16 L<indexOfChildInParent|/indexOfChildInParent> - Get the index of a child within the specified parent.

17 L<isFirst|/isFirst> - Return the specified child if that child is first under its parent, else return B<undef>.

18 L<isLast|/isLast> - Return the specified child if that child is last under its parent, else return B<undef>.

19 L<last|/last> - Get the last child under the specified parent.

20 L<lastMost|/lastMost> - Return the last most descendant child in the tree starting at this parent or else return B<undef> if this parent has no children.

21 L<merge|/merge> - Merge the children of the specified parent with those of the surrounding parents if the L<user|https://en.wikipedia.org/wiki/User_(computing)> data of those parents L<smartmatch> that of the specified parent.

22 L<mostRecentCommonAncestor|/mostRecentCommonAncestor> - Find the most recent common ancestor of the specified children.

23 L<new|/new> - Create a new child optionally recording the specified key or value.

24 L<next|/next> - Get the next sibling following the specified child.

25 L<nextPostOrderPath|/nextPostOrderPath> - Return a list of children visited between the specified child and the next child in post-order.

26 L<nextPreOrderPath|/nextPreOrderPath> - Return a list of children visited between the specified child and the next child in pre-order.

27 L<open|/open> - Add a child and make it the currently active scope into which new children will be added.

28 L<prev|/prev> - Get the previous sibling of the specified child.

29 L<prevPostOrderPath|/prevPostOrderPath> - Return a list of children visited between the specified child and the previous child in post-order.

30 L<prevPreOrderPath|/prevPreOrderPath> - Return a list of children visited between the specified child and the previous child in pre-order.

31 L<print|/print> - Print tree in normal pre-order.

32 L<printPostOrder|/printPostOrder> - Print tree in normal post-order.

33 L<printPreOrder|/printPreOrder> - Print tree in normal pre-order.

34 L<printReversePostOrder|/printReversePostOrder> - Print tree in reverse post-order

35 L<printReversePreOrder|/printReversePreOrder> - Print tree in reverse pre-order

36 L<printTree|/printTree> - String representation as a horizontal tree.

37 L<putFirst|/putFirst> - Place a new child first under the specified parent and return the child.

38 L<putLast|/putLast> - Place a new child last under the specified parent and return the child.

39 L<putNext|/putNext> - Place a new child after the specified child.

40 L<putPrev|/putPrev> - Place a new child before the specified child.

41 L<select|/select> - Select matching children in a tree.

42 L<setParentOfChild|/setParentOfChild> - Set the parent of a child and return the child.

43 L<siblingsAfter|/siblingsAfter> - Return a list of siblings after the specified child.

44 L<siblingsBefore|/siblingsBefore> - Return a list of siblings before the specified child.

45 L<single|/single> - Add one child in the current scope.

46 L<singleChildOfParent|/singleChildOfParent> - Return the only child of this parent if the parent has an only child, else B<undef>

47 L<split|/split> - Make the specified parent a grandparent of each of its children by interposing a copy of the specified parent between the specified parent and each of its children.

48 L<step|/step> - Make the first child of the specified parent the parents previous sibling and return the parent.

49 L<stepBack|/stepBack> - Make the previous sibling of the specified parent the parents first child and return the parent.

50 L<stepEnd|/stepEnd> - Make the next sibling of the specified parent the parents last child and return the parent.

51 L<stepEndBack|/stepEndBack> - Make the last child of the specified parent the parents next sibling and return the parent.

52 L<unwrap|/unwrap> - Unwrap the specified child and return that child.

53 L<wrap|/wrap> - Wrap the specified child with a new parent and return the new parent.

54 L<xml|/xml> - Print a tree as as xml.

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
use Test::More tests => 133;

my $startTime = time();
my $localTest = ((caller(1))[0]//'Tree::Ops') eq "Tree::Ops";                   # Local testing mode
Test::More->builder->output("/dev/null") if $localTest;                         # Suppress output in local testing mode
makeDieConfess;

#goto latestTest;

if (1) {                                                                        #Tnew #Topen #Tsingle #Tclose #Tselect
  my $a = Tree::Ops::new 'a', 'A';
  for(1..2)
   {$a->open  ('b', "B$_");
    $a->single('c', "C$_");
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
  my $a = fromLetters(q(bc(d)e));

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
  my %l = map{$_->key=>$_} fromLetters('b(c)d(efgh(i(j)))')->by;
  my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j) = @l{'a'..'j'};
  is_deeply $c->parent,   $b;
  is_deeply $a->first,    $b;
  is_deeply $a->last,     $d;
  is_deeply $e->next,     $f;
  is_deeply $f->prev,     $e;
 }

if (1) {                                                                        #TsingleChildOfParent #TisFirst #TisLast #Tempty
  my %l = map{$_->key=>$_} fromLetters('b(c)d(efgh(i(j)))')->by;
  my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j) = @l{'a'..'j'};

  is_deeply $a->brackets, 'a(b(c)d(efgh(i(j))))';
  is_deeply $b->singleChildOfParent, $c;
  is_deeply $e->isFirst, $e;
  ok !$f->isFirst;
  ok !$g->isLast;
  is_deeply $h->isLast, $h;
  ok  $j->empty;
  ok !$i->empty;
 }

if (1) {                                                                        #TputFirst #TputLast #TputNext #TputPrev
  my %l = map{$_->key=>$_} fromLetters('b(c)d(e)')->by;
  my ($a, $b, $d) = @l{qw(a b d)};

  my $z = $b->putNext(new 'z');
  is_deeply $z->brackets, 'z';
  is_deeply $a->brackets, 'a(b(c)zd(e))';

  my $y = $d->putPrev(new 'y');
  is_deeply $y->brackets, 'y';
  is_deeply $a->brackets, 'a(b(c)zyd(e))';

  $z->putLast(new 't');
  is_deeply $z->brackets, 'z(t)';
  is_deeply $a->brackets, 'a(b(c)z(t)yd(e))';

  $z->putFirst(new 's');
  is_deeply $a->brackets, 'a(b(c)z(st)yd(e))';
 }

if (1) {                                                                        #Tcut #Tunwrap #Twrap #Tcontext #Tby #Tdup
  my %l = map{$_->key=>$_} fromLetters('b(c)y(x)z(st)d(efgh(i(j))))')->by;
  my ($a, $x, $y, $z) = @l{qw(a x y z)};

  is_deeply [map {$_->key} $x->context], [qw(x y a)];

  is_deeply join(' ', $a->by(sub{$_[0]->key})), "c b x y s t z e f g j i h d a";
  is_deeply join(' ', map{$_->key} $a->by),     "c b x y s t z e f g j i h d a";

  $z->cut;
  is_deeply $a->brackets, 'a(b(c)y(x)d(efgh(i(j))))';

  $y->unwrap;
  is_deeply $a->brackets, 'a(b(c)xd(efgh(i(j))))';

  $y = $x->wrap('y');
  is_deeply $y->brackets, 'y(x)';
  is_deeply $a->brackets, 'a(b(c)y(x)d(efgh(i(j))))';

  $y->putNext($y->dup);
  is_deeply $a->brackets, 'a(b(c)y(x)y(x)d(efgh(i(j))))';
 }

if (1) {                                                                        #Tbrackets #TfirstMost #TlastMost #Tprint #Txml
  my $a = fromLetters('b(c)y(x)d(efgh(i(j)))');
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

  is_deeply $a->firstMost->brackets, 'c';
  is_deeply $a-> lastMost->brackets, 'j';
 }

if (1) {                                                                        #Tstep #TstepBack #TstepEnd #TstepEndBack
  my %l = map{$_->key=>$_} fromLetters('b(c)d(efgh(i(j)))')->by;
  my ($a, $b, $d) = @l{qw(a b d)};

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

if (1) {                                                                        #Tabove #Tbelow #Tbefore #Tafter
  my %l = map{$_->key=>$_} fromLetters('b(c(d(efgh(i(j)k)l)m)n')->by;
  my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j, $k, $l, $m, $n) = @l{'a'..'n'};

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
 }

if (1) {                                                                        #TmostRecentCommonAncestor
  my %l = map{$_->key=>$_} fromLetters('b(c(d(e))f(g(h)i)j)k')->by;
  my ($a, $b, $e, $h, $k) = @l{qw(a b e h k)};

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

if (1) {                                                                        #Tsplit #Tmerge
  my %l = map{$_->key=>$_} fromLetters('b(c)d(efgh(i(j)))')->by;
  my ($a, $d) = @l{qw(a d)};

  $d->split;
  is_deeply $d->brackets,       'd(d(e)d(f)d(g)d(h(i(j))))';
  is_deeply $a->brackets, 'a(b(c)d(d(e)d(f)d(g)d(h(i(j)))))';

  $d->first->merge;
  is_deeply $d->brackets,       'd(d(efgh(i(j))))';
  is_deeply $a->brackets, 'a(b(c)d(d(efgh(i(j)))))';

  $d->first->unwrap;
  is_deeply $d->brackets,       'd(efgh(i(j)))';
  is_deeply $a->brackets, 'a(b(c)d(efgh(i(j))))';
 }

if (1) {                                                                        #TsiblingsBefore #TsiblingsAfter
  my ($c, $d, $e, $f, $g, $b, $a) = fromLetters('b(cdefg)')->by;

  ok eval qq(\$$_->key eq '$_') for 'a'..'g';
  is_deeply [map {$_->key} $e->siblingsBefore], ["c", "d"];
  is_deeply [map {$_->key} $e->siblingsAfter ], ["f", "g"];
 }

if (1) {                                                                        #TnextPreOrderPath
  my @p = [my $a = fromLetters('b(c(d(e(fg)hi(j(kl)m)n)op)q)r')];

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
  my @n = my $a = fromLetters('b(c(d(e(fg)hi(j(kl)m)n)op)q)r');
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
  my @n = my $a = fromLetters('b(c(d(e(fg)hi(j(kl)m)n)op)q)r');
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
  my @p = [my $a = fromLetters('b(c(d(e(fg)hi(j(kl)m)n)op)q)r')];

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
  my ($c, $b, $d, $a) = fromLetters('b(c)d')->by;
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

done_testing;

if ($localTest)
 {say "TO finished in ", (time() - $startTime), " seconds";
 }

#   owf(q(/home/phil/z/z/z/zzz.txt), $dfa->dumpAsJson);

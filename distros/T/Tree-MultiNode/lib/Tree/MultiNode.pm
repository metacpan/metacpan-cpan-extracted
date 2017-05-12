
=head1 NAME

Tree::MultiNode -- a multi-node tree object.  Most useful for 
modeling hierarchical data structures.

=head1 SYNOPSIS

  use Tree::MultiNode;
  use strict; 
  use warnings;
  my $tree   = new Tree::MultiNode;
  my $handle = new Tree::MultiNode::Handle($tree);

  $handle->set_key("top");
  $handle->set_value("level");

  $handle->add_child("child","1");
  $handle->add_child("child","2");

  $handle->first();
  $handle->down();

  $handle->add_child("grandchild","1-1");
  $handle->up();

  $handle->last();
  $handle->down();

  $handle->add_child("grandchild","2-1");
  $handle->up();
  
  $handle->top();
  &dump_tree($handle);

  my $depth = 0;
  sub dump_tree
  {
    ++$depth;
    my $handle = shift;
    my $lead = ' ' x ($depth*2);
    my($key,$val);
  
    ($key,$val) = $handle->get_data();

    print $lead, "key:   $key\n";
    print $lead, "val:   $val\n";
    print $lead, "depth: $depth\n";
  
    my $i;
    for( $i = 0; $i < scalar($handle->children); ++$i ) {
      $handle->down($i);
        &dump_tree($handle);
      $handle->up();
    }
    --$depth;
  }

=head1 DESCRIPTION

Tree::MultiNode, Tree::MultiNode::Node, and MultiNode::Handle are objects 
modeled after C++ classes that I had written to help me model hierarchical 
information as data structures (such as the relationships between records in 
an RDBMS).  The tree is basically a list of lists type data structure, where 
each node has a key, a value, and a list of children.  The tree has no
internal sorting, though all operations preserve the order of the child 
nodes.  

=head2 Creating a Tree

The concept of creating a handle based on a tree lets you have multiple handles
into a single tree without having to copy the tree.  You have to use a handle
for all operations on the tree (other than construction).

When you first construct a tree, it will have a single empty node.  When you
construct a handle into that tree, it will set the top node in the tree as 
it's current node.  

  my $tree   = new Tree::MultiNode;
  my $handle = new Tree::MultiNode::Handle($tree);

=head2 Using a Handle to Manipulate the Tree

At this point, you can set the key/value in the top node, or start adding
child nodes.

  $handle->set_key("blah");
  $handle->set_value("foo");

  $handle->add_child("quz","baz");
  # or
  $handle->add_child();

add_child can take 3 parameters -- a key, a value, and a position.  The key
and value will set the key/value of the child on construction.  If pos is
passed, the new child will be inserted into the list of children.

To move the handle so it points at a child (so you can start manipulating that
child), there are a series of methods to call:

  $handle->first();   # sets the current child to the first in the list
  $handle->next();    # sets the next, or first if there was no next
  $handle->prev();    # sets the previous, or last if there was no next
  $handle->last();    # sets to the last child
  $handle->down();    # positions the handle's current node to the 
                      # current child

To move back up, you can call the method up:

  $handle->up();      # moves to this node's parent

up() will fail if the current node has no parent node.  Most of the member 
functions return either undef to indicate failure, or some other value to 
indicate success.

=head2 $Tree::MultiNode::debug

If set to a true value, it enables debugging output in the code.  This will 
likely be removed in future versions as the code becomes more stable.

=head1 API REFERENCE

=cut

################################################################################

=head2 Tree::MultiNode

The tree object.

=cut

package Tree::MultiNode;
use strict;
use vars qw( $VERSION @ISA );
require 5.004;

$VERSION = '1.0.13';
@ISA     = ();

=head2 Tree::MultiNode::new

  @param    package name or tree object [scalar]
  @returns  new tree object

Creates a new Tree.  The tree will have a single top level node when created.
The first node will have no value (undef) in either it's key or it's value.

  my $tree = new Tree::MultiNode;

=cut

sub new
{
  my $this = shift;
  my $class = ref($this) || $this;
  my $self = {};
  bless $self, $class;

  $self->{'top'} = Tree::MultiNode::Node->new();
  return $self;
}

#
# this destructor is for clearing the circular references between
# the tree, the nodes, and their children.
#
sub DESTROY
{
  my $self = shift;
  $self->{'top'}->_clearrefs() if $self->{'top'};
}

1;
################################################################################
package Tree::MultiNode::Node;
use strict;
use Carp;

=head2 Tree::MultiNode::Node

Please note that the Node object is used internally by the MultiNode object.  
Though you have the ability to interact with the nodes, it is unlikely that
you should need to.  That being said, the interface is documented here anyway.

=cut


=head2 Tree::MultiNode::Node::new

  new($)
    @param    package name or node object to clone [scalar]
    @returns  new node object

  new($$)
    @param    key   [scalar]
    @param    value [scalar]
    @returns  new node object

Creates a new Node.  There are three behaviors for new.  A constructor with no
arguments creates a new, empty node.  A single argument of another node object
will create a clone of the node object.  If two arguments are passed, the first
is stored as the key, and the second is stored as the value.

  # clone an existing node
  my $node = new Tree::MultiNode::Node($oldNode);
  # or
  my $node = $oldNode->new();

  # create a new node
  my $node = new Tree::MultiNode::Node;
  my $node = new Tree::MultiNode::Node("fname");
  my $node = new Tree::MultiNode::Node("fname","Larry");

=cut

sub new 
{
  my $this = shift;
  my $class = ref($this) || $this;
  my $self = {};
  bless $self, $class;

  my $node = shift;
  if( ref($node) eq "Tree::MultiNode::Node" ) {
    # become a copy of that node...
    $self->_clone($node);
  }
  else {
    my($key,$value);
    $key = $node;
    $value = shift;
    print __PACKAGE__, "::new() key,val = $key,$value\n" 
      if $Tree::MultiNode::debug;
    $self->{'children'} = [];
    $self->{'parent'}   = undef;
    $self->{'key'}      = $key || undef;
    $self->{'value'}    = defined $value ? $value : undef;
  }

  return $self;
}

#
# internal method for making the current node a clone of another
# node...
#
sub _clone
{
  my $self = shift;
  my $them = shift;
  $self->{'parent'}   = $them->parent;
  $self->{'children'} = [$them->children];
  $self->{'key'}      = $them->key;
  $self->{'value'}    = $them->value;
}

=head2 Tree::MultiNode::Node::key

  @param     key [scalar]
  @returns   the key [scalar]

Used to set, or retrieve the key for a node.  If a parameter is passed,
it sets the key for the node.  The value of the key member is always
returned.

  print $node3->key(), "\n";    # 'fname'

=cut

sub key
{
  my($self,$key) = @_;

  if(@_>1) {
    print __PACKAGE__, "::key() setting key: $key on $self\n" 
      if $Tree::MultiNode::debug;
    $self->{'key'} = $key;
  }

  return $self->{'key'};
}

=head2 Tree::MultiNode::Node::value

  @param    the value to set [scalar]
  @returns  the value [scalar]

Used to set, or retrieve the value for a node.  If a parameter is passed,
it sets the value for the node.  The value of the value member is always
returned.

  print $node3->value(), "\n";   # 'Larry'

=cut

sub value
{
  my $self = shift;
  my $value = shift;

  if( defined $value ) {
    print __PACKAGE__, "::value() setting value: $value on $self\n" 
      if $Tree::MultiNode::debug;
    $self->{'value'} = $value;
  }

  return $self->{'value'};
}

=head2 Tree::MultiNode::Node::clear_key

  @returns  the deleted key

Clears the key member by deleting it.

  $node3->clear_key();

=cut

sub clear_key
{
  my $self = shift;
  return delete $self->{'key'};
}

=head2 Tree::MultiNode::Node::clear_value

  @returns  the deleted value

Clears the value member by deleting it.

  $node3->clear_value();

=cut

sub clear_value
{
  my $self = shift;
  return delete $self->{'value'};
}

=head2 Tree::MultiNode::Node::children

  @returns  reference to children [array reference]

Returns a reference to the array that contains the children of the
node object.

  $array_ref = $node3->children();

=cut

sub children 
{
  my $self = shift;
  return $self->{'children'};
}

=head2 Tree::MultiNode::Node::child_keys  
Tree::MultiNode::Node::child_values
Tree::MultiNode::Node::child_kv_pairs

These functions return arrays consisting of the appropriate data
from the child nodes.

  my @keys     = $handle->child_keys();
  my @vals     = $handle->child_values();
  my %kv_pairs = $handle->child_kv_pairs();

=cut

sub child_keys
{
  my $self = shift;
  my $children = $self->{'children'};
  my @keys;
  my $node;

  foreach $node (@$children) {
    push @keys, $node->key();
  }

  return @keys;
}

sub child_values
{
  my $self = shift;
  my $children = $self->{'children'};
  my @values;
  my $node;

  foreach $node (@$children) {
    push @values, $node->value();
  }

  return @values;
}

sub child_kv_pairs
{
  my $self = shift;
  my $children = $self->{'children'};
  my %h;
  my $node;

  foreach $node (@$children) {
    $h{$node->key()} = $node->value();
  }

  return %h;
}

=head2 Tree::MultiNode::Node::child_key_positions  

This function returns a hash table that consists of the
child keys as the hash keys, and the position in the child
array as the value.  This allows for a quick and dirty way
of looking up the position of a given key in the child list.

  my %h = $node->child_key_positions();

=cut

sub child_key_positions
{
  my $self = shift;
  my $children = $self->{'children'};
  my(%h,$i,$node);

  $i = 0;
  foreach $node (@$children) {
    $h{$node->key()} = $i++;
  }

  return %h;
}


=head2 Tree::MultiNode::Node::parent

Returns a reference to the parent node of the current node.

  $node_parent = $node3->parent();

=cut

sub parent
{
  my $self = shift;
  return $self->{'parent'};
}

=head2 Tree::MultiNode::Node::dump

Used for diagnostics, it prints out the members of the node.

  $node3->dump();

=cut

sub dump
{
  my $self = shift;

  print "[dump] key:       ", $self->{'key'}, "\n";
  print "[dump] val:       ", $self->{'value'}, "\n";
  print "[dump] parent:    ", $self->{'parent'}, "\n";
  print "[dump] children:  ", $self->{'children'}, "\n";
}

sub _clearrefs
{
  my $self = shift;
  delete $self->{'parent'};
  foreach my $child ( @{$self->children()} ) {
    $child->_clearrefs();
  }
  delete $self->{'children'};
}

1;
################################################################################
package Tree::MultiNode::Handle;
use strict;
use Carp;

=head2 Tree::MultiNode::Handle

Handle is used as a 'pointer' into the tree.  It has a few attributes that it keeps
track of.  These are:

  1. the top of the tree 
  2. the current node
  3. the current child node
  4. the depth of the current node

The top of the tree never changes, and you can reset the handle to point back at
the top of the tree by calling the top() method.  

The current node is where the handle is 'pointing' in the tree.  The current node
is changed with functions like top(), down(), and up().

The current child node is used for traversing downward into the tree.  The members
first(), next(), prev(), last(), and position() can be used to set the current child,
and then traverse down into it.

The depth of the current node is a measure of the length of the path
from the top of the tree to the current node, i.e., the top of the node
has a depth of 0, each of its children has a depth of 1, etc.

=cut

=head2 Tree::MultiNode::Handle::New

Constructs a new handle.  You must pass a tree object to Handle::New.

  my $tree   = new Tree::MultiNode;
  my $handle = new Tree::MultiNode::Handle($tree);

=cut

sub new
{
  my $this = shift;
  my $class = ref($this) || $this;

  my $self = {};
  bless $self, $class;
  my $data = shift;
  print __PACKAGE__, "::new() ref($data) is: ", ref($data), "\n" 
    if $Tree::MultiNode::debug;
  if( ref($data) eq "Tree::MultiNode::Handle" ) {
    $self->_clone($data);
  }
  else {
    unless( ref($data) eq "Tree::MultiNode" ) {
      confess "Error, invalid Tree::MultiNode reference:  $data\n";
    }

    $self->{'tree'}       = $data;
    $self->{'curr_pos'}   = undef;
    $self->{'curr_node'}  = $data->{'top'};
    $self->{'curr_child'} = undef;
    $self->{'curr_depth'} = 0;
  }
  return $self;
}

#
# internal method for making the current handle a copy of another
# handle...
#
sub _clone
{
  my $self = shift;
  my $them = shift;
  print __PACKAGE__, "::_clone() cloning: $them\n" 
    if $Tree::MultiNode::debug;
  print __PACKAGE__, "::_clone() depth: ",$them->{'curr_depth'},"\n" 
    if $Tree::MultiNode::debug;
  $self->{'tree'}       = $them->{'tree'};
  $self->{'curr_pos'}   = $them->{'curr_pos'};
  $self->{'curr_node'}  = $them->{'curr_node'};
  $self->{'curr_child'} = $them->{'curr_child'};
  $self->{'curr_depth'} = $them->{'curr_depth'};
  return 1;
}

=head2 Tree::MultiNode::Handle::tree

Returns the tree that was used to construct the node.  Useful if you're
trying to create another node into the tree.

  my $handle2 = new Tree::MultiNode::Handle($handle->tree());

=cut

sub tree
{
  my $self = shift;
  return $self->{'tree'};
}

=head2 Tree::MultiNode::Handle::get_data

Retrieves both the key, and value (as an array) for the current node.

  my ($key,$val) = $handle->get_data();

=cut

sub get_data
{
  my $self = shift;
  my $node = $self->{'curr_node'};

  return($node->key,$node->value);
}

=head2 Tree::MultiNode::Handle::get_key

Retrieves the key for the current node.

  $key = $handle->get_key();

=cut

sub get_key
{
  my $self = shift;
  my $node = $self->{'curr_node'};

  my $key = $node->key();

  print __PACKAGE__, "::get_key() getting from $node : $key\n" 
    if $Tree::MultiNode::debug;

  return $key;
}

=head2 Tree::MultiNode::Handle::set_key

Sets the key for the current node.

  $handle->set_key("lname");

=cut

sub set_key
{
  my $self = shift;
  my $key = shift;
  my $node = $self->{'curr_node'};

  print __PACKAGE__, "::set_key() setting key \"$key\" on: $node\n" 
    if $Tree::MultiNode::debug;

  return $node->key($key);
}

=head2 Tree::MultiNode::Handle::get_value

Retrieves the value for the current node.

  $val = $handle->get_value();

=cut

sub get_value
{
  my $self = shift;
  my $node = $self->{'curr_node'};

  my $value = $node->value();

  print __PACKAGE__, "::get_value() getting from $node : $value\n",
    if $Tree::MultiNode::debug;

  return $value;
}

=head2 Tree::MultiNode::Handle::set_value

Sets the value for the current node.

  $handle->set_value("Wall");

=cut

sub set_value
{
  my $self = shift;
  my $value = shift;
  my $node = $self->{'curr_node'};

  print __PACKAGE__, "::set_value() setting value \"$value\" on: $node\n" 
    if $Tree::MultiNode::debug;

  return $node->value($value);
}

=head2 Tree::MultiNode::Handle::get_child

get_child takes an optional parameter which is the position of the child
that is to be retrieved.  If this position is not specified, get_child 
attempts to return the current child.  get_child returns a Node object.

  my $child_node = $handle->get_child();

=cut

sub get_child
{
  my $self = shift;
  my $children = $self->{'curr_node'}->children;
  my $pos = shift || $self->{'curr_pos'};

  print __PACKAGE__, "::get_child() children: $children   $pos\n" 
    if $Tree::MultiNode::debug;

  unless( defined $children ) {
    return undef;
  }

  unless( defined $pos && $pos <= $#{$children} ) {
    my $num = $#{$children};
    confess "Error, $pos is an invalid position [$num] $children.\n";
  }

  print __PACKAGE__, "::get_child() returning [$pos]: ", 
    ${$children}[$pos], "\n" if $Tree::MultiNode::debug;
  return( ${$children}[$pos] );
}

=head2 Tree::MultiNode::Handle::add_child

This member adds a new child node to the end of the array of children for the
current node.  There are three optional parameters:

  - a key
  - a value
  - a position

If passed, the key and value will be set in the new child.  If a position is 
passed, the new child will be inserted into the current array of children at
the position specified.

  $handle->add_child();                    # adds a blank child
  $handle->add_child("language","perl");   # adds a child to the end
  $handle->add_child("language","C++",0);  # adds a child to the front

=cut

sub add_child
{
  my $self = shift;
  my($key,$value,$pos) = @_;
  my $children = $self->{'curr_node'}->children;
  print __PACKAGE__, "::add_child() children: $children\n" 
    if $Tree::MultiNode::debug;
  my $curr_pos = $self->{'curr_pos'};
  my $curr_node = $self->{'curr_node'};

  my $child = Tree::MultiNode::Node->new($key,$value);
  $child->{'parent'} = $curr_node;

  print __PACKAGE__, "::add_child() adding child $child ($key,$value) ",
    "to: $children\n" if $Tree::MultiNode::debug;

  if(defined $pos) {
    print __PACKAGE__, "::add_child() adding at $pos $child\n" 
      if $Tree::MultiNode::debug;
    unless($pos <= $#{$children}) {
      my $num =  $#{$children};
      confess "Position $pos is invalid for child position [$num] $children.\n";
    }
    splice( @{$children}, $pos, 1, $child, ${$children}[$pos] );
  }
  else {
    print __PACKAGE__, "::add_child() adding at end $child\n" 
      if $Tree::MultiNode::debug;
    push @{$children}, $child;
  }

  print __PACKAGE__, "::add_child() children:", 
    join(',',@{$self->{'curr_node'}->children}), "\n" 
    if $Tree::MultiNode::debug;
}

=head2 Tree::MultiNode::Handle::add_child_node

Recently added via RT # 5435 -- Currently in need of proper documentation and test patches

  I've patched Tree::MultiNode 1.0.10 to add a method I'm currently calling add_child_node().
  It works just like add_child() except it takes either a Tree::MultiNode::Node or a 
  Tree::MultiNode object instead. I found this extremely useful when using recursion to populate
  a tree. It could also be used to subsume any tree into another tree, so this touches on the
  topic of the other bug item here asking for methods to copy/move trees/nodes.

=cut

sub add_child_node
{
  my $self = shift;
  my($child,$pos) = @_;
  my $children = $self->{'curr_node'}->children;
  print __PACKAGE__, "::add_child_node() children: $children\n" 
    if $Tree::MultiNode::debug;
  my $curr_pos = $self->{'curr_pos'};
  my $curr_node = $self->{'curr_node'};
  if(ref($child) eq 'Tree::MultiNode') {
    my $top = $child->{'top'};
    $child->{'top'} = undef;
    $child = $top;
  }
  confess "Invalid child argument.\n"
    if(ref($child) ne 'Tree::MultiNode::Node');

  $child->{'parent'} = $curr_node;

  print __PACKAGE__, "::add_child_node() adding child $child ",
    "to: $children\n" if $Tree::MultiNode::debug;

  if(defined $pos) {
    print __PACKAGE__, "::add_child_node() adding at $pos $child\n" 
      if $Tree::MultiNode::debug;
    unless($pos <= $#{$children}) {
      my $num =  $#{$children};
      confess "Position $pos is invalid for child position [$num] $children.\n";
    }
    splice( @{$children}, $pos, 1, $child, ${$children}[$pos] );
  }
  else {
    print __PACKAGE__, "::add_child_node() adding at end $child\n" 
      if $Tree::MultiNode::debug;
    push @{$children}, $child;
  }

  print __PACKAGE__, "::add_child_node() children:", 
    join(',',@{$self->{'curr_node'}->children}), "\n" 
    if $Tree::MultiNode::debug;
}

=head2 Tree::MultiNode::Handle::depth

Gets the depth for the current node.

  my $depth = $handle->depth();

=cut

sub depth
{
  my $self = shift;
  my $node = $self->{'curr_node'};

  print __PACKAGE__, "::depth() getting depth \"$self->{'curr_depth'}\" ",
    "on: $node\n" if $Tree::MultiNode::debug;


  return $self->{'curr_depth'};
}

=head2 Tree::MultiNode::Handle::select

Sets the current child via a specified value -- basically it iterates
through the array of children, looking for a match.  You have to 
supply the key to look for, and optionally a sub ref to find it.  The 
default for this sub is 

  sub { return shift eq shift; }

Which is sufficient for testing the equality of strings (the most common
thing that I think will get stored in the tree).  If you're storing multiple
data types as keys, you'll have to write a sub that figures out how to 
perform the comparisons in a sane manner.

The code reference should take two arguments, and compare them -- return
false if they don't match, and true if they do.

  $handle->select('lname', sub { return shift eq shift; } );

=cut

sub select
{
  my $self = shift;
  my $key  = shift;
  my $code = shift || sub { return shift eq shift; } ;
  my($child,$pos);
  my $found = undef;

  $pos = 0;
  foreach $child ($self->children()) {
    if( $code->($key,$child->key()) ) {
      $self->{'curr_pos'}   = $pos;
      $self->{'curr_child'} = $child;
      ++$found;
      last;
    }
    ++$pos;
  }

  return $found;
}

=head2 Tree::MultiNode::Handle::position

Sets, or retrieves the current child position.

  print "curr child pos is: ", $handle->position(), "\n";
  $handle->position(5);    # sets the 6th child as the current child

=cut

sub position
{
  my $self = shift;
  my $pos = shift;

  print __PACKAGE__, "::position() $self  $pos\n" 
    if $Tree::MultiNode::debug;

  unless( defined $pos ) {
    return $self->{'curr_pos'};
  }

  my $children = $self->{'curr_node'}->children;
  print __PACKAGE__, "::position() children: $children\n" 
    if $Tree::MultiNode::debug;
  print __PACKAGE__, "::position() position is $pos  ",
    $#{$children}, "\n" if $Tree::MultiNode::debug;
  unless( $pos <= $#{$children} ) {
    my $num = $#{$children};
    confess "Error, $pos is invalid [$num] $children.\n";
  }
  $self->{'curr_pos'} = $pos;
  $self->{'curr_child'} = $self->get_child($pos);
  return $self->{'curr_pos'};
}

=head2 Tree::MultiNode::Handle::first
Tree::MultiNode::Handle::next
Tree::MultiNode::Handle::prev
Tree::MultiNode::Handle::last

These functions manipulate the current child member.  first() sets the first
child as the current child, while last() sets the last.  next(), and prev() will
move to the next/prev child respectively.  If there is no current child node,
next() will have the same effect as first(), and prev() will operate as last().
prev() fails if the current child is the first child, and next() fails if the
current child is the last child -- i.e., they do not wrap around.

These functions will fail if there are no children for the current node.

  $handle->first();  # sets to the 0th child
  $handle->next();   # to the 1st child
  $handle->prev();   # back to the 0th child
  $handle->last();   # go straight to the last child.

=cut

sub first
{
  my $self = shift;

  $self->{'curr_pos'}   = 0;
  $self->{'curr_child'} = $self->get_child(0);
  print __PACKAGE__, "::first() set child[",$self->{'curr_pos'},"]: ",
    $self->{'curr_child'}, "\n" if $Tree::MultiNode::debug;
  return $self->{'curr_pos'};
}

sub next
{
  my $self = shift;
  my $pos = $self->{'curr_pos'} + 1;
  my $children = $self->{'curr_node'}->children;
  print __PACKAGE__, "::next() children: $children\n" 
    if $Tree::MultiNode::debug;

  unless( $pos >= 0 && $pos <= $#{$children} ) {
    return undef;
  }

  $self->{'curr_pos'}   = $pos;
  $self->{'curr_child'} = $self->get_child($pos);
  return $self->{'curr_pos'};
}

sub prev
{
  my $self = shift;
  my $pos = $self->{'curr_pos'} - 1;
  my $children = $self->{'curr_node'}->children;
  print __PACKAGE__, "::prev() children: $children\n" 
    if $Tree::MultiNode::debug;

  unless( $pos >= 0 && $pos <= $#{$children} ) {
    return undef;
  }

  $self->{'curr_pos'}   = $pos;
  $self->{'curr_child'} = $self->get_child($pos);
  return $self->{'curr_pos'};
}

sub last
{
  my $self = shift;
  my $children = $self->{'curr_node'}->children;
  my $pos = $#{$children};
  print __PACKAGE__, "::last() children [$pos]: $children\n" 
    if $Tree::MultiNode::debug;

  $self->{'curr_pos'}   = $pos;
  $self->{'curr_child'} = $self->get_child($pos);
  return $self->{'curr_pos'};
}

=head2 Tree::MultiNode::Handle::down

down() moves the handle to point at the current child node.  It fails
if there is no current child node.  When down() is called, the current
child becomes invalid (undef).

  $handle->down();

=cut

sub down
{
  my $self = shift;
  my $pos = shift;
  my $node = $self->{'curr_node'};
  return undef unless defined $node;
  my $children = $node->children;
  print __PACKAGE__, "::down() children: $children\n" 
    if $Tree::MultiNode::debug;

  if( defined $pos ) {
    unless( defined $self->position($pos) ) {
      confess "Error, $pos was an invalid position.\n";
    }
  }

  $self->{'curr_pos'}   = undef;
  $self->{'curr_node'}  = $self->{'curr_child'};
  $self->{'curr_child'} = undef;
  ++$self->{'curr_depth'};
  print __PACKAGE__, "::down() set to: ", $self->{'curr_node'}, "\n" 
    if $Tree::MultiNode::debug;

  return 1;
}

=head2 Tree::MultiNode::Handle::up

down() moves the handle to point at the parent of the current node.  It fails
if there is no parent node.  When up() is called, the current child becomes 
invalid (undef).

  $handle->up();

=cut

sub up
{
  my $self = shift;
  my $node = $self->{'curr_node'};
  return undef unless defined $node;
  my $parent = $node->parent();

  unless( defined $parent ) {
    return undef;
  }
  
  $self->{'curr_pos'}   = undef;
  $self->{'curr_node'}  = $parent;
  $self->{'curr_child'} = undef;
  --$self->{'curr_depth'};

  return 1;
}

=head2 Tree::MultiNode::Handle::top

Resets the handle to point back at the top of the tree.  
When top() is called, the current child becomes invalid (undef).

  $handle->top();

=cut

sub top
{
  my $self = shift;
  my $tree = $self->{'tree'};

  $self->{'curr_pos'}   = undef;
  $self->{'curr_node'}  = $tree->{'top'};
  $self->{'curr_child'} = undef;
  $self->{'curr_depth'} = 0;

  return 1;
}

=head2 Tree::MultiNode::Handle::children

This returns an array of Node objects that represents the children of the
current Node.  Unlike Node::children(), the array Handle::children() is not
a reference to an array, but an array.  Useful if you need to iterate through
the children of the current node.

  print "There are: ", scalar($handle->children()), " children\n";
  foreach $child ($handle->children()) {
    print $child->key(), " : ", $child->value(), "\n";
  }

=cut

sub children
{
  my $self = shift;
  my $node = $self->{'curr_node'};
  return undef unless defined $node;
  my $children = $node->children;

  return @{$children};
}

=head2 Tree::MultiNode::Handle::child_key_positions

This function returns a hash table that consists of the
child keys as the hash keys, and the position in the child
array as the value.  This allows for a quick and dirty way
of looking up the position of a given key in the child list.

  my %h = $handle->child_key_positions();

=cut

sub child_key_positions
{
  my $self = shift;
  my $node = $self->{'curr_node'};

  return $node->child_key_positions();
}

=head2 Tree::MultiNode::Handle::get_child_key

Returns the key at the specified position, or from the corresponding child
node.

  my $key = $handle->get_child_key();

=cut

sub get_child_key
{
  my $self = shift;
  my $pos  = shift;
  $pos = $self->{'curr_pos'} unless defined $pos;

  my $node = $self->get_child($pos);
  return defined $node ? $node->key() : undef;
}

=head2 Tree::MultiNode::Handle::get_child_value

Returns the value at the specified position, or from the corresponding child
node.

  my $value = $handle->get_child_value();

=cut

sub get_child_value
{
  my $self = shift;
  my $pos  = shift || $self->{'curr_pos'};

  print __PACKAGE__, "::sub get_child_value() pos is: $pos\n" 
    if $Tree::MultiNode::debug;
  my $node = $self->get_child($pos);
  return defined $node ? $node->value() : undef;
}

=head2 Tree::MultiNode::Handle::remove_child

Returns Tree::MultiNode::Node::child_kv_paris() for the
current node for this handle.

  my %pairs = $handle->kv_pairs();

=cut

sub kv_pairs
{
  my $self = shift;
  my $node = $self->{'curr_node'};

  return $node->child_kv_pairs();
}

=head2 Tree::MultiNode::Handle::remove_child

=cut

sub remove_child
{
  my $self = shift;
  my $pos  = shift || $self->{'curr_pos'};

  print __PACKAGE__, "::remove_child() pos is: $pos\n"
    if $Tree::MultiNode::debug;

  my $children = $self->{'curr_node'}->children;

  unless( defined $children ) {
    return undef;
  }

  unless( defined $pos && $pos >= 0 && $pos <= $#{$children} ) {
    my $num = $#{$children};
    confess "Error, $pos is an invalid position [$num] $children.\n";
  }

  my $node = splice(@{$children},$pos,1);

  return ($node->key,$node->value);
}

=head2 Tree::MultiNode::Handle::child_keys

Returns the keys from the current node's children.
Returns undef if there is no current node.

=cut

sub child_keys
{
  my $self = shift;
  my $node = $self->{'curr_node'};
  return undef unless $node;
  return $node->child_keys();
}

=head2 Tree::MultiNode::Handle::traverse

  $handle->traverse(sub {
    my $h = pop;
    printf "%sk: %s v: %s\n",('  ' x $handle->depth()),$h->get_data();
  });

Traverse takes a subroutine reference, and will visit each node of the tree,
starting with the node the handle currently points to, recursively down from the
current position of the handle.  Each time the subroutine is called, it will be
passed a handle which points to the node to be visited.  Any additional
arguments after the sub ref will be passed to the traverse function _before_
the handle is passed.  This should allow you to pass constant arguments to the
sub ref.

Modifying the node that the handle points to will cause traverse to work
from the new node forward.

=cut

sub traverse
{
  my($self,$subref,@args) = @_;
  confess "Error, invalid sub ref: $subref\n" unless 'CODE' eq ref($subref);
  # operate on a cloned handle
  return Tree::MultiNode::Handle->new($self)->_traverseImpl($subref,@args);
}

sub _traverseImpl
{
  my($self,$subref,@args) = @_;
  $subref->( @args, $self );
  for(my $i = 0; $i < scalar($self->children); ++$i ) {
    $self->down($i);
      $self->_traverseImpl($subref,@args);
    $self->up();
  }
  return;
}


=head2 Tree::MultiNode::Handle::traverse
 or to have
the subref to be a method on an object (and still pass the object's 
'self' to the method).

  $handle->traverse( \&Some::Object::method, $obj, $const1, \%const2 );

  ...
  sub method
  {
    my $handle = pop;
    my $self   = shift;
    my $const1 = shift;
    my $const2 = shift;
    # do something
  }
=cut

sub otraverse
{
  my($self,$subref,@args) = @_;
  confess "Error, invalid sub ref: $subref\n" unless 'CODE' eq ref($subref);
  # operate on a cloned handle
  return Tree::MultiNode::Handle->new($self)->_otraverseImpl($subref,@args);
}

sub _otraverseImpl
{
  my($self,$obj,$method,@args) = @_;
  $obj->$method( @args, $self );
  for(my $i = 0; $i < scalar($self->children); ++$i ) {
    $self->down($i);
      $self->_otraverseImpl($obj,$method,@args);
    $self->up();
  }
  return;
}


=head1 SEE ALSO

Algorithms in C++
   Robert Sedgwick
   Addison Wesley 1992
   ISBN 0201510596

The Art of Computer Programming, Volume 1: Fundamental Algorithms,
   third edition, Donald E. Knuth

=head1 AUTHORS

Kyle R. Burton <mortis@voicenet.com> (initial version, and maintenence)

Daniel X. Pape <dpape@canis.uiuc.edu> (see Changes file from the source archive)

Eric Joanis <joanis@cs.toronto.edu>

Todd Rinaldo <toddr@cpan.org>

=head1 BUGS

- There is currently no way to remove a child node.

=cut 

1;

package Treex::PML::Node;

use 5.008;
use strict;
use warnings;

use vars qw($VERSION);
BEGIN {
  $VERSION='2.22'; # version template
}
use Carp;

use base qw(Treex::PML::Struct);

use Treex::PML::Schema;
require Treex::PML::Instance;
use UNIVERSAL::DOES;
use Scalar::Util qw(weaken);

our ($parent, $firstson, $lbrother, $rbrother, $TYPE) = qw(_P_ _S_ _L_ _R_ _T_);

=pod

=head1 NAME

Treex::PML::Node - Treex::PML class representing a node.

=head1 DESCRIPTION

This class implements a node in a tree. The node has zero or one
parent node (C<parent()>) (if it has no parent, it is a root of a
tree), zero or more child nodes (the left-most of them returned by
C<firstson()>) and zero or more siblings (C<lbrother()> is the
immediate sibling the left and C<rbrother()> is the immediate sibling
the right).

A node can also be associated with a PML type (contianer or structure)
and may carry named attributes (with atomic or complex values).

=head2 Representation of trees

L<Treex::PML> provides representation for oriented rooted trees (such as
dependency trees or constituency trees).

In L<Treex::PML>, each tree is represented by its root-node. A node is a
Treex::PML::Node object, which is underlined by a usual Perl hash
reference whose hash keys represent node attributes (name-value
pairs).

The set of available attributes at each node is specified in the data
format (which, depending on I/O backend, is represented either by a
L<Treex::PML::FSFormat> or L<Treex::PML::Schema> object; whereas
L<Treex::PML::FSFormat> uses a fixed set of attributes for all nodes
with text values (or alternating text values), in
L<Treex::PML::Schema> the set of attributes may depend on the type of
the node and a wide range of data-structures is supported for
attribute values.  In particular, attribute values may be plain
scalars or L<Treex::PML> data objects (L<Treex::PML::List>,
L<Treex::PML::Alt>, L<Treex::PML::Struct>, L<Treex::PML::Container>,
L<Treex::PML::Seq>.

FS format also allows to declare some attributes as representants of
extra features, such as total ordering on a tree, text value of a
node, indicator for "hidden" nodes, etc. Similarly, in PML schema,
some attributes may be associated with roles, e.g. the role '#ID' for
an attribute carrying a unique identifier of the node, or '#ORDER' for
an integer attribute representing the order of the node in the
horizontal ordering of the tree.

The tree structure can be modified and traversed by various
Treex::PML::Node object methods, such as C<parent>, C<firstson>,
C<rbrother>, C<lbrother>, C<following>, C<previous>, C<cut>,
C<paste_on>, C<paste_after>, and C<paste_before>.

Four special hash keys are reserved for representing the tree
structure in the Treex::PML::Node hash. These keys are defined in
global variables: C<$Treex::PML::Node::parent>, C<$Treex::PML::Node::firstson>,
C<$Treex::PML::Node::rbrother>, and C<$Treex::PML::Node::lbrother>. Another
special key C<$Treex::PML::Node::type> is reserved for storing data type
information. It is highly recommended to use Treex::PML::Node
object methods instead of accessing these hash keys directly.  By
default, the values of these special keys in order are C<_P_>, C<_S_>,
C<_R_>, C<_L_>, C<_T_>.

Although arbitrary non-attribute non-special keys may be added to the
node hashes at run-time, such keys are not normally preserved via I/O
backends and extreme care must be taken to aviod conflicts with
attribute names or the special hash keys described above.

=head1 METHODS

=over 4

=item Treex::PML::Node->new($hash?,$reuse?)

NOTE: Don't call this constructor directly, use Treex::PML::Factory->createTypedNode() or 
Treex::PML::Factory->createNode() instead!

Create a new Treex::PML::Node object. Treex::PML::Node is basically a hash reference. This
means that node's attributes can be accessed simply as
C<< $node->{attribute} >>.

If a hash-reference is passed as the 1st argument, all its keys and
values are are copied to the new Treex::PML::Node. 

An optional 2nd argument $reuse can be set to a true value to indicate
that the passed hash-reference can be used directly as the underlying
hash-reference for the new Treex::PML::Node object (which avoids copying). It
is, however, not guaranteed that the hash-reference will be reused;
the caller thus must even in this case work with the object returned
by the constructor rather that the hash-reference passed.

Returns the newly created Treex::PML::Node object.

=cut


sub new {
  my $self = shift;
  my $class = ref($self) || $self;
  my $new = shift;
  if (ref($new)) {
    my $reuse=shift;
    unless ($reuse) {
      $new={%$new};
    }
  } else {
    my $size=$new;
    croak("Usage: ".__PACKAGE__."->new(key=>value, ...) - got ",join(', ',map ref($_).qq{= '$_'},@_)) if scalar(@_)/2!=0;
    $new = {@_};
    keys (%$new) = $size + 5 if defined($size);
  }
  bless $new, $class;
  return $new;
}

=pod

=item $node->destroy

This function destroys a Treex::PML::Node (and all its descendants). 
If the node has a parent, it is cut from it first.

=cut

sub destroy {
  my ($top) = @_;
  $top->cut() if $top->{$parent};
  undef %$_ for ($top->descendants,$top);
  return;
}

=item $node->destroy_leaf

This function destroys a leaf Treex::PML::Node and fails if the node is not a leaf (has children).
If the node has a parent, it is cut from it first.

=cut

sub destroy_leaf {
  my ($node) = @_;
  unless ($node->firstson) {
    $node->cut;
    undef %$node;
    undef $node;
    return 1;
  } else {
    croak(ref($node)."->destroy_leaf: Not a leaf node");
  }
}

{
no warnings qw(recursion); # disable deep recursion warnings in Treex::PML::Node::DESTROY (btw, no recursion there:-))
sub DESTROY {
  my ($self) = @_;
  return unless ref($self);
  %{$self}=(); # this should not be needed, but
               # without it, perl 5.10 leaks on weakened
               # structures, try:
               #   Scalar::Util::weaken({}) while 1
  return 1;
}
}

=pod

=item $node->parent

Return node's parent node (C<undef> if none).

=cut

sub parent {
  return shift()->{$parent};
}

=pod

=item $node->type (attr-path?)

If called without an argument or if C<attr-path> is empty, return
node's data-type declaration (C<undef> if none). If C<attr-path> is
non-empty, return the data-type declaration of the value reachable
from C<$node> under the attribute-path C<attr-path>.

=cut


sub type {
  my ($self,$attr) = @_;
  my $type = $self->{$TYPE};
  if (defined $attr and length $attr) {
    return $type ? $type->find($attr,1) : undef;
  } else {
    return $type;
  }
}

=item $node->root

Find and return the root of the node's tree.

=cut


sub root {
  my ($node) = @_;
  while (my $p = $node->{$parent}) {
    $node=$p;
  }
  return $node;
}

=item $node->level

Calculate node's level (root-level is 0).

=cut

sub level {
  my ($node) = @_;
  my $level=-1;
  while ($node) {
    $node=$node->parent;
    $level++;
  }  return $level;
}


=pod

=item $node->lbrother

Return node's left brother node (C<undef> if none).

=cut

sub lbrother {
  return shift()->{$lbrother};
}

=pod

=item $node->rbrother

Return node's right brother node (C<undef> if none).

=cut

sub rbrother {
  return shift()->{$rbrother};
}

=pod

=item $node->firstson

Return node's first dependent node (C<undef> if none).

=cut

sub firstson {
  return shift()->{$firstson};
}

sub set_parent {
  my ($node,$p) = @_;
  if (ref( $p )) {
    weaken( $node->{$parent} = $p );
  } else {
    $node->{$parent} = undef;
  }
  return $p;
}

sub set_lbrother {
  my ($node,$p) = @_;
  if (ref( $p )) {
    weaken( $node->{$lbrother} = $p );
  } else {
    $node->{$lbrother} = undef;
  }
  return $p;
}

sub set_rbrother {
  my ($node,$p) = @_;
  $node->{$rbrother}= ref($p) ? $p : undef;
}

sub set_firstson {
  my ($node,$p) = @_;
  $node->{$firstson}=ref($p) ? $p : undef;
}

=item $node->set_type (type)

Wherever possible, avoid using this method directly; instead
create a typed nodes using Treex::PML::Factory->createTypedNode().

Associate Treex::PML::Node object with a type declaration-object (see
L<Treex::PML::Schema> class).

=cut

sub set_type {
  my ($node,$t) = @_;
  $node->{$TYPE}=$t;
}

=item $node->set_type_by_name (schema,type-name)

Lookup a structure or container declaration in the given Treex::PML::Schema
by its type name and associate the corresponding type-declaration
object with the Treex::PML::Node.

=cut

sub set_type_by_name {
  if (@_!=3) {
    croak('Usage: $node->set_type_by_name($schema, $type_name)');
  }
  my ($node,$schema,$name) = @_;
  my $type = $schema->get_type_by_name($name);
  if (ref($type)) {
    my $decl_type = $type->get_decl_type;
    if ($decl_type == PML_MEMBER_DECL() ||
        $decl_type == PML_ELEMENT_DECL() ||
        $decl_type == PML_TYPE_DECL() ||
        $decl_type == PML_ROOT_DECL() ) {
      $type = $type->get_content_decl;
    }
    $decl_type = $type->get_decl_type;
    if ($decl_type == PML_CONTAINER_DECL() ||
        $decl_type == PML_STRUCTURE_DECL()) {
      $node->set_type($type);
    } else {
      croak __PACKAGE__."::set_type_by_name: Incompatible type '$name' (neither a structure nor a container)";
    }
  } else {
    croak __PACKAGE__."::set_type_by_name: Type not found '$name'";
  }
}

=item $node->validate (attr-path?,log?)

This method requires C<$node> to be associated with a type declaration.

Validates the content of the node according to the associated type and
schema. If attr-path is non-empty, validate only attribute selected by
the attribute path. An array reference may be passed as the 2nd
argument C<log> to obtain a detailed report of all validation errors.

Note: this method does not validate descendants of the node. Use e.g.

  $node->validate_subtree(\@log);

to validate the complete subtree.

Returns: 1 if the content validates, 0 otherwise.

=cut

sub validate {
  my ($node, $path, $log) = @_;
  if (defined $log and UNIVERSAL::isa($log,'ARRAY')) {
    croak __PACKAGE__."::validate: log must be an ARRAY reference";
  }
  my $type = $node->type;
  if (!ref($type)) {
    croak __PACKAGE__."::validate: Cannot determine node data type!";
  }
  if ($path eq q{}) {
    $type->validate_object($node,{ log=>$log, no_childnodes => 1 });
  } else {
    my $mtype = $type->find($path);
    if ($mtype) {
      $mtype->validate_object($node->attr($path),
                              {
                                path => $path,
                                log=>$log
                               });
    } else {
      croak __PACKAGE__."::validate: can't determine data type from attribute-path '$path'!";
    }
  }
}

=item $node->validate_subtree (log?)

This method requires C<$node> to be associated with a type declaration.

Validates the content of the node and all its descendants according to
the associated type and schema. An array reference C<log> may be
passed as an argument to obtain a detailed report of all validation
errors.

Returns: 1 if the subtree validates, 0 otherwise.

=cut

sub validate_subtree {
  my ($node, $log) = @_;
  if (defined $log and ! UNIVERSAL::isa($log,'ARRAY')) {
    croak __PACKAGE__."::validate: log must be an ARRAY reference";
  }
  my $type = $node->type;
  if (!ref($type)) {
    croak __PACKAGE__."::validate: Cannot determine node data type!";
  }
  $type->validate_object($node,{ log=>$log });
}

=item $node->attribute_paths

This method requires C<$node> to be associated with a type declaration.

This method is similar to Treex::PML::Schema->attributes but for a single
node. It returns attribute paths valid for the current node. That is,
it returns paths to all atomic subtypes of the type of the current
node.


=cut

sub attribute_paths {
  my ($node) = @_;
  my $type = $node->type;
  return unless $type;
  return $type->schema->get_paths_to_atoms([$type],{ no_childnodes => 1 });
}


=pod

=item $node->following (top?)

Return the next node of the subtree in the order given by structure
(C<undef> if none). If any descendant exists, the first one is
returned. Otherwise, right brother is returned, if any.  If the given
node has neither a descendant nor a right brother, the right brother
of the first (lowest) ancestor for which right brother exists, is
returned.

=cut

sub following {
  my ($node,$top) = @_;
  if ($node->{$firstson}) {
    return $node->{$firstson};
  }
  $top||=0; # for ==
  do {
    return if ($node==$top or !$node->{$parent});
    return $node->{$rbrother} if $node->{$rbrother};
    $node = $node->{$parent};
  } while ($node);
  return;
}

=pod

=item $node->following_visible (FSFormat_object,top?)

Return the next visible node of the subtree in the order given by
structure (C<undef> if none). A node is considered visible if it has
no hidden ancestor. Requires FSFormat object as the first parameter.

=cut

sub following_visible {
  my ($self,$fsformat,$top) = @_;
  return unless ref($self);
  my $node=$self->following($top);
  return $node unless ref($fsformat);
  my $hiding;
  while ($node) {
    return $node unless ($hiding=$fsformat->isHidden($node));
    $node=$hiding->following_right_or_up($top);
  }
}

=pod

=item $node->following_right_or_up (top?)

Return the next node of the subtree in the order given by
structure (C<undef> if none), but not descending.

=cut

sub following_right_or_up {
  my ($self,$top) = @_;
  return unless ref($self);

  my $node=$self;
  while ($node) {
    return 0 if (defined($top) and $node==$top or !$node->parent);
    return $node->rbrother if $node->rbrother;
    $node = $node->parent;
  }
}


=pod

=item $node->previous (top?)

Return the previous node of the subtree in the order given by
structure (C<undef> if none). The way of searching described in
C<following> is used here in reversed order.

=cut

sub previous {
  my ($node,$top) = @_;
  return unless ref $node;
  $top||=0;
  if ($node->{$lbrother}) {
    $node = $node->{$lbrother};
  DIGDOWN: while ($node->{$firstson}) {
      $node = $node->{$firstson};
    LASTBROTHER: while ($node->{$rbrother}) {
            $node = $node->{$rbrother};
        next LASTBROTHER;
      }
      next DIGDOWN;
    }
    return $node;
  }
  return if ($node == $top or !$node->{$parent});
  return $node->{$parent};
}


=pod

=item $node->previous_visible (FSFormat_object,top?)

Return the next visible node of the subtree in the order given by
structure (C<undef> if none). A node is considered visible if it has
no hidden ancestor. Requires FSFormat object as the first parameter.

=cut

sub previous_visible {
  my ($self,$fsformat,$top) = @_;
  return unless ref($self);
  my $node=$self->previous($top);
  my $hiding;
  return $node unless ref($fsformat);
  while ($node) {
    return $node unless ($hiding=$fsformat->isHidden($node));
    $node=$hiding->previous($top);
  }
}


=pod

=item $node->rightmost_descendant (node)

Return the rightmost lowest descendant of the node (or
the node itself if the node is a leaf).

=cut

sub rightmost_descendant {
  my ($self) = @_;
  return unless ref($self);
  my $node=$self;
 DIGDOWN: while ($node->firstson) {
    $node = $node->firstson;
  LASTBROTHER: while ($node->rbrother) {
      $node = $node->rbrother;
      next LASTBROTHER;
    }
    next DIGDOWN;
  }
  return $node;
}


=pod

=item $node->leftmost_descendant (node)

Return the leftmost lowest descendant of the node (or
the node itself if the node is a leaf).

=cut

sub leftmost_descendant {
  my ($self) = @_;
  return unless ref($self);
  my $node=$self;
  $node=$node->firstson while ($node->firstson);
  return $node;
}

=pod

=item $node->getAttribute (attr_name)

Return value of the given attribute.

=cut

# compatibility
sub getAttribute  { shift()->get_member(@_) }

=item $node->attr (path)

Retrieve first value matching a given attribute path.

$node->attr($path)

is an alias for

Treex::PML::Instance::get_data($node,$path);

See L<Treex::PML::Instance::get_data|Treex::PML::Instance/get_data> for details.

=cut

sub attr {
  &Treex::PML::Instance::get_data;
}

=item $node->all (path)

Retrieve all values matching a given attribute path.

$node->all($path)

is an alias for

Treex::PML::Instance::get_all($node,$path);

See L<Treex::PML::Instance::get_all|Treex::PML::Instance/get_all> for details.

=cut

sub all {
  &Treex::PML::Instance::get_all;
}

sub flat_attr {
  my ($node,$path) = @_;
  return "$node" unless ref($node);
  my ($step,$rest) = split /\//, $path,2;
  if (UNIVERSAL::DOES::does($node,'Treex::PML::List') or
      UNIVERSAL::DOES::does($node,'Treex::PML::Alt')) {
    if ($step =~ /^\[(\d+)\]$/) {
      return flat_attr($node->[$1-1],$rest);
    } else {
      return join "|",map { flat_attr($_,$rest) } @$node;
    }
  } else {
    return flat_attr($node->{$step},$rest);
  }
}

=item $node->set_attr (path,value,strict?)

Store a given value to a possibly nested attribute of $node specified
by path. The path argument uses the XPath-like syntax described  in
L<Treex::PML::Instance::set_data|Treex::PML::Instance/set_data>.

=cut

sub set_attr {
  &Treex::PML::Instance::set_data;
}

=pod

=item $node->setAttribute (name,value)

Set value of the given attribute.

=cut

# compatibility
BEGIN {
*setAttribute = \&set_member;
}

=pod

=item $node->children

Return a list of dependent nodes.

=cut

sub children {
  my $self = $_[0];
  my @children=();
  my $child=$self->firstson;
  while ($child) {
    push @children, $child;
    $child=$child->rbrother;
  }
  return @children;
}

=pod

=item $node->visible_children (fsformat)

Return a list of visible dependent nodes.

=cut

sub visible_children {
  my ($self,$fsformat) = @_;
  croak "required parameter missing for visible_children(fsformat)" unless $fsformat;
  my @children=();
  unless ($fsformat->isHidden($self)) {
    my $hid=$fsformat->hide;
    my $child=$self->firstson;
    while ($child) {
      my $hidden = $child->getAttribute($hid);
      push @children, $child unless defined($hidden) and length($hidden);
      $child=$child->rbrother;
    }
  }
  return @children;
}


=item $node->descendants

Return a list recursively dependent nodes.

=cut

sub descendants {
  my $self = $_[0];
  my @kin=();
  my $desc=$self->following($self);
  while ($desc) {
    push @kin, $desc;
    $desc=$desc->following($self);
  }
  return @kin;
}

=item $node->visible_descendants (fsformat)

Return a list recursively dependent visible nodes.

=cut

sub visible_descendants {
  my ($self,$fsformat) = @_;
  croak "required parameter missing for visible_descendants(fsfile)" unless $fsformat;
  my @kin=();
  my $desc=$self->following_visible($fsformat,$self);
  while ($desc) {
    push @kin, $desc;
    $desc=$desc->following_visible($fsformat,$self);
  }
  return @kin;
}

=item $node->ancestors

Return a list of ancestor nodes of $node, e.g. the list of nodes on
the path from the node's parent to the root of the tree.

=cut

sub ancestors {
  my ($self)=@_;
  $self = $self->parent;
  my @ancestors;
  while ($self) {
    push @ancestors,$self;
    $self = $self->parent;
  }
  return @ancestors;
}


=item $node->cut ()

Disconnect the node from its parent and siblings. Returns the node
itself.

=cut

sub cut {
  my ($node)=@_;
  my $p = $node->{$parent};
  if ($p and $node==$p->{$firstson}) {
    $p->{$firstson}=$node->{$rbrother};
  }
  $node->{$lbrother}->set_rbrother($node->{$rbrother}) if ($node->{$lbrother});
  $node->{$rbrother}->set_lbrother($node->{$lbrother}) if ($node->{$rbrother});
  $node->{$parent}=$node->{$lbrother}=$node->{$rbrother}=undef;
  return $node;
}


=item $node->paste_on (new-parent,ord-attr)

Attach a new or previously disconnected node to a new parent, placing
it to the position among the other child nodes corresponding to a
numerical value obtained from the ordering attribute specified in
C<ord-attr>. If C<ord-attr> is not given, the node becomes the
left-most child of its parent.

This method does not check node types, but one can use
C<$parent-E<gt>test_child_type($node)> before using this method to verify
that the node is of a permitted child-type for the parent node.

Returns the node itself.

=cut

sub paste_on {
  my ($node,$p,$fsformat)=@_;
  my $aord = ref($fsformat) ? $fsformat->order : $fsformat;
  my $ordnum = defined($aord) ? $node->{$aord} : undef;
  my $b=$p->{$firstson};
  if ($b and defined($ordnum) and $ordnum>($b->{$aord}||0)) {
    $b=$b->{$rbrother} while ($b->{$rbrother} and $ordnum>$b->{$rbrother}->{$aord});
    my $rb = $b->{$rbrother};
    $node->{$rbrother}=$rb;
    # $rb->set_lbrother( $node ) if $rb;
    weaken( $rb->{$lbrother} = $node ) if $rb;
    $b->{$rbrother}=$node;
    #$node->set_lbrother( $b );
    weaken( $node->{$lbrother} = $b );
    #$node->set_parent( $p );
    weaken( $node->{$parent} = $p );
  } else {
    $node->{$rbrother}=$b;
    $p->{$firstson}=$node;
    $node->{$lbrother}=undef;
    #$b->set_lbrother( $node ) if ($b);
    weaken( $b->{$lbrother} = $node ) if $b;
    #$node->set_parent( $p );
    weaken( $node->{$parent} = $p );
  }
  return $node;
}

=item $node->paste_after (ref-node)

Attach a new or previously disconnected node to ref-node's parent node
as a closest right sibling of ref-node in the structural order of
sibling nodes.

This method does not check node types, but one can use
C<$ref_node-E<gt>parent->test_child_type($node)> before using this method
to verify that the node is of a permitted child-type for the parent
node.

Returns the node itself.

=cut

sub paste_after {
  my ($node,$ref_node)=@_;
  croak(__PACKAGE__."->paste_after: ref_node undefined") unless $ref_node;
  my $p = $ref_node->{$parent};
  croak(__PACKAGE__."->paste_after: ref_node has no parent") unless $p;

  my $rb = $ref_node->{$rbrother};
  $node->{$rbrother}=$rb;
  # $rb->set_lbrother( $node ) if $rb;
  weaken( $rb->{$lbrother} = $node ) if $rb;
  $ref_node->{$rbrother}=$node;
  #$node->set_lbrother( $ref_node );
  weaken( $node->{$lbrother} = $ref_node );
  #$node->set_parent( $p );
  weaken( $node->{$parent} = $p );
  return $node;
}

=item $node->paste_before (ref-node)

Attach a new or previously disconnected node to ref-node's parent node
as a closest left sibling of ref-node in the structural order of
sibling nodes.

This method does not check node types, but one can use
C<$ref_node-E<gt>parent->test_child_type($node)> before using this method
to verify that the node is of a permitted child-type for the parent
node.

Returns the node itself.

=cut

sub paste_before {
  my ($node,$ref_node)=@_;

  croak(__PACKAGE__."->paste_before: ref_node undefined") unless $ref_node;
  my $p = $ref_node->{$parent};
  croak(__PACKAGE__."->paste_before: ref_node has no parent") unless $p;

  my $lb = $ref_node->{$lbrother};
  # $node->set_lbrother( $lb );
  if ($lb) {
    weaken( $node->{$lbrother} = $lb );
    $lb->{$rbrother}=$node;
  } else {
    $node->{$lbrother}=undef;
    $p->{$firstson}=$node;
  }
  # $ref_node->set_lbrother( $node );
  weaken( $ref_node->{$lbrother} = $node );
  $node->{$rbrother}=$ref_node;
  weaken( $node->{$parent} = $p );
  return $node;
}

=item $node->test_child_type ( test_node )

This method can be used before a C<paste_on> or a similar operation to
test if the node provided as an argument is of a type that is valid
for children of the current node. More specifically, return 1 if the
current node is not associated with a type declaration or if it has
a #CHILDNODES member which is of a list or sequence type and the list
or sequence can contain members of the type of C<test_node>.
Otherwise return 0.

A type-declaration object can be passed directly instead of
C<test_node>.

=cut

sub test_child_type {
  my ($self, $obj) = @_;
  die 'Usage: $node->test_child_type($node_or_decl)' unless ref($obj);
  my $type =  $self->type;
  return 1 unless $type;
  if (UNIVERSAL::DOES::does($obj,'Treex::PML::Schema::Decl')) {
    if ($obj->get_decl_type == PML_TYPE_DECL) {
      # a named type decl passed, no problem
      $obj = $obj->get_content_decl;
    }
  } else {
    # assume it's a node
    $obj = $obj->type;
    return 0 unless $obj;
  }
  if ($type->get_decl_type == PML_ELEMENT_DECL) {
    $type = $type->get_content_decl;
  }
  my ($ch) = $type->find_members_by_role('#CHILDNODES');
  if ($ch) {
    my $ch_is = $ch->get_decl_type;
    if ($ch_is == PML_MEMBER_DECL) {
      $ch = $ch->get_content_decl;
      $ch_is = $ch->get_decl_type;
    }
    if ($ch_is == PML_SEQUENCE_DECL) {
      return 1 if $ch->find_elements_by_content_decl($obj);
    } elsif ($ch_is == PML_LIST_DECL) { 
      return 1 if $ch->get_content_decl == $obj;
    }
  } else {
    return 0;
  }
}

=item $node->get_order

For a typed node return value of the ordering attribute on the node
(i.e. the one with role #ORDER). Returns undef for untyped nodes (for
untyped nodes the name of the ordering attribute can be obtained
from the FSFormat object).

=cut

sub get_order {
  my $self = $_[0];
  my $oattr = $self->get_ordering_member_name;
  return defined $oattr ? $self->{$oattr} : undef;
}

=item $node->get_ordering_member_name

For a typed node return name of the ordering attribute on the node
(i.e. the one with role #ORDER). Returns undef for untyped nodes (for
untyped nodes the name of the ordering attribute can be obtained
from the FSFormat object).

=cut

sub get_ordering_member_name {
  my $self = $_[0];
  my $type = $self->type;
  return undef unless $type;
  if ($type->get_decl_type == PML_ELEMENT_DECL) {
    $type = $type->get_content_decl;
  }
  my ($omember) = $type->find_members_by_role('#ORDER');
  if ($omember) {
    return ($omember->get_name);
  }
  return undef; # we want this undef
}

=item $node->get_id

For a typed node return value of the ID attribute on the node
(i.e. the one with role #ID). Returns undef for untyped nodes (for
untyped nodes the name of the ID attribute can be obtained
from the FSFormat object).

=cut

sub get_id {
  my $self = $_[0];
  my $oattr = $self->get_id_member_name;
  return defined $oattr ? $self->{$oattr} : undef;
}

=item $node->get_id_member_name

For a typed node return name of the ID attribute on the node
(i.e. the one with role #ID). Returns undef for untyped nodes (for
untyped nodes the name of the ID attribute can be obtained
from the FSFormat object).

=cut

sub get_id_member_name {
  my $self = $_[0];
  my $type = $self->type;
  return undef unless $type;
  if ($type->get_decl_type == PML_ELEMENT_DECL) {
    $type = $type->get_content_decl;
  }
  my ($omember) = $type->find_members_by_role('#ID');
  if ($omember) {
    return ($omember->get_name);
  }
  return undef; # we want this undef
}

sub _weakenLinks {
  my ($node)=@_;
  for ($node->{$lbrother}, $node->{$parent}) {
    weaken( $_ ) if $_
  }
}

######################################################################

eval << 'EO_XPATH' if ($ENV{'TREEX_PML_ENABLE_XPATH_EXTENSION'});
*getRootNode = *root;
*getParentNode = *parent;
*getNextSibling = *rbrother;
*getPreviousSibling = *lbrother;
*getChildNodes = sub { wantarray ? $_[0]->children : [ $_[0]->children ] };

sub getElementById { }
sub isElementNode { 1 }
sub get_global_pos { 0 }
sub getNamespaces { return wantarray ? () : []; }
sub isTextNode { 0 }
sub isPINode { 0 }
sub isCommentNode { 0 }
sub getNamespace { undef }
sub getValue { undef }
sub getName { "node" }
*getLocalName = *getName;
*string_value = *getValue;

sub getAttributes {
  my ($self) = @_;
  my @attribs = map { 
    Treex::PML::Attribute->new($self,$_,$self->{$_})
  } keys %$self;
  return wantarray ? @attribs : \@attribs;
}

sub find {
    my ($node,$path) = @_;
    require XML::XPath;
    local $_; # XML::XPath isn't $_-safe
    my $xp = XML::XPath->new(); # new is v. lightweight
    return $xp->find($path, $node);
}

sub findvalue {
    my ($node,$path) = @_;
    require XML::XPath;
    local $_; # XML::XPath isn't $_-safe
    my $xp = XML::XPath->new();
    return $xp->findvalue($path, $node);
}

sub findnodes {
    my ($node,$path) = @_;
    require XML::XPath;
    local $_; # XML::XPath isn't $_-safe
    my $xp = XML::XPath->new();
    return $xp->findnodes($path, $node);
}

sub matches {
    my ($node,$path,$context) = @_;
    require XML::XPath;
    local $_; # XML::XPath isn't $_-safe
    my $xp = XML::XPath->new();
    return $xp->matches($node, $path, $context);
}

package Treex::PML::Attribute;
use Carp;

sub new { # node, name, value
  my $class = shift;
  return bless [@_],$class;
}
sub getElementById { $_[0]->getElementById($_[1]) }
sub getLocalName { $_[0][1] }
BEGIN { *getName = \&getLocalName; }
sub string_value { $_[0][2] }
BEGIN { *getValue = \&string_value; }
sub getRootNode { $_[0][0]->getRootNode() }
sub getParentNode { $_[0][0] }
sub getNamespace { undef }

EO_XPATH


1;

=back

=cut

__END__

=head1 SEE ALSO

L<Treex::PML>, L<Treex::PML::Factory>, L<Treex::PML::Document>,
L<Treex::PML::Struct>, L<Treex::PML::Container>, L<Treex::PML::Schema>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2010 by Petr Pajas

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut


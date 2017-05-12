package Tree::Node;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.08';

require XSLoader;
XSLoader::load('Tree::Node', $VERSION);

require Exporter;

our @ISA = qw( Exporter );

our %EXPORT_TAGS = (
  'p_node' => [qw(
    p_new p_destroy p_allocated
    p_child_count p_get_child p_get_child_or_null p_set_child
    p_set_key p_force_set_key p_get_key p_key_cmp
    p_set_value p_get_value
  )],
  'utility' => [qw(
    _allocated_by_child_count MAX_LEVEL
  )],
);
$EXPORT_TAGS{'all'} = [
 @{ $EXPORT_TAGS{'p_node'} },
 @{ $EXPORT_TAGS{'utility'} }
];
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT    = ( );


1;
__END__

=head1 NAME

Tree::Node - Memory-efficient tree nodes in Perl

=begin readme,install

=head1 REQUIREMENTS

Perl 5.6.0 or newer is required. Only core modules are used.

A C compiler to is required to build the module.  (There is no Pure-perl
version because this package was written to overcome limitations of Perl.
See the L</DESCRIPTION> section below.)

=head1 INSTALLATION

Installation can be done using the traditional F<Makefile.PL> method:

  perl Makefile.PL
  make
  make test
  make install

(On Windows platforms you should use C<nmake> instead.)

=end readme,install

=for install stop

=head1 SYNOPSIS

  use Tree::Node;

  $node = Tree::Node->new(2);

  $node->set_child(0, $left);
  $node->set_child(1, $right);

  while ($node->key_cmp($key) < 0) {
    $node = $node->get_child(0);
  }    

=head1 DESCRIPTION

This module implements a memory-efficient node type (for trees,
skip lists and similar data structures) for Perl.

You may ask "Why bother implementing an ordered structure such
as a tree when Perl has hashes built-in?"  Since Perl is optimized
for speed over memory usage, hashes (and lists) use a lot of memory.

Using L<Devel::Size> for a reference, a list with four elements
(corresponding to a key, value, and two child node pointers) will
use at least 120 bytes.  A hash with four key/value pairs will
use at least 228 bytes.  But an equivalent L<Tree::Node> object
will use at least 68 bytes.  (However, see the L</KNOWN ISSUES>
section below for caveats regarding memory usage.)

So the purpose of this package is to provide a simple low-level Node
class which can be used as a base class to implement various kinds
of tree structures.  Each node has a key/value pair and a variable
number of "children" pointers.

How nodes are organized or the algorithm used to organize them is
for you to implement.

=for readme stop

=head2 Object Oritented Interface

=over

=item new

  $node = Tree::Node->new( $child_count );

Creates a new node with C<$child_count> children.  Only as much space as is
needed is allocated, and the number of children cannot be expanded later
on.

C<$child_count> cannot exceed L</MAX_LEVEL>.

=item child_count

  $child_count = $node->child_count;

Returns the number of childen allocated.

=item set_key

  $node->set_key($key);

Sets the key. Once it is set, it cannot be changed.

=item force_set_key

  $node->force_set_key($key);

Sets the key, irregardless of whether it is already set. (Note
that many data structures assume that the key is never changed,
so you should only use this for cases where it is safe to do
so.)

=item key

  $key = $node->key;

Returns the node key.

=item key_cmp

  if ($node->key_cmp($key) < 0) { ... }

Compares the node key with a key using the Perl string comparison
function C<cmp>.  Returns -1 if the node key is less than the
argument, 0 if it is equal, and 1 if it is greater.

If the key is undefined, then it will always return -1 (even if the
argument is undefined).

This method can be overriden if you need a different comparison
routine.  To use numeric keys, for example:

  package Tree::Node::Numeric;

  use base 'Tree::Node';

  sub key_cmp {
    my $self = shift;
    my $key  = shift;
    return ($self->key <=> $key);
  }

B<Warning>: if you are also using the L</Procedural Interface>, then you
should be aware that L</p_key_cmp> will not be inherited.  Instead, you
should use something like the following:

  {
    no warnings 'redefine';

    sub p_key_cmp {
      my $ptr  = shift;
      my $key  = shift;
      return (p_key_key($ptr) <=> $key);
    }

    sub key_cmp {
      my $self = shift;
      my $key  = shift;
      return (p_key_cmp($self->to_p_node), $key);
    }
  }

=item set_value

  $node->set_value($value);

Sets the value of the node.  The value can be changed.

=item value

  $value = $node->value;

Returns the value of the node.

=item set_child

  $node->set_child($index, $child);

Sets the child node.  C<$index> must be between 0 and L</child_count>-1.
Dues when the C<$index> is out of bounds.

=item get_child

  $child = $node->get_child($index);

Returns the child node.  Dies when the C<$index> is out of bounds.

=item get_child_or_undef

  $child = $node->get_child_or_undef($index);

Like L</get_child>, but returns C<undef> rather than dying when the
C<$index> is out of bounds.

=item get_children

  @children = $node->get_children;

=item add_children

  $node->add_children(@children)

Increases the L</child_count> and allocates space for the child nodes
specified.  (The child nodes can be C<undef>.)

=item add_children_left

Same as L</add_children>, except that the new nodes are added to
the beginning rather than end of the node list.

=item MAX_LEVEL

  use Tree::Node ':utility';

  ...

  $max = MAX_LEVEL;

Returns the maximum number of children. Defaults to the C constant
C<UCHAR_MAX>, which is usually 255.

=item _allocated

  $size = $node->_allocated;

This is a utility routine which says how much space is allocated for a
node.  It does not include the Perl overhead (see L</KNOWN ISSUES> below).

=item _allocated_by_child_count

  use Tree::Node ':utility';

  ...

  $size = _allocated_by_child_count( $child_count );

This is a utility routine which returns the amount of space that would be
allocated for a node with C<$child_count> children.

=item to_p_node

  $ptr = $node->to_p_node;

This returns the pointer to the raw node data, which can be used in
the L</Procedural Interface>.

B<Warning>: do not mix and match object-oriented and procedural interface
calls when reading child nodes!  Child node pointers are stored in an
incompatible format.

=back

=head2 Procedural Inferface

The experimental procedural interface was added in version 0.06.  The
advantage of this interface is that there is much less overhead than the
object-oriented interface (16 bytes instead of 45 bytes).  A disadvantage
is that the node cannot be simply subclassed to change the L</p_key_cmp>
function.

To use the procedural interface, you must import the procedure names:

  use Tree::Node ':p_node';

Aside from working with pointers rather than blessed objects, the 
procedures listed below are analagous to their object-oriented
counterparts.

However, you must manually call L</p_destroy> when you are done with
the node, since Perl will not automatically destroy it when done.

=over

=item p_new

  $ptr = p_new( $child_count );

=item p_child_count

  $child_count = p_child_count( $ptr );

=item p_set_child

  p_set_child( $mother_ptr, $index, $daughter_ptr );

=item p_get_child

  $daughter_ptr = p_get_child( $mother_ptr, $index );

=item p_get_child_or_null

  $daughter_ptr = p_get_child_or_null( $mother_ptr, $index );

=item p_set_key

  p_set_key( $ptr, $key );

See L</to_p_node> for caveats about mixing interfaces.

=item p_force_set_key

  p_force_set_key( $ptr, $key );

See L</to_p_node> for caveats about mixing interfaces.

=item p_get_key

  $key = p_get_key( $ptr );

See L</to_p_node> for caveats about mixing interfaces.

=item p_key_cmp

  if (p_key_cmp( $ptr, $key ) < 0) { ... }

See L</key_cmp> for caveats about mixing interfaces.

=item p_set_value

  p_set_value( $ptr, $value );

=item p_get_value

  $value = p_get_value( $ptr );

=item p_allocated

  $size = p_allocated($ptr);

=item p_destroy

  p_destroy($ptr);

This unallocates the memory.  Perl will not call this automatically, so
you must remember to manually destroy each pointer!

=back

=for readme continue

=begin readme

=head1 REVISION HISTORY

The following changes have been made since the last release:

=for readme include file="Changes" type="text" start="^0.08" stop="^0.06"

See the F<Changes> file for a more detailed revision history.

=end readme

=for readme continue

=head1 KNOWN ISSUES

This module implements a Perl wrapper around a C struct, which for the
object-oriented inferface involves a blessed reference to a pointer to
the struct.  This overhead of about 45 bytes may make up for any memory
savings that the C-based struct provided!

So if you what you are doing is implementing a simple key/value lookup,
then you may be better off sticking with hashes.  If what you are doing
requires a special structure that cannot be satisfied with hashes (even
sorted hashes), or requires a very large number of nodes, then this module
may be useful to you.

Another alternative is to use the L</Procedural Interface>.

=for readme stop

Packages such as L<Clone> and L<Storable> cannot properly handle Tree::Node
objects.

L<Devel::Size> may not properly determine the size of a node. Use the
L</_allocated> method to determine how much space is allocated for the
node in C.  This does not include the overhead for Perl to maintain a
reference to the C struct.

=for readme,install continue

=head1 SEE ALSO

L<Tree::DAG_Node> is written in pure Perl, but it offers a more
flexible interface.

=head1 AUTHOR

Robert Rothenberg <rrwo at cpan.org>

=head2 Suggestions and Bug Reporting

Feedback is always welcome.  Please use the CPAN Request Tracker at
L<http://rt.cpan.org> to submit bug reports.

=head1 LICENSE

Copyright (c) 2005,2007 Robert Rothenberg. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


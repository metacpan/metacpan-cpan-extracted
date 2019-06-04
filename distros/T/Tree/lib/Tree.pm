package Tree;

use 5.006;

use base 'Tree::Fast';
use strict;
use warnings;

our $VERSION = '1.14';

use Scalar::Util qw( blessed refaddr weaken );

# These are the class methods

my %error_handlers = (
    'quiet' => sub {
        my $node = shift;
        $node->last_error( join "\n", @_);
        return;
    },
    'warn' => sub {
        my $node = shift;
        $node->last_error( join "\n", @_);
        warn @_;
        return;
    },
    'die' => sub {
        my $node = shift;
        $node->last_error( join "\n", @_);
        die @_;
    },
);

sub QUIET { return $error_handlers{ 'quiet' } }
sub WARN  { return $error_handlers{ 'warn' } }
sub DIE   { return $error_handlers{ 'die' } }

# The default error handler is quiet
my $ERROR_HANDLER = $error_handlers{ 'quiet' };

sub _init {
    my $self = shift;

    $self->SUPER::_init( @_ );

    $self->{_height} = 1,
    $self->{_width} = 1,
    $self->{_depth} = 0,

    $self->{_error_handler} = $ERROR_HANDLER,
    $self->{_last_error} = undef;

    $self->{_handlers} = {
        add_child    => [],
        remove_child => [],
        value        => [],
    };

    $self->{_root} = undef,
    $self->_set_root( $self );

    return $self;
}

# These are the behaviors

sub add_child {
    my $self = shift;
    my @nodes = @_;

    $self->last_error( undef );

    my $options = $self->_strip_options( \@nodes );

    unless ( @nodes ) {
        return $self->error( "add_child(): No children passed in" );
    }

    if ( defined $options->{at}) {
        my $num_children = () = $self->children;
        unless ( $options->{at} =~ /^-?\d+$/ ) {
            return $self->error(
                "add_child(): '$options->{at}' is not a legal index"
            );
        }

        if ( $options->{at} > $num_children ||
                $num_children + $options->{at} < 0
        ) {
            return $self->error( "add_child(): '$options->{at}' is out-of-bounds" );
        }
    }

    for my $node ( @nodes ) {
        unless ( blessed($node) && $node->isa( __PACKAGE__ ) ) {
            return $self->error( "add_child(): '$node' is not a " . __PACKAGE__ );
        }

        if ( $node->root eq $self->root ) {
            return $self->error( "add_child(): Cannot add a node in the tree back into the tree" );
        }

        if ( $node->parent ) {
            return $self->error( "add_child(): Cannot add a child to another parent" );
        }
    }

    $self->SUPER::add_child( $options, @nodes );

    for my $node ( @nodes ) {
        $node->_set_root( $self->root );
        $node->_fix_depth;
    }

    $self->_fix_height;
    $self->_fix_width;

    $self->event( 'add_child', $self, @_ );

    return $self;
}

sub remove_child {
    my $self = shift;
    my @nodes = @_;

    $self->last_error( undef );

    my $options = $self->_strip_options( \@nodes );

    unless ( @nodes ) {
        return $self->error( "remove_child(): Nothing to remove" );
    }

    my @indices;
    my $num_children = () = $self->children;
    foreach my $proto (@nodes) {
        if ( !defined( $proto ) ) {
            return $self->error( "remove_child(): 'undef' is out-of-bounds" );
        }

        if ( !blessed( $proto ) ) {
            unless ( $proto =~ /^-?\d+$/ ) {
                return $self->error( "remove_child(): '$proto' is not a legal index" );
            }

            if ( $proto >= $num_children || $num_children + $proto <= 0 ) {
                return $self->error( "remove_child(): '$proto' is out-of-bounds" );
            }

            push @indices, $proto;
        }
        else {
            my ($index) = $self->get_index_for( $proto );

            unless ( defined $index ) {
                return $self->error( "remove_child(): '$proto' not found" );
            }

            push @indices, $index;
        }
    }

    my @return = $self->SUPER::remove_child( $options, @indices );

    for my $node ( @return ) {
        $node->_set_root( $node );
        $node->_fix_depth;
    }

    $self->_fix_height;
    $self->_fix_width;

    $self->event( 'remove_child', $self, @_ );

    return @return;
}

sub add_event_handler {
    my $self = shift;
    my ($opts) = @_;

    while ( my ($type,$handler) = each %$opts ) {
        push @{$self->{_handlers}{$type}}, $handler;
    }

    return $self;
}

sub event {
    my $self = shift;
    my ( $type, @args ) = @_;

    foreach my $handler ( @{$self->{_handlers}{$type}} ) {
        $handler->( @args );
    }

    $self->parent->event( @_ );

    return $self;
}

# These are the state-queries

sub is_root {
    my $self = shift;
    return !$self->parent;
}

sub is_leaf {
    my $self = shift;
    return $self->height == 1;
}

sub has_child {
    my $self = shift;
    my @nodes = @_;

    my @children = $self->children;
    my %temp = map { refaddr($children[$_]) => $_ } 0 .. $#children;

    my $rv = 1;
    $rv &&= exists $temp{refaddr($_)}
        for @nodes;
    return $rv;
}

sub get_index_for {
    my $self = shift;
    my @nodes = @_;

    my @children = $self->children;
    my %temp = map { refaddr($children[$_]) => $_ } 0 .. $#children;

    return map { $temp{refaddr($_)} } @nodes;
}

# These are the smart accessors

sub root {
    my $self = shift;
    return $self->{_root};
}

sub _set_root {
    my $self = shift;

    $self->{_root} = shift;
    weaken( $self->{_root} );

    # Propagate the root-change down to all children
    # Because this is called from DESTROY, we need to verify
    # that the child still exists because destruction in Perl5
    # is neither ordered nor timely.

    $_->_set_root( $self->{_root} )
        for grep { $_ } @{$self->{_children}};

    return $self;
}

for my $name ( qw( height width depth ) ) {
    no strict 'refs';

    *{ __PACKAGE__ . "::${name}" } = sub {
        use strict;
        my $self = shift;
        return $self->{"_${name}"};
    };
}

sub size {
    my $self = shift;
    my $size = 1;
    $size += $_->size for $self->children;
    return $size;
}

sub set_value {
    my $self = shift;

    my $old_value = $self->value();
    $self->SUPER::set_value( @_ );

    $self->event( 'value', $self, $old_value, $self->value );

    return $self;
}

# These are the error-handling functions

sub error_handler {
    my $self = shift;

    if ( !blessed( $self ) ) {
        my $old = $ERROR_HANDLER;
        $ERROR_HANDLER = shift if @_;
        return $old;
    }

    my $root = $self->root;
    my $old = $root->{_error_handler};
    $root->{_error_handler} = shift if @_;
    return $old;
}

sub error {
    my $self = shift;
    my @args = @_;

    return $self->error_handler->( $self, @_ );
}

sub last_error {
    my $self = shift;
    $self->root->{_last_error} = shift if @_;
    return $self->root->{_last_error};
}

# These are private convenience methods

sub _fix_height {
    my $self = shift;

    my $height = 1;
    for my $child ($self->children) {
        my $temp_height = $child->height + 1;
        $height = $temp_height if $height < $temp_height;
    }

    $self->{_height} = $height;

    $self->parent->_fix_height;

    return $self;
}

sub _fix_width {
    my $self = shift;

    my $width = 0;
    $width += $_->width for $self->children;

    $self->{_width} = $width ? $width : 1;

    $self->parent->_fix_width;

    return $self;
}

sub _fix_depth {
    my $self = shift;

    if ( $self->is_root ) {
        $self->{_depth} = 0;
    }
    else {
        $self->{_depth} = $self->parent->depth + 1;
    }

    $_->_fix_depth for $self->children;

    return $self;
}

sub _strip_options {
    my $self = shift;
    my ($params) = @_;

    if ( @$params && !blessed($params->[0]) && ref($params->[0]) eq 'HASH' ) {
        return shift @$params;
    }
    else {
        return {};
    }
}

# -----------------------------------------------

sub format_node
{
	my($self, $options, $node) = @_;
	my($s) = $node -> value;
	$s     .= '. Attributes: ' . $self -> hashref2string($node -> meta) if (! $$options{no_attributes});

	return $s;

} # End of format_node.

# -----------------------------------------------

sub hashref2string
{
	my($self, $hashref) = @_;
	$hashref ||= {};

	return '{' . join(', ', map{qq|$_ => "$$hashref{$_}"|} sort keys %$hashref) . '}';

} # End of hashref2string.

# -----------------------------------------------

sub node2string
{
	my($self, $options, $node, $vert_dashes) = @_;
	my($depth)         = $node -> depth;
	my(@siblings)      = $node -> parent -> children;
	my($sibling_count) = scalar @siblings; # Warning: Don't combine this with the previous line.
	my($offset)        = ' ' x 4;
	my(@indent)        = map{$$vert_dashes[$_] || $offset} 0 .. $depth - 1;
	@$vert_dashes      =
	(
		@indent,
		($sibling_count == 0 ? $offset : '    |'),
	);

	my(@i)                = $node -> parent -> get_index_for($node);
	my(@indexes)          = $node -> parent -> get_index_for($node);
	$$vert_dashes[$depth] = ($offset . ' ') if ($sibling_count == ($indexes[0] + 1) );

	return join('', @indent[1 .. $#indent]) . ($depth ? '    |--- ' : '') . $self -> format_node($options, $node);

} # End of node2string.

# ------------------------------------------------

sub tree2string
{
	my($self, $options)      = @_;
	$options                 ||= {};
	$$options{no_attributes} ||= 0;
	my(@nodes)               = $self -> traverse;

	my(@out);
	my(@vert_dashes);

	for my $i (0 .. $#nodes)
	{
		push @out, $self -> node2string($options, $nodes[$i], \@vert_dashes);
	}

	return [@out];

} # End of tree2string.

# -----------------------------------------------

1;
__END__

=head1 NAME

Tree - An N-ary tree

=head1 SYNOPSIS

  my $tree = Tree->new( 'root' );
  my $child = Tree->new( 'child' );
  $tree->add_child( $child );

  $tree->add_child( { at => 0 }, Tree->new( 'first child' ) );
  $tree->add_child( { at => -1 }, Tree->new( 'last child' ) );

  $tree->set_value( 'toor' );
  my $value = $tree->value;

  my @children = $tree->children;
  my @some_children = $tree->children( 0, 2 );

  my $height = $tree->height;
  my $width  = $tree->width;
  my $depth  = $tree->depth;
  my $size   = $tree->size;

  if ( $tree->has_child( $child ) ) {
      $tree->remove_child( $child );
  }

  $tree->remove_child( 0 );

  my @nodes = $tree->traverse( $tree->POST_ORDER );
  my $clone = $tree->clone; # See remarks under clone() re deep cloning.
  my $mirror = $tree->clone->mirror;

  $tree->add_event_handler({
      add_child    => sub { ... },
      remove_child => sub { ... },
      value        => sub { ... },
  });

  my $old_default_error_handler = $tree->error_handler(Tree->DIE);
  my $old_object_error_handler  = $tree->error_handler($tree->DIE);

=head1 DESCRIPTION

This is meant to be a full-featured N-ary tree representation with
configurable error-handling and a simple events system that allows for
transparent persistence to a variety of datastores. It is derived from
L<Tree::Simple>, but has a simpler interface and much, much more.

=head1 METHODS

=head2 Constructors

=head2 new([$value])

Here, [] indicate an optional parameter.

This will return a C<Tree> object. It will accept one parameter which, if passed,
will become the I<value> (accessible by C<value()>). All other parameters will be
ignored.

If you call C<< $tree->new([$value]) >>, it will instead call C<clone()>, then set
the I<value> of the clone to $value.

=head2 clone()

This will return a clone of C<$tree>. The clone will be a root tree, but all
children will be cloned.

If you call C<< Tree->clone([$value]) >>, it will instead call C<new($value)>.

B<NOTE:> the C<value> is merely a shallow copy. This means that all references
will be kept, but the C<meta> data attached to each node is not copied.

See L<Tree::DeepClone> and t/Tree_DeepClone/*.t if you want deep cloning, which is defined to
mean that the C<meta> data attached to each node is also copied into the clone.

=head2 Behaviors

=head2 add_child([$options], @nodes)

This will add all the C<@nodes> as children of C<$tree>. $options is a optional
unblessed hashref that specifies options for C<add_child()>. The optional
parameters are:

=over 4

=item * at

This specifies the index to add C<@nodes> at. If specified, this will be passed
into splice(). The only exceptions are if this is 0, it will act as an
unshift(). If it is unset or undefined, it will act as a push(). Lastly, if it is out of range
(too negative or too big [beyond the number of children]) the child is not added, and an error msg
will be available in L</last_error()>.

=back

add_child() resets last_error() upon entry.

=head2 remove_child([$options], @nodes)

Here, [] indicate an optional parameter.

This will remove all the C<@nodes> from the children of C<$tree>. You can either
pass in the actual child object you wish to remove, the index of the child you
wish to remove, or a combination of both.

$options is a optional unblessed hashref that specifies parameters for
remove_child(). Currently, no parameters are used.

remove_child() resets last_error() upon entry.

=head2 mirror()

This will modify the tree such that it is a mirror of what it was before. This
means that the order of all children is reversed.

B<NOTE>: This is a destructive action. It I<will> modify the internal structure
of the tree. If you wish to get a mirror, yet keep the original tree intact, use
C<< my $mirror = $tree->clone->mirror >>.

mirror() does not reset last_error() because it (mirror() ) is implemented in L<Tree::Fast>,
which has no error handling.

=head2 traverse([$order])

Here, [] indicate an optional parameter.

This will return a list of the nodes in the given traversal order. The default
traversal order is pre-order.

The various traversal orders do the following steps:

=over 4

=item * Pre-order

This will return the node, then the first sub tree in pre-order traversal,
then the next sub tree, etc.

Use C<< $tree->PRE_ORDER >> as the C<$order>.

=item * Post-order

This will return the each sub-tree in post-order traversal, then the node.

Use C<< $tree->POST_ORDER >> as the C<$order>.

=item * Level-order

This will return the node, then the all children of the node, then all
grandchildren of the node, etc.

Use C<< $tree->LEVEL_ORDER >> as the C<$order>.

=back

traverse() does not reset last_error() because it (traverse() ) is implemented in L<Tree::Fast>,
which has no error handling.

=head2 tree2string($options)

Returns an arrayref of lines, suitable for printing. These lines do not end in "\n".

Draws a nice ASCII-art representation of the tree structure.

The tree looks like:

	Root. Attributes: {uid => "0"}
	    |--- H. Attributes: {uid => "1"}
	    |    |--- I. Attributes: {uid => "2"}
	    |    |    |--- J. Attributes: {uid => "3"}
	    |    |--- K. Attributes: {uid => "4"}
	    |    |--- L. Attributes: {uid => "5"}
	    |--- M. Attributes: {uid => "6"}
	    |--- N. Attributes: {uid => "7"}
	         |--- O. Attributes: {uid => "8"}
	              |--- P. Attributes: {uid => "9"}
	                   |--- Q. Attributes: {uid => "10"}

Or, without attributes:

	Root
	    |--- H
	    |    |--- I
	    |    |    |--- J
	    |    |--- K
	    |    |--- L
	    |--- M
	    |--- N
	         |--- O
	              |--- P
	                   |--- Q

See scripts/print.tree.pl.

Example usage:

  print map("$_\n", @{$tree -> tree2string});

If you do not wish to supply options, use C<tree2string()> or C<tree2string({})>.

Possible keys in the $options hashref (which defaults to {}):

=over 4

=item o no_attributes => $Boolean

If 1, the node attributes are not included in the string returned.

Default: 0 (include attributes).

=back

Calls L</node2string($options, $node, $vert_dashes)>.

=head2 State Queries

=head2 is_root()

This will return true if C<$tree> has no parent and false otherwise.

=head2 is_leaf()

This will return true if C<$tree> has no children and false otherwise.

=head2 has_child(@nodes)

This will return true if C<$tree> has each of the C<@nodes> as a child.
Otherwise, it will return false.

The test to see if a node is in the tree uses refaddr() from L<Scalar::Util>, not the I<value> of the node.
This means C<@nodes> must be an array of C<Tree> objects.

=head2 get_index_for(@nodes)

This will return the index into the children list of C<$tree> for each of the C<@nodes>
passed in.

=head2 Accessors

=head2 parent()

This will return the parent of C<$tree>.

=head2 children( [ $idx, [$idx, ..] ] )

Here, [] indicate optional parameters.

This will return the children of C<$tree>. If called in list context, it will
return all the children. If called in scalar context, it will return the
number of children.

You may optionally pass in a list of indices to retrieve. This will return the
children in the order you asked for them. This is very much like an
arrayslice.

=head2 root()

This will return the root node of the tree that C<$tree> is in. The root of
the root node is itself.

=head2 height()

This will return the height of C<$tree>. A leaf has a height of 1. A parent
has a height of its tallest child, plus 1.

=head2 width()

This will return the width of C<$tree>. A leaf has a width of 1. A parent has
a width equal to the sum of all the widths of its children.

=head2 depth()

This will return the depth of C<$tree>. A root has a depth of 0. A child has
the depth of its parent, plus 1.

This is the distance from the root. It is useful for things like
pretty-printing the tree.

=head2 size()

This will return the number of nodes within C<$tree>. A leaf has a size of 1.
A parent has a size equal to the 1 plus the sum of all the sizes of its
children.

=head2 value()

This will return the value stored in the node.

=head2 set_value([$value])

Here, [] indicate an optional parameter.

This will set the I<value> stored in the node to $value, then return $self.

If C<$value> is not provided, undef is used.

=head2 meta()

This will return a hashref that can be used to store whatever metadata the
client wishes to store. For example, L<Tree::Persist::DB> uses this to store
database row ids.

It is recommended that you store your metadata in a subhashref and not in the
top-level metadata hashref, keyed by your package name. L<Tree::Persist> does
this, using a unique key for each persistence layer associated with that tree.
This will help prevent clobbering of metadata.

=head2 format_node($options, $node)

Returns a string consisting of the node's name and, optionally, it's attributes.

Possible keys in the $options hashref:

=over 4

=item o no_attributes => $Boolean

If 1, the node attributes are not included in the string returned.

Default: 0 (include attributes).

=back

Calls L</hashref2string($hashref)>.

Called by L</node2string($options, $node, $vert_dashes)>.

You would not normally call this method.

If you do not wish to supply options, use format_node({}, $node).

=head2 hashref2string($hashref)

Returns the given hashref as a string.

Called by L</format_node($options, $node)>.

=head2 node2string($options, $node, $vert_dashes)

Returns a string of the node name and attributes, with a leading indent, suitable for printing.

Possible keys in the $options hashref:

=over 4

=item o no_attributes => $Boolean

If 1, the node attributes are not included in the string returned.

Default: 0 (include attributes).

=back

Ignore the parameter $vert_dashes. The code uses it as temporary storage.

Calls L</format_node($options, $node)>.

Called by L</tree2string($options)>.

=head1 ERROR HANDLING

Describe what the default error handlers do and what a custom error handler is
expected to do.

=head2 Error-related methods

=head2 error_handler( [ $handler ] )

This will return the current error handler for the tree. If a value is passed
in, then it will be used to set the error handler for the tree.

If called as a class method, this will instead work with the default error
handler.

=head2 error( $error, [ arg1 [, arg2 ...] ] )

Call this when you wish to report an error using the currently defined
error_handler for the tree. The only guaranteed parameter is an error string
describing the issue. There may be other arguments, and you may certainly
provide other arguments in your subclass to be passed to your custom handler.

=head2 last_error()

If an error occurred during the last behavior, this will return the error
string. It is reset only by add_child() and remove_child().

=head2 Default error handlers

=over 4

=item QUIET

Use this error handler if you want to have quiet error-handling. The
L</last_error()> method will retrieve the error from the last operation, if there
was one. If an error occurs, the operation will return undefined.

=item WARN

=item DIE

=back

=head1 EVENT HANDLING

Tree provides for basic event handling. You may choose to register one or
more callbacks to be called when the appropriate event occurs. The events
are:

=over 4

=item * add_child

This event will trigger as the last step in an L</add_child([$options], @nodes)> call.

The parameters will be C<( $self, @args )> where C<@args> is the arguments
passed into the add_child() call.

=item * remove_child

This event will trigger as the last step in an L</remove_child([$options], @nodes)> call.

The parameters will be C<( $self, @args )> where C<@args> is the arguments
passed into the remove_child() call.

=item * value

This event will trigger as the last step in a L<set_value()> call.

The parameters will be C<( $self, $old_value )> where
C<$old_value> is what the value was before it was changed. The new value can
be accessed through C<$self-E<gt>value()>.

=back

=head2 Event handling methods

=head2 add_event_handler( {$type => $callback [, $type => $callback, ... ]} )

You may choose to add event handlers for any known type. Callbacks must be
references to subroutines. They will be called in the order they are defined.

=head2 event( $type, $actor, @args )

This will trigger an event of type C<$type>. All event handlers registered on
C<$tree> will be called with parameters of C<($actor, @args)>. Then, the
parent will be notified of the event and its handlers will be called, on up to
the root.

This allows you specify an event handler on the root and be guaranteed that it
will fire every time the appropriate event occurs anywhere in the tree.

=head1 NULL TREE

If you call C<$self-E<gt>parent> on a root node, it will return a Tree::Null
object. This is an implementation of the Null Object pattern optimized for
usage with L<Tree>. It will evaluate as false in every case (using
I<overload>) and all methods called on it will return a Tree::Null object.

=head2 Notes

=over 4

=item *

Tree::Null does B<not> inherit from Tree. This is so that all the
methods will go through AUTOLOAD vs. the actual method.

=item *

However, calling isa() on a Tree::Null object will report that it is-a
any object that is either Tree or in the Tree:: hierarchy.

=item *

The Tree::Null object is a singleton.

=item *

The Tree::Null object I<is> defined, though. I could not find a way to
make it evaluate as undefined. That may be a good thing.

=back

=head1 CIRCULAR REFERENCES

Please q.v. L<Forest> for more info on this topic.

=head1 FAQ

=head2 Which is the best tree processing module?

L<Tree::DAG_Node>. More details: L</SEE ALSO>.

=head2 How do I implement the visitor pattern?

I have deliberately chosen to not implement the Visitor pattern as described
by Gamma et al. Given a sufficiently powerful C<traverse()> and the capabilities
of Perl, an explicit visitor object is almost always unneeded. If you
want one, it is easy to write one yourself. Here is a simple one I wrote in 5
minutes:

  package My::Visitor;

  sub new {
      my $class = shift;
      my $opts  = @_;

      return bless {
          tree => $opts->{tree},
          action => $opts->{action},
      }, $class;
  }

  sub visit {
      my $self = shift;
      my ($mode) = @_;

      foreach my $node ( $self->{tree}->traverse( $mode ) ) {
          $self->{action}->( $node );
      }
  }

=head2 Should I implement the visitor pattern?

No. You are better off using the L<Tree::DAG_Node/walk_down($options)> method.

=head1 SEE ALSO

=over 4

=item o L<Tree::Binary>

Lightweight.

=item o L<Tree::DAG_Node>

Lightweight, and with a long list of methods.

=item o L<Tree::DAG_Node::Persist>

Lightweight.

=item o L<Tree::Persist>

Lightweight.

=item o L<Forest>

Uses L<Moose>.

=back

C<Tree> itself is also lightweight.

=head1 CODE COVERAGE

These statistics are as of V 1.01.

We use L<Devel::Cover> to test the code coverage of our tests. Below is the
L<Devel::Cover> report on the test suite of this module.

  ---------------------------- ------ ------ ------ ------ ------ ------ ------
  File                           stmt   bran   cond    sub    pod   time  total
  ---------------------------- ------ ------ ------ ------ ------ ------ ------
  blib/lib/Tree.pm              100.0  100.0   94.4  100.0  100.0   67.3   99.7
  blib/lib/Tree/Binary.pm        96.4   95.0  100.0  100.0  100.0   10.7   96.7
  blib/lib/Tree/Fast.pm          99.4   95.5   91.7  100.0  100.0   22.0   98.6
  Total                          98.9   96.8   94.9  100.0  100.0  100.0   98.5
  ---------------------------- ------ ------ ------ ------ ------ ------ ------

=head1 ACKNOWLEDGEMENTS

=over 4

=item * Stevan Little for writing L<Tree::Simple>, upon which Tree is based.

=back

=head1 Repository

L<https://github.com/ronsavage/Tree>

=head1 SUPPORT

The mailing list is at L<TreeCPAN@googlegroups.com>. I also read
L<http://www.perlmonks.com> on a daily basis.

=head1 AUTHORS

Rob Kinyon E<lt>rob.kinyon@iinteractive.comE<gt>

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

Thanks to Infinity Interactive for generously donating our time.

Co-maintenance since V 1.02 is by Ron Savage <rsavage@cpan.org>.
Uses of 'I' in previous versions is not me, but will be hereafter.

=head1 COPYRIGHT AND LICENSE

Copyright 2004, 2005 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut


package Tree::Binary;

use strict;
use warnings;

our $VERSION = '1.08';

use Scalar::Util qw(blessed);

## ----------------------------------------------------------------------------
## Tree::Binary
## ----------------------------------------------------------------------------

### constructor

sub new {
	my ($_class, $node) = @_;
	my $class = ref($_class) || $_class;
	my $binary_tree = {};
	bless($binary_tree, $class);
	$binary_tree->_init($node);
	return $binary_tree;
}

### ---------------------------------------------------------------------------
### methods
### ---------------------------------------------------------------------------

## ----------------------------------------------------------------------------
## private methods

sub _init {
	my ($self, $node) = @_;
    (defined($node)) || die "Insufficient Arguments : you must provide a node value";
    # set the value of the unique id
    ($self->{_uid}) = ("$self" =~ /\((.*?)\)$/);
	# set the value of the node
	$self->{_node}   = $node;
    # create the child nodes
    $self->{_left}   = undef;
    $self->{_right}  = undef;
    # initialize the parent and depth here
    $self->{_parent} = undef;
    $self->{_depth}  = 0;
}

## ----------------------------------------------------------------------------
## mutators

sub setNodeValue {
	my ($self, $node_value) = @_;
	(defined($node_value)) || die "Insufficient Arguments : must supply a value for node";
	$self->{_node} = $node_value;
}

sub setUID {
    my ($self, $uid) = @_;
    ($uid) || die "Insufficient Arguments : Custom Unique ID's must be a true value";
    $self->{_uid} = $uid;
}

sub setLeft {
    my ($self, $tree) = @_;
    (blessed($tree) && $tree->isa("Tree::Binary"))
        || die "Insufficient Arguments : left argument must be a Tree::Binary object";
	$tree->{_parent} = $self;
    $self->{_left} = $tree;
    unless ($tree->isLeaf()) {
        $tree->fixDepth();
    }
    else {
        $tree->{_depth} = $self->getDepth() + 1;
    }
    $self;
}

sub removeLeft {
    my ($self) = @_;
    ($self->hasLeft()) || die "Illegal Operation: cannot remove node that doesnt exist";
    my $left = $self->{_left};
    $left->{_parent} = undef;
    unless ($left->isLeaf()) {
        $left->fixDepth();
    }
    else {
        $left->{_depth} = 0;
    }
    $self->{_left} = undef;
    return $left;
}

sub setRight {
    my ($self, $tree) = @_;
    (blessed($tree) && $tree->isa("Tree::Binary"))
        || die "Insufficient Arguments : right argument must be a Tree::Binary object";
	$tree->{_parent} = $self;
    $self->{_right} = $tree;
    unless ($tree->isLeaf()) {
        $tree->fixDepth();
    }
    else {
        $tree->{_depth} = $self->getDepth() + 1;
    }
    $self;
}

sub removeRight {
    my ($self) = @_;
    ($self->hasRight()) || die "Illegal Operation: cannot remove node that doesnt exist";
    my $right = $self->{_right};
    $right->{_parent} = undef;
    unless ($right->isLeaf()) {
        $right->fixDepth();
    }
    else {
        $right->{_depth} = 0;
    }
    $self->{_right} = undef;
    return $right;
}

## ----------------------------------------------------------------------------
## accessors

sub getUID {
    my ($self) = @_;
    return $self->{_uid};
}

sub getParent {
	my ($self)= @_;
	return $self->{_parent};
}

sub getDepth {
	my ($self) = @_;
	return $self->{_depth};
}

sub getNodeValue {
	my ($self) = @_;
	return $self->{_node};
}

sub getLeft {
    my ($self) = @_;
    return $self->{_left};
}

sub getRight {
    my ($self) = @_;
    return $self->{_right};
}

## ----------------------------------------------------------------------------
## informational

sub isLeaf {
	my ($self) = @_;
	return (!defined $self->{_left} && !defined $self->{_right});
}

sub hasLeft {
    my ($self) = @_;
    return defined $self->{_left};
}

sub hasRight {
    my ($self) = @_;
    return defined $self->{_right};
}

sub isRoot {
	my ($self) = @_;
	return not defined $self->{_parent};
}

## ----------------------------------------------------------------------------
## misc

# NOTE:
# Occasionally one wants to have the
# depth available for various reasons
# of convience. Sometimes that depth
# field is not always correct.
# If you create your tree in a top-down
# manner, this is usually not an issue
# since each time you either add a child
# or create a tree you are doing it with
# a single tree and not a hierarchy.
# If however you are creating your tree
# bottom-up, then you might find that
# when adding hierarchies of trees, your
# depth fields are all out of whack.
# This is where this method comes into play
# it will recurse down the tree and fix the
# depth fields appropriately.
# This method is called automatically when
# a subtree is added to a child array
sub fixDepth {
	my ($self) = @_;
	# make sure the tree's depth
	# is up to date all the way down
	$self->traverse(sub {
			my ($tree) = @_;
            unless ($tree->isRoot()) {
                $tree->{_depth} = $tree->getParent()->getDepth() + 1;
            }
            else {
                $tree->{_depth} = 0;
            }
		}
	);
}

sub traverse {
	my ($self, $func) = @_;
	(defined($func)) || die "Insufficient Arguments : Cannot traverse without traversal function";
    (ref($func) eq "CODE") || die "Incorrect Object Type : traversal function is not a function";
    $func->($self);
    $self->{_left}->traverse($func) if defined $self->{_left};
    $self->{_right}->traverse($func) if defined $self->{_right};
}

sub mirror {
    my ($self) = @_;
    # swap left for right
    my $temp = $self->{_left};
    $self->{_left} = $self->{_right};
    $self->{_right} = $temp;
    # and recurse
    $self->{_left}->mirror() if $self->hasLeft();
    $self->{_right}->mirror() if $self->hasRight();
    $self;
}

sub size {
    my ($self) = @_;
    my $size = 1;
    $size += $self->{_left}->size() if $self->hasLeft();
    $size += $self->{_right}->size() if $self->hasRight();
    return $size;
}

sub height {
    my ($self) = @_;
    my ($left_height, $right_height) = (0, 0);
    $left_height = $self->{_left}->height() if $self->hasLeft();
    $right_height = $self->{_right}->height() if $self->hasRight();
    return 1 + (($left_height > $right_height) ? $left_height : $right_height);
}

sub accept {
	my ($self, $visitor) = @_;
    # it must be a blessed reference and ...
	(blessed($visitor) &&
        # either a Tree::Simple::Visitor object, or ...
        ($visitor->isa("Tree::Binary::Visitor") ||
            # it must be an object which has a 'visit' method avaiable
            $visitor->can('visit')))
		|| die "Insufficient Arguments : You must supply a valid Visitor object";
	$visitor->visit($self);
}

## ----------------------------------------------------------------------------
## cloning

sub clone {
    my ($self) = @_;
    # first clone the value in the node
    my $cloned_node = _cloneNode($self->getNodeValue());
    # create a new Tree::Simple object
    # here with the cloned node, however
    # we do not assign the parent node
    # since it really does not make a lot
    # of sense. To properly clone it would
    # be to clone back up the tree as well,
    # which IMO is not intuitive. So in essence
    # when you clone a tree, you detach it from
    # any parentage it might have
    my $clone = $self->new($cloned_node);
    # however, because it is a recursive thing
    # when you clone all the children, and then
    # add them to the clone, you end up setting
    # the parent of the children to be that of
    # the clone (which is correct)
    $clone->setLeft($self->{_left}->clone()) if $self->hasLeft();
    $clone->setRight($self->{_right}->clone()) if $self->hasRight();
    # return the clone
    return $clone;
}


# this allows cloning of single nodes while
# retaining connections to a tree, this is sloppy
sub cloneShallow {
	my ($self) = @_;
	my $cloned_tree = { %{$self} };
	bless($cloned_tree, ref($self));
	# just clone the node (if you can)
    my $cloned_node =_cloneNode($self->getNodeValue());
    (defined($cloned_node)) || die "Node did not clone : " . $self->getNodeValue();
	$cloned_tree->setNodeValue($cloned_node);
	return $cloned_tree;
}

# this is a helper function which
# recursively clones the node
sub _cloneNode {
    my ($node, $seen) = @_;
    # create a cache if we dont already
    # have one to prevent circular refs
    # from being copied more than once
    $seen = {} unless defined $seen;
    # now here we go...
    my $clone;
    # if it is not a reference, then lets just return it
    return $node unless ref($node);
    # if it is in the cache, then return that
    return $seen->{$node} if exists ${$seen}{$node};
    # if it is an object, then ...
    if (blessed($node)) {
        # see if we can clone it
        if ($node->can('clone')) {
            $clone = $node->clone();
        }
        # otherwise respect that it does
        # not want to be cloned
        else {
            $clone = $node;
        }
    }
    else {
        # if the current slot is a scalar reference, then
        # dereference it and copy it into the new object
        if (ref($node) eq "SCALAR" || ref($node) eq "REF") {
            my $var = "";
            $clone = \$var;
            ${$clone} = _cloneNode(${$node}, $seen);
        }
        # if the current slot is an array reference
        # then dereference it and copy it
        elsif (ref($node) eq "ARRAY") {
            $clone = [ map { _cloneNode($_, $seen) } @{$node} ];
        }
        # if the current reference is a hash reference
        # then dereference it and copy it
        elsif (ref($node) eq "HASH") {
            $clone = {};
            foreach my $key (keys %{$node}) {
                $clone->{$key} = _cloneNode($node->{$key}, $seen);
            }
        }
        else {
            # all other ref types are not copied
            $clone = $node;
        }
    }
    # store the clone in the cache and
    $seen->{$node} = $clone;
    # then return the clone
    return $clone;
}


## ----------------------------------------------------------------------------
## Desctructor

sub DESTROY {
	my ($self) = @_;
    # we need to call DESTORY on all our children
	# (first checking if they are defined
	# though since we never know how perl's
	# garbage collector will work)
    $self->{_left}->DESTROY() if defined $self->{_left};
    $self->{_right}->DESTROY() if defined $self->{_right};
    $self->{_parent} = undef;
}

1;

__END__

=head1 NAME

Tree::Binary - An Object Oriented Binary Tree for Perl

=head1 SYNOPSIS

This program ships as scripts/traverse.1.pl:

	#!/usr/bin/env perl

	use strict;
	use warnings;

	use Tree::Binary;
	use Tree::Binary::Visitor::BreadthFirstTraversal;
	use Tree::Binary::Visitor::InOrderTraversal;
	use Tree::Binary::Visitor::PreOrderTraversal;
	use Tree::Binary::Visitor::PostOrderTraversal;

	# ---------------

	# A tree representaion of the expression:
	#     ( (2 + 2) * (4 + 5) )

	my($btree) = Tree::Binary -> new('*')
					-> setLeft
						(
							Tree::Binary -> new('+')
								-> setLeft(Tree::Binary->new('2') )
								-> setRight(Tree::Binary->new('2') )
						)
					-> setRight
						(
							Tree::Binary->new('+')
								-> setLeft(Tree::Binary->new('4') )
								-> setRight(Tree::Binary->new('5') )
						);

	# Or shown visually:
	#     +---(*)---+
	#     |         |
	#  +-(+)-+   +-(+)-+
	#  |     |   |     |
	# (2)   (2) (4)   (5)

	# There is no method which will display the above,
	# but a crude tree-printer follows.

	my($parent_depth);

	$btree -> traverse
	(
		sub
		{
			my($tree) = @_;

			print "\t" x $tree -> getDepth, $tree -> getNodeValue, "\n";
		}
	);

	# Get a InOrder visitor.

	my($visitor) = Tree::Binary::Visitor::InOrderTraversal -> new;

	$btree -> accept($visitor);

	# Print the expression in infix order.

	print join(' ', $visitor -> getResults), "\n"; # Prints '2 + 2 * 4 + 5'.

	# Get a PreOrder visitor.

	$visitor = Tree::Binary::Visitor::PreOrderTraversal -> new;

	$btree -> accept($visitor);

	# Print the expression in prefix order.

	print join(' ', $visitor -> getResults), "\n"; # Prints '* + 2 2 + 4 5'.

	# Get a PostOrder visitor.

	$visitor = Tree::Binary::Visitor::PostOrderTraversal -> new;

	$btree -> accept($visitor);

	# Print the expression in postfix order.

	print join(' ', $visitor -> getResults), "\n"; # Prints '2 2 + 4 5 + *'.

	# Get a BreadthFirst visitor.

	$visitor = Tree::Binary::Visitor::BreadthFirstTraversal -> new;

	$btree -> accept($visitor);

	# Print the expression in breadth first order.

	print join(' ', $visitor -> getResults), "\n"; # Prints '* + + 2 2 4 5'.

	# Be sure to clean up all circular references.
	# Of course, since we're exiting immediately, this particular program
	# does not need such a defensive manoeuvre.

	$btree -> DESTROY();

If printing the tree is important, you are better off using
L<Tree::DAG_Node|https://metacpan.org/pod/Tree::DAG_Node#tree2string-options-some_tree>.

=head1 DESCRIPTION

This module is a fully object oriented implementation of a binary tree. Binary trees are a specialized type of tree which has only two possible branches, a left branch and a right branch. While it is possible to use an I<n>-ary tree, like L<Tree::Simple>, to fill most of your binary tree needs, a true binary tree object is just easier to mantain and use.

Binary Tree objects are especially useful (to me anyway) when building parse trees of things like mathematical or boolean expressions. They can also be used in games for such things as descisions trees. Binary trees are a well studied data structure and there is a wealth of information on the web about them.

This module uses exceptions and a minimal Design By Contract style. All method arguments are required unless specified in the documentation, if a required argument is not defined an exception will usually be thrown. Many arguments are also required to be of a specific type, for instance the C<$tree> argument to both the C<setLeft> and C<setRight> methods, B<must> be a B<Tree::Binary> object or an object derived from B<Tree::Binary>, otherwise an exception is thrown. This may seems harsh to some, but this allows me to have the confidence that my code works as I intend, and for you to enjoy the same level of confidence when using this module. Note however that this module does not use any Exception or Error module, the exceptions are just strings thrown with C<die>.

This object uses a number of methods copied from another module of mine, Tree::Simple. Users of that module will find many similar methods and behaviors. However, it did not make sense for Tree::Binary to be derived from Tree::Simple, as there are a number of methods in Tree::Simple that just wouldn't make sense in Tree::Binary. So, while I normally do not approve of cut-and-paste code reuse, it was what made the most sense in this case.

=head1 METHODS

=over 4

=item B<new ($node)>

The constructor accepts a C<$node> value argument. The C<$node> value can be any scalar value (which includes references and objects).

=back

=head2 Mutators

=over 4

=item B<setNodeValue ($node_value)>

Sets the current Tree::Binary object's node to be C<$node_value>

=item B<setUID ($uid)>

This allows you to set your own unique ID for this specific Tree::Binary object. A default value derived from the object's hex address is provided for you, so use of this method is entirely optional. It is the responsibility of the user to ensure the value's uniqueness, all that is tested by this method is that C<$uid> is a true value (evaluates to true in a boolean context). For even more information about the Tree::Binary UID see the C<getUID> method.

=item B<setLeft ($tree)>

This method sets C<$tree> to be the left subtree of the current Tree::Binary object.

=item B<removeLeft>

This method removed the left subtree of the current Tree::Binary object, making sure to remove all references to the current tree. However, in order to properly clean up and circular references the removed child might have, it is advised to call the C<DESTROY> method. See the L<CIRCULAR REFERENCES> section for more information.

=item B<setRight ($tree)>

This method sets C<$tree> to be the right subtree of the current Tree::Binary object.

=item B<removeRight>

This method removed the right subtree of the current Tree::Binary object, making sure to remove all references to the current tree. However, in order to properly clean up and circular references the removed child might have, it is advised to call the C<DESTROY> method. See the L<CIRCULAR REFERENCES> section for more information.

=back

=head2 Accessors

=over 4

=item B<getUID>

This returns the unique ID associated with this particular tree. This can be custom set using the C<setUID> method, or you can just use the default. The default is the hex-address extracted from the stringified Tree::Binary object. This may not be a I<universally> unique identifier, but it should be adequate for at least the current instance of your perl interpreter. If you need a UUID, one can be generated with an outside module (there are many to choose from on CPAN) and the C<setUID> method (see above).

=item B<getParent>

Returns the parent of the current Tree::Binary object.

=item B<getDepth>

Returns the depth of the current Tree::Binary object within the larger hierarchy.

=item B<getNodeValue>

Returns the node value associated with the current Tree::Binary object.

=item B<getLeft>

Returns the left subtree of the current Tree::Binary object.

=item B<getRight>

Returns the right subtree of the current Tree::Binary object.

=back

=head2 Informational

=over 4

=item B<isLeaf>

A leaf is a tree with no branches, if the current Tree::Binary object does not have either a left or a right subtree, this method will return true (C<1>), otherwise it will return false (C<0>).

=item B<hasLeft>

This method will return true (C<1>) if the current Tree::Binary object has a left subtree, otherwise it will return false (C<0>).

=item B<hasRight>

This method will return true (C<1>) if the current Tree::Binary object has a right subtree, otherwise it will return false (C<0>).

=item B<isRoot>

This method will return true (C<1>) if the current Tree::Binary object is the root (it does not have a parent), otherwise it will return false (C<0>).

=back

=head2 Recursive Methods

=over 4

=item B<traverse ($func)>

This method takes a single argument of a subroutine reference C<$func>. If the argument is not defined and is not in fact a CODE reference then an exception is thrown. The function is then applied recursively to both subtrees of the invocant. Here is an example of a traversal function that will print out the hierarchy as a tabbed in list.

This code is taken from scripts/traverse.1.pl:

	$btree -> traverse
	(
		sub
		{
			my($tree) = @_;

			print "\t" x $tree -> getDepth, $tree -> getNodeValue, "\n";
		}
	);

=item B<mirror>

This method will swap the left node for the right node and then do this recursively on down the tree. The result is the tree is a mirror image of what it was. So that given this tree:

     +---(-)---+
     |         |
  +-(*)-+   +-(+)-+
  |     |   |     |
 (1)   (2) (4)   (5)

Calling C<mirror> will result in your tree now looking like this:

     +---(-)---+
     |         |
  +-(+)-+   +-(*)-+
  |     |   |     |
 (5)   (4) (2)   (1)

It should be noted that this is a destructive action, it will alter your current tree. Although it is easily reversable by simply calling C<mirror> again. However, if you are looking for a mirror copy of the tree, I advise calling C<clone> first.

  my $mirror_copy = $tree->clone()->mirror();

Of course, the cloning operation is a full deep copy, so keep in mind the expense of this operation. Depending upon your needs it may make more sense to call C<mirror> a few times and gather your results with a Visitor object, rather than to C<clone>.

=item B<size>

Returns the total number of nodes in the current tree and all its sub-trees.

=item B<height>

Returns the length of the longest path from the current tree to the furthest leaf node.

=back

=head2 Misc. Methods

=over 4

=item B<accept ($visitor)>

It accepts either a B<Tree::Binary::Visitor::*> object, or an object who has the C<visit> method available (tested with C<$visitor-E<gt>can('visit')>). If these qualifications are not met, and exception will be thrown. We then run the Visitor C<visit> method giving the current tree as its argument.

=item B<clone>

The clone method does a full deep-copy clone of the object, calling C<clone> recursively on all its children. This does not call C<clone> on the parent tree however. Doing this would result in a slowly degenerating spiral of recursive death, so it is not recommended and therefore not implemented. What it does do is to copy the parent reference, which is a much more sensible act, and tends to be closer to what we are looking for. This can be a very expensive operation, and should only be undertaken with great care. More often than not, this method will not be appropriate. I recommend using the C<cloneShallow> method instead.

=item B<cloneShallow>

This method is an alternate option to the plain C<clone> method. This method allows the cloning of single B<Tree::Binary> object while retaining connections to the rest of the tree/hierarchy. This will attempt to call C<clone> on the invocant node if the node is an object (and responds to C<$obj-E<gt>can('clone')>) otherwise it will just copy it.

=item B<DESTROY>

To avoid memory leaks through uncleaned-up circular references, we implement the C<DESTROY> method. This method will attempt to call C<DESTROY> on each of its children (if it as any). This will result in a cascade of calls to C<DESTROY> on down the tree. It also cleans up the parental relations as well.

Because of perl reference counting scheme and how that interacts with circular references, if you want an object to be properly reaped you should manually call C<DESTROY>. This is especially nessecary if your object has any children. See the section on L<CIRCULAR REFERENCES> for more information.

=item B<fixDepth>

For the most part, Tree::Binary will manage your tree depth fields for you. But occasionally your tree depth may get out of synch. If you run this method, it will traverse your tree correcting the depth as it goes.

=back

=head1 CIRCULAR REFERENCES

Perl uses reference counting to manage the destruction of objects, and this can cause problems with circularly referencing object like Tree::Binary. In order to properly manage your circular references, it is nessecary to manually call the C<DESTROY> method on a Tree::Binary instance. Here is some example code:

  # create a root
  my $root = Tree::Binary->new()

  { # create a lexical scope

      # create a subtree (with a child)
      my $subtree = Tree::Binary->new("1")
                          ->setRight(
                              Tree::Binary->new("1.1")
                          );

      # add the subtree to the root
      $root->setLeft($subtree);

      # ... do something with your trees

      # remove the first child
      $root->removeLeft();
  }

At this point you might expect perl to reap C<$subtree> since it has been removed from the C<$root> and is no longer available outside the lexical scope of the block. However, since C<$subtree> itself has a subtree, its reference count is still (at least) one and perl will not reap it. The solution to this is to call the C<DESTROY> method manually at the end of the lexical block, this will result in the breaking of all relations with the DESTROY-ed object and allow that object to be reaped by perl. Here is a corrected version of the above code.

  # create a root
  my $root = Tree::Binary->new()

  { # create a lexical scope

      # create a subtree (with a child)
      my $subtree = Tree::Binary->new("1")
                          ->setRight(
                              Tree::Binary->new("1.1")
                          );

      # add the subtree to the root
      $root->setLeft($subtree);

      # ... do something with your trees

      # remove the first child and capture it
      my $removed = $root->removeLeft();

      # now force destruction of the removed child
      $removed->DESTROY();
  }

As you can see if the corrected version we used a new variable to capture the removed tree, and then explicitly called C<DESTROY> upon it. Only when a removed subtree has no children (it is a leaf node) can you safely ignore the call to C<DESTROY>. It is even nessecary to call C<DESTROY> on the root node if you want it to be reaped before perl exits, this is especially important in long running environments like mod_perl.

=head1 OTHER TREE MODULES

As crazy as it might seem, there are no pure (non-search) binary tree implementations on CPAN (at least not that I could find). I found several balanced trees of one kind or another (see the C<OTHER TREE MODULES> section of the Tree::Binary::Search documentation for that list). The closet thing I could find was the Tree module described below.

=over 4

=item B<Tree>

I cannot tell for sure, but this module may include a non-search binary tree in it. Its documentation is beyond non-existant, and I gave up after reading about 3/4 of the source code. It was uploaded in October 1999 and as far as I can tell it has ever been updated (the file modification dates are 05-Jan-1999). There is no actual file called Tree.pm, so CPAN can find no version number. It has no MANIFEST, README of Makefile.PL, so installation is entirely manual. Some of it even appears to have been written by Mark Jason Dominus, as far back as 1997 (possibly the source code from an old TPJ article on B-Trees by him).

=back

=head1 SEE ALSO

This module is part of a larger group, which are listed below.

=over 4

=item L<Tree::Binary::Search>

=item L<Tree::Binary::VisitorFactory>

=item L<Tree::Binary::Visitor::BreadthFirstTraversal>

=item L<Tree::Binary::Visitor::PreOrderTraversal>

=item L<Tree::Binary::Visitor::PostOrderTraversal>

=item L<Tree::Binary::Visitor::InOrderTraversal>

=back

=head1 BUGS

None that I am aware of. Of course, if you find a bug, let me know, and I will be sure to fix it.

=head1 CODE COVERAGE

I use B<Devel::Cover> to test the code coverage of my tests, below is the B<Devel::Cover> report on this module test suite.

 -------------------------------------------- ------ ------ ------ ------ ------ ------ ------
 File                                           stmt branch   cond    sub    pod   time  total
 -------------------------------------------- ------ ------ ------ ------ ------ ------ ------
 Tree/Binary.pm                                100.0   97.3   93.9  100.0  100.0   71.7   98.7
 Tree/Binary/Search.pm                          99.0   90.5   81.2  100.0  100.0   13.9   95.1
 Tree/Binary/Search/Node.pm                    100.0  100.0   66.7  100.0  100.0   11.7   98.2
 Tree/Binary/VisitorFactory.pm                 100.0  100.0    n/a  100.0  100.0    0.5  100.0
 Tree/Binary/Visitor/Base.pm                   100.0  100.0   66.7  100.0  100.0    0.5   96.4
 Tree/Binary/Visitor/BreadthFirstTraversal.pm  100.0  100.0  100.0  100.0  100.0    0.0  100.0
 Tree/Binary/Visitor/InOrderTraversal.pm       100.0  100.0  100.0  100.0  100.0    1.1  100.0
 Tree/Binary/Visitor/PostOrderTraversal.pm     100.0  100.0  100.0  100.0  100.0    0.3  100.0
 Tree/Binary/Visitor/PreOrderTraversal.pm      100.0  100.0  100.0  100.0  100.0    0.3  100.0
 -------------------------------------------- ------ ------ ------ ------ ------ ------ ------
 Total                                          99.6   94.4   88.8  100.0  100.0  100.0   97.4
 -------------------------------------------- ------ ------ ------ ------ ------ ------ ------

=head1 Repository

L<https://github.com/ronsavage/Tree-Binary>

=head1 AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

Since V 1.00, Ron Savage E<lt>ron@savage.net.auE<gt> has been the maintainer.

=head1 COPYRIGHT AND LICENSE

Copyright 2004, 2005 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


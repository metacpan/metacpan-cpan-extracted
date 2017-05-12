package Tree::RedBlack;

use strict;
use Tree::RedBlack::Node;
use vars qw($VERSION);
$VERSION = '0.5';

=head1 NAME

Tree::RedBlack - Perl implementation of Red/Black tree, a type of balanced tree.

=head1 SYNOPSIS

  use Tree::RedBlack;
  
  my $t = new Tree::RedBlack;
  $t->insert(3, 'cat');
  $t->insert(4, 'dog');
  my $v = $t->find(4);
  my $min = $t->min;
  my $max = $t->max;
  $t->delete(3);
  $t->print;

=head1 DESCRIPTION

This is a perl implementation of the Red/Black tree algorithm found in the book
"Algorithms", by Cormen, Leiserson & Rivest (more commonly known as "CLR" or
"The White Book").  A Red/Black tree is a binary tree which remains "balanced"-
that is, the longest length from root to a node is at most one more than the
shortest such length.  It is fairly efficient; no operation takes more than
O(lg(n)) time.

A Tree::RedBlack object supports the following methods:

=over 4

=item new ()

Creates a new RedBlack tree object.

=item root ()

Returns the root node of the tree.  Note that this will either be undef if no
nodes have been added to the tree, or a Tree::RedBlack::Node object.  See the
L<Tree::RedBlack::Node> manual page for details on the Node object.

=item cmp (&)

Use this method to set a comparator subroutine.  The tree defaults to lexical
comparisons.  This subroutine should be just like a comparator subroutine to
sort, except that it doesn't do the $a, $b trick; the two elements to compare
will just be the first two items on the stack.

=item insert ($;$)

Adds a new node to the tree.  The first argument is the key of the node, the
second is its value.  If a node with that key already exists, its value is
replaced with the given value and the old value is returned.  Otherwise, undef
is returned.

=item delete ($)

The argument should be either a node object to delete or the key of a node
object to delete. WARNING!!! THIS STILL HAS BUGS!!!

=item find ($)

Searches the tree to find the node with the given key.  Returns the value of
that node, or undef if a node with that key isn't found.  Note, in particular,
that you can't tell the difference between finding a node with value undef and
not finding a node at all.  If you want to determine if a node with a given key
exists, use the node method, below.

=item node ($)

Searches the tree to find the node with the given key.  Returns that node
object if it is found, undef otherwise.  The node object is a
Tree::RedBlack::Node object.

=item min ()

Returns the node with the minimal key.

=item max ()

Returns the node with the maximal key.

=back

=head1 AUTHOR

Benjamin Holzman <bholzman@earthlink.net>

=head1 SEE ALSO

Tree::RedBlack::Node

=cut

sub new {
  my $type = shift;
  return bless {'null' => Tree::RedBlack::Node::->new,
		'root' => undef}, $type;
}

sub DESTROY { if ($_[0]->{'root'}) { $_[0]->{'root'}->DESTROY } }

sub root {
  my $this = shift;
  return $this->{'root'};
}

sub cmp {
  my($this, $cr) = @_;
  $this->{'cmp'} = $cr;
}

sub insert {
  my($this, $key, $value) = @_;
  my $cmp = $this->{'cmp'};
  my $node = $this->{'root'};
  my $parent;
  while ($node) {
    $parent = $node;
    if ($cmp ? $cmp->($key, $node->key) < 0 : $key lt $node->key) {
      $node = $node->left;
    } else {
      $node = $node->right;
    }
  }
  if ($parent) {
    # Handle case of inserting node with duplicate key.
    if ($cmp ? $cmp->($parent->key, $key) == 0 : $parent->key eq $key) {
      my $val = $parent->val;
      $parent->val($value);
      return $val;
    }
    $node = $parent->new($key, $value);
    if ($this->{'cmp'} ? $this->{'cmp'}->($key, $parent->key) < 0
		       : $key lt $parent->key) {
      $parent->left($node);
    } else {
      $parent->right($node);
    }
  } else {
    $this->{'root'} = $node = Tree::RedBlack::Node::->new($key, $value);
  }
  $node->color(1);
  while ($node != $this->{'root'} && $node->parent->color) {
    if (defined $node->parent->parent->left && $node->parent == $node->parent->parent->left) {
      my $uncle = $node->parent->parent->right;
      if ($uncle && $uncle->color) {
	$node->parent->color(0);
	$uncle->color(0);
	$node->parent->parent->color(1);
	$node = $node->parent->parent;
      } else {
	if ($node == $node->parent->right) {
	  $node = $node->parent;
	  $this->left_rotate($node);
	}
	$node->parent->color(0);
	$node->parent->parent->color(1);
	$this->right_rotate($node->parent->parent);
      }
    } else {
      my $uncle = $node->parent->parent->left;
      if ($uncle && $uncle->color) {
	$node->parent->color(0);
	$uncle->color(0);
	$node->parent->parent->color(1);
	$node = $node->parent->parent;
      } else {
	if (defined $node->parent->left && $node == $node->parent->left) {
	  $node = $node->parent;
	  $this->right_rotate($node);
	}
	$node->parent->color(0);
	$node->parent->parent->color(1);
	$this->left_rotate($node->parent->parent);
      }
    }
  }
  $this->{'root'}->color(0);
  return;
}

sub left_rotate {
  my($this, $node) = @_;
  my $child = $node->right;
  $node->right($child->left);
  if ($child->left) {
    $child->left->parent($node);
  }
  $child->parent($node->parent);
  if ($node->parent) {
    if ($node == $node->parent->left) {
      $node->parent->left($child);
    } else {
      $node->parent->right($child);
    }
  } else {
    $this->{'root'} = $child;
  }
  $child->left($node);
  $node->parent($child);
}

sub right_rotate {
  my($this, $node) = @_;
  my $child = $node->left;
  $node->left($child->right);
  if ($child->right) {
    $child->right->parent($node);
  }
  $child->parent($node->parent);
  if ($node->parent) {
    if ($node == $node->parent->right) {
      $node->parent->right($child);
    } else {
      $node->parent->left($child);
    }
  } else {
    $this->{'root'} = $child;
  }
  $child->right($node);
  $node->parent($child);
}

sub delete {
  my($this, $node_or_key) = @_;
  my $node;
  if (ref $node_or_key && $node_or_key->isa('Tree::RedBlack::Node')) {
    $node = $node_or_key;
  } else {
    $node = $this->node($node_or_key) or return;
  }
  my($successor, $successor_child);
  if (!($node->left && $node->right)) {
    $successor = $node;
  } else {
    $successor = $node->successor;
  }
  if ($successor->left) {
    $successor_child = $successor->left;
  } else {
    $successor_child = $successor->right || $this->{'null'};
  }
  $successor_child->parent($successor->parent);
  if (!$successor_child || !$successor_child->parent) {
    $this->{'root'} = $successor_child;
  } elsif ($successor == $successor->parent->left) {
    $successor->parent->left($successor_child);
  } else {
    $successor->parent->right($successor_child);
  }
  if ($successor != $node) {
    $node->key($successor->key);
    $node->val($successor->val);
  }
  if (!$successor->color) {
    $this->delete_fixup($successor_child);
  }
  if (!$successor_child->parent) {
    $this->{'root'} = undef;
  }
  $successor;
}

sub delete_fixup {
  my($this, $x) = @_;
  while ($x != $this->{'root'} && !$x->color) {
    if ($x == $x->parent->left) {
      my $w = $x->parent->right;
      if ($w->color) {
 	$w->color(0);
	$x->parent->color(1);
	$this->left_rotate($x->parent);
      }
      if (!$w->left->color && !$w->right->color) {
	$w->color(1);
	$x = $x->parent;
      } else {
	if (!$w->right->color) {
	  $w->left->color(0);
	  $w->color(1);
	  $this->right_rotate($w);
	  $w = $x->parent->right;
	}
	$w->color($x->parent->color);
	$x->parent->color(0);
	$w->right->color(0);
	$this->left_rotate($x->parent);
	$x = $this->{'root'};
      }
    } else {
      my $w = $x->parent->left;
      if ($w->color) {
 	$w->color(0);
	$x->parent->color(1);
	$this->right_rotate($x->parent);
      }
      if (!$w->left->color && !$w->right->color) {
	$w->color(1);
	$x = $x->parent;
      } else {
	if (!$w->left->color) {
	  $w->right->color(0);
	  $w->color(1);
	  $this->left_rotate($w);
	  $w = $x->parent->left;
	}
	$w->color($x->parent->color);
	$x->parent->color(0);
	$w->left->color(0);
	$this->right_rotate($x->parent);
	$x = $this->{'root'};
      }
    }
  }
  $x->color(0);
}

sub min {
  my $this = shift;
  if ($this->{'root'}) {
    if ($this->{'root'}->left) {
      return $this->{'root'}->left->min;
    } else {
      return $this->{'root'};
    }
  }
  return;
}

sub max {
  my $this = shift;
  if ($this->{'root'}) {
    if ($this->{'root'}->right) {
      return $this->{'root'}->right->max;
    } else {
      return $this->{'root'};
    }
  }
  return;
}

sub find {
  my($this, $key) = @_;
  my $cmp = $this->{'cmp'};
  my $node = $this->{'root'};
  while ($node) {
    if ($cmp ? $cmp->($key, $node->key) == 0 : $key eq $node->key) {
      return $node->val;
    } elsif ($cmp ? $cmp->($key, $node->key) < 0 : $key lt $node->key) {
      $node = $node->left;
    } else {
      $node = $node->right;
    }
  }
  # Got to the end without finding the node.
  return;
}

sub node {
  my($this, $key) = @_;
  my $cmp = $this->{'cmp'};
  my $node = $this->{'root'};
  while ($node) {
    if ($cmp ? $cmp->($key, $node->key) == 0 : $key eq $node->key) {
      return $node;
    } elsif ($cmp ? $cmp->($key, $node->key) < 0 : $key lt $node->key) {
      $node = $node->left;
    } else {
      $node = $node->right;
    }
  }
  # Got to the end without finding the node.
  return;
}


1;

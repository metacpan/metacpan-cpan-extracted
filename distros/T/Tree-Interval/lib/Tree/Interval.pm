package Tree::Interval;
#
# Copyright (C) 2011 by Opera Software Australia Pty Ltd
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# Derived from Tree::RedBlack by Benjamin Holzman <bholzman@earthlink.net>
# which bore this message:
#
#     This program is free software; you can redistribute it and/or modify
#     it under the terms of the Artistic License, a copy of which can be
#     found with perl.
#
#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     Artistic License for more details.
#
use strict;
use Tree::Interval::Node;
use vars qw($VERSION);
$VERSION = '0.3.2';

=head1 NAME

Tree::Interval - Perl implementation of an interval tree

=head1 SYNOPSIS

 use Tree::Interval;
 
 my $t = Tree::Interval->new();
 $t->insert(3, 5, 'cat');
 $t->insert(7, 15, 'dog');
 my $v = $t->find(4);
 my $min = $t->min();
 my $max = $t->max();

=head1 DESCRIPTION

This is a perl implementation of an interval tree for non-overlapping
intervals, based on Tree::RedBlack by Benjamin Holzman <bholzman@earthlink.net>.
An interval tree is a binary tree which remains "balanced" i.e.
the longest length from root to a node is at most one more than the
shortest such length.  It is fairly efficient; no operation takes more than
O(log(N)) time.

A Tree::Interval object supports the following methods:

=over

=item I<Tree::Interval-E<gt>new()>

Creates a new Interval tree object.

=cut

sub new {
  my $type = shift;
  return bless {'null' => Tree::Interval::Node::->new,
		'root' => undef}, $type;
}


sub DESTROY { if ($_[0]->{'root'}) { $_[0]->{'root'}->DESTROY } }

=item I<root()>

Returns the root node of the tree.  Note that this will either be I<undef> if no
nodes have been added to the tree, or a Tree::Interval::Node object.

=cut

sub root {
  my $this = shift;
  return $this->{'root'};
}

=item I<cmp(coderef)>

Use this method to set a comparator subroutine.  The tree defaults to
builtin Perl numerical comparisons.  This subroutine should be just like
a comparator subroutine to I<sort>, except that it doesn't do the $a, $b
trick; the two elements to compare will just be the first two items on
the stack.  For example,

 sub example_comparator
 {
    my ($ka, $kb) = @_;
    return $ka <=> $kb;
 }

=cut

sub cmp {
  my($this, $cr) = @_;
  $this->{'cmp'} = $cr;
}

sub _default_cmp
{
  my($ka, $kb) = @_;
  return $ka <=> $kb;
}

=item I<insert(low, high, value)>

Adds a new node to the tree.  The first two arguments are an interval
which forms the key of the node, the third is its value and may not be
I<undef>.  Overlapping or duplicate keys are an error.  Errors are
handled using I<die>.  Nothing is returned.

=cut

sub insert {
  my($this, $low, $high, $value) = @_;
  my $cmp = $this->{'cmp'} || \&_default_cmp;
  my $node = $this->{'root'};
  my $parent;
  die "Trying to insert undef"
    unless defined $value;
  while ($node) {
    $parent = $node;
    if ($cmp->($low, $node->low) < 0) {
      die "Overlapping nodes"
	if ($cmp->($high, $node->low) >= 0);
      $node = $node->left;
    } else {
      die "Overlapping nodes"
	if ($cmp->($low, $node->high) <= 0);
      $node = $node->right;
    }
  }
  if ($parent) {
    $node = $parent->new($low, $high, $value);
    if ($cmp->($low, $parent->low) < 0) {
      $parent->left($node);
    } else {
      $parent->right($node);
    }
  } else {
    $this->{'root'} = $node = Tree::Interval::Node::->new($low, $high, $value);
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

# TODO: not translated from plain Red/Black to Interval
# =item I<delete ($)
# 
# The argument should be either a node object to delete or the key of a node
# object to delete. WARNING!!! THIS STILL HAS BUGS!!!
# 
# =cut

sub delete {
  my($this, $node_or_key) = @_;
  my $node;
  if (ref $node_or_key && $node_or_key->isa('Tree::Interval::Node')) {
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
    $node->low($successor->low);
    $node->high($successor->high);
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

=item I<min()>

Returns the node with the minimal key.

=cut

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

=item I<max()>

Returns the node with the maximal key.

=cut

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

=item I<find(key)>

Searches the tree to find the node whose interval contains the given
I<key>.  Returns the value of that node, or I<undef> if a node with that
key isn't found.

=cut

sub find {
  my($this, $key) = @_;
  my $cmp = $this->{'cmp'} || \&_default_cmp;
  my $node = $this->{'root'};
  while ($node) {
    if ($cmp->($key, $node->low) < 0) {
      $node = $node->left;
    }
    elsif ($cmp->($key, $node->high) <= 0) {
      # found it
      return $node->val;
    }
    else {
      $node = $node->right;
    }
  }
  # Got to the end without finding the node.
  return;
}

sub _values {
    my($node, $res) = @_;
    return unless $node;
    _values($node->left, $res);
    push(@$res, $node->val);
    _values($node->right, $res);
}

=item I<values()>

Returns a list of all the node values.

=cut

sub values {
  my($this) = @_;
  my $res = [];
  _values($this->{'root'}, $res);
  return @$res;
}

=back

=head1 AUTHOR

Greg Banks <gnb@fastmail.fm>, heavily based on Tree::RedBlack by
Benjamin Holzman <bholzman@earthlink.net>

=cut
1;

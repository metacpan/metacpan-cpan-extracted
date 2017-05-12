package Tree::RedBlack::Node;

use strict;

=head1 NAME

Tree::RedBlack::Node - Node class for Perl implementation of Red/Black tree

=head1 SYNOPSIS

use Tree::RedBlack;
my $t = new Tree::RedBlack;
$t->insert(3, 'dog');
my $node = $t->node(3);
$animal = $node->val;

=head1 DESCRIPTION

A Tree::RedBlack::Node object supports the following methods:

=over 4

=item key ()

Key of the node.  This is what the nodes are sorted by in the tree.

=item val ($)

Value of the node.  Can be any perl scalar, so it could be a hash-ref,
f'rinstance.  This can be set directly.

=item color ()

Color of the node.  1 for "red", 0 or undef for "black".

=item parent ()

Parent node of this one.  Returns undef for root node.

=item left ()

Left child node of this one.  Returns undef for leaf nodes.

=item right ()

Right child node of this one.  Returns undef for leaf nodes.

=item min ()

Returns the node with the minimal key starting from this node.

=item max ()

Returns the node with the maximal key starting from this node.

=item successor ()

Returns the node with the smallest key larger than this node's key, or this
node if it is the node with the maximal key.

=item predecessor ()

Similar to successor. WARNING: NOT YET IMPLEMENTED!!

=back

You can use these methods to write utility routines for actions on red/black
trees.  For instance, here's a routine which writes a tree out to disk, putting
the byte offsets of the left and right child records in the record for each
node.

    sub dump {
      my($node, $fh) = @_;
      my($left, $right);
      my $pos = tell $fh;
      print $fh $node->color ? 'R' : 'B';
      seek($fh, 8, 1);
      print $fh $node->val;
      if ($node->left) {
        $left = dump($node->left,$fh);
      }
      if ($node->right) { 
        $right = dump($node->right,$fh);
      }
      my $end = tell $fh;
      seek($fh, $pos+1, 0);
      print $fh pack('NN', $left, $right);
      seek($fh, $end, 0);
      $pos;
    }

You would call it like this:

    my $t = new Tree::RedBlack;
    ...
    open(FILE, ">tree.dump");
    dump($t->root,\*FILE);
    close FILE;

As another example, here's a simple routine to print a human-readable dump of
the tree:

    sub pretty_print {
      my($node, $fh, $lvl) = @_;
      if ($node->right) {
        pretty_print($node->right, $fh, $lvl+1);
      }
      print $fh ' 'x($lvl*3),'[', $node->color ? 'R' : 'B', ']', $node->key, "\n";
      if ($node->left) {
        pretty_print($this->left, $fh, $lvl+1);
      }
    } 

A cleaner way of doing this kind of thing is probably to allow sub-classing of
Tree::RedBlack::Node, and then allow the Tree::RedBlack constructor to take an
argument saying what class of node it should be made up out of. Hmmm...

=head1 AUTHOR

Benjamin Holzman <bholzman@earthlink.net>

=head1 SEE ALSO

Tree::RedBlack

=cut

sub new {
  my $type = shift;
  my $this = {};
  if (ref $type) {
    $this->{'parent'} = $type;
    $type = ref $type;
  }
  if (@_) {
    @$this{'key','val'} = @_;
  }
  return bless $this, $type;
}

sub DESTROY {
  if ($_[0]->{'left'}) { 
    (delete $_[0]->{'left'})->DESTROY;
  }
  if ($_[0]->{'right'}) {
    (delete $_[0]->{'right'})->DESTROY;
  }
  delete $_[0]->{'parent'};
}

sub key {
  my $this = shift;
  if (@_) {
    $this->{'key'} = shift;
  }
  $this->{'key'};
}

sub val {
  my $this = shift;
  if (@_) {
    $this->{'val'} = shift;
  }
  $this->{'val'};
}

sub color {
  my $this = shift;
  if (@_) {
    $this->{'color'} = shift;
  }
  $this->{'color'};
}

sub left {
  my $this = shift;
  if (@_) {
    $this->{'left'} = shift;
  }
  $this->{'left'};
}

sub right {
  my $this = shift;
  if (@_) {
    $this->{'right'} = shift;
  }
  $this->{'right'};
}

sub parent {
  my $this = shift;
  if (@_) {
    $this->{'parent'} = shift;
  }
  $this->{'parent'};
}

sub successor {
  my $this = shift;
  if ($this->{'right'}) {
    return $this->{'right'}->min;
  }
  my $parent = $this->{'parent'};
  while ($parent && $this == $parent->{'right'}) {
    $this = $parent;
    $parent = $parent->{'parent'};
  }
  $parent;
}

sub min {
  my $this = shift;
  while ($this->{'left'}) {
    $this = $this->{'left'};
  }
  $this;
}

sub max {
  my $this = shift;
  while ($this->{'right'}) {
    $this = $this->{'right'};
  }
  $this;
}

1;

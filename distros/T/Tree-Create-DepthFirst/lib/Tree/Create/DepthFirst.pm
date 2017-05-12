#_{ Encoding and name
=encoding utf8
=head1 NAME
Tree::Create::DepthFirst - Create a Tree::Simple in the order as the created tree will traverse its nodes when traversing it depth first.
=cut
package Tree::Create::DepthFirst;

use strict;
use warnings;

#_}
#_{ Version
=head1 VERSION

Version 0.02
=cut
our $VERSION = '0.02';
#_}
#_{ Synopsis
=head1 SYNOPSIS

=pod

 use Tree::Create::DepthFirst;

 my $tree_creator = Tree::Create::DepthFirst->new();
 $tree_creator -> addNode(0, 'child 1');
 $tree_creator -> addNode(0, 'child 2');
 $tree_creator -> addNode(1, 'grand chhild 1');
 $tree_creator -> addNode(1, 'grand chhild 2');
 $tree_creator -> addNode(2, 'grand-grand chhild 2');

 my $tree_simple = $tree_creator->getTree();
=cut
#_}

use Tree::Simple;

#_{ Methods
=head1 Methods
=cut

sub new { #_{

=head2 new()

Creates the tree creator.

    my $tree_creator = Tree::Create::DepthFirst->new()

From now on, you will want to call

    $tree_creator->addNode(…);

until the tree is finished. Then you get the created tree with

    my $tree_simple = $tree_simple->getTree();

=cut

	my ($_class, $input) = @_;
	my $class = ref($_class) || $_class;

  my $self = {};
  bless $self, $class;

  $self->{tree} = Tree::Simple->new('root', Tree::Simple->ROOT);
  $self->{current_tree} = $self->{tree};

  return $self;
} #_}

sub addNode { #_{

=head2 addNode($depth, $nodeValue)

Add tree nodes and leaves in the same order as a depth first traversal would traverse
the tree.

There are two restrictions on $depth: a) it must be greater or equal to 0. b) It must
not be greater than the last added node's $depth+1.

=cut

#
#    Note the similarity to parts of Tree::Parser's sub _parse
#

  my $self      = shift;
  my $depth     = shift;
  my $nodeValue = shift;

  my $new_tree = Tree::Simple->new($nodeValue);

  if ($self->{current_tree}->isRoot()) {
    $self->{current_tree}->addChild($new_tree);
    $self->{current_tree}=$new_tree;
    return $self->{tree};
  }

  my $tree_depth = $self->{current_tree}->getDepth();
  if ($depth == $tree_depth) {
     $self->{current_tree}->addSibling($new_tree);
     $self->{current_tree} = $new_tree;
  }
  elsif ($depth > $tree_depth) {

    if ($depth - $tree_depth > 1) {
      die "Passed depth (=$depth) must not be greater than current current_tree depth (=$tree_depth) + 1";
    }

    $self->{current_tree}->addChild($new_tree);
    $self->{current_tree}=$new_tree;

  }
  else {
    $self->{current_tree} = $self->{current_tree}->getParent() while ($depth < $self->{current_tree}->getDepth());

    $self->{current_tree}->addSibling($new_tree);
    $self->{current_tree}=$new_tree;

  }
  return $self->{tree};

} #_}

sub getTree { #_{

=head2 getTree()

After building, getTree() returns the created tree (as a Tree::Simple) object.

    $tree_simple = $tree_creator->getTree();

=cut

  my $self      = shift;

  return $self->{tree};

} #_}
#_}
#_{ More POD
=head1 AUTHOR

René Nyffenegger, C<< <rene.nyffenegger at adp-gmbh.ch> >>

=head1 LICENSE

According to the C<LICENSE> file that comes with the package.

=head1 LINKS

The source code is in L<this Github repository|https://github.com/ReneNyffenegger/Tree-Create-DepthFirst>

=cut

#_}

"tq84";

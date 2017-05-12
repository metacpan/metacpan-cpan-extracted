package Tree::RB::Node;

use strict;
use Carp;
use Tree::RB::Node::_Constants;
use vars qw( $VERSION @EXPORT_OK );

require Exporter;
*import    = \&Exporter::import;
@EXPORT_OK = qw[set_color color_of parent_of left_of right_of];

$VERSION = '0.2';

my %attribute = (
    key    => _KEY,
    val    => _VAL,
    color  => _COLOR,
    parent => _PARENT,
    left   => _LEFT,
    right  => _RIGHT,
);

sub _accessor {
    my $index = shift;
    return sub {
        my $self = shift;
        if (@_) {
          $self->[$index] = shift;
        }
        return $self->[$index];
    };
}

while(my($at, $idx) = each %attribute) {
    no strict 'refs';
    *$at = _accessor($idx);
}

sub new {
    my $class = shift;
    my $obj = [];

    if (@_) {
        $obj->[_KEY] = shift;
        $obj->[_VAL] = shift;
    }
    return bless $obj, $class;
}

sub min {
    my $self = shift;
    while ($self->[_LEFT]) {
        $self = $self->[_LEFT];
    }
    return $self;
}

sub max {
    my $self = shift;
    while ($self->[_RIGHT]) {
        $self = $self->[_RIGHT];
    }
    return $self;
}

sub leaf {
    my $self = shift;
    while (my $any_child = $self->[_LEFT] || $self->[_RIGHT]) {
        $self = $any_child;
    }
    return $self;
}

sub successor {
    my $self = shift;
    if ($self->[_RIGHT]) {
        return $self->[_RIGHT]->min;
    }
    my $parent = $self->[_PARENT];
    while ($parent && $parent->[_RIGHT] && $self == $parent->[_RIGHT]) {
        $self = $parent;
        $parent = $parent->[_PARENT];
    }
    return $parent;
}

sub predecessor {
    my $self = shift;
    if ($self->[_LEFT]) {
        return $self->[_LEFT]->max;
    }
    my $parent = $self->[_PARENT];
    while ($parent && $parent->[_LEFT] && $self == $parent->[_LEFT]) {
        $self = $parent;
        $parent = $parent->[_PARENT];
    }
    return $parent;
}

sub as_lol {
    my $self = shift;
    my $node = shift || $self;
    my $aref;
    push @$aref,
         $node->[_LEFT]
           ? $self->as_lol($node->[_LEFT])
           : '*';
    push @$aref,
         $node->[_RIGHT]
           ? $self->as_lol($node->[_RIGHT])
           : '*';
    my $color = ($node->[_COLOR] == RED ? 'R' : 'B');
    no warnings 'uninitialized';
    push @$aref, "$color:$node->[_KEY]";
    return $aref;
}

sub strip {
    my $self = shift;
    my $callback = shift;

    my $x = $self;
    while($x) {
        my $leaf = $x->leaf;
        $x = $leaf->[_PARENT];

        # detach $leaf from the (sub)tree
        no warnings "uninitialized";
        if($leaf == $x->[_LEFT]) {
            undef $x->[_LEFT];
        }
        else {
            undef $x->[_RIGHT];
        }
        undef $leaf->[_PARENT];
        if($callback) {
            $callback->($leaf);
        }

        if(!$x->[_LEFT] && !$x->[_RIGHT]) {
            $x = $x->[_PARENT];
        }
    }
}

sub DESTROY { $_[0]->strip; }

# Null aware accessors to assist with rebalancings during insertion and deletion
#
# A weird case of Java to the rescue!
# These are inspired by http://www.javaresearch.org/source/jdk142/java/util/TreeMap.java.html
# which was found via http://en.wikipedia.org/wiki/Red-black_tree#Implementations

sub set_color {
    my ($node, $color) = @_;
    if($node) {
        $node->[_COLOR] = $color || BLACK;
    }
}

sub color_of {
    $_[0] ? $_[0]->[_COLOR] : BLACK;
}

sub parent_of {
    $_[0] ? $_[0]->[_PARENT] : undef;
}

sub left_of {
    $_[0] ? $_[0]->[_LEFT] : undef;
}

sub right_of {
    $_[0] ? $_[0]->[_RIGHT] : undef;
}


1; # Magic true value required at end of module
__END__

=head1 NAME

Tree::RB::Node - A node class for implementing Red/Black trees


=head1 VERSION

This document describes Tree::RB::Node version 0.0.1


=head1 SYNOPSIS

    use Tree::RB;

    my $tree = Tree::RB->new;
    $tree->put('France'  => 'Paris');
    $tree->put('England' => 'London');

    my $node = $tree->delete('France'); # $node is a Tree::RB::Node object
    print $node->key; # 'France'
    print $node->val; # 'Paris'


=head1 DESCRIPTION

A Tree::RB tree is made up of nodes that are objects of type Tree::RB::Node


=head1 INTERFACE

A Tree::RB::Node object supports the following methods:

=head2 new()

Creates and returns a new node.

=head2 key([KEY])

Get/set the key of the node. This is what the nodes are sorted by in the tree.

=head2 val([VALUE])

Get/set the value of the node. This can be any scalar.

=head2 color([COLOR])

Get/set the color of the node. Valid colors are the constants RED
and BLACK which are exported by Tree::RB::Node::_Constants

=head2 parent([PARENT])

Get/set the parent of the node, which must be another Tree::RB::Node object.

=head2 left([NODE])

Get/set the left child node of the node, which must be another Tree::RB::Node object.

=head2 right([NODE])

Get/set the right child node of the node, which must be another Tree::RB::Node object.

=head2 min()

Returns the node with the minimal key starting from this node.

=head2 max()

Returns the node with the maximal key starting from this node.

=head2 leaf()

Returns the first leaf node found starting from this node, using a depth first,
left to right search.

=head2 successor()

Returns the node with the smallest key larger than this node's key,
or C<undef> if it is the node with the maximal key.

=head2 predecessor()

Returns the node with the greatest key smaller than this node's key,
or C<undef> if it is the node with the minimal key.

=head2 as_lol([NODE])

Returns a list of lists representing the tree whose root is either NODE
if NODE is specified, or this node otherwise.

This could be used for printing a tree, as the following snippet shows
(this assumes that Tree::DAG_Node is also installed)

    use strict;
    use Tree::DAG_Node;
    use Tree::RB;

    my $t = Tree::RB->new;

    foreach (qw/the rain in spain falls mainly in the plains/) {
        $t->put($_, "${_} val");
    }

    my $tree = Tree::DAG_Node->lol_to_tree( $t->root->as_lol );
    $, = "\n";
    print @{ $tree->draw_ascii_tree };

This will print

                      |
                   <B:rain>
               /-------------------\
               |                   |
             <R:in>             <B:the>
        /-----------\            /------\
        |           |            |      |
    <B:falls>   <B:mainly>   <R:spain> <*>
      /---\    /------\        /---\
      |   |    |      |        |   |
     <*> <*>  <*> <R:plains>  <*> <*>
                    /---\
                    |   |
                   <*> <*>

=head2 strip([$callback])

Strips off all nodes under this node. If a callback is specified,
it will be called once for each node that is detached, with the detached
node as its sole argument.




=head1 DEPENDENCIES

None.


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-tree-rb-node@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Arun Prasad  C<< <arunbear@cpan.org> >>

Some documentation has been borrowed from Benjamin Holzman's L<Tree::RedBlack::Node>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Arun Prasad C<< <arunbear@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

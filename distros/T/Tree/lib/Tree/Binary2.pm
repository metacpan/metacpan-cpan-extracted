package Tree::Binary2;

use 5.006;

use base 'Tree';
use strict;
use warnings FATAL => 'all';

use Scalar::Util qw( blessed );

our $VERSION = '1.11';

sub _init {
    my $self = shift;
    $self->SUPER::_init( @_ );

    # Make this class a complete binary tree,
    # filling in with Tree::Null as appropriate.
    $self->{_children}->[$_] = $self->_null
        for 0 .. 1;

    return $self;
}

sub left {
    my $self = shift;
    return $self->_set_get_child( 0, @_ );
}

sub right {
    my $self = shift;
    return $self->_set_get_child( 1, @_ );
}

sub _set_get_child {
    my $self = shift;
    my $index = shift;

    if ( @_ ) {
        my $node = shift;
        $node = $self->_null unless $node;

        my $old = $self->children->[$index];
        $self->children->[$index] = $node;

        if ( $node ) {
            $node->_set_parent( $self );
            $node->_set_root( $self->root );
            $node->_fix_depth;
        }

        if ( $old ) {
            $old->_set_parent( $old->_null );
            $old->_set_root( $old->_null );
            $old->_fix_depth;
        }

        $self->_fix_height;
        $self->_fix_width;

        return $self;
    }
    else {
        return $self->children->[$index];
    }
}

sub _clone_children {
    my ($self, $clone) = @_;

    @{ $clone->{_children} } = ();
    $clone->add_child({}, map { $_->clone } @{ $self->{_children} });
}

sub children {
    my $self = shift;
    if ( @_ ) {
        my @idx = @_;
        return @{$self->{_children}}[@idx];
    }
    else {
        if ( caller->isa( __PACKAGE__ ) || $self->isa( scalar(caller) ) ) {
            return wantarray ? @{$self->{_children}} : $self->{_children};
        }
        else {
            return grep { $_ } @{$self->{_children}};
        }
    }
}

use constant IN_ORDER => 4;

# One of the things we have to do in a traversal is to remove all of the
# Tree::Null elements that are appended to the tree to make this a complete
# binary tree. The user isn't going to expect them, because they're an
# internal nicety.

sub traverse {
    my $self = shift;
    my $order = shift;
    $order = $self->PRE_ORDER unless $order;

    if ( wantarray ) {
        if ( $order == $self->IN_ORDER ) {
            return grep { $_ } (
                $self->left->traverse( $order ),
                $self,
                $self->right->traverse( $order ),
            );
        }
        else {
            return grep { $_ } $self->SUPER::traverse( $order );
        }
    }
    else {
        my $closure;

        if ( $order eq $self->IN_ORDER ) {
            my @list = $self->traverse( $order );

            $closure = sub {
                return unless @list;
                return shift @list;
            };
        }
        elsif ( $order eq $self->PRE_ORDER ) {
            my $next_node = $self;
            my @stack = ( $self );
            my @next_meth = ( 0 );

            my @meths = qw( left right );
            $closure = sub {
                my $node = $next_node;
                return unless $node;
                $next_node = undef;

                while ( @stack && !$next_node ) {
                    while ( @next_meth && $next_meth[0] == 2 ) {
                        shift @stack;
                        shift @next_meth;
                    }

                    if ( @stack ) {
                        my $meth = $meths[ $next_meth[0]++ ];
                        $next_node = $stack[0]->$meth;
                        next unless $next_node;
                        unshift @stack, $next_node;
                        unshift @next_meth, 0;
                    }
                }

                return $node;
            };
        }
        elsif ( $order eq $self->POST_ORDER ) {
            my @list = $self->traverse( $order );

            $closure = sub {
                return unless @list;
                return shift @list;
            };
            #my @stack = ( $self );
            #my @next_idx = ( 0 );
            #while ( @{ $stack[0]->{_children} } ) {
            #    unshift @stack, $stack[0]->{_children}[0];
            #    unshift @next_idx, 0;
            #}
            #
            #$closure = sub {
            #    my $node = $stack[0] || return;
            #
            #    shift @stack; shift @next_idx;
            #    $next_idx[0]++;
            #
            #    while ( @stack && exists $stack[0]->{_children}[ $next_idx[0] ] ) {
            #        unshift @stack, $stack[0]->{_children}[ $next_idx[0] ];
            #        unshift @next_idx, 0;
            #    }
            #
            #    return $node;
            #};
        }
        elsif ( $order eq $self->LEVEL_ORDER ) {
            my @nodes = ($self);
            $closure = sub {
                my $node = shift @nodes;
                return unless $node;
                push @nodes, grep { $_ } @{$node->{_children}};
                return $node;
            };
        }
        else {
            return $self->error( "traverse(): '$order' is an illegal traversal order" );
        }

        return $closure;
    }
}

1;
__END__

=head1 NAME

Tree::Binary2 - An implementation of a binary tree

=head1 SYNOPSIS

  my $tree = Tree::Binary2->new( 'root' );

  my $left = Tree::Binary2->new( 'left' );
  $tree->left( $left );

  my $right = Tree::Binary2->new( 'left' );
  $tree->right( $right );

  my $right_child = $tree->right;

  $tree->right( undef ); # Unset the right child.

  my @nodes = $tree->traverse( $tree->POST_ORDER );

  my $traversal = $tree->traverse( $tree->IN_ORDER );
  while ( my $node = $traversal->() ) {
      # Do something with $node here
  }

=head1 DESCRIPTION

This is an implementation of a binary tree. This class inherits from L<Tree>,
which is an N-ary tree implemenation. Because of this, this class actually
provides an implementation of a complete binary tree vs. a sparse binary tree.
The empty nodes are instances of Tree::Null, which is described in L<Tree>.
This should have no effect on your usage of this class.

=head1 METHODS

In addition to the methods provided by L<Tree>, the following items are
provided or overriden.

=over 4

=item * C<left([$child])> / C<right([$child])>

These access the left and right children, respectively. They are mutators,
which means that their behavior changes depending on if you pass in a value.

If you do not pass in any parameters, then it will act as a getter for the
specific child, return the child (if set) or undef (if not).

If you pass in a child, it will act as a setter for the specific child,
setting the child to the passed-in value and returning the $tree. (Thus, this
method chains.)

If you wish to unset the child, do C<$treeE<gt>left( undef );>

=item * C<children()>

This will return the children of the tree.

B<NOTE:> There will be two children, always. Tree::Binary2 implements a
complete binary tree, filling in missing children with Tree::Null objects.
(Please see L<Tree::Fast> for more information on Tree::Null.)

=item * B<traverse( [$order] )>

When called in list context (C<my @traversal = $tree-E<gt>traverse()>), this will
return a list of the nodes in the given traversal order. When called in scalar
context (C<my $traversal = $tree-E<gt>traverse()>), this will return a closure
that will, over successive calls, iterate over the nodes in the given
traversal order. When finished it will return false.

The default traversal order is pre-order.

In addition to the traversal orders provided by L<Tree>, Tree::Binary2 provides
in-order traversals.

=over 4

=item * In-order

This will return the result of an in-order traversal on the left node (if
any), then the node, then the result of an in-order traversal on the right
node (if any).

=back

=back

B<NOTE:> You have access to all the methods provided by L<Tree>, but it is not
recommended that you use many of them, unless you know what you're doing. This
list includes C<add_child()> and C<remove_child()>.

=head1 TODO

=over 4

=item * Make in-order closure traversal work iteratively

=item * Make post-order closure traversal work iteratively

=back

=head1 CODE COVERAGE

Please see the relevant sections of L<Tree>.

=head1 SUPPORT

Please see the relevant sections of L<Tree>.

=head1 AUTHORS

Rob Kinyon E<lt>rob.kinyon@iinteractive.comE<gt>

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

Thanks to Infinity Interactive for generously donating our time.

=head1 COPYRIGHT AND LICENSE

Copyright 2004, 2005 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

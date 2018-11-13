package Tree::Fast;

use 5.006;

use strict;
use warnings FATAL => 'all';

our $VERSION = '1.12';

use Scalar::Util qw( blessed weaken );

sub new {
    my $class = shift;

    return $class->clone( @_ )
        if blessed $class;

    my $self = bless {}, $class;

    $self->_init( @_ );

    return $self;
}

sub _init {
    my $self = shift;
    my ($value) = @_;

    $self->{_parent} = $self->_null,
    $self->{_children} = [];
    $self->{_value} = $value,

    $self->{_meta} = {};

    return $self;
}

sub _clone_self {
    my $self = shift;
    my $value = @_ ? shift : $self->value;

    return blessed($self)->new( $value );
}

sub _clone_children {
    my ($self, $clone) = @_;

    if ( my @children = @{$self->{_children}} ) {
        $clone->add_child({}, map { $_->clone } @children );
    }
}

sub clone {
    my $self = shift;

    return $self->new(@_) unless blessed $self;

    my $clone = $self->_clone_self(@_);
    $self->_clone_children($clone);

    return $clone;
}

sub add_child {
    my $self = shift;
    my ( $options, @nodes ) = @_;

    for my $node ( @nodes ) {
        $node->_set_parent( $self );
    }

    if ( defined $options->{at} ) {
        if ( $options->{at} ) {
            splice @{$self->{_children}}, $options->{at}, 0, @nodes;
        }
        else {
            unshift @{$self->{_children}}, @nodes;
        }
    }
    else {
        push @{$self->{_children}}, @nodes;
    }

    return $self;
}

sub remove_child {
    my $self = shift;
    my ($options, @indices) = @_;

    my @return;
    for my $idx (sort { $b <=> $a } @indices) {
        my $node = splice @{$self->{_children}}, $idx, 1;
        $node->_set_parent( $node->_null );

        push @return, $node;
    }

    return @return;
}

sub parent {
    my $self = shift;
    return $self->{_parent};
}

sub _set_parent {
    my $self = shift;

    $self->{_parent} = shift;
    weaken( $self->{_parent} );

    return $self;
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
            return @{$self->{_children}};
        }
    }
}

sub value {
    my $self        = shift;
	my $value       = shift;
	$self->{_value} = $value if (defined $value);

    return $self->{_value};
}

sub set_value {
    my $self = shift;

    $self->{_value} = $_[0];

    return $self;
}

sub meta {
    my $self       = shift;
    my $meta       = shift;
    $self->{_meta} = {%{$self->{_meta} }, %$meta} if ($meta && !blessed($meta) && ref($meta) eq 'HASH');

    return $self->{_meta};
}

sub mirror {
    my $self = shift;

    @{$self->{_children}} = reverse @{$self->{_children}};
    $_->mirror for @{$self->{_children}};

    return $self;
}

use constant PRE_ORDER   => 1;
use constant POST_ORDER  => 2;
use constant LEVEL_ORDER => 3;

sub traverse {
    my $self = shift;
    my $order = shift;
    $order = $self->PRE_ORDER unless $order;

    if ( wantarray ) {
        my @list;

        if ( $order eq $self->PRE_ORDER ) {
            @list = ($self);
            push @list, map { $_->traverse( $order ) } @{$self->{_children}};
        }
        elsif ( $order eq $self->POST_ORDER ) {
            @list = map { $_->traverse( $order ) } @{$self->{_children}};
            push @list, $self;
        }
        elsif ( $order eq $self->LEVEL_ORDER ) {
            my @queue = ($self);
            while ( my $node = shift @queue ) {
                push @list, $node;
                push @queue, @{$node->{_children}};
            }
        }
        else {
            return $self->error( "traverse(): '$order' is an illegal traversal order" );
        }

        return @list;
    }
    else {
        my $closure;

        if ( $order eq $self->PRE_ORDER ) {
            my $next_node = $self;
            my @stack = ( $self );
            my @next_idx = ( 0 );

            $closure = sub {
                my $node = $next_node;
                return unless $node;
                $next_node = undef;

                while ( @stack && !$next_node ) {
                    while ( @stack && !exists $stack[0]->{_children}[ $next_idx[0] ] ) {
                        shift @stack;
                        shift @next_idx;
                    }

                    if ( @stack ) {
                        $next_node = $stack[0]->{_children}[ $next_idx[0]++ ];
                        unshift @stack, $next_node;
                        unshift @next_idx, 0;
                    }
                }

                return $node;
            };
        }
        elsif ( $order eq $self->POST_ORDER ) {
            my @stack = ( $self );
            my @next_idx = ( 0 );
            while ( @{ $stack[0]->{_children} } ) {
                unshift @stack, $stack[0]->{_children}[0];
                unshift @next_idx, 0;
            }

            $closure = sub {
                my $node = $stack[0];
                return unless $node;

                shift @stack; shift @next_idx;
                $next_idx[0]++;

                while ( @stack && exists $stack[0]->{_children}[ $next_idx[0] ] ) {
                    unshift @stack, $stack[0]->{_children}[ $next_idx[0] ];
                    unshift @next_idx, 0;
                }

                return $node;
            };
        }
        elsif ( $order eq $self->LEVEL_ORDER ) {
            my @nodes = ($self);
            $closure = sub {
                my $node = shift @nodes;
                return unless $node;
                push @nodes, @{$node->{_children}};
                return $node;
            };
        }
        else {
            return $self->error( "traverse(): '$order' is an illegal traversal order" );
        }

        return $closure;
    }
}

sub _null {
    return Tree::Null->new;
}

package Tree::Null;

our $VERSION = '1.12';

#XXX Add this in once it's been thought out
#our @ISA = qw( Tree );

# You want to be able to interrogate the null object as to
# its class, so we don't override isa() as we do can()

use overload
    '""' => sub { return "" },
    '0+' => sub { return 0 },
    'bool' => sub { return },
        fallback => 1,
;

{
    my $singleton = bless \my($x), __PACKAGE__;
    sub new { return $singleton }
    sub AUTOLOAD { return $singleton }
    sub can { return sub { return $singleton } }
}

# The null object can do anything
sub isa {
    my ($proto, $class) = @_;

    if ( $class =~ /^Tree(?:::.*)?$/ ) {
        return 1;
    }

    return $proto->SUPER::isa( $class );
}

1;
__END__

=head1 NAME

Tree::Fast - the fastest possible implementation of a tree in pure Perl

=head1 SYNOPSIS

  my $tree = Tree::Fast->new( 'root' );
  my $child = Tree::Fast->new( 'child' );
  $tree->add_child( {}, $child );

  $tree->add_child( { at => 0 }, Tree::Fast->new( 'first child' ) );
  $tree->add_child( { at => -1 }, Tree::Fast->new( 'last child' ) );

  my @children = $tree->children;
  my @some_children = $tree->children( 0, 2 );

  $tree->remove_child( 0 );

  my @nodes = $tree->traverse( $tree->POST_ORDER );

  my $traversal = $tree->traverse( $tree->POST_ORDER );
  while ( my $node = $traversal->() ) {
      # Do something with $node here
  }

  my $clone = $tree->clone;
  my $mirror = $tree->clone->mirror;

=head1 DESCRIPTION

This is meant to be the core implementation for L<Tree>, stripped down as much
as possible. There is no error-checking, bounds-checking, event-handling,
convenience methods, or anything else of the sort. If you want something fuller-featured,
please look at L<Tree>, which is a wrapper around Tree::Fast.

=head1 METHODS

=head2 Constructors

=head2 new([$value])

Here, [] indicate an optional parameter.

This will return a C<Tree::Fast> object. It will accept one parameter which, if passed,
will become the I<value> (accessible by C<value()>). All other parameters will be
ignored.

If you call C<< $tree->new([$value]) >>, it will instead call C<clone()>, then set
the I<value> of the clone to $value.

=head2 clone()

This will return a clone of C<$tree>. The clone will be a root tree, but all
children will be cloned.

If you call C<< Tree::Fast->clone([$value]) >>, it will instead call C<new()>.

B<NOTE:> the value is merely a shallow copy. This means that all references
will be kept.

=head2 Behaviors

=head2 add_child($options, @nodes)

This will add all the C<@nodes> as children of C<$tree>. C<$options> is a required
hashref that specifies options for C<add_child()>. The optional parameters are:

=over 4

=item * at

This specifies the index to add C<@nodes> at. If specified, this will be passed
into splice(). The only exceptions are if this is 0, it will act as an
unshift(). If it is unset or undefined, it will act as a push().

=back

=head2 remove_child($options, @nodes)

This will remove all the C<@nodes> from the children of C<$tree>. You can either
pass in the actual child object you wish to remove, the index of the child you
wish to remove, or a combination of both.

$options is a required hashref that specifies parameters for remove_child().
Currently, no parameters are used.

=head2 mirror()

This will modify the tree such that it is a mirror of what it was before. This
means that the order of all children is reversed.

B<NOTE>: This is a destructive action. It I<will> modify the internal
structure of the tree. If you wish to get a mirror, yet keep the original tree intact, use
C<< my $mirror = $tree->clone->mirror >>.

=head2 traverse( [$order] )

Here, [] indicate an optional parameter.

When called in list context (C<< my @traversal = $tree->traverse() >>), this will
return a list of the nodes in the given traversal order. When called in scalar
context (C<< my $traversal = $tree->traverse() >>), this will return a closure
that will, over successive calls, iterate over the nodes in the given
traversal order. When finished it will return false.

The default traversal order is pre-order.

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

=head2 value()

This will return the value stored in the node.

=head2 set_value([$value])

Here, [] indicate an optional parameter.

This will set the I<value> stored in the node to $value, then return $self.

If C<$value> is not provided, undef is used.

=head2 meta()

This will return a hashref that can be used to store whatever metadata the client
wishes to store. For example, L<Tree::Persist::DB> uses this to store database
row ids.

It is recommended that you store your metadata in a subhashref and not in the
top-level metadata hashref, keyed by your package name. L<Tree::Persist> does
this, using a unique key for each persistence layer associated with that tree.
This will help prevent clobbering of metadata.

=head1 NULL TREE

If you call C<< $self->parent >> on a root node, it will return a Tree::Null
object. This is an implementation of the Null Object pattern optimized for
usage with L<Tree::Fast>. It will evaluate as false in every case (using
I<overload>) and all methods called on it will return a Tree::Null object.

=head2 Notes

=over 4

=item *

Tree::Null does B<not> inherit from anything. This is so that all the
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

=head1 CODE COVERAGE

Please see the relevant sections of L<Tree>.

=head1 SUPPORT

Please see the relevant sections of L<Tree>.

=head1 ACKNOWLEDGEMENTS

=over 4

=item * Stevan Little for writing L<Tree::Simple>, upon which Tree is based.

=back

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

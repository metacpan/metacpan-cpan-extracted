package Tree::Simple::View::ASCII;

use strict;
use warnings;
use Tree::Simple::View::Exceptions;

use parent 'Tree::Simple::View';

our $VERSION = '0.19';

sub expandPathSimple {
    my ( $self, $tree, @full_path ) = @_;

    my $output = '';
    my @vert_dashes;

    my $traversal = sub {
        my ( $t, $redo, $current_path, @path ) = @_;
        $output .= $self->_processNode( $t, \@vert_dashes ) unless $t->isRoot;
        my @children = $t->getAllChildren;
        for my $i ( 0 .. $#children ) {
            my $subcat  = $children[$i];
            my $is_last = $i == $#children;
            $output .=
              $self->_handle_child( $subcat, $redo, \@path, $current_path,
                \@vert_dashes, $is_last );
        }
    };

    $output .= $self->_processNode( $tree, \@vert_dashes )
      if $self->{include_trunk};

    shift @full_path
      if ( $self->{include_trunk}
        && defined $full_path[0]
        && $self->_compareNodeToPath( $full_path[0], $tree ) );

    # Its the U combinator baby!
    $traversal->( $tree, $traversal, @full_path );

    return $output;
}

sub expandAllSimple {
    my ($self) = @_;

    my $output = '';
    my @vert_dashes;

    $output .= $self->_processNode( $self->{tree}, \@vert_dashes )
      if $self->{include_trunk};
    $self->{tree}->traverse(
        sub {
            my $t        = shift;
            my @siblings = $t->getParent->getAllChildren;
            $output .=
              $self->_processNode( $t, \@vert_dashes,
                $t == $siblings[-1] ? 1 : 0 );
        }
    );

    return $output;
}

sub expandPathComplex {
    my ( $self, $tree, undef, @full_path ) = @_;

    # complex stuff is not supported here ...
    $self->expandPathSimple( $tree, @full_path );
}

*expandAllComplex = \&expandAllSimple;

sub _processNode {
    my ( $self, $t, $vert_dashes, $is_last ) = @_;
    my $depth = $t->getDepth;
    my $sibling_count = $t->isRoot ? 1 : $t->getParent->getChildCount;

    $depth++ if $self->{include_trunk};

    my $chars = $self->_merge_characters;
    my @indents =
      map { $vert_dashes->[$_] || $chars->{indent} } 0 .. $depth - 1;

    @$vert_dashes =
      ( @indents, ( $sibling_count == 1 ? $chars->{indent} : $chars->{pipe} ) );
    $vert_dashes->[$depth] = $chars->{indent}
      if ( $sibling_count == ( $t->getIndex + 1 ) );

    my $node =
      exists $self->{config}->{node_formatter}
      ? $self->{config}->{node_formatter}->($t)
      : $t->getNodeValue;

    return (
        ( join "" => @indents[ 1 .. $#indents ] )
        . (
            $depth
            ? ( $is_last ? $chars->{last_branch} : $chars->{branch} )
            : ""
          )
          . $node . "\n"
    );
}

sub _handle_child {
    my ( $self, $child, $redo, $path, $current_path, $vert_dashes, $is_last ) =
      @_;
    return $redo->( $child, $redo, @$path )
      if ( defined $current_path
        && $self->_compareNodeToPath( $current_path, $child ) );
    return $self->_processNode( $child, $vert_dashes, $is_last );
}

sub _merge_characters {
    my ($self) = shift;

    return {
        pipe        => '    |   ',
        indent      => '        ',
        last_branch => '    \---',
        branch      => '    |---',
      }
      if ( !defined $self->{config} || !defined $self->{config}->{characters} );

    my $chars = { @{ $self->{config}->{characters} } };
    $chars->{pipe}        = '    |   ' unless $chars->{pipe};
    $chars->{indent}      = '        ' unless $chars->{indent};
    $chars->{last_branch} = '    \---' unless $chars->{last_branch};
    $chars->{branch}      = '    |---' unless $chars->{branch};
    return $chars;
}

1;

__END__

=pod

=head1 NAME

Tree::Simple::View::ASCII - A class for viewing Tree::Simple hierarchies in ASCII

=head1 SYNOPSIS

    use Tree::Simple::View::ASCII;

    my $tree_view = Tree::Simple::View::ASCII->new($tree);

    $tree_view->includeTrunk(1);

    print $tree_view->expandAll();

    # root
    #     |---Node Level: 1
    #     |       |---Node Level: 1.1
    #     |       |---Node Level: 1.2
    #     |       |       |---Node Level: 1.2.1
    #     |       |       \---Node Level: 1.2.2
    #     |       \---Node Level: 1.3
    #     |---Node Level: 2
    #     |       |---Node Level: 2.1
    #     |       \---Node Level: 2.2
    #     |---Node Level: 3
    #     |       \---Node Level: 3.1
    #     |               |---Node Level: 3.1.1
    #     |               \---Node Level: 3.1.2
    #     \---Node Level: 4
    #             \---Node Level: 4.1

    print $tree_view->expandPath("root", "Node Level: 1", "Node Level: 1.2");

    # root
    #     |---Node Level: 1
    #     |       |---Node Level: 1.1
    #     |       |---Node Level: 1.2
    #     |       |       |---Node Level: 1.2.1
    #     |       |       \---Node Level: 1.2.2
    #     |       \---Node Level: 1.3
    #     |---Node Level: 2
    #     |---Node Level: 3
    #     \---Node Level: 4

    my $tree_view = Tree::Simple::View::ASCII->new($tree, (
        characters => [ indent => "    ", pipe => " |  ", last_branch => " \- ", branch => " |- " ]
    ) );

    # root
    #  |- Node Level: 1
    #  |  |- Node Level: 1.1
    #  |  |- Node Level: 1.2
    #  |  |  |- Node Level: 1.2.1
    #  |  |  \- Node Level: 1.2.2
    #  |  \- Node Level: 1.3
    #  |- Node Level: 2
    #  |- Node Level: 3
    #  \- Node Level: 4

=head1 DESCRIPTION

This is a Tree::Simple::View subclass which provides simple ASCII formatting for trees.

I had this code lying around, and I figured it was best to put it into here. This is
an early release of this, and it lacks configuration parameter handling, but that can
be easily added later when I need it.

=head1 METHODS

=over 4

=item B<expandAllSimple>

This will draw a fully expanded tree.

=item B<expandAllComplex>

This currently is aliased to the C<expandAllSimple> since we don't have config handling.

=item B<expandPathSimple (@path)>

This will draw a tree with the given C<@path> expanded.

=item B<expandPathComplex>

This currently is aliased to the C<expandPathSimple> since we don't have config handling.

=back

=head1 TODO

Config handling, allowing you to customize the drawing. Patches welcome, I just don't
currently have the time to add it.

=head1 BUGS

None that I am aware of. Of course, if you find a bug, let me know, and I will be sure to fix it.

=head1 AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2008 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

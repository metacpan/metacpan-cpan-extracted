package Text::Tree::Indented;
$Text::Tree::Indented::VERSION = '0.02';
use 5.010;
use strict;
use warnings;
use Carp            qw/ croak       /;
use Ref::Util 0.202 qw/ is_arrayref /;
use parent          qw/ Exporter    /;
use utf8;

our @EXPORT_OK = qw/ generate_tree /;

my %arguments = (
    style => "styling of tree, one of: classic, boxrule, norule",
);

my %styles = (
    boxrule => { vert => '│', horiz => '─', tee => '├', corner => '└' },
    classic => { vert => '|', horiz => '-', tee => '+', corner => '+' },
    norule  => { vert => ' ', horiz => ' ', tee => ' ', corner => ' ' },
);

sub generate_tree
{
    my ($tree, $opt) = @_;

    $opt          //= {};
    $opt->{style} //= 'boxrule';

    foreach my $arg (keys %$opt) {
        croak "unknown argument '$arg'" if not exists $arguments{$arg};
    }

    croak "unknown style '$opt->{style}'" if not exists($styles{ $opt->{style} });

    my $render = '';

    foreach my $entry (@$tree) {
        if (is_arrayref($entry)) {
            _render_subtree($entry, \$render, $opt, "  ");
        }
        else {
            $render .= $entry."\n";
        }
    }

    return $render;
}

sub _render_subtree
{
    my ($subtree, $textref, $opt, $indent) = @_;
    my $chars  = $styles{ $opt->{style} };
    my @nodes  = @$subtree;

    while (@nodes > 0) {
        my $node      = shift @nodes;
        my $last_node = 0 == int(grep { !is_arrayref($_) } @nodes);
        if (is_arrayref($node)) {
            _render_subtree($node, $textref, $opt, $indent.($last_node ? "    " : "$chars->{vert}   "));
        }
        else {
            my $prefix = ($last_node ? $chars->{corner} : $chars->{tee}).$chars->{horiz};
            $$textref .= $indent . $prefix . $node . "\n";
        }
    }
}

1;

=encoding utf8

=head1 NAME

Text::Tree::Indented - render a tree data structure in the classic indented view

=head1 SYNOPSIS

    use Text::Tree::Indented qw/ generate_tree /;

    my $data = [ 'ABC', [
                   'DEF', [ 'GHI', 'JKL' ],
                   'MNO', [ 'PQR', ['STU' ]],
                   'VWX'
               ] ];

    binmode(STDOUT, "utf8");
    print generate_tree($data);

which produces

 ABC
   ├─DEF
   │   ├─GHI
   │   └─JKL
   ├─MNO
   │   └─PQR
   │       └─STU
   └─VWX

=head1 DESCRIPTION

This module provides a single function, C<generate_tree>,
which takes a perl data structure and renders it into
an indented tree view.

B<Note>: the design of this module is still very much in flux,
so the data structure and other aspects may change from release
to release.

The tree data is passed as an arrayref.
A string in the arrayref represents a node in the tree;
if it's followed by an arrayref, that's a subtree.
So let's say the root of your tree is B<Fruit>,
and it has three children, B<Apples>, B<Bananas>, and B<Oranges>,
then the data would look like this:

 my $tree = ['Fruit', ['Apples', 'Bananas', 'Oranges'] ];

This results in the following tree:

 Fruit
   ├─Apples
   ├─Bananas
   └─Oranges

Now you want to add in Red Bananas and Williams Bananas,
so your data becomes:

 my $tree = ['Fruit', ['Apples', 'Bananas', ['Red', 'Williams'], 'Oranges'] ];

And now the tree looks like this:

 Fruit
   ├─Apples
   ├─Bananas
   │   ├─Red
   │   └─Williams
   └─Oranges

=head2 generate_tree( $data, $options )

In addition to the tree data,
this function takes an optional second argument,
which should be a hashref.

At the moment there is just one option, B<style>,
which can be one of B<'boxrule'>, B<'classic'>, or B<'norule'>:

 print generate_tree($data, { style => 'classic' });

For the example shown in the SYNOPSIS, the resulting tree is:

 ABC
   +-DEF
   |   +-GHI
   |   +-JKL
   +-MNO
   |   +-PQR
   |       +-STU
   +-VWX

The default is 'boxrule'.

If you are using the boxrule style,
then you should make sure your output can handle wide characters,
as in the SYNOPSIS.


=head1 SEE ALSO

There are many modules on CPAN for building tree data structures,
such as L<Tree>, L<Tree::AVL>, L<Tree::Binary>, etc.

L<Data::RenderAsTree>, L<Data::TreeDumper>, and L<Data::TreeDraw>
will render a Perl data structure as an ASCII tree.

L<Text::Tree> takes a representation of a tree and draws
a top-down tree with ASCII boxes around the labels.

L<Tree::To::TextLines> draws an indented tree,
but requires the tree to be in a more complex,
but richer, data structure.

L<Tree::Visualize> can render trees in a number of ways,
aimed at situations where you're already using something
like L<Tree::Binary> to hold your tree data.

=head1 REPOSITORY

L<https://github.com/neilb/Text-Tree-Indented>


=head1 AUTHOR

Neil Bowers <neilb@cpan.org>


=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Neil Bowers.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


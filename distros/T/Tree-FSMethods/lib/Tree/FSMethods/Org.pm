package Tree::FSMethods::Org;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-06-27'; # DATE
our $DIST = 'Tree-FSMethods'; # DIST
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

use Code::Includable::Tree::NodeMethods;
use Org::Parser::Tiny;

use parent qw(Tree::FSMethods);

sub new {
    my ($class, %args) = (shift, @_);
    $args{filename_method} //= sub {
        my $node = shift;
        return undef unless $node->can("title");
        my $name = $node->title;
        $name =~ s/\[.*?\]//g;
        $name =~ s/\s{2,}/ /g;
        $name =~ s/^\s+//;
        $name =~ s/\s$//;
        $name;
    };
    if (defined $args{org_file}) {
        $args{tree} = Org::Parser::Tiny->new->parse_file(
            delete $args{org_file});
    }
    if (defined $args{org_file1}) {
        $args{tree1} = Org::Parser::Tiny->new->parse_file(
            delete $args{org_file1});
    }
    if (defined $args{org_file2}) {
        $args{tree2} = Org::Parser::Tiny->new->parse_file(
            delete $args{org_file2});
    }
    $class->SUPER::new(%args);
}

sub before_cp {
    my ($self, $nodes_to_copy, $target_node) = @_;

    # adjust level, e.g. if we move level1 headings under another level1 heading
    # then the level1 headings to be copied (as well as their descendants) will
    # need to be demoted by 1 level.

    #say "D1: ", scalar(@$nodes_to_copy);
    my $target_level = $target_node->can("level") ? $target_node->level : 0;
    my $levels_to_increase;

    for my $node_to_copy (@$nodes_to_copy) {
        unless (defined $levels_to_increase) {
            my $node_level = $node_to_copy->can("level") ? $node_to_copy->level : 0;
            $levels_to_increase = $target_level+1 - $node_to_copy->level;
            $levels_to_increase = 0 if $levels_to_increase < 0;
        }
        next unless $levels_to_increase;
        $node_to_copy->level( $node_to_copy->level + $levels_to_increase )
            if $node_to_copy->can("level");
        Code::Includable::Tree::NodeMethods::walk(
            $node_to_copy, sub {
                my $node = shift;
                $node->level( $node->level + $levels_to_increase )
                    if $node->can("level");
            });
    }
}

sub before_mv {
    my $self = shift;
    $self->before_cp(@_);
}

sub on_mkdir {
    my ($self, $node, $filename) = @_;
    my $child_node = Org::Parser::Tiny::Node::Headline->new;
    $child_node->level($node->can("level") ? $node->level+1 : 1);
    $child_node->title($filename);
    $child_node->parent($node);
    $node->children([ @{ $node->children }, $child_node ]);
    $child_node;
}

1;
# ABSTRACT: Perform filesystem-like operations on Org document tree

__END__

=pod

=encoding UTF-8

=head1 NAME

Tree::FSMethods::Org - Perform filesystem-like operations on Org document tree

=head1 VERSION

This document describes version 0.003 of Tree::FSMethods::Org (from Perl distribution Tree-FSMethods), released on 2021-06-27.

=head1 SYNOPSIS

 use Tree::FSMethods::Org;

 my $fs = Tree::FSMethods::Org->new(
     # specify an already parsed Org document ...
     tree => $tree,
     # tree1 => $tree,
     # tree2 => $other_tree,

     # ... or request parse from a file
     org_file => "/some/path/to/file.org",
     # org_file1 => ...
     # org_file2 => ...

     # defaults to getting from title(), with "[...]" trimmed (priority like
     # "[#B]" or statistics cookie like "[20%]" or "[2/10]")
     # filename_method => 'filename',
 );

=head1 DESCRIPTION

This is a subclass of L<Tree::FSMethods> with some nicer defaults for Org
document tree produced by L<Org::Parser::Tiny>.

=for Pod::Coverage ^(.+)$

=head1 METHODS

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Tree-FSMethods>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Tree-FSMethods>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Tree-FSMethods>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Tree::FSMethods>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

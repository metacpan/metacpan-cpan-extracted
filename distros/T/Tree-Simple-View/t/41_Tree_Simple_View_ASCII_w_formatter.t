#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 16;
use Test::LongString;

BEGIN {
    use_ok('Tree::Simple::View::ASCII');
}

use Tree::Simple;
my $tree = Tree::Simple->new( Tree::Simple->ROOT )->addChildren(
    Tree::Simple->new("1")->addChildren(
        Tree::Simple->new("1.1"),
        Tree::Simple->new("1.2")->addChildren( Tree::Simple->new("1.2.1"), Tree::Simple->new("1.2.2") ),
        Tree::Simple->new("1.3")
    ),
    Tree::Simple->new("2")->addChildren( Tree::Simple->new("2.1"), Tree::Simple->new("2.2") ),
    Tree::Simple->new("3")
      ->addChildren( Tree::Simple->new("3.1")->addChildren( Tree::Simple->new("3.1.1"), Tree::Simple->new("3.1.2") ), ),
    Tree::Simple->new("4")->addChildren( Tree::Simple->new("4.1") )
);
isa_ok( $tree, 'Tree::Simple' );

can_ok( "Tree::Simple::View::ASCII", 'new' );
can_ok( "Tree::Simple::View::ASCII", 'expandAll' );

{
    my $tree_view = Tree::Simple::View::ASCII->new(
        $tree,
        node_formatter => sub {
            my $t = shift;
            "Node Level: " . $t->getNodeValue;
        }
    );
    isa_ok( $tree_view, 'Tree::Simple::View::ASCII' );

    my $output = $tree_view->expandAll();
    ok( $output, '... make sure we got some output' );

    my $expected = <<EXPECTED;
Node Level: 1
    |---Node Level: 1.1
    |---Node Level: 1.2
    |       |---Node Level: 1.2.1
    |       \\---Node Level: 1.2.2
    \\---Node Level: 1.3
Node Level: 2
    |---Node Level: 2.1
    \\---Node Level: 2.2
Node Level: 3
    \\---Node Level: 3.1
            |---Node Level: 3.1.1
            \\---Node Level: 3.1.2
Node Level: 4
    \\---Node Level: 4.1
EXPECTED

    is_string( $output, $expected, '... got what we expected' );
}

{
    my $tree_view = Tree::Simple::View::ASCII->new(
        $tree,
        node_formatter => sub {
            my $t = shift;
            "Node Level: " . $t->getNodeValue;
        }
    );
    isa_ok( $tree_view, 'Tree::Simple::View::ASCII' );

    $tree_view->includeTrunk(1);

    my $output = $tree_view->expandAll();
    ok( $output, '... make sure we got some output' );

    my $expected = <<EXPECTED;
Node Level: root
    |---Node Level: 1
    |       |---Node Level: 1.1
    |       |---Node Level: 1.2
    |       |       |---Node Level: 1.2.1
    |       |       \\---Node Level: 1.2.2
    |       \\---Node Level: 1.3
    |---Node Level: 2
    |       |---Node Level: 2.1
    |       \\---Node Level: 2.2
    |---Node Level: 3
    |       \\---Node Level: 3.1
    |               |---Node Level: 3.1.1
    |               \\---Node Level: 3.1.2
    \\---Node Level: 4
            \\---Node Level: 4.1
EXPECTED

    is_string( $output, $expected, '... got what we expected' );
}

{
    my $tree_view = Tree::Simple::View::ASCII->new(
        $tree,
        node_formatter => sub {
            my $t = shift;
            "Node Level: " . $t->getNodeValue;
        }
    );
    isa_ok( $tree_view, 'Tree::Simple::View::ASCII' );

    my $output = $tree_view->expandPath( "1", "1.2" );
    ok( $output, '... make sure we got some output' );

    my $expected = <<EXPECTED;
Node Level: 1
    |---Node Level: 1.1
    |---Node Level: 1.2
    |       |---Node Level: 1.2.1
    |       \\---Node Level: 1.2.2
    \\---Node Level: 1.3
Node Level: 2
Node Level: 3
Node Level: 4
EXPECTED

    is( $output, $expected, '... got what we expected' );
}

{
    my $tree_view = Tree::Simple::View::ASCII->new(
        $tree,
        node_formatter => sub {
            my $t = shift;
            "Node Level: " . $t->getNodeValue;
        }
    );
    isa_ok( $tree_view, 'Tree::Simple::View::ASCII' );

    $tree_view->includeTrunk(1);

    my $output = $tree_view->expandPath( "root", "1", "1.2" );
    ok( $output, '... make sure we got some output' );

    my $expected = <<EXPECTED;
Node Level: root
    |---Node Level: 1
    |       |---Node Level: 1.1
    |       |---Node Level: 1.2
    |       |       |---Node Level: 1.2.1
    |       |       \\---Node Level: 1.2.2
    |       \\---Node Level: 1.3
    |---Node Level: 2
    |---Node Level: 3
    \\---Node Level: 4
EXPECTED

    is( $output, $expected, '... got what we expected' );
}

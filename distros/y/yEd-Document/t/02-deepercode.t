#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use yEd::Document;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Developer tests not required for installation" );
}
#TODO: write new tests
my @nodes = ('GenericNode', 'ShapeNode');
my @edges = ('ArcEdge', 'BezierEdge', 'GenericEdge', 'PolyLineEdge', 'QuadCurveEdge', 'SplineEdge');
plan tests => 4 + @nodes + @edges;

my $d = new_ok( 'yEd::Document', [], "testing basic Document creation:");

my $n;
foreach my $ntype (@nodes) {
    eval {
        $n = $d->addNewNode($ntype);
    };
    fail("basic $ntype creation: $@") if $@;
    isa_ok($n, "yEd::Node::$ntype", "testing basic $ntype creation and adding it:");
}

my $e;
foreach my $etype (@edges) {
    eval {
        $e = $d->addNewEdge($etype,$n,$n);
    };
    fail("basic $etype creation: $@") if $@;
    isa_ok($e, "yEd::Edge::$etype", "testing basic $etype creation and adding it:");
}

my $l;
eval {
    $l = $e->addNewLabel("I'm an EdgeLabel");
};
fail('basic EdgeLabel creation: ' . $@) if $@;
isa_ok($l, 'yEd::Label::EdgeLabel', "testing basic EdgeLabel creation and adding it:");

my $l2;
eval {
    $l2 = $n->addNewLabel("I'm a NodeLabel");
};
fail('basic NodeLabel creation: ' . $@) if $@;
isa_ok($l2, 'yEd::Label::NodeLabel', "testing basic NodeLabel creation and adding it:");

my $xml;
eval {
    $xml = $d->buildDocument();
};
fail('building the document: ' . $@) if $@;
ok($xml =~ m/^<\?xml version="1\.0" encoding="UTF-8" standalone="no"\?>/, "building the Document (not saving it to disk)");

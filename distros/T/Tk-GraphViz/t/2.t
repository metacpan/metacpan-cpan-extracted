# Creates a Tk::GraphViz, without displaying anything.
# The test is simply to lay-out a simple dot file (test1.dot)

use strict;
use warnings;

use Test::More;
use Tk;
use Tk::GraphViz;
use File::Basename;

my $mw = eval { MainWindow->new() };
plan skip_all => 'No display' if !Tk::Exists($mw);

plan tests => 6;

my $gv = $mw->GraphViz();
ok $gv, 'widget';

# Render the graph from the file
ok ( eval { $gv->show ( dirname(__FILE__).'/test1.dot' ) } );
is $@, '', 'no error in ->show';

# Check the number of nodes, edges, subgraphs
my @nodes = $gv->find ( withtag => 'node' );
is scalar @nodes, 15, 'number nodes' or diag explain \@nodes;

my @edges = $gv->find ( withtag => 'edge' );
is scalar @edges, 15, 'number edges' or diag explain \@edges;

my @subgraphs = $gv->find ( withtag => 'subgraph' );
is scalar @subgraphs, 0, 'number subgraphs' or diag explain \@subgraphs;

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More tests => 6;
BEGIN { use_ok('Tk::GraphViz') };

#########################

# Creates a Tk::GraphViz, without displaying anything.
# -- still requires connection to display, unfortunately
# The test is simply to lay-out a simple dot file (test1.dot)

use Tk;
use File::Basename;

my $mw = new MainWindow();

my $gv = $mw->GraphViz();
ok ( $gv );

# Render the graph from the file
ok ( eval { $gv->show ( dirname(__FILE__).'/test1.dot' ) } );

# Check the number of nodes, edges, subgraphs
my @nodes = $gv->find ( withtag => 'node' );
ok( @nodes == 15 );

my @edges = $gv->find ( withtag => 'edge' );
ok( @edges == 15 );

my @subgraphs = $gv->find ( withtag => 'subgraph' );
ok( @subgraphs == 0 );



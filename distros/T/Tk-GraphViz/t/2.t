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

plan tests => 9;

my $gv = $mw->GraphViz();
ok $gv, 'widget';

# Render the graph from the file
ok ( eval { $gv->show ( dirname(__FILE__).'/test1.dot' ) } );
is $@, '', 'no error in ->show';

# Check the number of nodes, edges, subgraphs
my @nodes = $gv->find ( withtag => 'node&&outermost' );
is scalar @nodes, 15, 'number nodes' or diag explain \@nodes;
my $got = [ sort $gv->nodes ];
is_deeply $got, ['a'..'l', 'x'..'z'] or diag explain $got;
isnt $gv->_findNode('a'), undef;

my @edges = $gv->find ( withtag => 'edge' );
is scalar @edges, 15, 'number edges' or diag explain \@edges;
$got = [ sort { "@$a" cmp "@$b" } $gv->edges ];
is_deeply $got, [
  [qw(a b)], [qw(a x)], [qw(a y)], [qw(a z)], [qw(b c)], [qw(b x)],
  [qw(d e)], [qw(e f)], [qw(f g)], [qw(g h)], [qw(h i)], [qw(i j)],
  [qw(j k)], [qw(k l)], [qw(x z)],
] or diag explain $got;

my @subgraphs = $gv->find ( withtag => 'subgraph' );
is scalar @subgraphs, 0, 'number subgraphs' or diag explain \@subgraphs;

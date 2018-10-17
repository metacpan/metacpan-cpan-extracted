use Graph;
use Graph::D3;
my $g = new Graph(
    vertices => [qw/1 2 3 4 5/], 
    edges => [[qw/1 2/], [qw/2 3/], [qw/3 5/], [qw/4 1/]] 
);
my $d3 = new Graph::D3(graph => $g);
my $output = $d3->force_directed_graph(); #output is hash reference
$output = $d3->hierarchical_edge_bundling(); #output is hash reference
 
$d3 = new Graph::D3(graph => $g, type => json); 
my $json = $d3->force_directed_graph(); # output is json format
$json = $d3->hierarchical_edge_bundling(); # output is json format
print "$json\n";

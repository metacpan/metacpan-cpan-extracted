#!perl

use strict;
use warnings;
use autodie;
use feature qw/ say /;
use lib 'lib';
use YAGL;
use Cwd;
use Test::More tests => 2;
use constant DEBUG => undef;

my $cwd = getcwd;

=head1 GraphViz output tests

=head2 Test 1. Basic GraphViz output

=cut

my $g = YAGL->new;
$g->read_csv(qq[$cwd/data/three-triangles.csv]);

chomp(my $got = $g->to_graphviz);

$g->draw('triangles') if DEBUG;

my $expected = <<"EOF";
graph { 
 a  --   {  b [ label=b  ]  } [label=13]
 a  --   {  c [ label=c  ]  } [label=7]
 b  --   {  c [ label=c  ]  } [label=9]
 b  --   {  d [ label=d  ]  } [label=16]
 c  --   {  g [ label=g  ]  } [label=23]
 d  --   {  e [ label=e  ]  } [label=3]
 d  --   {  f [ label=f  ]  } [label=3]
 e  --   {  f [ label=f  ]  } [label=12]
 f  --   {  h [ label=h  ]  } [label=18]
 g  --   {  h [ label=h  ]  } [label=1]
 g  --   {  i [ label=i  ]  } [label=6]
 h  --   {  i [ label=i  ]  } [label=9]
  } 
EOF

chomp($expected);

ok( $got eq $expected, "Graphviz data format is as expected" );

=head2 Test 2. GraphViz output with path

=cut

my $g2 = YAGL->new;
$g2->read_csv(qq[$cwd/data/three-triangles.csv]);

my @path = map {$_->{vertex}} $g2->dijkstra('a', 'i');

chomp(my $got2 = $g2->to_graphviz(\@path));

my $expected2 = <<"EOF";
graph { 
 a [style=filled fillcolor=red] 
 a  --   {  b [ label=b  ]  } [label=13]
 c [style=filled fillcolor=red] 
 a  --   {  c [ label=c  ]  } [label=7]
 c [style=filled fillcolor=red] 
 b  --   {  c [ label=c  ]  } [label=9]
 b  --   {  d [ label=d  ]  } [label=16]
 c [style=filled fillcolor=red] 
 g [style=filled fillcolor=red] 
 c  --   {  g [ label=g  ]  } [label=23]
 d  --   {  e [ label=e  ]  } [label=3]
 d  --   {  f [ label=f  ]  } [label=3]
 e  --   {  f [ label=f  ]  } [label=12]
 f  --   {  h [ label=h  ]  } [label=18]
 g [style=filled fillcolor=red] 
 g  --   {  h [ label=h  ]  } [label=1]
 i [style=filled fillcolor=red] 
 g  --   {  i [ label=i  ]  } [label=6]
 i [style=filled fillcolor=red] 
 h  --   {  i [ label=i  ]  } [label=9]
 i [style=filled fillcolor=red] 
  } 
EOF

$g2->draw('dijkstra', \@path) if DEBUG;

chomp($expected2);

ok( $got2 eq $expected2, "Graphviz data format is as expected when a path argument is passed" );

__END__

#        A
#       / \
#      /   \
#      B - C
#     /     \
#    /       \
#   /         \
#   D          G
# /  \         / \
# E - F ----- H - I

# Local Variables:
# compile-command: "cd .. && perl t/33-to-graphviz.t"
# End:

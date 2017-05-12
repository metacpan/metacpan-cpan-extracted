use utf8;
use strict;

use open qw(:std :utf8);
use Test::More 'no_plan';
use lib 't/lib';

use TreePath;

my $simpletree = [
    {
        id => '1',
        source => 'File',
        file => '/tmp/file1.txt'},
    {
        id => '2',
        source => 'File',
        file => '/tmp/file2.txt'},
    {
        id => '1',
        source => 'Page',
        parent => 0,
        files => [ { 'File_1'}, {'File_2'}],
        name => '/',},
    {
        id => '2',
        source => 'Page',
        parent => { 'Page_1' },
        name => 'A'},
    {
        id => '3',
        source => 'Page',
        parent =>  { 'Page_2' },
        name => 'B'},
    {
        id => '4',
        source => 'Page',
        parent =>  { 'Page_3' },
        name => 'C'},
    {
        id => '5',
        source => 'Page',
        parent =>  { 'Page_4' },
        name => 'D'},
    {
        id => '6',
        source => 'Page',
        parent =>  { 'Page_4' },
        name => 'E'},
    {
        id => '7',
        source => 'Page',
        parent =>  { 'Page_2' },
        name => '♥'},
    {
        id => '8',
        source => 'Page',
        parent =>  { 'Page_7' },
        name => 'G'},
    {
        id => '9',
        source => 'Page',
        parent => { 'Page_7' },
        name => 'E'},
    {
        id => '10',
        source => 'Page',
        parent =>  { 'Page_9' },
        name => 'I'},
    {
        id => '11',
        source => 'Page',
        parent => { 'Page_9' },
        name => 'J'},
    {
        id => '1',
        source => 'Comment',
        parent => { 'Page_1' }},
    {
        id => '2',
        source => 'Comment',
        parent => { 'Page_1' }},
    {
        id => '3',
        source => 'Comment',
        parent => { 'Page_2' }},
    {
        id => '4',
        source => 'Comment',
        parent => { 'Page_2' }},
    {
        id => '5',
        source => 'Comment',
        parent => { 'Page_1' }},
    {
        id => '6',
        source => 'Comment',
        parent => { 'Page_7' }},
    {
        id => '7',
        source => 'Comment',
        parent => { 'Page_11' }},
    {
        id => '8',
        source => 'Comment',
        parent => { 'Page_11' }},

];


my @confs = ( $simpletree,                # use default 'parent' key
              't/conf/treefromfile.yml',  # use 'parent' (Page)  and 'page' (Comment) as parent_key
              't/conf/treefromdbix.yml',
            );



foreach my $conf ( @confs ){

    ok(1,'-'x55);
    my $arg = 'conf';
    if ( ref($conf)) {
        $arg = 'datas'
    }
    # ok( my $tp = TreePath->new(  $arg  => $conf ),
    #     "New TreePath ( $arg => $conf)");

    ok( my $tp = TreePath->new(  $arg  => $conf  ),
        "New TreePath ( $arg => $conf)");

    $tp->load;

    my $tree = $tp->tree;
    isa_ok($tree, 'HASH');

    my $root = $tp->root;
    is($root,$tree->{Page_1}, 'retrieve root');
    isa_ok($root, 'HASH', "root" );
    is ( $tp->count, 21, 'tree has 21 nodes');
    my $count = 21;


    # search --------------------------
    is($tp->search({ mykey => 'test'}), 0, "mykey is unknown, return 0");

    # in scalar context, return the first found
    ok( my $E = $tp->search( { name => 'E', source => 'Page' } ), 'first Page E found');
    isa_ok($E, 'HASH');
    isa_ok($E->{parent},      'HASH' , 'parent');
    is($E->{parent}->{name}, 'C', 'C is parent of E');

    # If not found, retounr undef
    ok( ! $tp->search( { name => 'Z', source => 'Page' } ), 'Z not found');

    # in array context, returns all found
    ok(my @allE = $tp->search( { name => 'E', source => 'Page' } ), 'search all E');
    is(@allE, 2, 'both found E');


    # It is also possible to specify a particular field of a hash
    ok( my $B = $tp->search( { name => 'B', 'parent.name' => 'A', source => 'Page'} ), 'search B, specify parent.name to search in hashref');
    is($B->{parent}->{name}, 'A', 'A is parent of B');

    # search_path ---------------------
    # in scalar context, return the last
    ok(my $slash    = $tp->search_path('Page', '/'), 'search Page / in scalar context, return root ');
    isa_ok($slash, 'HASH');
    is($slash->{name},'/', 'name is /');
    is ($slash, $root, 'slash and root are the same');

    ok(my $c    = $tp->search_path('Page', '/A/B/C'), 'search /A/B/C in scalar context, return C ');
    is($c->{name},'C', 'name is C');

    ok(my $childrenc = $c->{children}, 'children c');
    is($childrenc->[0]->{name}, 'D', 'first child is D');
    is($childrenc->[1]->{name}, 'E', 'second child is E');

    my $notfound = $tp->search_path('Page', '/A/B/Z');
    is ($notfound,'', "search /A/B/Z in scalar context, return '' (not found)" );

    # in array context, return found and not_found
    # found = /, A, B and not_found = X, D, E
    ok(my ($found, $not_found) = $tp->search_path('Page', '/A/B/X/D/E'), 'search /A/B/X/D/E in array context');

    is_deeply( node_names($found), ['/', 'A', 'B'], "found /, A, B" );
    is_deeply( \@$not_found, ['X', 'D', 'E'], "not found X, D, E" );


    # B == found->[2] ?
    is( $B, $found->[2], 'B and found->[2] are the same');


  # test utf8 -----------------------
  ok( my $coeur = $tp->search( { name => '♥', source => 'Page'} ), 'search ♥');
  is($coeur->{parent}->{name},'A', 'parent is A');

  # traverse ------------------------
  ok(my $coeur_nodes = $tp->traverse($coeur), 'all nodes from ♥');
  is(scalar @$coeur_nodes, 8, 'traverse ♥ and 7 children');

  my $args = {};
  ok($tp->traverse($coeur, \&myfunc, $args), 'traverse tree with function');
  is($args->{_count}, 8, '♥ as 7 children + himself');

  #is_deeply( node_names($args->{all_nodes}), ['♥', 'G', 'E', 'I', 'J' ], "traverse and return all nodes from ♥" );

  # delete node ---------------------
  ok( my $E2 = $tp->search( { name => 'E', 'parent.name' => '♥', source => 'Page'} ), 'search E to delete');

  # before deletion
  is ( $tp->count, $count, "before deletion tree has $count nodes");
  is(scalar @{$coeur->{children}}, 2, 'before deletion ♥ has two children (G and E)');
  ok(my $E2_nodes = $tp->traverse($E2), 'all nodes from E2');
  is(scalar @$E2_nodes, 5, 'traverse E2 and 4 children');

  # recursively deletes E2 and children
  is($tp->del($E2), 5, 'delete E and 4 childrens');
  $count = $count -5;
  is ( $tp->count, $count, "after deletion tree has $count nodes");
  is(scalar @{$coeur->{children}}, 1, 'after deletion ♥ has only one child (G)');
  is(scalar @{$coeur->{children_Comment}}, 1, 'and only one comment (6)');

  # delete several nodes
  ok(my $n1 = $tp->add({ name => 'N1', source => 'Page', id => '100'}, $coeur), 'n1 added as a child to ♥');
  ok(my $n2 = $tp->add({ name => 'N2', source => 'Page', id => '101'}, $coeur), 'n2 added as a child to ♥');
  ok(my $n3 = $tp->add({ name => 'N3', source => 'Page', id => '102'}, $n2), 'n3 added as a child to n2');
  $count = $count + 3;
  is(scalar @{$coeur->{children}}, 3, '♥ has 3 children (G, N1, N2)');
  is(scalar @{$coeur->{children_Comment}}, 1, '♥ has also a comment');
  is ( $tp->count, $count, "tree has $count nodes");

  is($tp->del($n1, $n2), 3, 'delete N1, N2 and child N3');
  $count = $count - 3;
  is(scalar @{$coeur->{children}}, 1, 'after deletion ♥ has only one child (G)');
  is ( $tp->count, $count, "tree has $count nodes");

  # add node ---------------------
  eval { $tp->add({ name => 'hehe', source => 'source1', id => 33, parent => 0}) };
  ok($@ =~ m/root already exist/,"cannot add a second root");

  my $x = { name => 'X', source => 'Page', id => '200'};
  ok(my $X = $tp->add($x, $coeur), 'x added as a child to ♥');
  $count = $count + 1;

  my $x_parent = $X->{parent};
  is( $x_parent->{id}, $coeur->{id}, 'X have ♥ as parent');

  my $x_parent_children = $x_parent->{children};
  is($$x_parent_children[-1]->{id}, $X->{id}, 'X is the last child of ♥');

  ok(my $G = $tp->search( { name => 'G', source => 'Page' } ), 'search G, the first child of ♥');

  ok(my $noparent = $tp->add({ name => 'NoParent', source => 'Page', id => '1000'}), 'add a node without parent');
  $count = $count + 1;
  ok(my $NoParent = $tp->search( { name => 'NoParent', source => 'Page' } ), 'search NoParent');
  is($NoParent, $NoParent, 'retrieve NoParent');
  ok(my $WithParent = $tp->move($NoParent, $root ), 'move NoParent to root');
  is($WithParent->{parent}, $root, 'now NoParent has a parent');
  is ( $tp->count, $count, "tree has $count nodes");

  # move node ---------------------
  my $zz = { name => 'ZZ', source => 'Page', id => '300'};
  ok(my $Z1 = $tp->add($zz, $tp->root), 'zz added as a child of root');
  $count = $count + 1;
  is(scalar @{$coeur->{children}}, 2, '♥ has two child (G, X)');
  ok(my $Z2 = $tp->move($Z1, $coeur ), 'move zz to ♥');
  is(scalar @{$coeur->{children}}, 3, 'now ♥ has three child (G, X, ZZ)');

    # test array
    my $files = $root->{files};
    is($files->[0], $tp->tree->{File_1}, "files are ref to tree nodes");

}

unlink 't/test.db';

sub myfunc() {
  my ($node, $args) = @_;

  $args->{all_nodes} = []
  if ( ! defined $args->{all_nodes});

  if(defined($node)) {
    push(@{$args->{all_nodes}}, $node);
    return 1;
  }
}

sub node_names {
  my $nodes = shift;
  return [map { $_->{name}} @$nodes ];
}

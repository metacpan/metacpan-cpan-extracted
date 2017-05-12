use Test::More tests => 15;

use XML::Parser::Lite::Tree;
my $x = XML::Parser::Lite::Tree->instance();
ok( defined($x), "instance() returns something" );
ok( ref $x eq 'XML::Parser::Lite::Tree', "instance returns the right object" );

my $tree = $x->parse('<foo bar="baz">woo<yay />hoopla</foo>');

ok( defined($tree), "parse() returns something" );
ok( scalar @{$tree->{children}} == 1, "tree root contains a single root node" );

my $root_node = pop @{$tree->{children}};

ok( $root_node->{type} eq 'element', "root node is an element" );
ok( $root_node->{name} eq 'foo', "root node has correct name" );
ok( scalar keys %{$root_node->{attributes}} == 1, "correct attribute count" );
ok( $root_node->{attributes}->{bar} eq 'baz', "correct attribute name and value" );
ok( scalar @{$root_node->{children}} == 3, "correct child count" );

ok( $root_node->{children}->[0]->{type} eq 'text', "child 1 type correct" );
ok( $root_node->{children}->[0]->{content} eq 'woo', "child 1 content correct" );

ok( $root_node->{children}->[1]->{type} eq 'element', "child 2 type correct" );
ok( $root_node->{children}->[1]->{name} eq 'yay', "child 2 name correct" );

ok( $root_node->{children}->[2]->{type} eq 'text', "child 3 type correct" );
ok( $root_node->{children}->[2]->{content} eq 'hoopla', "child 3 content correct" );

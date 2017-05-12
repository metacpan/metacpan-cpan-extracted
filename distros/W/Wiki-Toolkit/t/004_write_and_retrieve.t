use strict;
use Wiki::Toolkit::TestLib;
use Test::More;

if ( scalar @Wiki::Toolkit::TestLib::wiki_info == 0 ) {
    plan skip_all => "no backends configured";
} else {
    plan tests => ( 12 * scalar @Wiki::Toolkit::TestLib::wiki_info );
}

my $iterator = Wiki::Toolkit::TestLib->new_wiki_maker;

while ( my $wiki = $iterator->new_wiki ) {
    # Test a simple write and retrieve.
    ok( $wiki->write_node("A Node", "Node content."),
        "write_node can create a node" );
    is( $wiki->retrieve_node("A Node"), "Node content.",
        "retrieve_node can retrieve it" );

    # Test calling syntax of ->retrieve_node.
    eval { $wiki->retrieve_node; };
    ok( $@, "retrieve_node dies if we don't tell it a node parameter" );
    is( $wiki->retrieve_node(name => "A Node"), "Node content.",
        "retrieve_node still works if we supply params as a hash" );
    is( $wiki->retrieve_node(name => "A Node", version => 1), "Node content.",
        "...still works if we supply a version param" );
    my %node_data = $wiki->retrieve_node("A Node");
    is( $node_data{content}, "Node content.",
	"...still works when called in list context" );
    foreach (qw( last_modified version checksum )) {
        ok( defined $node_data{$_}, "...and $_ is defined" );
    }

    # Test ->node_exists.
    ok( $wiki->node_exists("A Node"),
        "node_exists returns true for an existing node" );
    ok( ! $wiki->node_exists("This Is A Nonexistent Node"),
	    "...and false for a nonexistent one" );

    # Test -> node_name_for_id
    my $id = $wiki->store->{_dbh}->selectrow_array("SELECT id FROM node WHERE name = 'A Node'");
    is( "A Node", $wiki->store->node_name_for_id($id),
        "Can fetch the name of a node with a id" );
}

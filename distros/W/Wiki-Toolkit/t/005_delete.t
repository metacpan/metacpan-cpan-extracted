use strict;
use Wiki::Toolkit::TestLib;
use Test::More;

if ( scalar @Wiki::Toolkit::TestLib::wiki_info == 0 ) {
    plan skip_all => "no backends configured";
} else {
    plan tests => ( 5 * scalar @Wiki::Toolkit::TestLib::wiki_info );
}

my $iterator = Wiki::Toolkit::TestLib->new_wiki_maker;

while ( my $wiki = $iterator->new_wiki ) {
    $wiki->write_node("A Node", "Node content.") or die "Can't write node";

    # Test deletion of an existing node.
    eval { $wiki->delete_node("A Node") };
    is( $@, "", "delete_node doesn't die when deleting an existing node" );
    is( $wiki->retrieve_node("A Node"), "",
	"...and retrieving a deleted node returns the empty string" );
    ok( ! $wiki->node_exists("A Node"),
	    "...and ->node_exists now returns false" );
    SKIP: {
        skip "No search configured for this combination", 1
          unless $wiki->search_obj;
        my %results = $wiki->search_nodes("content");
        is_deeply( \%results, { }, "...and a search does not find the node" );
    }

    # Test deletion of a nonexistent node.
    eval { $wiki->delete_node("idonotexist") };
    is( $@, "",
	"delete_node doesn't die when deleting a non-existent node" );
}

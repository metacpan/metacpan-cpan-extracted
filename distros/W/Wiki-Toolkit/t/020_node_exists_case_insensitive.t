use strict;
use Wiki::Toolkit::TestLib;
use Test::More;

if ( scalar @Wiki::Toolkit::TestLib::wiki_info == 0 ) {
    plan skip_all => "no backends configured";
} else {
    plan tests => ( 3 * scalar @Wiki::Toolkit::TestLib::wiki_info );
}

my $iterator = Wiki::Toolkit::TestLib->new_wiki_maker;

while ( my $wiki = $iterator->new_wiki ) {
    print "# Store: " . (ref $wiki->store) . "\n"; 

    # Write data.
    $wiki->write_node( "Node 1", "foo" ) or die "Can't write node";

    # Test old syntax.
    ok( $wiki->node_exists( "Node 1" ),
        "old calling syntax for ->node_exists still works" );

    # Now test case-insensitivity works on all backends.
    ok( $wiki->node_exists( name => "node 1", ignore_case => 1 ),
        "->node_exists OK when ignore_case is true, name lowercase" );
    ok( $wiki->node_exists( name => "NODE 1", ignore_case => 1 ),
        "->node_exists OK when ignore_case is true, name uppercase" );

}

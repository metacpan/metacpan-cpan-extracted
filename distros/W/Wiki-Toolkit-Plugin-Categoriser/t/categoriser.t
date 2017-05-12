use strict;
use Wiki::Toolkit::TestLib;
use Test::More;

my $iterator = Wiki::Toolkit::TestLib->new_wiki_maker;
plan tests => ( 1 + $iterator->number * 7 );

use_ok( "Wiki::Toolkit::Plugin::Categoriser" );

while ( my $wiki = $iterator->new_wiki ) {
    print "#\n##### TEST CONFIG: Store: " . (ref $wiki->store) . "\n";

    my $categoriser = eval { Wiki::Toolkit::Plugin::Categoriser->new; };
    is( $@, "", "'new' doesn't croak" );
    isa_ok( $categoriser, "Wiki::Toolkit::Plugin::Categoriser" );
    $wiki->register_plugin( plugin => $categoriser );

    $wiki->write_node( "Calthorpe Arms", "beer", undef,
			 { category => [ "Pubs", "Pub Food" ] } )
      or die "Can't write node";
    $wiki->write_node( "Albion", "pub", undef,
			 { category => [ "Pubs", "Pub Food" ] } )
      or die "Can't write node";
    $wiki->write_node( "Ken Livingstone", "Congestion charge hero", undef,
                       { category => [ "People" ] } )
      or die "Can't write node";

    # Test ->in_category
    my $isa_pub = $categoriser->in_category( category => "Pubs",
                                             node     => "Albion" );
    ok( $isa_pub, "in_category returns true for things in the category" );
    $isa_pub = $categoriser->in_category( category => "Pubs",
                                          node     => "Ken Livingstone" );
    ok( !$isa_pub, "...and false for things not in the category" );

    $isa_pub = $categoriser->in_category( category => "pubs",
                                          node     => "Albion" );
    ok( $isa_pub, "...and is case-insensitive" );

    # Test ->categories
    my @categories = $categoriser->categories( node => "Calthorpe Arms" );
    is_deeply( [ sort @categories ], [ "Pub Food", "Pubs" ],
               "...->categories returns all categories" );

    # Make sure we only look at current category data.
    my %node_data = $wiki->retrieve_node( "Calthorpe Arms" );
    $wiki->write_node( "Calthorpe Arms",
                       "Oh noes, they stopped doing food!",
                       $node_data{checksum},
                       { category => [ "Pubs" ] } )
      or die "Can't write node";
    @categories = $categoriser->categories( node => "Calthorpe Arms" );
    is_deeply( \@categories, [ "Pubs" ],
               "->categories ignores out-of-date data" );
}

use strict;
use Wiki::Toolkit::TestLib;
use Test::More;

# Test for search backends that support metadata indexing
# (currently just Lucy).  Note that Wiki::Toolkit::TestLib sets up three
# indexed metadata fields in the Lucy search - address, category, and locale.

my $num_tests = 11;

if ( scalar @Wiki::Toolkit::TestLib::wiki_info == 0 ) {
    plan skip_all => "no backends configured";
} else {
    plan tests => ( $num_tests * scalar @Wiki::Toolkit::TestLib::wiki_info );
}

my $iterator = Wiki::Toolkit::TestLib->new_wiki_maker;

while ( my $wiki = $iterator->new_wiki ) {
    SKIP: {
        print "# Store is: " . ( ref $wiki->store ) . "\n";
        print "# Search is: " . ( ref $wiki->search_obj ) . "\n";

        skip "No search configured for this backend", $num_tests
            unless ref $wiki->search_obj;

        skip "Metadata indexing not supported by this backend", $num_tests
            unless $wiki->search_obj->supports_metadata_indexing;

        # Put some test data in.
        $wiki->write_node( "Red Lion", "A drinking establishment", undef,
          { category    => [ "Pubs", "Real Ale" ],
            locale      => [ "London", "Soho" ],
            not_indexed => "wombats" } )
          or die "Couldn't write node: Red Lion";

        $wiki->write_node( "Wiki Etiquette", "Be excellent to each other" )
          or die "Couldn't write node: Wiki Etiquette";

        my %results = $wiki->search_nodes( "etiquette" );
         ok( defined $results{"Wiki Etiquette"}, "Search with metadata "
             . "indexing set up can find things with no metadata" );

        %results = $wiki->search_nodes( "real ale" );
         ok( defined $results{"Red Lion"},
            "Search finds things in metadata" );

        %results = $wiki->search_nodes( "london pubs" );
        ok( defined $results{"Red Lion"}, "Search finds things partly in one "
            . "metadata field and partly in another" );

        %results = $wiki->search_nodes( "soho drinking" );
        ok( defined $results{"Red Lion"}, "Search finds things partly in "
            . "content and partly in metadata" );

        %results = $wiki->search_nodes( "red lion london" );
        ok( defined $results{"Red Lion"}, "Search finds things partly in "
            . "title and partly in metadata" );

        %results = $wiki->search_nodes( "wombats" );
        ok( !defined $results{"Red Lion"}, "Search ignores metadata fields "
            . "that it's not been told to index" );

        # Write a new version with different metadata, make sure the old data
        # is removed and the new data is picked up.
        my %data = $wiki->retrieve_node( "Red Lion" );
        my $checksum = $data{checksum};
        $wiki->write_node( "Red Lion", "A drinking establishment",
          $data{checksum},
          { category => [ "Bars", "Cocktails" ],
            locale   => [ "Oxford", "Cowley Road" ] } )
          or die "Couldn't write node";

        %results = $wiki->search_nodes( "real ale" );
         ok( !defined $results{"Red Lion"},
            "Search doesn't look at old versions of metadata" );

        %results = $wiki->search_nodes( "cocktails" );
         ok( defined $results{"Red Lion"},
            "...but it does look at the new versions" );

        # Delete the new version, check the old data is now picked up.
        $wiki->delete_node( name => "Red Lion", version => 2 );

        %results = $wiki->search_nodes( "real ale" );
         ok( defined $results{"Red Lion"},
            "Search picks up most recent metadata when one version deleted" );

        %results = $wiki->search_nodes( "cocktails" );
         ok( !defined $results{"Red Lion"},
            "...and ignores the deleted stuff" );

        # Delete node entirely, make sure it doesn't get picked up.
        $wiki->delete_node( name => "Red Lion" );

        %results = $wiki->search_nodes( "real ale" );
         ok( !defined $results{"Red Lion"},
            "Search ignores metadata of deleted nodes" );

    }
}

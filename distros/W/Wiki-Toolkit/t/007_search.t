use strict;
use Wiki::Toolkit::TestLib;
use Test::More;

if ( scalar @Wiki::Toolkit::TestLib::wiki_info == 0 ) {
    plan skip_all => "no backends configured";
} else {
    plan tests => ( 16 * scalar @Wiki::Toolkit::TestLib::wiki_info );
}

my $iterator = Wiki::Toolkit::TestLib->new_wiki_maker;

while ( my $wiki = $iterator->new_wiki ) {
    SKIP: {
        skip "Not testing search for this configuration", 16
            unless $wiki->search_obj;

        print '# $wiki->search_obj is a ' . $wiki->search_obj . "\n";

        my %results = eval { $wiki->search_nodes( "foo" ); };
        is( $@, "",
            "->search_nodes doesn't die when we've not written anything" );

        # Put some test data in.
        $wiki->write_node( "Home", "This is the home node." )
          or die "Couldn't write node";
        $wiki->write_node( "Another Node", "This isn't the home node." )
          or die "Couldn't write node";
        $wiki->write_node( "Everyone's Favourite Hobby",
                           "Performing expert wombat defenestration." )
          or die "Couldn't write node";
        $wiki->write_node( "001 Defenestration",
                           "Expert advice for all your defenestration needs!")
          or die "Couldn't write node";

        %results = eval {
            local $SIG{__WARN__} = sub { die $_[0] };
            $wiki->search_nodes('home');
        };
        is( $@, "", "search_nodes doesn't throw warning" );

        isnt( scalar keys %results, 0, "...and can find a single word" );
        is( scalar keys %results, 2, "...the right number of times" );
        is_deeply( [sort keys %results], ["Another Node", "Home"],
                   "...and the hash returned has node names as keys" );

        %results = $wiki->search_nodes('expert defenestration');
        isnt( scalar keys %results, 0,
              "...and can find two words on an AND search" );

        my %and_results = $wiki->search_nodes('wombat home', 'AND');
        if ( scalar keys %and_results ) {
            print "# " . join( "\n# ", map { "$_: " . $and_results{$_} }
                                       keys %and_results ) . "\n";
        }
        is( scalar keys %and_results, 0,
            "...AND search doesn't find nodes with only one term." );

        %results = $wiki->search_nodes('wombat home', 'OR');
        isnt( scalar keys %results, 0,
              "...and the OR search seems to work" );

        SKIP: {
            skip "Search backend doesn't support phrase searches", 2
                unless $wiki->supports_phrase_searches;

            %results=$wiki->search_nodes('expert "wombat defenestration"');
            isnt( scalar keys %results, 0, "...and can find a phrase" );
            ok( ! defined $results{"001 Defenestration"},
                "...and ignores nodes that only have part of the phrase" );
        }

        # Test case-insensitivity.
        %results = $wiki->search_nodes('performing');
        ok( defined $results{"Everyone's Favourite Hobby"},
            "a lower-case search finds things defined in mixed case" );

        %results = $wiki->search_nodes('WoMbAt');
        ok( defined $results{"Everyone's Favourite Hobby"},
            "a mixed-case search finds things defined in lower case" );

        # Check that titles are searched.
        %results = $wiki->search_nodes('Another');
        ok( defined $results{"Another Node"},
            "titles are searched" );

        ##### Test that newly-created nodes come up in searches, and that
        ##### once deleted they don't come up any more.
        %results = $wiki->search_nodes('Sunnydale');
        unless ( scalar keys %results == 0 ) {
            die "'Sunnydale' already in indexes -- rerun init script";
        }
        unless ( ! defined $results{"New Searching Node"} ) {
            die "'New Searching Node' already in indexes -- rerun init script";
        }
        $wiki->write_node("New Searching Node", "Sunnydale")
            or die "Can't write 'New Searching Node'";
            # will die if node already exists
        %results = $wiki->search_nodes('Sunnydale');
        ok( defined $results{"New Searching Node"},
            "new nodes are correctly indexed for searching" );
        $wiki->delete_node("New Searching Node")
            or die "Can't delete 'New Searching Node'";
        %results = $wiki->search_nodes('Sunnydale');
        ok( ! defined $results{"New Searching Node"},
            "...and removed from the indexes on deletion" );

        # Make sure that overwritten content doesn't come up in searches.
        $wiki->write_node( "Overwritten Node", "aubergines" )
            or die "Can't write 'Overwritten Node'";
        my %node_data = $wiki->retrieve_node( "Overwritten Node" );
        $wiki->write_node( "Overwritten Node", "bananas",
                           $node_data{checksum} )
            or die "Can't write 'Overwritten Node'";
        %results = $wiki->search_nodes( "aubergines" );
        ok( ! defined $results{ "Overwritten Node" },
            "Overwritten content doesn't show up in searches." );
    }
}

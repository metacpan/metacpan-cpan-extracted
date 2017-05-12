use strict;
use Wiki::Toolkit::TestLib;
use Test::More;

my $num_tests = 3;

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

        skip "Tests only relevant to Lucy search backend", $num_tests
            unless ( ref $wiki->search_obj
                     && $wiki->search_obj->isa("Wiki::Toolkit::Search::Lucy"));

        # Write data without title weighting, store the search scores.
        write_data( $wiki );
        my %results = $wiki->search_nodes( "putney tandoori" );
        my $orig_putney = $results{"Putney"};
        my $orig_tandoori = $results{"Putney Tandoori"};
        print "# Putney score: $orig_putney\n";
        print "# Putney Tandoori score: $orig_tandoori\n";

        # Clear database, set up a new search backend with title weighting,
        # write data again and check search scores.
        $wiki->delete_node( "Putney" ) or die "Couldn't delete Putney";
        $wiki->delete_node( "Putney Tandoori" )
            or die "Couldn't delete Putney Tandoori";

        # Copied from Wiki::Toolkit::TestLib.
        require Wiki::Toolkit::Search::Lucy;
        require File::Path;
        my $dir = "t/lucy";
        File::Path::rmtree( $dir, 0, 1 ); #  0 = verbose, 1 = safe
        mkdir $dir or die $!;
        my $new_search = Wiki::Toolkit::Search::Lucy->new(
            path => $dir,
            metadata_fields => [ "address", "category", "locale" ],
            boost => { title => 5 } );

        my $new_wiki = Wiki::Toolkit->new(
            store => $wiki->store,
            search => $new_search );

        write_data( $new_wiki );

        %results = $new_wiki->search_nodes( "putney tandoori" );
        my $new_putney = $results{"Putney"};
        my $new_tandoori = $results{"Putney Tandoori"};
        print "# New Putney score: $new_putney\n";
        print "# New Putney Tandoori score: $new_tandoori\n";

        ok( $new_putney > $orig_putney,
            "Lucy title score boosting works for single word" );
        ok( $new_tandoori > $orig_tandoori, "...and for two words" );

        ok( $results{"Putney Tandoori"} > $results{"Putney"},
            "We can make sure that words in title score higher" );
    }
}

sub write_data {
    my $wiki= shift;
    $wiki->write_node( "Putney Tandoori", "Indian food", undef,
                       { address => "London Road" } )
      or die "Couldn't write node";
    $wiki->write_node( "Putney", "There is a tandoori restaurant here",
                       undef, { locale => "London" } )
      or die "Couldn't write node";
}

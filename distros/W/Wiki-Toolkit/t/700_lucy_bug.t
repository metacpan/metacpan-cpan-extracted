use strict;
use Wiki::Toolkit::TestLib;
use Test::More;

# Test for bug discovered in version 0.02 of Wiki::Toolkit::Search::Lucy
# - if you wrote a node called Foo Bar and then another one called Foo,
# it would delete Foo Bar from the index.

if ( scalar @Wiki::Toolkit::TestLib::wiki_info == 0 ) {
    plan skip_all => "no backends configured";
} else {
    plan tests => ( 2 * scalar @Wiki::Toolkit::TestLib::wiki_info );
}

my $iterator = Wiki::Toolkit::TestLib->new_wiki_maker;

while ( my $wiki = $iterator->new_wiki ) {
    SKIP: {
        print "# Store is: " . ( ref $wiki->store ) . "\n";
        print "# Search is: " . ( ref $wiki->search_obj ) . "\n";

        skip "No search configured for this backend", 2
            unless ref $wiki->search_obj;

        # Put some test data in.
        $wiki->write_node( "Foo Bar", "baz" )
          or die "Couldn't write node";
        $wiki->write_node( "Foo", "quux" )
          or die "Couldn't write node";

        my %results = $wiki->search_nodes( "baz" );
        ok( defined $results{"Foo Bar"},
            "Search doesn't forget about Foo Bar when we write Foo" );

        %results = $wiki->search_nodes( "quux" );
        ok( defined $results{Foo}, "...and it remembers Foo too" );
    }
}

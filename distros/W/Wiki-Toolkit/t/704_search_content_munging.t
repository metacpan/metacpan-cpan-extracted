use strict;
use Wiki::Toolkit::TestLib;
use Test::More;

my $num_tests = 2;

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

        my $using_lucy = ref $wiki->search_obj
            && $wiki->search_obj->isa( "Wiki::Toolkit::Search::Lucy" );

        my $using_plucene = ref $wiki->search_obj
            && $wiki->search_obj->isa( "Wiki::Toolkit::Search::Plucene" );

        skip "Tests only relevant to Lucy/Plucene search backends", $num_tests
            unless ( $using_lucy || $using_plucene );

        # Set up a new search backend which excludes the word "secretword"
        # from search indexing, then set up a new wiki using that backend.
        # Path info copied from Wiki::Toolkit::TestLib.
        my $new_search;

        if ( $using_lucy ) {
            require Wiki::Toolkit::Search::Lucy;
            $new_search = Wiki::Toolkit::Search::Lucy->new(
                path => "t/lucy",
                content_munger => \&munger,
            );
        } else {
            require Wiki::Toolkit::Search::Plucene;
            $new_search = Wiki::Toolkit::Search::Plucene->new(
                path => "t/plucene",
                content_munger => \&munger,
            );
        }

        my $new_wiki = Wiki::Toolkit->new(
            store => $wiki->store,
            search => $new_search );

        $new_wiki->write_node( "Secrets", "banana secretword elephant" )
          or die "Couldn't write node";

        my %results = $new_wiki->search_nodes( "secretword" );
        ok( !defined $results{Secrets},
            "content munging works to exclude word from search index" );

        %results = $new_wiki->search_nodes( "banana" );
        ok( $results{Secrets}, "...doesn't affect other words" );
    }
}

sub munger {
    my $content = shift;
    $content =~ s/secretword//gs;
    return $content;
}

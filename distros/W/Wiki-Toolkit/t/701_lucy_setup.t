use strict;
use Test::More tests => 2;

eval { require Lucy; };
SKIP: {
    skip "Lucy not installed", 2 if $@;
    require Wiki::Toolkit::Search::Lucy;

    my $search = Wiki::Toolkit::Search::Lucy->new( path => "t/lucy" );
    isa_ok( $search, "Wiki::Toolkit::Search::Lucy",
            "Lucy search with no metadata indexing" );

    $search = Wiki::Toolkit::Search::Lucy->new(
        path => "t/lucy",
        metadata_fields => [ "category", "locale", "address" ] );
    isa_ok( $search, "Wiki::Toolkit::Search::Lucy",
            "Lucy search with metadata indexing" );
}

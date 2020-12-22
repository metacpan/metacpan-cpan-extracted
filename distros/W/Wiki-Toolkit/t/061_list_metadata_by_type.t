use strict;
use Wiki::Toolkit::TestLib;
use Test::More;

if ( scalar @Wiki::Toolkit::TestLib::wiki_info == 0 ) {
    plan skip_all => "no backends configured";
} else {
    plan tests => ( 9 * scalar @Wiki::Toolkit::TestLib::wiki_info );
}

my $iterator = Wiki::Toolkit::TestLib->new_wiki_maker;

while ( my $wiki = $iterator->new_wiki ) {
    # Put some test data in.
    $wiki->write_node( "Reun Thai", "A restaurant", undef,
        { postcode => "W6 9PL",
          category => [ "Thai Food", "Restaurant", "Hammersmith" ],
          latitude => "51.911", longitude => "" } );

    $wiki->write_node( "GBK", "A burget restaurant", undef,
        { postcode => "OX1 2AY",
          category => [ "Burgers", "Restaurant", "Oxford" ] });

    # And one with an un-moderated version
    $wiki->write_node( "Cafe Roma", "A cafe", undef,
        { category => [ "Cafe", "Oxford" ],
          latitude => "51.759", longitude => "-1.270" },
        1 
    );
    $wiki->moderate_node("Cafe Roma", 1);

    my %node = $wiki->retrieve_node( "Cafe Roma" );
    $wiki->write_node( "Cafe Roma", "A cafe unmod", $node{"checksum"},
        { category => [ "Cafe", "Oxford", "Unmoderated", "NotSeen" ],
          latitude => "51.759", longitude => "-1.270",
          locale => [ "Oxford" ] },
    );


    my @md;


    # With nothing, get back undef
    is($wiki->store->list_metadata_by_type(), undef, "Needs a type given");


    # Postcode should be easy
    @md = $wiki->store->list_metadata_by_type("postcode");
    is_deeply( [sort @md], [ "OX1 2AY", "W6 9PL" ], 
       "Correct metadata listing" );


    # Latitude also
    @md = $wiki->store->list_metadata_by_type("latitude");
    is_deeply( [sort @md], [ "51.759", "51.911" ],
       "Correct metadata listing" );


    # For category, will not see unmoderated versio
    @md = $wiki->store->list_metadata_by_type("category");
    is_deeply( [sort @md], [ "Burgers", "Cafe", "Hammersmith",
                           "Oxford", "Restaurant", "Thai Food" ],
       "Correct metadata listing" );

    @md = $wiki->store->list_metadata_names();
    is_deeply( [sort @md], [ "category", "latitude", "longitude", "postcode" ],
       "Correct metadata names" );


    # Now moderate that one, see it come in
    $wiki->moderate_node("Cafe Roma", 2);
    @md = $wiki->store->list_metadata_by_type("category");
    is_deeply( [sort @md], [ "Burgers", "Cafe", "Hammersmith", "NotSeen",
                           "Oxford", "Restaurant", "Thai Food", "Unmoderated" ],
       "Correct metadata listing" );

    @md = $wiki->store->list_metadata_names();
    is_deeply( [sort @md], [ "category", "latitude", "locale",
                             "longitude", "postcode" ],
       "Correct metadata names" );


    # And un-moderate another, see it go away
    $wiki->store->dbh->do("UPDATE content SET moderated = '0' WHERE version = 2");
    @md = $wiki->store->list_metadata_by_type("category");
    is_deeply( [sort @md], [ "Burgers", "Cafe", "Hammersmith",
                           "Oxford", "Restaurant", "Thai Food" ],
       "Correct metadata listing" );

    @md = $wiki->store->list_metadata_names();
    is_deeply( [sort @md], [ "category", "latitude", "longitude", "postcode" ],
       "Correct metadata names" );
}


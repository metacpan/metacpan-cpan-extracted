use strict;
use Wiki::Toolkit::TestLib;
use Test::More;

if ( scalar @Wiki::Toolkit::TestLib::wiki_info == 0 ) {
    plan skip_all => "no backends configured";
} else {
    plan tests => ( 22 * scalar @Wiki::Toolkit::TestLib::wiki_info );
}

my $iterator = Wiki::Toolkit::TestLib->new_wiki_maker;

while ( my $wiki = $iterator->new_wiki ) {
    # Put some test data in.
    $wiki->write_node( "Reun Thai", "A restaurant", undef,
        { postcode => "W6 9PL",
          category => [ "Thai Food", "Restaurant", "Hammersmith" ],
          latitude => "51.911", longitude => "" } );
    my %node = $wiki->retrieve_node( "Reun Thai" );
    my $data = $node{metadata}{postcode};
    is( ref $data, "ARRAY", "arrayref always returned" );
    is( $node{metadata}{postcode}[0], "W6 9PL",
        "...simple metadata retrieved" );
    my $cats = $node{metadata}{category};
    is_deeply( [ sort @{$cats||[]} ],
               [ "Hammersmith", "Restaurant", "Thai Food" ],
               "...more complex metadata too" );

    # Test list_nodes_by_metadata.
    $wiki->write_node( "The Old Trout", "A pub", undef,
        { category => [ "Pub", "Hammersmith" ] } );
    my @nodes = $wiki->list_nodes_by_metadata(
        metadata_type  => "category",
        metadata_value => "Hammersmith" );
    is_deeply( [ sort @nodes ], [ "Reun Thai", "The Old Trout" ],
               "list_nodes_by_metadata returns everything it should" );
    $wiki->write_node( "The Three Cups", "Another pub", undef,
                       { category => "Pub" } );
    @nodes = $wiki->list_nodes_by_metadata( metadata_type  => "category",
                                metadata_value => "Pub" );
    is_deeply( [ sort @nodes ], [ "The Old Trout", "The Three Cups" ],
               "...and not things it shouldn't" );

    # Case insensitivity option.
    @nodes = $wiki->list_nodes_by_metadata(
        metadata_type  => "category",
        metadata_value => "hammersmith",
        ignore_case    => 0,
    );
    is_deeply( [ sort @nodes ], [ ],
               "ignore_case => 0 doesn't ignore case of metadata_value" );
    @nodes = $wiki->list_nodes_by_metadata(
        metadata_type  => "category",
        metadata_value => "hammersmith",
        ignore_case    => 1,
    );
    is_deeply( [ sort @nodes ], [ "Reun Thai", "The Old Trout" ],
               "ignore_case => 1 ignores case of metadata_value" );
    @nodes = $wiki->list_nodes_by_metadata(
        metadata_type  => "Category",
        metadata_value => "Hammersmith",
        ignore_case    => 1,
    );
    is_deeply( [ sort @nodes ], [ "Reun Thai", "The Old Trout" ],
               "...and case of metadata_type" );


    # Test list_nodes_by_missing_metadata
    #  Shouldn't get any if we search on category
    @nodes = $wiki->list_nodes_by_missing_metadata(
                            metadata_type => "category"
    );
    is( scalar @nodes, 0, "All have metadata category" );
    #  By latitude, should only get The Old Trout+The Three Cups
    @nodes = $wiki->list_nodes_by_missing_metadata(
                            metadata_type => "latitude"
    );
    is_deeply( [ sort @nodes ], [ "The Old Trout", "The Three Cups" ], 
                    "By lat, not Reun Thai" );
    #  By longitude, we should get all (Reun Thai has it blank)
    @nodes = $wiki->list_nodes_by_missing_metadata(
                            metadata_type => "longitude"
    );
    is_deeply( [ sort @nodes ], [ "Reun Thai", "The Old Trout", "The Three Cups" ], "By long, get all" );
    #  With category=Pub, we should get only the Reun Thai
    @nodes = $wiki->list_nodes_by_missing_metadata(
                            metadata_type => "category",
                            metadata_value => "Pub"
    );
    is_deeply( [ sort @nodes ], [ "Reun Thai" ], "Reun Thai not a pub" );
    #  With Category, we should get all
    @nodes = $wiki->list_nodes_by_missing_metadata(
                            metadata_type => "Category"
    );
    is_deeply( [ sort @nodes ], [ "Reun Thai", "The Old Trout", "The Three Cups" ], "By Category, get all" );
    #  With category=hammersmith, we should get all
    @nodes = $wiki->list_nodes_by_missing_metadata(
                            metadata_type => "category",
                            metadata_value => "hammersmith"
    );
    is_deeply( [ sort @nodes ], [ "Reun Thai", "The Old Trout", "The Three Cups" ], "By category=hammersmith (case sensitive), get all" );
    #  But with category=hammersmith+case insensitive, shouldn't get any
    @nodes = $wiki->list_nodes_by_missing_metadata(
                            metadata_type => "category",
                            metadata_value => "hammersmith",
                            ignore_case => 1
    );
    is_deeply( [ sort @nodes ], [ "The Three Cups" ], "By category=hammersmith (ci), get all but the three cups" );


    %node = $wiki->retrieve_node("The Three Cups");
    $wiki->write_node( "The Three Cups", "Not a pub any more",
                       $node{checksum} );
    @nodes = $wiki->list_nodes_by_metadata( metadata_type  => "category",
                                metadata_value => "Pub" );
    is_deeply( [ sort @nodes ], [ "The Old Trout" ],
       "removing metadata from a node stops it showing up in list_nodes_by_metadata" );

    my $dbh = eval { $wiki->store->dbh; };
    my $id_sql = "SELECT id FROM node WHERE name='Reun Thai'";
    my $id = @{ $dbh->selectcol_arrayref($id_sql) }[0];
    $wiki->delete_node("Reun Thai");
    @nodes = $wiki->list_nodes_by_metadata( metadata_type  => "category",
                                metadata_value => "Hammersmith" );
    is_deeply( [ sort @nodes ], [ "The Old Trout" ],
               "...as does deleting a node" );


    # Check that deleting a node really does clear out the metadata.
    SKIP: {
        skip "Test only works on database backends", 1 unless $dbh;
        # White box testing.
        my $sql = "SELECT metadata_type, metadata_value FROM metadata
                   WHERE node_id = $id";
        my $sth = $dbh->prepare($sql);
        $sth->execute;
        my ( $type, $value ) = $sth->fetchrow_array;
        is_deeply( [ $type, $value ], [undef, undef],
                   "deletion of a node removes metadata from database" );
    }

    # Test checksumming.
    %node = $wiki->retrieve_node("The Three Cups");
    ok( $wiki->write_node( "The Three Cups", "Not a pub any more",
                       $node{checksum}, { newdata => "foo" } ),
        "writing node with metadata succeeds when checksum fresh" );
    ok( !$wiki->write_node( "The Three Cups", "Not a pub any more",
                       $node{checksum}, { newdata => "bar" } ),
        "writing node with identical content but different metadata fails when checksum not updated" );

    # Test with duplicate metadata.
    $wiki->write_node( "Dupe Test", "test", undef,
                       { foo => [ "bar", "bar" ] } );
    %node = $wiki->retrieve_node( "Dupe Test" );
    is( scalar @{$node{metadata}{foo}}, 1,
        "duplicate metadata only written once" );

    # Test version is updated when metadata is removed.
    $wiki->write_node( "Dupe Test", "test", $node{checksum} );
    %node = $wiki->retrieve_node( "Dupe Test" );
    is( $node{version}, 2, "version updated when metadata removed" );
}


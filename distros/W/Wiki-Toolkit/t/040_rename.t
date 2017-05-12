use strict;
use Wiki::Toolkit::TestLib;
use Test::More;
use Time::Piece;

if ( scalar @Wiki::Toolkit::TestLib::wiki_info == 0 ) {
    plan skip_all => "no backends configured";
} else {
    plan tests => ( 39 * scalar @Wiki::Toolkit::TestLib::wiki_info );
}

my $iterator = Wiki::Toolkit::TestLib->new_wiki_maker;

while ( my $wiki = $iterator->new_wiki ) {
    my %non_existent_node = ( content => "", version => 0, last_modified => "",
       checksum => "d41d8cd98f00b204e9800998ecf8427e", moderated => undef,
       node_requires_moderation => undef, metadata => {} );

    # Ensure our formatter supports renaming
    ok( $wiki->{_formatter}->can("rename_links"),
        "The formatter must be able to rename links for these tests to work" );

    # Add three pages, which all link to each other, where there
    # are multiple versions of two of the three

    $wiki->write_node( "NodeOne", "This is the first node, which links to "
            . "NodeTwo, NodeThree, [NodeTwo] and [NodeThree | Node Three]." )
        or die "Couldn't write node";
    my %nodeone1 = $wiki->retrieve_node("NodeOne");
    $wiki->write_node( "NodeOne", "This is the second version of the first "
            . "node, which links to NodeTwo, NodeThree, [NodeTwo], "
            . "[NodeFour|Node Four] and [NodeThree | Node Three].",
            $nodeone1{checksum} )
        or die "Couldn't write node";
    my %nodeone2 = $wiki->retrieve_node("NodeOne");

    $wiki->write_node( "NodeTwo", "This is the second node, which links to "
            . "just NodeOne [NodeOne | twice].")
        or die "Couldn't write node";
    my %nodetwo1 = $wiki->retrieve_node("NodeTwo");
    $wiki->write_node( "NodeTwo", "This is the second version of the second "
            . "node, which links to [NodeTwo|itself] and NodeOne",
            $nodetwo1{checksum} )
        or die "Couldn't write node";
    my %nodetwo2 = $wiki->retrieve_node("NodeTwo");

    $wiki->write_node( "NodeThree", "This is the third node, which links to "
            . "all 3 via NodeOne, NodeTwo and [NodeThree]")
        or die "Couldn't write node";
    my %nodethree1 = $wiki->retrieve_node("NodeThree");

    # Rename NodeOne to NodeFoo, without new versions
    # (Don't pass in the key names)
    ok( $wiki->rename_node("NodeOne", "NodeFoo"), "Rename node");

    # Should be able to find it as NodeFoo, but not NodeOne
    my %asnode1 = $wiki->retrieve_node("NodeOne");
    my %asnodef = $wiki->retrieve_node("NodeFoo");
    $nodeone2{checksum} = $asnodef{checksum};

    is_deeply( \%asnode1, \%non_existent_node, "Renamed to NodeFoo" );
    is_deeply( \%asnodef, \%nodeone2, "Renamed to NodeFoo" );
    is( "This is the second version of the first node, which links to "
        . "NodeTwo, NodeThree, [NodeTwo], [NodeFour|Node Four] and "
        . "[NodeThree | Node Three].",
        $asnodef{"content"}, "no change needed to node" );

    # Check that the other pages were updated as required
    # NodeTwo linked implicitly
    my %anode2 = $wiki->retrieve_node("NodeTwo");
    is( "This is the second version of the second node, which links to "
        . "[NodeTwo|itself] and NodeFoo",
        $anode2{'content'}, "implicit link was updated" );
    is( 2, $anode2{'version'}, "no new version" );
    # NodeThree linked implicitly
    my %anode3 = $wiki->retrieve_node("NodeThree");
    is( "This is the third node, which links to all 3 via NodeFoo, NodeTwo "
        . "and [NodeThree]", $anode3{'content'}, "implicit link was updated" );
    is( 1, $anode3{'version'}, "no new version" );

    # Rename it back to NodeOne
    # (Pass in the key names)
    ok( $wiki->rename_node( new_name => "NodeOne", old_name => "NodeFoo" ),
        "Rename node");

    # Should be able to find it as NodeOne again, but not NodeFoo
    %asnode1 = $wiki->retrieve_node("NodeOne");
    %asnodef = $wiki->retrieve_node("NodeFoo");
    $nodeone2{checksum} = $asnode1{checksum};

    is_deeply( \%asnodef, \%non_existent_node, "Renamed to NodeOne" );
    is_deeply( \%asnode1, \%nodeone2, "Renamed to NodeFoo" );
    is( "This is the second version of the first node, which links to "
        . "NodeTwo, NodeThree, [NodeTwo], [NodeFour|Node Four] and "
        . "[NodeThree | Node Three].",
        $asnode1{"content"}, "no change needed to node" );

    # Now check two and three changed back
    %anode2 = $wiki->retrieve_node("NodeTwo");
    is( "This is the second version of the second node, which links to "
        . "[NodeTwo|itself] and NodeOne", $anode2{'content'},
        "implicit link was updated" );
    is( 2, $anode2{'version'}, "no new version" );
    %anode3 = $wiki->retrieve_node("NodeThree");
    is( "This is the third node, which links to all 3 via NodeOne, NodeTwo "
        . "and [NodeThree]",
        $anode3{'content'}, "implicit link was updated" );
    is( 1, $anode3{'version'}, "no new version" );

    # Tweak the formatter - swap to extended links from implicit
    $wiki->{_formatter} = Wiki::Toolkit::Formatter::Default->new(
                              extended_links => 1, implicit_links => 0 );
    ok( $wiki->{_formatter}->can("rename_links"),
        "The formatter must be able to rename links for these tests to work" );

    # Rename NodeTwo to NodeFooBar
    ok( $wiki->rename_node( old_name => "NodeTwo", new_name => "NodeFooBar"),
        "Rename node" );

    # Check NodeTwo is now as expected
    my %asnode2 = $wiki->retrieve_node("NodeTwo");
    %asnodef = $wiki->retrieve_node("NodeFooBar");
    $nodetwo2{checksum} = $asnodef{checksum};
    $nodetwo2{content} = "This is the second version of the second node, "
            . "which links to [NodeFooBar|itself] and NodeOne";
    $nodetwo2{last_modified} = $asnodef{last_modified};

    is_deeply( \%asnode2, \%non_existent_node, "Renamed to NodeFooBar" );
    is_deeply( \%asnodef, \%nodetwo2, "Renamed to NodeFooBar" );
    is( $asnodef{"content"}, $nodetwo2{content}, "node was changed" );

    # Check the other two nodes
    my %anode1 = $wiki->retrieve_node("NodeOne");
    is( "This is the second version of the first node, which links to "
        . "NodeTwo, NodeThree, [NodeFooBar], [NodeFour|Node Four] and "
        . "[NodeThree | Node Three].", $anode1{'content'},
        "explicit link was updated, implicit not" );
    is( 2, $anode1{'version'}, "no new version" );
    %anode3 = $wiki->retrieve_node("NodeThree");
    is( "This is the third node, which links to all 3 via NodeOne, NodeTwo "
        . "and [NodeThree]", $anode3{'content'},
        "no explicit to update, implicit link not" );
    is( 1, $anode3{'version'}, "no new version" );

    # Now rename back, but with the new version stuff
    # (Nodes 1 and 2 should get new versions, but not node 3)
    ok( $wiki->rename_node( new_name=>"NodeTwo", old_name=>"NodeFooBar",
                            create_new_versions => 1), "Rename node" );
    %asnode2 = $wiki->retrieve_node("NodeTwo");
    %asnodef = $wiki->retrieve_node("NodeFooBar");
    $nodetwo2{checksum} = $asnode2{checksum};
    $nodetwo2{content} = "This is the second version of the second node, "
                         . "which links to [NodeTwo|itself] and NodeOne";
    $nodetwo2{version} = 3;
    $nodetwo2{last_modified} = $asnode2{last_modified};

    is_deeply( \%asnodef, \%non_existent_node, "Renamed back to NodeTwo" );
    is_deeply( \%asnode2, \%nodetwo2, "Renamed back to NodeTwo" );
    is( $asnode2{"content"}, $nodetwo2{content}, "node was changed" );
    is( $asnode2{"version"}, 3, "new node version" );

    # Check the other two nodes
    %anode1 = $wiki->retrieve_node("NodeOne");
    is( "This is the second version of the first node, which links to "
        . "NodeTwo, NodeThree, [NodeTwo], [NodeFour|Node Four] and "
        . "[NodeThree | Node Three].",
        $anode1{'content'}, "explicit link was updated, implicit not" );
    is( 3, $anode1{'version'}, "new version" );
    %anode3 = $wiki->retrieve_node("NodeThree");
    is( "This is the third node, which links to all 3 via NodeOne, NodeTwo "
        . "and [NodeThree]", $anode3{'content'},
        "no explicit to update, implicit link not" );
    is( 1, $anode3{'version'}, "no new version" );

    # Ensure force_ucfirst_nodes is respected if and only if it's switched on.
    # Note that this isn't the same as the perl function ucfirst, which only
    # uppercases the first character of a string - it uppercases the first
    # character of each word.
    eval { require Wiki::Toolkit::Formatter::UseMod; };
    SKIP: {
        skip "Wiki::Toolkit::Formatter::UseMod not available", 4 if $@;

        # First check with it on.
        $wiki->{_formatter} = Wiki::Toolkit::Formatter::UseMod->new(
            force_ucfirst_nodes => 1,
            munge_urls => 1,
        );
        $wiki->write_node( "Test Node", "A test node" )
            or die "Couldn't write Test Node";
        # "testing node" should be forced to "Testing Node"
        $wiki->rename_node( "Test Node", "testing node" );
        ok( $wiki->retrieve_node( "Testing Node" ),
            "New name for renamed node is forced ucfirst if we want it to be");
        ok( !$wiki->retrieve_node( "testing node" ),
            "... and the non-ucfirst name is not found" );

        # And now check with it off.
        $wiki->{_formatter} = Wiki::Toolkit::Formatter::UseMod->new(
            force_ucfirst_nodes => 0,
            munge_urls => 1,
        );
        $wiki->write_node( "Test Node Two", "Another test node" )
            or die "Couldn't write Test Node Two";
        $wiki->rename_node( "Test Node Two", "testing node two" );
        ok( !$wiki->retrieve_node( "Testing Node Two" ),
            "New name for renamed node isn't forced ucfirst if we don't "
            . "want it to be" );
        ok( $wiki->retrieve_node( "testing node two" ),
            "... and the non-ucfirst name is found instead" );
    }
}

use strict;
use Wiki::Toolkit::TestLib;
use Test::More;
use Time::Piece;

if ( scalar @Wiki::Toolkit::TestLib::wiki_info == 0 ) {
    plan skip_all => "no backends configured";
} else {
    plan tests => ( 89 * scalar @Wiki::Toolkit::TestLib::wiki_info );
}

my $iterator = Wiki::Toolkit::TestLib->new_wiki_maker;

while ( my $wiki = $iterator->new_wiki ) {
    # Put some test data in.
    $wiki->write_node( "Home", "This is the home node." )
      or die "Couldn't write node";

	# Now add another version
    my %node_data = $wiki->retrieve_node("Home");

    ok( $wiki->write_node("Home", "xx", $node_data{checksum}),
        "write_node succeeds when node matches checksum" );

	# Fetch it with and without specifying a version
    my %new_node_data = $wiki->retrieve_node("Home");
    my %new_node_data_v = $wiki->retrieve_node(name=>"Home", version=>$new_node_data{version});
    print "# version now: [$new_node_data{version}]\n";
    is( $new_node_data{version}, $node_data{version} + 1,
        "...and the version number is updated on successful writing" );
    is( $new_node_data{version}, $new_node_data_v{version},
        "...and the version number is updated on successful writing" );

	# Ensure that the moderation required flag isn't set on the node
	is( $node_data{node_requires_moderation}, '0', "New node correctly doesn't require moderation" );
	is( $new_node_data{node_requires_moderation}, '0', "Nor does it require moderation after being updated" );
	is( $new_node_data_v{node_requires_moderation}, '0', "Nor does it require moderation after being updated via version" );


	# Ensure the moderated flag is set on the two entries in content
	is( $node_data{moderated}, '1', "No moderation required, so is moderated" );
	is( $new_node_data{moderated}, '1', "No moderation required, so is moderated" );
	is( $new_node_data_v{moderated}, '1', "No moderation required, so is moderated" );


	# Now add a new node requiring moderation
    $wiki->write_node( "Moderation", "This is the moderated node.", undef, undef, 1);
    my %mn_data = $wiki->retrieve_node("Moderation");
	is( $mn_data{moderated}, '0', "First version shouldn't be moderated" );
	is( $mn_data{node_requires_moderation}, '1', "New node needs moderation" );

	# Shouldn't have the text if fetched without the version
	is( $mn_data{content}, "=== This page has yet to be moderated. ===", "First version isn't moderated" );

	# If we fetch with a version, we should get the text
    my %mnv_data = $wiki->retrieve_node(name=>"Moderation", version=>1);
	is( $mnv_data{content}, "This is the moderated node.", "Should get text if a version is given" );

	is( $mnv_data{moderated}, '0', "First version shouldn't be moderated" );
	is( $mnv_data{node_requires_moderation}, '1', "New node needs moderation" );


	# Update it
    my $nmn_ver = $wiki->write_node("Moderation", "yy", $mn_data{checksum});
    ok( $nmn_ver, "Can update where moderation is enabled" );
    my %nmn_data = $wiki->retrieve_node("Moderation");
    my %nmnv_data = $wiki->retrieve_node(name=>"Moderation", version=>2);
    is( $nmn_data{version}, '1', "Latest moderated version" );
    is( $nmnv_data{version}, '2', "Latest unmoderated version" );
    is( $nmn_ver, '2', "Latest (unmoderated) version returned by write_node" );

	# Check content was updated right
	is( $nmnv_data{content}, "yy", "Version 2 text");

	# Should still be the same as before (unmoderated v1)
	is_deeply(\%mn_data,\%nmn_data, "Should still be the unmod first ver");
	is( $nmn_data{content}, "=== This page has yet to be moderated. ===", "No version is moderated" );

	# Check node requires it still
	is( $nmnv_data{node_requires_moderation}, '1', "New node needs moderation" );

	# Check content not moderated
	is( $nmnv_data{moderated}, '0', "Second version shouldn't be moderated" );


	# Add the third entry
    ok( $wiki->write_node("Moderation", "foo foo", $nmn_data{checksum}),
		"Can update where moderation is enabled" );
    my %mn3_data = $wiki->retrieve_node("Moderation");
	is( $mn3_data{node_requires_moderation}, '1', "New node needs moderation" );
	is( $mn3_data{moderated}, '0', "Third version shouldn't be moderated" );
	is( $mn3_data{content}, "=== This page has yet to be moderated. ===", "No version is moderated" );


	# Moderate the second entry
	ok( $wiki->moderate_node("Moderation", 2), "Can't moderate 2nd version" );
	%node_data = $wiki->retrieve_node(name=>"Moderation");
	my %mmn2 = $wiki->retrieve_node(name=>"Moderation",version=>2);

	# Node should now hold 2nd version 
	is( $mmn2{moderated}, '1', "Second version should now be moderated" );
	is( $mmn2{node_requires_moderation}, '1', "Still requires moderation" );
	is( $node_data{moderated}, '1', "Current version should now be moderated" );
	is( $node_data{node_requires_moderation}, '1', "Still requires moderation" );
	is( $node_data{content}, "yy", "Node should be second version" );
	is( $node_data{version}, "2", "Node should be second version" );


	# Moderate the first entry
	ok( $wiki->moderate_node(name=>"Moderation", version=>1), "Can't moderate 1st version" );
	%node_data = $wiki->retrieve_node(name=>"Moderation");
	my %mmn1 = $wiki->retrieve_node(name=>"Moderation",version=>1);

	# First entry should now be moderated, but node should not be changed
	is( $mmn1{moderated}, '1', "First version should now be moderated" );
	is( $mmn1{node_requires_moderation}, '1', "Still requires moderation" );
	is( $node_data{moderated}, '1', "Current version should still be moderated" );
	is( $node_data{node_requires_moderation}, '1', "Still requires moderation" );
	is( $node_data{content}, "yy", "Node should still be second version" );
	is( $node_data{version}, "2", "Node should still be second version" );


	# Moderate the third entry
	ok( $wiki->moderate_node(name=>"Moderation", version=>3), "Can't moderate 3rd version" );
	%node_data = $wiki->retrieve_node(name=>"Moderation");
	my %mmn3 = $wiki->retrieve_node(name=>"Moderation",version=>3);

	# Third entry should now be moderated, and node should have been changed
	is( $mmn3{moderated}, '1', "Third version should now be moderated" );
	is( $mmn3{node_requires_moderation}, '1', "Still requires moderation" );
	is( $node_data{moderated}, '1', "Current version should still be moderated" );
	is( $node_data{node_requires_moderation}, '1', "Still requires moderation" );
	is( $node_data{content}, "foo foo", "Node should be third version" );
	is( $node_data{version}, "3", "Node should be third version" );


	# Add a 4th entry
    ok( $wiki->write_node("Moderation", "bar bar", $node_data{checksum}),
		"Can update where moderation is enabled" );
    %node_data = $wiki->retrieve_node("Moderation");
    my %mn4_data = $wiki->retrieve_node(name=>"Moderation", version=>4);

	# Node should still be third entry, with 4th needing moderation
	is( $node_data{moderated}, '1', "Current version should still be moderated" );
	is( $node_data{node_requires_moderation}, '1', "Still requires moderation" );
	is( $node_data{content}, "foo foo", "Node should still be third version" );
	is( $node_data{version}, "3", "Node should still be third version" );

	is( $mn4_data{moderated}, '0', "New version shouldn't be moderated" );
	is( $mn4_data{node_requires_moderation}, '1', "Still requires moderation" );
	is( $mn4_data{content}, "bar bar", "Content should have fourth version" );
	is( $mn4_data{version}, "4", "Content should have fourth version" );


	# Add the 5th entry, and moderate it
    ok( $wiki->write_node("Moderation", "I shall be deleted", $node_data{checksum}),
		"Can update where moderation is enabled" );
    %node_data = $wiki->retrieve_node("Moderation");

	# Moderate it
	ok( $wiki->moderate_node(name=>"Moderation", version=>5), "Can't moderate 5th version" );
    my %mn5_data = $wiki->retrieve_node(name=>"Moderation", version=>5);
	is( $mn5_data{moderated}, '1', "Current version should be moderated" );
	is( $mn5_data{node_requires_moderation}, '1', "Still requires moderation" );
	is( $mn5_data{content}, "I shall be deleted", "Node should be fifth version" );
	is( $mn5_data{version}, "5", "Node should be fifth version" );


	# Delete the 5th entry - should fall back to the 3rd
	is( 1, $wiki->delete_node(name=>"Moderation", version=>5), "Can't delete 5th version" );
    %node_data = $wiki->retrieve_node("Moderation");

	is( $node_data{moderated}, '1', "Current version should still be moderated" );
	is( $node_data{node_requires_moderation}, '1', "Still requires moderation" );
	is( $node_data{content}, "foo foo", "Node should now be third version" );
	is( $node_data{version}, "3", "Node should now be third version" );

	# Delete the 4th version, should remain the 3rd version


	# Now mark this node as not needing moderation, and add a new version
	is( 1, $wiki->set_node_moderation(name=>"Moderation", required=>0), "Can set as not needing moderation" );

    %node_data = $wiki->retrieve_node("Moderation");

	is( $node_data{moderated}, '1', "Current version should still be moderated" );
	is( $node_data{node_requires_moderation}, '0', "Doesn't requires moderation" );
	is( $node_data{content}, "foo foo", "Node should now be third version" );
	is( $node_data{version}, "3", "Node should now be third version" );

	# Check now not moderated
    ok( $wiki->write_node("Moderation", "No moderation", $node_data{checksum}),
		"Can update where moderation is disabled again" );
    my %mn5b_data = $wiki->retrieve_node(name=>"Moderation", version=>5);
    %node_data = $wiki->retrieve_node("Moderation");
	is_deeply( \%mn5b_data, \%node_data, "Version 5 (again) is the latest" );

	is( $node_data{moderated}, '1', "Current version should be moderated" );
	is( $node_data{node_requires_moderation}, '0', "Doesn't requires moderation" );
	is( $node_data{content}, "No moderation", "Node should now be fifth version" );
	is( $node_data{version}, "5", "Node should now be fifth version" );


	# Now turn moderation back on
	is( 1, $wiki->set_node_moderation(name=>"Moderation", required=>1), "Can set as needing moderation" );

    %node_data = $wiki->retrieve_node("Moderation");

	is( $node_data{moderated}, '1', "Current version should be moderated" );
	is( $node_data{node_requires_moderation}, '1', "Now requires moderation" );
	is( $node_data{content}, "No moderation", "Node should now be fifth version" );
	is( $node_data{version}, "5", "Node should now be fifth version" );


    # Test that the shorthand node_required_moderation behaves
    is( 0, $wiki->node_required_moderation("MADE_UP"), "node_required_moderation behaves");
    is( 0, $wiki->node_required_moderation("Home"), "node_required_moderation behaves");
    is( 1, $wiki->node_required_moderation("Moderation"), "node_required_moderation behaves");

	# Check that we get 0, not 1 back, when trying to set moderation
	#  on a node that doesn't exist
	is( 0, $wiki->set_node_moderation(name=>"NODE THAT DOES NOT EXIST", required=>1), "returns 0 if you set moderation on an unknown node" );
}

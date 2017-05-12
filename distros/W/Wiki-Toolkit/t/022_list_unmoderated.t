use strict;
use Wiki::Toolkit::TestLib;
use Test::More;
use Time::Piece;

if ( scalar @Wiki::Toolkit::TestLib::wiki_info == 0 ) {
    plan skip_all => "no backends configured";
} else {
    plan tests => ( 40 * scalar @Wiki::Toolkit::TestLib::wiki_info );
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

	# Now add a new node requiring moderation
    $wiki->write_node( "Moderation", "This is the moderated node.", undef, undef, 1);
    my %mn_data = $wiki->retrieve_node("Moderation");
	is( $mn_data{moderated}, '0', "First version shouldn't be moderated" );
	is( $mn_data{node_requires_moderation}, '1', "New node needs moderation" );

	# Update it
    ok( $wiki->write_node("Moderation", "yy", $mn_data{checksum}),
		"Can update where moderation is enabled" );

	# And another needing moderation
    $wiki->write_node( "Moderation2", "This is another moderated node.", undef, undef, 1);

	# And two versions of a third
    $wiki->write_node( "Moderation3", "3 This is another moderated node.", undef, undef, 1);
    my %mn3_data = $wiki->retrieve_node("Moderation3");
    ok( $wiki->write_node("Moderation3", "3yy3", $mn3_data{checksum}),
		"Can update where moderation is enabled" );



	# Now look for all nodes needing moderation
	my @all_mod_nodes = $wiki->list_unmoderated_nodes();
	my @new_mod_nodes = $wiki->list_unmoderated_nodes(only_where_latest=>1);

	# All should have nodes 2 (2 vers), 3 and 4 (2 vers)
	is( scalar @all_mod_nodes, 5, "Should find 5 needing moderation");

	# New should have nodes 2, 3 and 4
	is( scalar @new_mod_nodes, 3, "Should find 3 needing moderation");

	# Check we did get the right data back
	my %m21 = (name=>'Moderation', node_id=>2, version=>1, moderated_version=>1);
	my %m22 = (name=>'Moderation', node_id=>2, version=>2, moderated_version=>1);
	my %m31 = (name=>'Moderation2', node_id=>3, version=>1, moderated_version=>1);
	my %m41 = (name=>'Moderation3', node_id=>4, version=>1, moderated_version=>1);
	my %m42 = (name=>'Moderation3', node_id=>4, version=>2, moderated_version=>1);

	is_deeply( $all_mod_nodes[0], \%m21, "Should have right data" );
	is_deeply( $all_mod_nodes[1], \%m22, "Should have right data" );
	is_deeply( $all_mod_nodes[2], \%m31, "Should have right data" );
	is_deeply( $all_mod_nodes[3], \%m41, "Should have right data" );
	is_deeply( $all_mod_nodes[4], \%m42, "Should have right data" );

	is_deeply( $new_mod_nodes[0], \%m21, "Should have right data" );
	is_deeply( $new_mod_nodes[1], \%m31, "Should have right data" );
	is_deeply( $new_mod_nodes[2], \%m41, "Should have right data" );


	# Mark the last (only) version Moderation2 as moderated
	ok( $wiki->moderate_node("Moderation2", 1), "Can't moderate 1st version" );

	# Check counts now
	@all_mod_nodes = $wiki->list_unmoderated_nodes();
	@new_mod_nodes = $wiki->list_unmoderated_nodes(only_where_latest=>1);

	is( scalar @all_mod_nodes, 4, "Should find 4 needing moderation");
	is( scalar @new_mod_nodes, 2, "Should find 2 needing moderation");

	# Check data now
	is_deeply( $all_mod_nodes[0], \%m21, "Should have right data" );
	is_deeply( $all_mod_nodes[1], \%m22, "Should have right data" );
	is_deeply( $all_mod_nodes[2], \%m41, "Should have right data" );
	is_deeply( $all_mod_nodes[3], \%m42, "Should have right data" );

	is_deeply( $new_mod_nodes[0], \%m21, "Should have right data" );
	is_deeply( $new_mod_nodes[1], \%m41, "Should have right data" );


	# Mark the last version Moderation3 as moderated
	ok( $wiki->moderate_node("Moderation3", 2), "Can't moderate 2nd version" );
	
	# Check counts now
	@all_mod_nodes = $wiki->list_unmoderated_nodes();
	@new_mod_nodes = $wiki->list_unmoderated_nodes(only_where_latest=>1);

	is( scalar @all_mod_nodes, 3, "Should find 3 needing moderation");
	is( scalar @new_mod_nodes, 1, "Should find 1 needing moderation");

	# Check data now
	$m41{'moderated_version'} = 2; # Moderated version now shows 2
	is_deeply( $all_mod_nodes[0], \%m21, "Should have right data" );
	is_deeply( $all_mod_nodes[1], \%m22, "Should have right data" );
	is_deeply( $all_mod_nodes[2], \%m41, "Should have right data" );

	is_deeply( $new_mod_nodes[0], \%m21, "Should have right data" );
	
        # Check that we can make ->list_recent_changes show us only things
        # that have been moderated.
	my @rc_mod_nodes = $wiki->list_recent_changes( days => 7,
                                                 moderation => 1);

        # Sort them by name, since otherwise we get spurious test failures
        # if the initial node-writing takes more than a second.
        @rc_mod_nodes = sort { $a->{name} cmp $b->{name} } @rc_mod_nodes;

	is( scalar(@rc_mod_nodes), 4, "Count of recent changes nodes");
	is( $rc_mod_nodes[0]{name}, 'Home', "RC node 0 name" );
	is( $rc_mod_nodes[0]{version}, 2, "RC node 0 version" );
	is( $rc_mod_nodes[1]{name}, 'Moderation', "RC node 1 name" );
	is( $rc_mod_nodes[1]{version}, 1, "RC node 1 version" );
	is( $rc_mod_nodes[2]{name}, 'Moderation2', "RC node 2 name" );
	is( $rc_mod_nodes[2]{version}, 1, "RC node 2 version" );
	is( $rc_mod_nodes[3]{name}, 'Moderation3', "RC node 3 name" );
	is( $rc_mod_nodes[3]{version}, 2, "RC node 3 version" );
}


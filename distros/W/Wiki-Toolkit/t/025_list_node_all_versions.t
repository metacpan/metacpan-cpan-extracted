use strict;
use Wiki::Toolkit::TestLib;
use Test::More;

if ( scalar @Wiki::Toolkit::TestLib::wiki_info == 0 ) {
    plan skip_all => "no backends configured";
} else {
    plan tests => ( 59 * scalar @Wiki::Toolkit::TestLib::wiki_info );
}

my $iterator = Wiki::Toolkit::TestLib->new_wiki_maker;

while ( my $wiki = $iterator->new_wiki ) {
	# Add three base nodes
    foreach my $name ( qw( Carrots Handbags Cheese ) ) {
        $wiki->write_node( $name, "content" ) or die "Can't write node";
    }

	# Add three more versions of Cheese
	my %node = $wiki->retrieve_node("Cheese");
	$wiki->write_node("Cheese", "Content v2", $node{checksum}, { "foo" => "bar" } ) or die "Can't write node";

	%node = $wiki->retrieve_node("Cheese");
	$wiki->write_node("Cheese", "Content v3", $node{checksum}, { "foo" => "bar", "bar" => "foo" } ) or die "Can't write node";

	%node = $wiki->retrieve_node("Cheese");
	$wiki->write_node("Cheese", "Content v4", $node{checksum} ) or die "Can't write node";


	# Fetch all the versions
	my @all_versions = $wiki->list_node_all_versions("Cheese");

	is( scalar @all_versions, 4, "list_node_all_versions gives the right number back" );

	# Check them
	is( $all_versions[0]->{'version'}, 4, "right ordering" );
	is( $all_versions[1]->{'version'}, 3, "right ordering" );
	is( $all_versions[2]->{'version'}, 2, "right ordering" );
	is( $all_versions[3]->{'version'}, 1, "right ordering" );
	is( $all_versions[0]->{'name'}, "Cheese", "right node" );
	is( $all_versions[1]->{'name'}, "Cheese", "right node" );
	is( $all_versions[2]->{'name'}, "Cheese", "right node" );
	is( $all_versions[3]->{'name'}, "Cheese", "right node" );


	# Fetch with content too
	@all_versions = $wiki->list_node_all_versions(
								name => "Cheese",
								with_content => 1
	);

	is( scalar @all_versions, 4, "list_node_all_versions gives the right number back" );

	# Check them
	is( $all_versions[0]->{'version'}, 4, "right ordering" );
	is( $all_versions[1]->{'version'}, 3, "right ordering" );
	is( $all_versions[2]->{'version'}, 2, "right ordering" );
	is( $all_versions[3]->{'version'}, 1, "right ordering" );
	is( $all_versions[0]->{'name'}, "Cheese", "right node" );
	is( $all_versions[1]->{'name'}, "Cheese", "right node" );
	is( $all_versions[2]->{'name'}, "Cheese", "right node" );
	is( $all_versions[3]->{'name'}, "Cheese", "right node" );
	is( $all_versions[0]->{'content'}, "Content v4", "right node" );
	is( $all_versions[1]->{'content'}, "Content v3", "right node" );
	is( $all_versions[2]->{'content'}, "Content v2", "right node" );
	is( $all_versions[3]->{'content'}, "content", "right node" );


	# With metadata, but not content
	@all_versions = $wiki->list_node_all_versions(
								name => "Cheese",
								with_content => 0,
								with_metadata => 1
	);

	is( scalar @all_versions, 4, "list_node_all_versions gives the right number back" );

	# Check them
	is( $all_versions[0]->{'version'}, 4, "right ordering" );
	is( $all_versions[1]->{'version'}, 3, "right ordering" );
	is( $all_versions[2]->{'version'}, 2, "right ordering" );
	is( $all_versions[3]->{'version'}, 1, "right ordering" );
	is( $all_versions[0]->{'name'}, "Cheese", "right node" );
	is( $all_versions[1]->{'name'}, "Cheese", "right node" );
	is( $all_versions[2]->{'name'}, "Cheese", "right node" );
	is( $all_versions[3]->{'name'}, "Cheese", "right node" );
	is( $all_versions[0]->{'content'}, undef, "right node" );
	is( $all_versions[1]->{'content'}, undef, "right node" );
	is( $all_versions[2]->{'content'}, undef, "right node" );
	is( $all_versions[3]->{'content'}, undef, "right node" );

	my %md_1 = ();
	my %md_2 = (foo=>'bar');
	my %md_3 = (foo=>'bar',bar=>'foo');
	my %md_4 = ();

	is_deeply( $all_versions[0]->{'metadata'}, \%md_4, "right metadata" );
	is_deeply( $all_versions[1]->{'metadata'}, \%md_3, "right metadata" );
	is_deeply( $all_versions[2]->{'metadata'}, \%md_2, "right metadata" );
	is_deeply( $all_versions[3]->{'metadata'}, \%md_1, "right metadata" );


	# With both
	@all_versions = $wiki->list_node_all_versions(
								name => "Cheese",
								with_content => 1,
								with_metadata => 1
	);

	is( scalar @all_versions, 4, "list_node_all_versions gives the right number back" );

	# Check them
	is( $all_versions[0]->{'version'}, 4, "right ordering" );
	is( $all_versions[1]->{'version'}, 3, "right ordering" );
	is( $all_versions[2]->{'version'}, 2, "right ordering" );
	is( $all_versions[3]->{'version'}, 1, "right ordering" );
	is( $all_versions[0]->{'name'}, "Cheese", "right node" );
	is( $all_versions[1]->{'name'}, "Cheese", "right node" );
	is( $all_versions[2]->{'name'}, "Cheese", "right node" );
	is( $all_versions[3]->{'name'}, "Cheese", "right node" );
	is( $all_versions[0]->{'content'}, "Content v4", "right node" );
	is( $all_versions[1]->{'content'}, "Content v3", "right node" );
	is( $all_versions[2]->{'content'}, "Content v2", "right node" );
	is( $all_versions[3]->{'content'}, "content", "right node" );

	is_deeply( $all_versions[0]->{'metadata'}, \%md_4, "right metadata" );
	is_deeply( $all_versions[1]->{'metadata'}, \%md_3, "right metadata" );
	is_deeply( $all_versions[2]->{'metadata'}, \%md_2, "right metadata" );
	is_deeply( $all_versions[3]->{'metadata'}, \%md_1, "right metadata" );


	# Finally, check that we still only have 1 version of the carrots node
	my @carrots_versions = $wiki->list_node_all_versions(
								name => "Carrots",
								with_content => 1,
								with_metadata => 1
	);

	is( scalar @carrots_versions, 1, "list_node_all_versions gives the right number back" );

	is( $carrots_versions[0]->{'version'}, 1, "right ordering" );
	is( $carrots_versions[0]->{'name'}, "Carrots", "right node" );
}


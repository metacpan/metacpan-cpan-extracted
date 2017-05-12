use strict;
use Wiki::Toolkit::TestLib;
use Test::More;

if ( scalar @Wiki::Toolkit::TestLib::wiki_info == 0 ) {
    plan skip_all => "no backends configured";
} else {
    plan tests => ( 21 * scalar @Wiki::Toolkit::TestLib::wiki_info );
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

    # Nobble the dates on these
    $wiki->store->dbh->do("UPDATE content SET modified='2006-10-01' WHERE version = 1");
    $wiki->store->dbh->do("UPDATE content SET modified='2006-09-04' WHERE version = 1 and node_id = 2");
    $wiki->store->dbh->do("UPDATE content SET modified='2006-10-02' WHERE version = 2");
    $wiki->store->dbh->do("UPDATE content SET modified='2006-10-03' WHERE version = 3");
    $wiki->store->dbh->do("UPDATE content SET modified='2006-11-01' WHERE version = 4");


	# Fetch everything before 2007
    my @all = $wiki->list_last_version_before('2007-01-01');

	is( scalar @all, 3, "list_last_version_before gives the right number back" );

	# Check them
	is( $all[0]->{'version'}, 1, "right ordering" );
	is( $all[1]->{'version'}, 1, "right ordering" );
	is( $all[2]->{'version'}, 4, "right ordering" );
	is( $all[0]->{'name'}, 'Carrots', "right ordering" );
	is( $all[1]->{'name'}, 'Handbags', "right ordering" );
	is( $all[2]->{'name'}, 'Cheese', "right ordering" );

    # Now before 2006-10-02
    @all = $wiki->list_last_version_before('2006-10-02');

	is( scalar @all, 3, "list_last_version_before gives the right number back" );
	is( $all[0]->{'version'}, 1, "right ordering" );
	is( $all[1]->{'version'}, 1, "right ordering" );
	is( $all[2]->{'version'}, 2, "right ordering" );
	is( $all[0]->{'name'}, 'Carrots', "right ordering" );
	is( $all[1]->{'name'}, 'Handbags', "right ordering" );
	is( $all[2]->{'name'}, 'Cheese', "right ordering" );

    # Now before 2006-09-10
    @all = $wiki->store->list_last_version_before('2006-09-10');

	is( scalar @all, 3, "list_last_version_before gives the right number back" );
	is( $all[0]->{'version'}, undef, "right ordering" );
	is( $all[1]->{'version'}, 1, "right ordering" );
	is( $all[2]->{'version'}, undef, "right ordering" );
	is( $all[0]->{'name'}, 'Carrots', "right ordering" );
	is( $all[1]->{'name'}, 'Handbags', "right ordering" );
	is( $all[2]->{'name'}, 'Cheese', "right ordering" );
}


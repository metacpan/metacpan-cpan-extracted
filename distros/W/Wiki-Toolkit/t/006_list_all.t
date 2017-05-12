use strict;
use Wiki::Toolkit::TestLib;
use Test::More;

if ( scalar @Wiki::Toolkit::TestLib::wiki_info == 0 ) {
    plan skip_all => "no backends configured";
} else {
    plan tests => ( 6 * scalar @Wiki::Toolkit::TestLib::wiki_info );
}

my $iterator = Wiki::Toolkit::TestLib->new_wiki_maker;

while ( my $wiki = $iterator->new_wiki ) {
    foreach my $name ( qw( Carrots Handbags Cheese ) ) {
        $wiki->write_node( $name, "content" ) or die "Can't write node";
    }

    my @all_nodes = $wiki->list_all_nodes;
    is( scalar @all_nodes, 3,
    	"list_all_nodes returns the right number of nodes" );
    is_deeply( [sort @all_nodes], [ qw( Carrots Cheese Handbags ) ],
               "...and the right ones, too" );

    @all_nodes = $wiki->list_all_nodes(with_details=>1);
    is( scalar @all_nodes, 3,
    	"list_all_nodes returns the right number of nodes" );

	@all_nodes = sort { $a->{'name'} cmp $b->{'name'} } @all_nodes;
    is_deeply( $all_nodes[0], 
				{ name=>'Carrots',  version=>'1', node_id=>'1', moderate=>'0' },
			"...and the right ones, too" );
    is_deeply( $all_nodes[1], 
				{ name=>'Cheese',   version=>'1', node_id=>'3', moderate=>'0' },
			"...and the right ones, too" );
    is_deeply( $all_nodes[2], 
				{ name=>'Handbags', version=>'1', node_id=>'2', moderate=>'0' },
			"...and the right ones, too" );
}


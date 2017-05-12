use strict;
use Wiki::Toolkit::TestLib;
use Test::More;

if ( scalar @Wiki::Toolkit::TestLib::wiki_info == 0 ) {
    plan skip_all => "no backends configured";
} else {
    plan tests => ( 4 * scalar @Wiki::Toolkit::TestLib::wiki_info );
}

my $iterator = Wiki::Toolkit::TestLib->new_wiki_maker;

my $metadata_orig = { foo => [ 7 ], bar => [ 9 ] };
my $metadata_changed = { foo => [ "changed" ], bar => [ 9 ] };
my $content_orig = "Node content.";
my $content_changed = "Node content -- changed";
my $id = "A Node";

while ( my $wiki = $iterator->new_wiki ) {
    $wiki->write_node($id, $content_orig, undef, $metadata_orig );

    my %node_data = $wiki->retrieve_node($id);

    is( $wiki->write_node(
            $id, $content_orig, $node_data{checksum},
            $metadata_orig,
        ),
	-1,
	"refuses to update if new content and metadata is the same",
    );

    %node_data = $wiki->retrieve_node($id);

    ok( $wiki->write_node(
            $id, $content_orig, $node_data{checksum},
            $metadata_changed,
	) >= 1,
        "still updates if metadata is different",
    );
    
    %node_data = $wiki->retrieve_node($id);

    ok( $wiki->write_node(
            $id, $content_changed, $node_data{checksum},
	    $metadata_changed,
	) >= 1,
        "still updates if content is different",
    );

    %node_data = $wiki->retrieve_node($id);

    is( $wiki->write_node(
            $id, $content_changed, $node_data{checksum},
            $metadata_changed,
	),
	-1,
        "... and refuses again when nothing changed",
    );
}

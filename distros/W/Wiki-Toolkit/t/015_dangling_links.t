use strict;
use Wiki::Toolkit::TestLib;
use Test::More;

if ( scalar @Wiki::Toolkit::TestLib::wiki_info == 0 ) {
    plan skip_all => "no backends configured";
} else {
    plan tests => ( 3 * scalar @Wiki::Toolkit::TestLib::wiki_info );
}

my $iterator = Wiki::Toolkit::TestLib->new_wiki_maker;

while ( my $wiki = $iterator->new_wiki ) {
    # Put some test data in.
    $wiki->write_node( "NodeOne", "NonExistentNode" )
      or die "Couldn't write node";
    $wiki->write_node( "NodeTwo", "NodeOne" )
      or die "Couldn't write node";
    $wiki->write_node( "NodeThree", "NonExistentNode" )
      or die "Couldn't write node";

    my @links = $wiki->list_dangling_links;
    my %dangling;
    foreach my $link (@links) {
        $dangling{$link}++;
    }
    ok( $dangling{"NonExistentNode"},
        "dangling links returned by ->list_dangling_links" );
    ok( !$dangling{"NodeOne"}, "...but not existing ones" );
    is( $dangling{"NonExistentNode"}, 1,
        "...and each dangling link only returned once" );
}

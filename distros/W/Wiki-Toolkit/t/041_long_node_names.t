use strict;
use Wiki::Toolkit::TestLib;
use Test::More;

my $num_tests = 2;

if ( scalar @Wiki::Toolkit::TestLib::wiki_info == 0 ) {
    plan skip_all => "no backends configured";
} else {
    plan tests => ( $num_tests * scalar @Wiki::Toolkit::TestLib::wiki_info );
}

my $iterator = Wiki::Toolkit::TestLib->new_wiki_maker;

while ( my $wiki = $iterator->new_wiki ) {
    my $long_name = "Node With A Really Really Really Really Really Really Really Really Really Really Really Really Really Really Really Really Really Really Really Really Really Really Really Really Really V V Long Name";
    my $content = "That's a lot of reallys.";

    eval { $wiki->write_node( $long_name, $content ); };
    is( $@, "", "We can write nodes with 200-character names." );
    is( $wiki->retrieve_node( $long_name ), $content,
        "...and retrieve them." );
}

use Test::More tests => 2;

BEGIN {
use_ok( 'XML::OPML::SimpleGen' );
}

can_ok( 'XML::OPML::SimpleGen',
    qw( new
        id
        head
        group
        groups
        xml_options
        outline
        xml_head
        xml_outlines
        xml
        add_group
        insert_outline
        add_outline
        as_string
        save ) );

diag( "Testing XML::OPML::SimpleGen $XML::OPML::SimpleGen::VERSION, Perl $], $^X" );

#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Test::WWW::Mechanize::LibXML' );
}

diag( "Testing Test::WWW::Mechanize::LibXML $Test::WWW::Mechanize::LibXML::VERSION, Perl $], $^X" );

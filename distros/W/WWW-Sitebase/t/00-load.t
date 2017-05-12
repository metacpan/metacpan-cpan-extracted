#!perl -T

use Test::More tests => 3;

BEGIN {
    use_ok( 'WWW::Sitebase' );
    use_ok( 'WWW::Sitebase::Navigator' );
    use_ok( 'WWW::Sitebase::Poster' );
}

diag( "Testing WWW::Sitebase $WWW::Sitebase::VERSION, Perl $], $^X" );

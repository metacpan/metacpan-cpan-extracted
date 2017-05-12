#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'WWW::Yandex::Catalog::LookupSite' ) || print "Bail out!
";
}

diag( "Testing WWW::Yandex::Catalog::LookupSite $WWW::Yandex::Catalog::LookupSite::VERSION, Perl $], $^X" );

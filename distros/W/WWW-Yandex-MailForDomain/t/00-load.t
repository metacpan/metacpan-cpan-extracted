#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'WWW::Yandex::MailForDomain' ) || print "Bail out!";
}

diag( "Testing WWW::Yandex::MailForDomain $WWW::Yandex::MailForDomain::VERSION, Perl $], $^X" );

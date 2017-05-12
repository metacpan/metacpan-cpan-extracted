#!perl -T

use Test::More tests => 9;

BEGIN {
    use_ok( 'XAS::Service::Server' )             || print "Bail out!\n";
    use_ok( 'XAS::Service::Search' )             || print "Bail out!\n";
    use_ok( 'XAS::Service::Profiles' )           || print "Bail out!\n";
    use_ok( 'XAS::Service::Profiles::Search' )   || print "Bail out!\n";
    use_ok( 'XAS::Service::Resource' )           || print "Bail out!\n";
    use_ok( 'XAS::Service::CheckParameters' )    || print "Bail out!\n";
    use_ok( 'XAS::Docs::Service::Installation' ) || print "Bail out!\n";
    use_ok( 'XAS::Apps::Service::Testd' )        || print "Bail out!\n";
    use_ok( 'XAS::Service' )                     || print "Bail out!\n";
}

diag( "Testing XAS::Service $XAS::Service::VERSION, Perl $], $^X" );

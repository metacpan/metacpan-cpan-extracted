#!perl -T

use Test::More tests => 10;

BEGIN {

    use_ok( 'XAS::Apps::Logmon::Monitor' )      || print "Bail out!\n";
    use_ok( 'XAS::Apps::Logmon::XAS::Process' ) || print "Bail out!\n";
    use_ok( 'XAS::Lib::Regexp::Log::XAS' )      || print "Bail out!\n";
    use_ok( 'XAS::Logmon::Filter::Merge' )      || print "Bail out!\n";
    use_ok( 'XAS::Logmon::Format::Logstash' )   || print "Bail out!\n";
    use_ok( 'XAS::Logmon::Input::File' )        || print "Bail out!\n";
    use_ok( 'XAS::Logmon::Input::Tail' )        || print "Bail out!\n";
    use_ok( 'XAS::Logmon::Output::Spool' )      || print "Bail out!\n";
    use_ok( 'XAS::Logmon::Parser::XAS::Logs' )  || print "Bail out!\n";
    use_ok( 'XAS::Logmon' )                     || print "Bail out!\n";
}

diag( "Testing XAS::Logmon $XAS::Logmon::VERSION, Perl $], $^X" );

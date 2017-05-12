#!perl

use Test::More tests => 18;

BEGIN {
    use_ok( 'XAS::Apps::Collector::Process' )            || print "Bail out!\n";
    use_ok( 'XAS::Collector::Input::Stomp' )             || print "Bail out!\n";
    use_ok( 'XAS::Collector::Format::Base' )             || print "Bail out!\n";
    use_ok( 'XAS::Collector::Format::Alerts' )           || print "Bail out!\n";
    use_ok( 'XAS::Collector::Format::Logs' )             || print "Bail out!\n";
    use_ok( 'XAS::Collector::Output::Console::Base' )    || print "Bail out!\n";
    use_ok( 'XAS::Collector::Output::Console::Alerts' )  || print "Bail out!\n";
    use_ok( 'XAS::Collector::Output::Console::Logs' )    || print "Bail out!\n";
    use_ok( 'XAS::Collector::Output::Database::Base' )   || print "Bail out!\n";
    use_ok( 'XAS::Collector::Output::Database::Alerts' ) || print "Bail out!\n";
    use_ok( 'XAS::Collector::Output::Database::Logs' )   || print "Bail out!\n";
    use_ok( 'XAS::Collector::Output::Socket::Base' )     || print "Bail out!\n";
    use_ok( 'XAS::Collector::Output::Socket::Logstash' ) || print "Bail out!\n";
    use_ok( 'XAS::Collector::Output::Socket::OpenTSDB' ) || print "Bail out!\n";
    use_ok( 'XAS::Docs::Collector::Installation' )       || print "Bail out!\n";
    use_ok( 'XAS::Model::Database::Messaging::Result::Alert' ) || print "Bail out!\n";
    use_ok( 'XAS::Model::Database::Messaging::Result::Log' )   || print "Bail out!\n";
    use_ok( 'XAS::Collector' )                           || print "Bail out!\n";
}

diag( "Testing XAS Collector $XAS::Collector::VERSION, Perl $], $^X" );

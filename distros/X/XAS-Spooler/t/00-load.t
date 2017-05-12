#!perl

use Test::More tests => 5;

BEGIN {
    use_ok( 'XAS::Apps::Spooler::Process' )      || print "Bail out!\n";
    use_ok( 'XAS::Docs::Spooler::Installation' ) || print "Bail out!\n";
    use_ok( 'XAS::Spooler::Connector' )          || print "Bail out!\n";
    use_ok( 'XAS::Spooler::Processor' )          || print "Bail out!\n";
    use_ok( 'XAS::Spooler' )                     || print "Bail out!\n";
}

diag( "Testing XAS Spooler $XAS::Spooler::VERSION, Perl $], $^X" );

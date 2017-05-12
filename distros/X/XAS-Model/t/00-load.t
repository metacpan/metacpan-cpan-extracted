#!perl

use Test::More tests => 8;

BEGIN {
    use_ok( 'XAS::Apps::Database::ExtractData' )    || print "Bail out!\n";
    use_ok( 'XAS::Apps::Database::ExtractGlobals' ) || print "Bail out!\n";
    use_ok( 'XAS::Apps::Database::RemoveData' )     || print "Bail out!\n";
    use_ok( 'XAS::Apps::Database::Schema' )         || print "Bail out!\n";
    use_ok( 'XAS::Model::Database' )                || print "Bail out!\n";
    use_ok( 'XAS::Model::DBM' )                     || print "Bail out!\n";
    use_ok( 'XAS::Model::Schema' )                  || print "Bail out!\n";
    use_ok( 'XAS::Model' )                          || print "Bail out!\n";
}

diag( "Testing XAS::Model $XAS::Model::VERSION, Perl $], $^X" );


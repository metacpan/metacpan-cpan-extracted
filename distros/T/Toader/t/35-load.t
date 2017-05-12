#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Toader::Entry::Cache' ) || print "Bail out!
";
}

diag( "Testing Toader::Entry::Cache $Toader::Entry::Cache::VERSION, Perl $], $^X" );

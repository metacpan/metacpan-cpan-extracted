#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Util::XML_YAML_Perl' ) || print "Bail out!
";
}

diag( "Testing Util::XML_YAML_Perl $Util::XML_YAML_Perl::VERSION, Perl $], $^X" );

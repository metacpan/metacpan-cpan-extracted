#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'YAWF::Object::MongoDB' ) || print "Bail out!
";
}

diag( "Testing YAWF::Object::MongoDB $YAWF::Object::MongoDB::VERSION, Perl $], $^X" );

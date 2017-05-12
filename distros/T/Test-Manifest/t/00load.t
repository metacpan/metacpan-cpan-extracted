use Test::More tests => 1;

print "bail out! Test::Manifest could not compile.\n"
	unless use_ok( "Test::Manifest" );

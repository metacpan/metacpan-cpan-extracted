#!perl -T

use Test::More;

BEGIN {
	foreach (qw(
		Test::Proto

		Test::Proto::Base
		Test::Proto::Role::Value

		Test::Proto::Common
		Test::Proto::TestCase
		Test::Proto::TestRunner

		Test::Proto::Formatter
		Test::Proto::Formatter::TestBuilder

		Test::Proto::HashRef
		Test::Proto::Role::HashRef
		Test::Proto::ArrayRef
		Test::Proto::Role::ArrayRef

		Test::Proto::CodeRef
		Test::Proto::Object

		Test::Proto::Compare
		Test::Proto::Compare::Numeric
	))
	{
    	use_ok( $_ ) || print "Bail out!\n";
	}
}

diag( "Testing Test::Proto $Test::Proto::VERSION, Perl $], $^X" );
done_testing();

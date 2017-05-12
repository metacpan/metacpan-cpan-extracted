#!/usr/bin/perl

use Test::More tests => 5;

BEGIN {
	use_ok( 'XML::Assert' );
}

can_ok('XML::Assert', 'assert_xpath_count');
can_ok('XML::Assert', 'is_xpath_count');

can_ok('XML::Assert', 'assert_xpath_value_match');
can_ok('XML::Assert', 'does_xpath_value_match');

# can_ok('XML::Assert', 'is_different');

diag( "Tested XML::Assert $XML::Assert::VERSION, Perl $], $^X, XML::LibXML $XML::LibXML::VERSION" );

#!/usr/bin/perl

use Test::More tests => 3;

BEGIN {
    use_ok( 'Test::XML::Assert');
}

can_ok('Test::XML::Assert', 'is_xpath_count');
can_ok('Test::XML::Assert', 'does_xpath_value_match');

diag( "Tested Test::XML::Compare $Test::XML::Compare::VERSION, Perl $], $^X, XML::LibXML $XML::LibXML::VERSION" );

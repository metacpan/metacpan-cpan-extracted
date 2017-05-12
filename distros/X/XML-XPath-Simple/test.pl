#!/usr/bin/perl -w 
#############################################################
#  XML::XPath::Simple
#  Whyte.Wolf Simple XPathe Module
#  Copyright (c) 2002 by S.D. Campbell <whytwolf@spots.ab.ca>
#
#  Last modified 30/03/2002
#
#  Test scripts to test that the XML::XPath::Simple module has 
#  been installed correctly.  See Test::More for more 
#  information.
#
#############################################################

use Carp;
use Test::More tests => 13;

#  Check to see if we can use and/or require the module
BEGIN { 
	use_ok('XML::XPath::Simple'); 														# Test 1
	}
require_ok('XML::XPath::Simple');														# Test 2

#  Create XML document for testing purposes
my $xml = <<END;
<?xml version='1.0'?>
<doc>
	<a href="http://www.whytewolf.ca/">Whyte.Wolf</a>
	<a href="http://www.wolfbridge.net/">Wolfbridge</a>
	<a href="http://www.steelwolfe.ca/">Steelwolfe</a>
	<b name="whytewolf" />
	<c>
		<d id="11" name="eleven" />
		<d id="22" name="twenty-two" />
	</c>
	<c>
		<d id="33" name="thirty-three" />
		<d id="44" name="fourty-four" />
	</c>
</doc>
END

#  Create new XML::XPath::Simple object
my $xp = new XML::XPath::Simple(xml => $xml, context => '/');
isa_ok($xp, 'XML::XPath::Simple');														# Test 3

# Check and see if there is a /doc element
is($xp->find('/doc'), 'true', 'found <doc>');											# Test 4

# Get value of <a> element
is($xp->valueof('/doc/a[1]'), 'Whyte.Wolf', 'retrived value of <a>');					# Test 5

# Get value of name attribute
is($xp->valueof('/doc/b@name'), 'whytewolf', 'retrieved value of name');				# Test 6

# Get value of id attribute
is($xp->valueof('/doc/c[2]/d[2]@id'), '44', 'retrieved value of id');					# Test 7

# Check default context
is($xp->context(), '/', 'root context');												# Test 8

# Change default context
$xp->context('/doc/c[2]');
is($xp->context(), '/doc/c[2]', '/doc/c context');										# Test 9

# Check for relative values
is($xp->valueof('d[1]@id'), '33', 'Relative value');									# Test 10

# Check for relative values
is($xp->valueof('../a[1]'), 'Whyte.Wolf', 'Relative value');							# Test 11

# Check for relative values
$xp->context('/doc/a[3]');
is($xp->valueof('.'), 'Steelwolfe', 'Relative Value');									# Test 12

# Check for relative values
is($xp->valueof('@href'), 'http://www.steelwolfe.ca/', 'Relative Value'); 				# Test 13
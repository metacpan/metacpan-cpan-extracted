#!/usr/bin/env perl

use warnings;
use strict;

use lib 'lib','t';
use TestTools;

use XML::Compile::Schema;
use XML::Compile::Tester;
use Math::BigFloat;

use Test::More tests => 175;
use utf8;

my $schema   = XML::Compile::Schema->new( <<__SCHEMA__ );
<schema xmlns="$SchemaNS"
   targetNamespace="$TestNS">

<element name="test1" type="int" />
<element name="test2" type="boolean" />
<element name="test3" type="float" />
<element name="test4" type="NMTOKENS" />
<element name="test5" type="positiveInteger" />
<element name="test6" type="base64Binary" />
<element name="test7" type="dateTime" />
<element name="test8" type="duration" />
<element name="test9" type="hexBinary" />
<element name="testA" type="string" />

</schema>
__SCHEMA__

ok(defined $schema);
set_compile_defaults
    elements_qualified => 'NONE';

###
### int
###

test_rw($schema, test1 => '<test1>0</test1>', 0); 
test_rw($schema, test1 => '<test1>3</test1>', 3); 

###
### Boolean
###

test_rw($schema, test2 => '<test2>0</test2>', 0); 
test_rw($schema, test2 => '<test2>false</test2>', 0
  , '<test2>false</test2>', 'false'); 

test_rw($schema, test2 => '<test2>1</test2>', 1); 
test_rw($schema, test2 => '<test2>true</test2>', 1
  , '<test2>true</test2>', 'true'); 

###
### Float
###

test_rw($schema, test3 => '<test3>0</test3>', 0); 
test_rw($schema, test3 => '<test3>9</test3>', 9); 
test_rw($schema, test3 => '<test3>INF</test3>',  Math::BigFloat->binf); 
test_rw($schema, test3 => '<test3>-INF</test3>', Math::BigFloat->binf('-')); 
test_rw($schema, test3 => '<test3>NaN</test3>',  Math::BigFloat->bnan); 

my $error = error_r($schema, test3 => '<test3></test3>');
is($error, "illegal value `' for type {http://www.w3.org/2001/XMLSchema}float at {http://test-types}test3");

$error = error_w($schema, test3 => 'aap');
is($error, "illegal value `aap' for type {http://www.w3.org/2001/XMLSchema}float at {http://test-types}test3");

$error = error_w($schema, test3 => '');
is($error, "illegal value `' for type {http://www.w3.org/2001/XMLSchema}float at {http://test-types}test3");

###

test_rw($schema, test4 => '<test4>A bc D</test4>', [ qw/A bc D/ ]);

###
### Integers
###

test_rw($schema, test5 => '<test5>4320239</test5>', 4320239); 

###
### Base64Binary
###

test_rw($schema,test6 => '<test6>SGVsbG8sIFdvcmxkIQ==</test6>','Hello, World!');

$error = error_w($schema, test6 => "€");
is($error, 'use Encode::encode() for base64Binary field at {http://test-types}test6');

###
### dateTime validation
###

my $d = '2010-02-11T08:52:47';
test_rw($schema, test7 => "<test7>$d</test7>", $d); 

###
### duration validation
###

my $e = 'PT5M';
test_rw($schema, test8 => "<test8>$e</test8>", $e); 

###
### hexBinary
###

my $f = pack "N", 0x12345678;
test_rw($schema, test9 => "<test9>12345678</test9>", $f); 

###
### string
###

test_rw($schema, testA => "<testA>abc</testA>", 'abc'); 

my $r1 = reader_create $schema, "CDATA reader" => "{$TestNS}testA";
my $cd = '<testA><![CDATA[abc]]></testA>';

my $r1a = $r1->($cd);
cmp_ok($r1a, 'eq', 'abc');

my $cdata = XML::LibXML::CDATASection->new('abc'); 
is('<![CDATA[abc]]>', $cdata->toString(1));

#XXX MO 20120815: XML::LibXML crashed on cleanup of double refs to CDATA
# object (as done in clone of test_rw).  Other XML::LibXML objects do not
# crash on this.
#test_rw($schema, testA => $cd, 'abc', $cd, $cdata);

test_rw($schema, testA => '<testA></testA>', '');

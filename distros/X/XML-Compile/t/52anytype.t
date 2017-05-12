#!/usr/bin/env perl
# test anyType

use warnings;
use strict;

use lib 'lib','t';
use TestTools;

use XML::Compile::Schema;
use XML::Compile::Tester;

use Test::More tests => 15;

my $NS2 = "http://test2/ns";

my $doc = XML::LibXML::Document->new('test doc', 'utf-8');
isa_ok($doc, 'XML::LibXML::Document');
my $root = $doc->createElement('root');
$doc->setDocumentElement($root);
$root->setNamespace('http://x', 'b', 1);

my $schema   = XML::Compile::Schema->new( <<__SCHEMA__ );
<schema
  targetNamespace="$TestNS"
  xmlns="$SchemaNS"
  xmlns:me="$TestNS"
  elementFormDefault="qualified"
>

<element name="test1" type="anyType" />

</schema>
__SCHEMA__

ok(defined $schema);

set_compile_defaults
    include_namespaces => 1;

test_rw($schema, test1 => <<__XML, 10);
<test1 xmlns="$TestNS">10</test1>
__XML

my $r1   = reader_create($schema, "struct", "{$TestNS}test1");
my $elem = qq{<test1 xmlns="$TestNS"><a>11</a><b>12</b></test1>};
my $e1   = $r1->($elem);
isa_ok($e1, 'XML::LibXML::Element');

is($e1->toString, $elem);

#
# Hook
#

set_compile_defaults
    include_namespaces => 1
  , any_type => sub { $_[2]->($_[0], $_[1])+2 };

my $r2    = reader_create($schema, "struct", "{$TestNS}test1");
my $elem2 = qq{<test1 xmlns="$TestNS">11</test1>};
is($r2->($elem2), 13);

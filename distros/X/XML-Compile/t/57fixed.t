#!/usr/bin/env perl
# test use element fixed

use warnings;
use strict;

use lib 'lib','t';
use TestTools;

use XML::Compile::Schema;
use XML::Compile::Tester;

use Test::More tests => 48;

set_compile_defaults
    elements_qualified => 'NONE';

my $schema   = XML::Compile::Schema->new( <<__SCHEMA__ );
<schema targetNamespace="$TestNS"
        xmlns="$SchemaNS"
        xmlns:me="$TestNS">

<element name="test1">
  <complexType>
    <sequence>
      <element name="t1a" type="string" fixed="not-changeable" />
      <element name="t1b" type="int" minOccurs="0" />
    </sequence>
    <attribute name="t1c" type="int" fixed="42" />
  </complexType>
</element>

<element name="test2">
  <complexType>
    <attribute name="t2a" type="int" />
    <attribute name="t2b" type="int" fixed="13" use="optional" />
  </complexType>
</element>
</schema>
__SCHEMA__

ok(defined $schema);

##
### Fixed Integers
##  Big-ints are checked in 49big.t

test_rw($schema, test1 => <<__XML, {t1a => 'not-changeable', t1c => 42});
<test1 t1c="42"><t1a>not-changeable</t1a></test1>
__XML

my $r1 = reader_create $schema, 'missing fixed reader', "{$TestNS}test1";
isa_ok($r1, 'CODE');
my $h1 = $r1->('<test1><t1b>12</t1b></test1>');
is_deeply($h1, {t1b => 12, t1a => 'not-changeable', t1c => 42});

my $w1 = writer_create $schema, 'missing fixed writer', "{$TestNS}test1";
isa_ok($w1, 'CODE');
my $x1 = writer_test $w1, {t1b => 13};
compare_xml $x1, '<test1><t1b>13</t1b></test1>';

my %t1c = (t1a => 'wrong', t1b => 12, t1c => 42);
my $error = error_w($schema, test1 => \%t1c);
is($error, "element `t1a' has value fixed to `not-changeable', got `wrong' at {http://test-types}test1/t1a");

#
# Optional fixed integers
#

my %t2a = (t2a => 14, t2b => 13);
test_rw($schema, test2 => <<__XML, \%t2a);
<test2 t2a="14" t2b="13"/>
__XML

$error = error_r($schema, test2 => <<__XML);
<test2 t2a="15" t2b="12"/>
__XML
is($error, "value of attribute `t2b' is fixed to `13', not `12' at {http://test-types}test2/\@t2b");

my %t2b     = (t2a => 15, t2b => 12);
$error = error_w($schema, test2 => \%t2b);
is($error, "value of attribute `t2b' is fixed to `13', not `12' at {http://test-types}test2/\@t2b");

my %t2c     = (t2a => 17, t2b => 13);
test_rw($schema, test2 => <<__XML, \%t2c);
<test2 t2a="17" t2b="13"/>
__XML

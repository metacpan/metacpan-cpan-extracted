#!/usr/bin/env perl
# test element default

use warnings;
use strict;

use lib 'lib','t';
use TestTools;

use XML::Compile::Schema;
use XML::Compile::Tester;

use Test::More tests => 91;

my $schema   = XML::Compile::Schema->new( <<__SCHEMA__ );
<schema targetNamespace="$TestNS"
        xmlns="$SchemaNS"
        xmlns:me="$TestNS">

<element name="test1">
  <complexType>
    <sequence>
      <element name="t1a" type="integer" default="10"/>
      <element name="t1b" type="integer" default="10"/>
    </sequence>
  </complexType>
</element>

<element name="test2">
  <complexType>
    <sequence>
      <element name="t2a" type="string" default="foo" />
      <element name="t2b" type="string" />
    </sequence>
    <attribute name="t2c" type="int"    default="42" />
  </complexType>
</element>

<element name="test3">
  <complexType>
    <sequence>
      <element name="e3" type="me:t3" default="foo bar" />
    </sequence>
  </complexType>
</element>

<simpleType name="t3">
  <list itemType="token" />
</simpleType>

<element name="test4">
  <complexType>
    <sequence>
      <element name="e4a" type="int" />
      <element name="e4b" type="int" default="72" />
      <element name="e4e" type="int" minOccurs="0" />
    </sequence>
    <attribute name="a4c" type="int" />
    <attribute name="a4d" type="int" default="73" />
  </complexType>
</element>

<element name="test5" default="U">
 <complexType>
  <simpleContent>
   <extension base="string">
    <attribute name="a5" use="required" />
   </extension>
  </simpleContent>
 </complexType>
</element>

</schema>
__SCHEMA__

ok(defined $schema);

set_compile_defaults
   elements_qualified => 'NONE'
 , sloppy_integers    => 1;

##
### Integers
##  Big-ints are checked in 49big.t

test_rw($schema, "test1" => <<__XML, {t1a => 11, t1b => 12});
<test1><t1a>11</t1a><t1b>12</t1b></test1>
__XML

# insert default in hash, but not when producing XML
test_rw($schema, "test1" => <<__XML, {t1a => 10, t1b => 13}, <<__XML, {t1b => 13});
<test1><t1b>13</t1b></test1>
__XML
<test1><t1b>13</t1b></test1>
__XML

##
### Strings
##

my %t21 = (t2a => 'foo', t2b => 'bar', t2c => '42');
my %t22 = (t2b => 'bar');  # do not complete default in XML output
test_rw($schema, "test2" => <<__XML, \%t21, <<__XML, \%t22);
<test2><t2b>bar</t2b></test2>
__XML
<test2><t2b>bar</t2b></test2>
__XML

### List

# bug-report rt.cpan.org#36093

my %t31 = (e3 => ['foo', 'bar']);
test_rw($schema, "test3" => <<__XML, \%t31, <<__XML, {});
<test3/>
__XML
<test3/>
__XML

test_rw($schema, "test3" => <<__XML, \%t31, <<__XML, {e3 => []});
<test3><e3></e3></test3>
__XML
<test3><e3></e3></test3>
__XML

### various DEFAULT_VALUES modes [0.91]

set_compile_defaults
   sloppy_integers    => 1
 , elements_qualified => 'NONE'
 , default_values     => 'EXTEND';

test_rw($schema, test4 => <<__XML, {e4a => 9, e4b => 10, a4c => 11, a4d => 12});
<test4 a4c="11" a4d="12"><e4a>9</e4a><e4b>10</e4b></test4>
__XML

my $r4a = reader_create $schema, 'reader extend', "{$TestNS}test4";
my $h4a = $r4a->( <<__XML );
<test4><e4a>20</e4a><e4e>21</e4e></test4>
__XML
is_deeply($h4a, {e4a => 20, e4b => 72, a4d => 73, e4e => 21});

$h4a = $r4a->( <<__XML );
<test4 a4c="22" a4d="73"><e4a>23</e4a><e4b>72</e4b><e4e>24</e4e></test4>
__XML
is_deeply($h4a, {e4a => 23, e4b => 72, a4c => 22, a4d => 73, e4e => 24});

my $w4a = writer_create $schema, 'writer extend', "{$TestNS}test4";
my $x4a = writer_test $w4a, {e4a => 25};
compare_xml($x4a, <<__XML);
<test4 a4d="73">
   <e4a>25</e4a>
   <e4b>72</e4b>
</test4>
__XML

# IGNORE

set_compile_defaults
   sloppy_integers    => 1
 , elements_qualified => 'NONE'
 , default_values     => 'IGNORE';

test_rw($schema, test4 => <<__XML, {e4a => 9, e4b => 10, a4c => 11, a4d => 12});
<test4 a4c="11" a4d="12"><e4a>9</e4a><e4b>10</e4b></test4>
__XML

my $r4b = reader_create $schema, 'reader ignore', "{$TestNS}test4";
my $h4b = $r4b->( <<__XML );
<test4><e4a>30</e4a><e4e>31</e4e></test4>
__XML
is_deeply($h4b, {e4a => 30, e4e => 31});

$h4b = $r4b->( <<__XML );
<test4 a4c="32" a4d="73"><e4a>33</e4a><e4b>72</e4b><e4e>34</e4e></test4>
__XML
is_deeply($h4b, {e4a => 33, e4b => 72, a4c => 32, a4d => 73, e4e => 34});

my $w4b = writer_create $schema, 'writer ignore', "{$TestNS}test4";
my $x4b = writer_test $w4b, {e4a => 35};
compare_xml($x4b, '<test4><e4a>35</e4a></test4>');

# MINIMAL

set_compile_defaults
   sloppy_integers    => 1
 , elements_qualified => 'NONE'
 , default_values     => 'MINIMAL';

test_rw($schema, test4 => <<__XML, {e4a => 9, e4b => 10, a4c => 11, a4d => 12});
<test4 a4c="11" a4d="12"><e4a>9</e4a><e4b>10</e4b></test4>
__XML

my $r4c = reader_create $schema, 'reader minimal', "{$TestNS}test4";
my $h4c = $r4c->( <<__XML );
<test4><e4a>40</e4a><e4e>41</e4e></test4>
__XML
is_deeply($h4c, {e4a => 40, e4e => 41});

$h4c = $r4c->( <<__XML );
<test4 a4c="42" a4d="73"><e4a>43</e4a><e4b>72</e4b><e4e>44</e4e></test4>
__XML
is_deeply($h4c, {e4a => 43, a4c => 42, e4b => undef, e4e => 44});

my $w4c = writer_create $schema, 'writer minimal', "{$TestNS}test4";
my $x4c = writer_test $w4c, {a4c => 45, a4d => 73, e4a => 46, e4b => 72, e4e => 47};
compare_xml($x4c, <<__XML);
<test4 a4c="45">
   <e4a>46</e4a>
   <e4e>47</e4e>
</test4>
__XML

# Philip Garrett  2012-03-12
my $r5c = reader_create $schema, 'reader default', "{$TestNS}test5";
my $h5c = $r5c->( <<__XML );
<test5 a5="abc">F</test5>
__XML
is_deeply($h5c, {_ => 'F', a5 => 'abc'} );


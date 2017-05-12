#!/usr/bin/env perl

use warnings;
use strict;

use lib 'lib','t';
use TestTools;

use XML::Compile::Schema;
use XML::Compile::Tester;

use Test::More tests => 236;

set_compile_defaults
    elements_qualified => 'NONE';

my $schema   = XML::Compile::Schema->new( <<__SCHEMA__ );
<schema targetNamespace="$TestNS"
        xmlns="$SchemaNS"
        xmlns:me="$TestNS">

<!-- choice with one element -->

<element name="test1" type="me:t1" />
<complexType name="t1">
  <choice>
    <element name="t1_a" type="int" />
  </choice>
</complexType>

<element name="test2">
  <complexType>
    <choice>
       <element name="t2_a" type="int" />
    </choice>
  </complexType>
</element>

<!-- choice with more elements -->

<element name="test3" type="me:t3" />
<complexType name="t3">
  <choice>
    <element name="t3_a" type="int" />
    <element name="t3_b" type="int" />
    <element name="t3_c" type="int" />
  </choice>
</complexType>

<!-- choice can be sequence -->

<element name="test4" type="me:t4" />
<complexType name="t4">
  <choice>
    <element name="t4_a" type="int" />
    <sequence>
       <element name="t4_b" type="int" />
       <element name="t4_c" type="int" />
    </sequence>
    <element name="t4_d" type="int" />
  </choice>
</complexType>

<!-- multiple picks -->

<element name="test5">
  <complexType>
    <choice minOccurs="0" maxOccurs="unbounded">
      <element name="t5_a" type="int" />
      <element name="t5_b" type="int" />
      <element name="t5_c" type="int" />
    </choice>
  </complexType>
</element>

<element name="test6">
  <complexType>
    <choice minOccurs="1" maxOccurs="3">
      <element name="t6_a" type="int" />
      <element name="t6_b" type="int" />
      <element name="t6_c" type="int" />
    </choice>
  </complexType>
</element>

<!-- weird construct from WSDL/tOperation -->
<element name="test7">
  <complexType>
    <choice>
      <group ref="me:g7a"/>
      <group ref="me:g7b"/>
    </choice>
  </complexType>
</element>
<group name="g7a">
  <sequence>
    <element name="g7e1" type="int"/>
    <element name="g7e2" type="int"/>
  </sequence>
</group>
<group name="g7b">
  <sequence>
    <element name="g7e2" type="int"/>
    <element name="g7e1" type="int"/>
  </sequence>
</group>

<!-- really silly, but used -->
<element name="test8">
  <complexType>
    <choice>
      <element name="t8a" type="int" />
      <element name="t8b" type="int" minOccurs="0" />
    </choice>
  </complexType>
</element>

<!-- from a bug-report -->
<element name="test9">
  <complexType>
    <choice>
      <sequence maxOccurs="2">
        <element name="t9a" type="me:t9t"/>
        <element name="t9b" type="string" />
      </sequence>
      <element name="t9c" type="int"/>
    </choice>
  </complexType>
</element>
<complexType name="t9t" />

<element name="test10">
  <complexType>
    <sequence>
      <element name="t10a" type="int" minOccurs="0" />
      <choice minOccurs="0">
        <element name="t10b" type="int" />
        <element name="t10c" type="int" />
      </choice>
      <element name="t10d" type="int" minOccurs="0" />
    </sequence>
  </complexType>
</element>

<element name="test11">
  <complexType>
    <choice>
      <choice minOccurs="1" maxOccurs="unbounded">
        <element name="t11a" type="int" />
        <element name="t11b" type="int" />
      </choice>
      <element name="t11c" type="int" />
    </choice>
  </complexType>
</element>

</schema>
__SCHEMA__

ok(defined $schema);

test_rw($schema, test1 => <<__XML, {t1_a => 10});
<test1><t1_a>10</t1_a></test1>
__XML

my $error = error_r($schema, test1 => <<__XML);
<test1><t1_a>8</t1_a><extra>9</extra></test1>
__XML
is($error, "element `extra' not processed for {http://test-types}test1 at /test1/extra");

# choice itself is not a choice, unless minOccurs=0
$error = error_r($schema, test1 => <<__XML);
<test1 />
__XML
is($error, "element `t1_a' expected for choice at {http://test-types}test1");

test_rw($schema, test2 => <<__XML, {t2_a => 11});
<test2><t2_a>11</t2_a></test2>
__XML

# test 3

test_rw($schema, test3 => <<__XML, {t3_a => 13});
<test3><t3_a>13</t3_a></test3>
__XML

test_rw($schema, test3 => <<__XML, {t3_b => 14});
<test3><t3_b>14</t3_b></test3>
__XML

test_rw($schema, test3 => <<__XML, {t3_c => 15});
<test3><t3_c>15</t3_c></test3>
__XML

# test 4

test_rw($schema, test4 => <<__XML, {t4_a => 16});
<test4><t4_a>16</t4_a></test4>
__XML

test_rw($schema, test4 => <<__XML, {t4_b => 17, t4_c => 18});
<test4><t4_b>17</t4_b><t4_c>18</t4_c></test4>
__XML

test_rw($schema, test4 => <<__XML, {t4_d => 19});
<test4><t4_d>19</t4_d></test4>
__XML

# test 5

test_rw($schema, test5 => <<__XML, {cho_t5_a => [ {t5_a => 20} ]} );
<test5><t5_a>20</t5_a></test5>
__XML

test_rw($schema, test5 => <<__XML, {cho_t5_a => [ {t5_b => 21} ]} );
<test5><t5_b>21</t5_b></test5>
__XML

test_rw($schema, test5 => <<__XML, {cho_t5_a => [ {t5_c => 22} ]} );
<test5><t5_c>22</t5_c></test5>
__XML

my %t5_a =
 ( cho_t5_a => [ {t5_a => 23}
               , {t5_b => 24}
               , {t5_c => 25}
               ]
 );

test_rw($schema, test5 => <<__XML, \%t5_a);
<test5><t5_a>23</t5_a><t5_b>24</t5_b><t5_c>25</t5_c></test5>
__XML

my %t5_b =
 ( cho_t5_a => [ {t5_a => 30}
               , {t5_a => 31}
               , {t5_c => 32}
               , {t5_a => 33}
               ]
 );

test_rw($schema, test5 => <<__XML, \%t5_b);
<test5><t5_a>30</t5_a><t5_a>31</t5_a><t5_c>32</t5_c><t5_a>33</t5_a></test5>
__XML

test_rw($schema, test5 => '<test5/>', {});

# test 6

test_rw($schema, test6 => <<__XML, {cho_t6_a => [ {t6_b => 10} ]} );
<test6><t6_b>10</t6_b></test6>
__XML

$error = error_r($schema, test6 => '<test6 />');
is($error, "no element left to pick choice at {http://test-types}test6");

$error = error_w($schema, test6 => {});
is($error, "found 0 blocks for `cho_t6_a', must be between 1 and 3 inclusive at {http://test-types}test6");

$error = error_r($schema, test6 => <<__XML);
<test6><t6_a>30</t6_a><t6_a>31</t6_a><t6_c>32</t6_c><t6_a>33</t6_a></test6>
__XML
is($error, "element `t6_a' not processed for {http://test-types}test6 at /test6/t6_a[3]");

my %t6_b =
 ( cho_t6_a => [ {t6_a => 30}
               , {t6_a => 31}
               , {t6_c => 32}
               , {t6_a => 33}
               ]
 );

$error = error_w($schema, test6 => \%t6_b);
is($error, "found 4 blocks for `cho_t6_a', must be between 1 and 3 inclusive at {http://test-types}test6");

# test 7

## the other group comes first, for writer
test_rw($schema, test7 => <<__XML, {g7e1 => 12, g7e2 => 13}, <<__XML );
<test7><g7e2>13</g7e2><g7e1>12</g7e1></test7>
__XML
<test7><g7e1>12</g7e1><g7e2>13</g7e2></test7>
__XML

test_rw($schema, test7 => <<__XML, {g7e1 => 14, g7e2 => 15} );
<test7><g7e1>14</g7e1><g7e2>15</g7e2></test7>
__XML

# test 8
test_rw($schema, test8 => <<__XML, { t8a => 16 });
<test8><t8a>16</t8a></test8>
__XML

test_rw($schema, test8 => <<__XML, { });  # match minOccurs=0!
<test8/>
__XML

# test 9
my @t9 = { t9a => {}, t9b => 'monkey'};
test_rw($schema, test9 => <<__XML, { seq_t9a => \@t9 });
<test9>
   <t9a/>
   <t9b>monkey</t9b>
</test9>
__XML

push @t9, { t9a => {}, t9b => 'donkey' };
test_rw($schema, test9 => <<__XML, { seq_t9a => \@t9 });
<test9>
   <t9a/>
   <t9b>monkey</t9b>
   <t9a/>
   <t9b>donkey</t9b>
</test9>
__XML

test_rw($schema, test9 => <<__XML, { t9c => 42 });
<test9>
   <t9c>42</t9c>
</test9>
__XML

# test10

test_rw($schema, test10 => <<__XML, { t10a => 3, t10b => 4, t10d => 5 });
<test10>
  <t10a>3</t10a>
  <t10b>4</t10b>
  <t10d>5</t10d>
</test10>
__XML

test_rw($schema, test10 => <<__XML, { t10a => 6, t10d => 7 });
<test10>
  <t10a>6</t10a>
  <t10d>7</t10d>
</test10>
__XML

# test11, nested choice

my $out = templ_perl($schema, "{$TestNS}test11", show => 'ALL'
 , skip_header => 1, , prefixes => [ 'me' => $TestNS ]
 );
is($out, <<__TEST11);
# Describing complex me:test11
#     {http://test-types}test11

# is an unnamed complex
{ # choice of cho_t11a, t11c

  # choice of t11a, t11b
  # occurs 1 <= # <= unbounded times
  cho_t11a => 
  [ {
      # is a xs:int
      t11a => 42,

      # is a xs:int
      t11b => 42, },
  ],

  # is a xs:int
  t11c => 42, }
__TEST11

my $t11 = { cho_t11a => [ {t11a => 3},{t11b => 4},{t11b => 5},{t11a => 6} ]};
test_rw($schema, test11 => <<__XML, $t11);
<test11>
  <t11a>3</t11a>
  <t11b>4</t11b>
  <t11b>5</t11b>
  <t11a>6</t11a>
</test11>
__XML

test_rw($schema, test11 => <<__XML, {t11c => 7} );
<test11>
  <t11c>7</t11c>
</test11>
__XML

#!/usr/bin/env perl

use warnings;
use strict;

use lib 'lib','t';
use TestTools;

use XML::Compile::Schema;
use XML::Compile::Tester;

use Test::More tests => 182;

set_compile_defaults
    elements_qualified => 'NONE';

my $schema   = XML::Compile::Schema->new( <<__SCHEMA__ );
<schema targetNamespace="$TestNS"
        xmlns="$SchemaNS"
        xmlns:me="$TestNS">

<!-- all with one element -->

<element name="test1" type="me:t1" />
<complexType name="t1">
  <all>
    <element name="t1_a" type="int" />
  </all>
</complexType>

<element name="test2">
  <complexType>
    <all>
       <element name="t2_a" type="int" />
    </all>
  </complexType>
</element>

<!-- all with more elements -->

<element name="test3" type="me:t3" />
<complexType name="t3">
  <all>
    <element name="t3_a" type="int" />
    <element name="t3_b" type="int" />
    <element name="t3_c" type="int" />
  </all>
</complexType>

<element name="test4" type="me:t4" />
<complexType name="t4">
  <all>
    <element name="t4_a" type="int" />
    <sequence>
       <element name="t4_b" type="int" />
       <element name="t4_c" type="int" />
    </sequence>
    <element name="t4_d" type="int" />
  </all>
</complexType>

<!-- multiple picks -->

<element name="test5">
  <complexType name="t5">
    <all minOccurs="0" maxOccurs="unbounded">
      <element name="t5_a" type="int" />
      <element name="t5_b" type="int" />
      <element name="t5_c" type="int" />
    </all>
  </complexType>
</element>

<element name="test6">
  <complexType name="t6">
    <all minOccurs="1" maxOccurs="3">
      <element name="t6_a" type="int" />
      <element name="t6_b" type="int" />
      <element name="t6_c" type="int" />
    </all>
  </complexType>
</element>

</schema>
__SCHEMA__

ok(defined $schema);
my $error;

test_rw($schema, test1 => <<__XML, {t1_a => 10});
<test1><t1_a>10</t1_a></test1>
__XML

$error = error_r($schema, test1 => <<__XML);
<test1><t1_a>8</t1_a><extra>9</extra></test1>
__XML
is($error, "element `extra' not processed for {http://test-types}test1 at /test1/extra");

# all itself is not a all, unless minOccurs=0
$error = error_r($schema, test1 => <<__XML);
<test1 />
__XML
is($error, "data for element or block starting with `t1_a' missing at {http://test-types}test1");

test_rw($schema, test1 => undef, {});

test_rw($schema, test2 => <<__XML, {t2_a => 11});
<test2><t2_a>11</t2_a></test2>
__XML

# test 3

foreach my $f
 ( [qw/t3_a t3_b t3_c/ ]
 , [qw/t3_a t3_c t3_b/ ]
 , [qw/t3_b t3_a t3_c/ ]
 , [qw/t3_b t3_c t3_a/ ]
 , [qw/t3_c t3_a t3_b/ ]
 , [qw/t3_c t3_b t3_a/ ]
 )
{   my %f = ( $f->[0] => 13, $f->[1] => 14, $f->[2] => 15 );
    ok(1, "try $f->[0], $f->[1], $f->[2]");

    test_rw($schema, test3 => <<__XML, \%f, <<__XMLWriter);
<test3>
   <$f->[0]>13</$f->[0]>
   <$f->[1]>14</$f->[1]>
   <$f->[2]>15</$f->[2]>
</test3>
__XML
<test3>
   <t3_a>$f{t3_a}</t3_a>
   <t3_b>$f{t3_b}</t3_b>
   <t3_c>$f{t3_c}</t3_c>
</test3>
__XMLWriter

    $error = error_r($schema, test3 => <<__XML);
<test3>
   <$f->[0]>13</$f->[0]>
   <$f->[1]>14</$f->[1]>
</test3>
__XML

    is($error, "data for element or block starting with `$f->[2]' missing at {http://test-types}test3");

    $error = error_r($schema, test3 => <<__XML);
<test3>
   <$f->[0]>13</$f->[0]>
</test3>
__XML

    like($error, qr/^data for element or block starting with `.*' missing at \{http\:\/\/test-types\}test3$/);
}

# test 4

test_rw($schema, test4 => <<__XML, {t4_a=>16, t4_b=>17, t4_c=>18, t4_d=>19});
<test4><t4_a>16</t4_a><t4_b>17</t4_b><t4_c>18</t4_c><t4_d>19</t4_d></test4>
__XML

my %t4b = (t4_a=>20, t4_b=>22, t4_c=>23, t4_d=>21);
test_rw($schema, test4 => <<__XML, \%t4b, <<__XML2);
<test4><t4_a>20</t4_a><t4_d>21</t4_d><t4_b>22</t4_b><t4_c>23</t4_c></test4>
__XML
<test4><t4_a>20</t4_a><t4_b>22</t4_b><t4_c>23</t4_c><t4_d>21</t4_d></test4>
__XML2

$error = error_r($schema, test4 => <<__XML);
<test4><t4_a>24</t4_a><t4_d>25</t4_d><t4_c>26</t4_c><t4_b>27</t4_b></test4>
__XML
is($error, "data for element or block starting with `t4_b' missing at {http://test-types}test4");

# test 5

my %t5_a =
 ( all_t5_a => [ { t5_a => 23
               , t5_b => 24
               , t5_c => 25
               } ]
 );

test_rw($schema, test5 => <<__XML, \%t5_a);
<test5><t5_a>23</t5_a><t5_b>24</t5_b><t5_c>25</t5_c></test5>
__XML

my %t5_b = (all_t5_a =>
  [ { t5_a => 30
    , t5_b => 31
    , t5_c => 32
    }
  , { t5_a => 35
    , t5_b => 34
    , t5_c => 33
    }
  ]);

test_rw($schema, test5 => <<__XML, \%t5_b, <<__XML2);
<test5>
  <t5_a>30</t5_a><t5_b>31</t5_b><t5_c>32</t5_c>
  <t5_c>33</t5_c><t5_b>34</t5_b><t5_a>35</t5_a>
</test5>
__XML
<test5>
  <t5_a>30</t5_a><t5_b>31</t5_b><t5_c>32</t5_c>
  <t5_a>35</t5_a><t5_b>34</t5_b><t5_c>33</t5_c>
</test5>
__XML2

test_rw($schema, test5 => '<test5/>', {});

# test 6

$error = error_r($schema, test6 => '<test6 />');
like($error, qr[data for element or block starting with `t6_[abc]' missing at \{http://test-types\}test6]);

$error = error_w($schema, test6 => {});
is($error, "found 0 blocks for `all_t6_a', must be between 1 and 3 inclusive at {http://test-types}test6");

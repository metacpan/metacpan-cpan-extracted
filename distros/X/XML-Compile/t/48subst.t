#!/usr/bin/env perl
# SubstitutionGroups

use warnings;
use strict;

use lib 'lib','t';
use TestTools;

use XML::Compile::Schema;
use XML::Compile::Tester;

use Test::More tests => 57;
use Log::Report 'try';

set_compile_defaults
    elements_qualified => 'NONE';

my $TestNS2 = "http://second-ns";

my $schema   = XML::Compile::Schema->new( <<__SCHEMA );
<schema targetNamespace="$TestNS"
        xmlns="$SchemaNS"
        xmlns:one="$TestNS">

<element name="head" type="string" abstract="true" />

<element name="test1">
  <complexType>
    <sequence>
      <element name="t1" type="int"  />
      <element ref="one:head"        />
      <element name="t3" type="int"  />
    </sequence>
  </complexType>
</element>

<element name="test2">
  <complexType>
    <sequence>
      <element ref="one:head" minOccurs="0" maxOccurs="3" />
      <element name="id2" type="int" />
    </sequence>
  </complexType>
</element>

<!-- more schemas below -->
</schema>
__SCHEMA

ok(defined $schema);

try { test_rw($schema, test1 => <<__XML, undef) };
<test1><t1>42</t1><t2>43</t2><t3>44</t3></test1>
__XML

ok($@, 'compile-time error');
my $error = $@->wasFatal;
is("$error", "error: data for element or block starting with `head' missing at {$TestNS}test1\n");

$schema->importDefinitions( <<__EXTRA );
<!-- alternatives in same namespace -->
<schemas>

<schema targetNamespace="$TestNS"
        xmlns="$SchemaNS"
        xmlns:one="$TestNS">

<!-- this is not an extension of head's "string" but easier to recognize -->
<element name="alt1" substitutionGroup="one:head">
  <complexType>
    <sequence>
      <element name="a1" type="int" />
    </sequence>
  </complexType>
</element>

</schema>

<!-- alternatives in other namespace -->
<schema targetNamespace="$TestNS2"
        xmlns="$SchemaNS"
        xmlns:one="$TestNS"
        xmlns:two="$TestNS2">

<element name="alt2" substitutionGroup="one:head">
  <complexType>
    <sequence>
      <element name="a2" type="int" />
    </sequence>
  </complexType>
</element>

</schema>

</schemas>
__EXTRA

my %t1 = (t1 => 42, alt1 => {a1 => 43}, t3 => 44);
test_rw($schema, test1 => <<__XML, \%t1);
<test1><t1>42</t1><alt1><a1>43</a1></alt1><t3>44</t3></test1>
__XML

my %t2 = (t1 => 45, alt2 => {a2 => 46}, t3 => 47);
test_rw($schema, test1 => <<__XML, \%t2);
<test1><t1>45</t1><alt2><a2>46</a2></alt2><t3>47</t3></test1>
__XML

# abstract within substitutionGroup
$error = error_r $schema, test1 => <<__XML;
<test1><t1>10</t1><head>11</head><t3>12</t3></test1>
__XML
is($error, "abstract element `head' used at {$TestNS}test1/one:head");

### test2

my %t3 =
 ( head =>
   [ {alt1 => {a1 => 50}}
   , {alt1 => {a1 => 51}}
   , {alt2 => {a2 => 52}}
   ]
 , id2 => 53
 );

test_rw($schema, test2 => <<__XML, \%t3);
<test2>
  <alt1><a1>50</a1></alt1>
  <alt1><a1>51</a1></alt1>
  <alt2><a2>52</a2></alt2>
  <id2>53</id2>
</test2>
__XML

my %t4 = (id2 => 54);
test_rw($schema, test2 => <<__XML, \%t4);
<test2>
  <id2>54</id2>
</test2>
__XML

my %t5 =
 ( head =>
   [ {alt2 => {a2 => 55}}
   , {alt1 => {a1 => 56}}
   ]
 , id2 => 57
 );

test_rw($schema, test2 => <<__XML, \%t5);
<test2>
  <alt2><a2>55</a2></alt2>
  <alt1><a1>56</a1></alt1>
  <id2>57</id2>
</test2>
__XML

### multi-level
$schema->importDefinitions( <<__EXTRA );
<schema targetNamespace="$TestNS2"
        xmlns="$SchemaNS"
        xmlns:one="$TestNS"
        xmlns:two="$TestNS2">

<element name="alt3" substitutionGroup="two:alt2" type="int" />
</schema>
__EXTRA

my %t6 = (head => [ {alt3 => 61} ], id2 => 62);
test_rw($schema, test2 => <<__XML, \%t6);
<test2>
  <alt3>61</alt3>
  <id2>62</id2>
</test2>
__XML

my $out = templ_perl $schema, "{$TestNS}test2", skip_header => 1
 , abstract_types => 1;

is($out, <<'__TEMPL');
# Describing complex x0:test2
#     {http://test-types}test2

# is an unnamed complex
{ # sequence of head, id2

  # substitutionGroup x0:head
  #   alt1 unnamed complex
  #   alt2 unnamed complex
  #   alt3 xs:int
  #   head xs:string (abstract)
  # occurs 0 <= # <= 3 times
  head => [ { alt1 => {...} }, ],

  # is a xs:int
  id2 => 42, }
__TEMPL

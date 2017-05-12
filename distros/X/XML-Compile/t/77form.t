#!/usr/bin/env perl
# test "form" overrule.  The code is derived from bugreport #86079
# by Manfred Stock.

use warnings;
use strict;

use lib 'lib','t';
use TestTools;

use XML::Compile::Schema;
use XML::Compile::Tester;
use XML::Compile::Util qw/pack_type SCHEMA2001/;

use Test::More tests => 36;

my $schemans = SCHEMA2001;
my $tns      = 'http://test-types';

my $template = <<__SCHEMA;
<schema elementFormDefault="__FORM01__"
  xmlns="$schemans" targetNamespace="$tns">
 <element name="request">
  <complexType>
   <sequence>
    <element name="x" minOccurs="0" type="float" form="__FORM02__" />
    <element name="y" minOccurs="0" type="float" />
   </sequence>
  </complexType>
 </element>
</schema>
__SCHEMA

my @combinations =
  ( [   'qualified',   'qualified', <<__QQ ]
<x0:request xmlns:x0="$tns">
  <x0:x>42</x0:x>
  <x0:y>3</x0:y>
</x0:request>
__QQ

  , [ 'unqualified',   'qualified', <<__UQ ]
<x0:request xmlns:x0="$tns">
  <x0:x>42</x0:x>
  <y>3</y>
</x0:request>
__UQ

  , [   'qualified', 'unqualified', <<__QU ]
<x0:request xmlns:x0="$tns">
  <x>42</x>
  <x0:y>3</x0:y>
</x0:request>
__QU

  , [ 'unqualified', 'unqualified', <<__UU ]
<x0:request xmlns:x0="$tns">
  <x>42</x>
  <y>3</y>
</x0:request>
__UU
  );

set_compile_defaults
    include_namespaces    => 1
  , use_default_namespace => 0;

foreach (@combinations)
{   my ($schema_form, $elem_form, $expect) = @$_;
    my $data = $template;
    $data =~ s{__FORM01__}{$schema_form};
    $data =~ s{__FORM02__}{$elem_form};
    ok 1, "next combination: elementFormDefault=$schema_form, form=$elem_form";

    my $schema = XML::Compile::Schema->new($data);

    test_rw $schema, request => $expect, {x => 42, y => 3};
}


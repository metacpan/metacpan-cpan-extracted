#!/usr/bin/env perl
# test abstract elements

use warnings;
use strict;

use lib 'lib','t';
use TestTools;

use XML::Compile::Schema;
use XML::Compile::Tester;

use Test::More tests => 11;

set_compile_defaults
    elements_qualified => 'NONE';

my $schema   = XML::Compile::Schema->new( <<__SCHEMA__ );
<schema targetNamespace="$TestNS"
        xmlns="$SchemaNS"
        xmlns:me="$TestNS">

<element name="test1" type="int" abstract="true" />

<element name="test2">
  <complexType>
    <sequence>
      <element ref="me:test1" />
    </sequence>
  </complexType>
</element>

</schema>
__SCHEMA__

ok(defined $schema);

my $error = error_w($schema, test2 => {test1 => 42});
is($error, "attempt to instantiate abstract element `test1' at {http://test-types}test2/me:test1");

$error = error_r($schema, test2 => <<__XML);
<test2><test1>43</test1></test2>
__XML
is($error, "abstract element `test1' used at {http://test-types}test2/me:test1");

# abstract elements are skipped from the docs
my $out = templ_perl($schema, "{$TestNS}test2", abstract_types => 1, skip_header => 1);
is($out, <<'__TEMPL');
# Describing complex x0:test2
#     {http://test-types}test2

# is an unnamed complex
{ # sequence of test1

  # is a xs:int
  # ABSTRACT
  test1 => 42, }
__TEMPL

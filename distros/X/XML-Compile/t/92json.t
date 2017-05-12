#!/usr/bin/env perl
# test json-friendly conversion

use warnings;
use strict;

use lib 'lib','t';
use TestTools;

use XML::Compile::Schema;
use XML::Compile::Tester;

use Test::More;

my @json_modules = qw/JSON::XS Cpanel::JSON::XS JSON::PP/;

my %has;
foreach my $module (@json_modules)
{   eval "require $module";
    $has{$module} = 1 if !$@;
}

{
    no warnings 'once';

    if($has{'JSON::PP'} && JSON::PP->VERSION < 2.91)
    {   diag "JSON::PP too old, requires 2.91 to work";
            delete $has{'JSON::PP'};
    }

    if($has{'JSON::XS'} && JSON::XS->VERSION < 3.02)
    {   diag "JSON::XS too old, requires 3.02 to work";
            delete $has{'JSON::XS'};
    }

    if($has{'Cpanel::JSON::XS'} && Cpanel::JSON::XS->VERSION < 3.0201)
    {   diag "Cpanel::JSON::XS too old, requires 3.0201 to work";
            delete $has{'Cpanel::JSON::XS'};
    }
}

keys %has
    or plan skip_all => "No module of the following available: @json_modules";

plan 'no_plan';

my $schema   = XML::Compile::Schema->new( <<__SCHEMA__ );
<schema xmlns="$SchemaNS"
   targetNamespace="$TestNS">

<element name="boolean" type="boolean" />
<element name="integer" type="integer" />
<element name="long" type="long" />
<element name="negativeInteger" type="negativeInteger" />
<element name="nonNegativeInteger" type="nonNegativeInteger" />
<element name="nonPositiveInteger" type="nonPositiveInteger" />
<element name="positiveInteger" type="positiveInteger" />
<element name="unsignedInt" type="unsignedInt" />
<element name="unsignedLong" type="unsignedLong" />
<element name="byte" type="byte" />
<element name="int" type="int" />
<element name="short" type="short" />
<element name="unsignedByte" type="unsignedByte" />
<element name="decimal" type="decimal" />
<element name="double" type="double" />
<element name="float" type="float" />
<element name="string" type="string" />
<element name="complex">
  <complexType>
    <sequence>
      <element name="elem" type="int" minOccurs="0" maxOccurs="unbounded" />
    </sequence>
  </complexType>
</element>

</schema>
__SCHEMA__

ok(defined $schema);

my $json_serializer;
sub test_r_json($$$$;@)
{   my ($schema, $test, $xml, $expected_json, %args) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    SKIP: {
        skip "No bignum implementation with " . ref($json_serializer), 1
            if $args{need_bignum} && !$json_serializer->can('allow_bignum');

        my $type = $test =~ m/\{/ ? $test : "{$TestNS}$test";

        my $r = XML::Compile::Tester::reader_create($schema, $test, $type);
        defined $r or return;

        my $h = $r->($xml);

        my $got_json = $json_serializer->encode($h);
        is $got_json, $expected_json
      , "json serialization (" . ref($json_serializer) . ") for $test";
    }
}

my @default_compile_defaults =
  ( elements_qualified => 'NONE'
  , json_friendly      => 1
  , sloppy_floats      => 1
  );

SKIP: foreach my $json_module (@json_modules)
{
    $has{$json_module}
        or skip "Skip tests with $json_module", 1;

    $json_serializer = $json_module->new->utf8->canonical->allow_nonref;
    if($json_serializer->can('allow_bignum'))
    {   $json_serializer->allow_bignum;
            set_compile_defaults @default_compile_defaults;
    }
    else
    {
        # for JSON::XS (lacks bignum support)
        set_compile_defaults
            @default_compile_defaults
          , sloppy_integers => 1
          , sloppy_floats   => 1
          ;
    }

    test_r_json $schema, boolean => '<boolean>0</boolean>', 'false';
    test_r_json $schema, boolean => '<boolean>false</boolean>', 'false';
    test_r_json $schema, boolean => '<boolean>1</boolean>', 'true';
    test_r_json $schema, boolean => '<boolean>true</boolean>', 'true';

    test_r_json $schema, integer => '<integer>-123</integer>', '-123';
    test_r_json $schema, integer => '<integer>0</integer>', '0';
    test_r_json $schema, integer => '<integer>123</integer>', '123';

    test_r_json $schema, long => '<long>-1234</long>', '-1234';
    test_r_json $schema, long => '<long>0</long>', '0';
    test_r_json $schema, long => '<long>1234</long>', '1234';
    test_r_json $schema, long => '<long>1234567890123456789</long>', '1234567890123456789', need_bignum => 1;

    test_r_json $schema, negativeInteger => '<negativeInteger>-123</negativeInteger>', '-123';

    test_r_json $schema, nonNegativeInteger => '<nonNegativeInteger>123</nonNegativeInteger>', '123';
    test_r_json $schema, nonNegativeInteger => '<nonNegativeInteger>0</nonNegativeInteger>', '0';

    test_r_json $schema, nonPositiveInteger => '<nonPositiveInteger>-123</nonPositiveInteger>', '-123';
    test_r_json $schema, nonPositiveInteger => '<nonPositiveInteger>0</nonPositiveInteger>', '0';

    test_r_json $schema, positiveInteger => '<positiveInteger>123</positiveInteger>', '123';

    test_r_json $schema, unsignedInt => '<unsignedInt>123</unsignedInt>', '123';
    test_r_json $schema, unsignedLong => '<unsignedLong>1234567890123456789</unsignedLong>', '1234567890123456789', need_bignum => 1;

    test_r_json $schema, byte => '<byte>-128</byte>', '-128';
    test_r_json $schema, byte => '<byte>0</byte>', '0';
    test_r_json $schema, byte => '<byte>127</byte>', '127';

    test_r_json $schema, int => '<int>-2147483648</int>', '-2147483648';
    test_r_json $schema, int => '<int>0</int>', '0';
    test_r_json $schema, int => '<int>2147483647</int>', '2147483647';
    test_r_json $schema, int => '<int>+2147483647</int>', '2147483647';

    test_r_json $schema, short => '<short>-32768</short>', '-32768';
    test_r_json $schema, short => '<short>0</short>', '0';
    test_r_json $schema, short => '<short>32767</short>', '32767';

    test_r_json $schema, 'unsignedByte', '<unsignedByte>0</unsignedByte>', '0';
    test_r_json $schema, 'unsignedByte', '<unsignedByte>255</unsignedByte>', '255';

# Currently broken
# test_r_json $schema, 'decimal', '<decimal>-99999999999999999999.9999</decimal>', '-99999999999999999999.9999', need_bignum => 1;
    test_r_json $schema, 'decimal', '<decimal>-123.4560</decimal>', '-123.456'; # trailing zero gets lost!
    test_r_json $schema, 'decimal', '<decimal>-123.456</decimal>', '-123.456';
    test_r_json $schema, 'decimal', '<decimal>-123</decimal>', '-123';
    test_r_json $schema, 'decimal', '<decimal>0</decimal>', '0';

# Depends on the JSON parser
#   test_r_json $schema, 'decimal', '<decimal>0.0</decimal>', '0.0'; # XXX .0 gets lost!
    test_r_json $schema, 'decimal', '<decimal>123</decimal>', '123';
    test_r_json $schema, 'decimal', '<decimal>123.456</decimal>', '123.456';
    test_r_json $schema, 'decimal', '<decimal>123.4560</decimal>', '123.456';

# Currently broken
# test_r_json $schema, 'decimal', '<decimal>99999999999999999999.9999</decimal>', '99999999999999999999.9999', need_bignum => 1;

    test_r_json $schema, 'float', '<float>123.4560</float>', '123.456';
    test_r_json $schema, 'float', '<float>-123.4560</float>', '-123.456';
    {
        local $TODO = "NaN/inf support partially buggy";
        # see https://github.com/rurban/Cpanel-JSON-XS/issues/78
        # JSON::XS has no option to prevent NaN/inf generation
        test_r_json $schema, 'float', '<float>NaN</float>', 'null'; # no Nan/Inf... support in JSON
        test_r_json $schema, 'float', '<float>-INF</float>', 'null'; # no Nan/Inf... support in JSON
        test_r_json $schema, 'float', '<float>+INF</float>', 'null'; # no Nan/Inf... support in JSON
    }

    test_r_json $schema, 'string', '<string></string>', '""';
    test_r_json $schema, 'string', '<string>non-empty</string>', '"non-empty"';
    test_r_json $schema, 'string', '<string>&#x20ac;</string>', qq{"\342\202\254"}; # euro sign

    test_r_json $schema, 'complex', '<complex></complex>', '{}';
    test_r_json $schema, 'complex', '<complex><elem>1</elem><elem>2</elem></complex>', '{"elem":[1,2]}';

}

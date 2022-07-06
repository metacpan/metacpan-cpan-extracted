#!/usr/bin/env perl

use strict;
use warnings;

use Cpanel::JSON::XS::Type;
use Test::JSON::Type;
use Test::More 'tests' => 2;

my $json_struct1 = <<'END';
{
  "bool": true,
  "float": 0.23,
  "int": 1,
  "null": null,
  "string": "bar"
}
END
my $json_struct2 = <<'END';
{
  "bool": false,
  "float": 1.23,
  "int": 2,
  "null": null,
  "string": "foo"
}
END
my $expected_type_hr = {
  'bool' => JSON_TYPE_BOOL,
  'float' => JSON_TYPE_FLOAT,
  'int' => JSON_TYPE_INT,
  'null' => JSON_TYPE_NULL,
  'string' => JSON_TYPE_STRING,
};
is_json_type($json_struct1, $expected_type_hr, 'Test JSON type #1.');
is_json_type($json_struct2, $expected_type_hr, 'Test JSON type #2.');

# Output:
# 1..2
# ok 1 - Test JSON type \#1.
# ok 2 - Test JSON type \#2.
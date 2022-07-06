#!/usr/bin/env perl

use strict;
use warnings;

use Test::JSON::Type;
use Test::More 'tests' => 2;

my $json_blank1 = '{}';
my $json_blank2 = '{}';
cmp_json_types($json_blank1, $json_blank2, 'Blank JSON strings.');

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
cmp_json_types($json_struct1, $json_struct2, 'Structured JSON strings.');

# Output:
# 1..2
# ok 1 - Blank JSON strings.
# ok 2 - Structured JSON strings.
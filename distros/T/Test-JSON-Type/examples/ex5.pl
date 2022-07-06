#!/usr/bin/env perl

use strict;
use warnings;

use Cpanel::JSON::XS::Type;
use Test::JSON::Type;
use Test::More 'tests' => 2;

my $json_struct = <<'END';
{
  "array": [1,2,3]
}
END
my $expected_type1_hr = {
  'array' => json_type_arrayof(JSON_TYPE_INT),
};
my $expected_type2_hr = {
  'array' => [
    JSON_TYPE_INT,
    JSON_TYPE_INT,
    JSON_TYPE_INT,
  ],
};
is_json_type($json_struct, $expected_type1_hr, 'Test JSON type (multiple integers).');
is_json_type($json_struct, $expected_type2_hr, 'Test JSON type (three integers)');

# Output:
# 1..2
# ok 1 - Test JSON type (multiple integers).
# ok 2 - Test JSON type (three integers)
#!/usr/bin/env perl

use strict;
use warnings;

use Test::JSON::Type;
use Test::More 'tests' => 1;

my $json_struct_err1 = <<'END';
{
  "int": 1,
  "array": ["1", 1]
}
END
my $json_struct_err2 = <<'END';
{
  "int": 1,
  "array": 1
}
END
cmp_json_types($json_struct_err1, $json_struct_err2, 'Structured JSON strings with error.');

# Output:
# 1..1
# not ok 1 - Structured JSON strings with error.
# #   Failed test 'Structured JSON strings with error.'
# #   at ./ex3.pl line 21.
# # +----+--------------------------+----+-----------------------------+
# # | Elt|Got                       | Elt|Expected                     |
# # +----+--------------------------+----+-----------------------------+
# # |   0|{                         |   0|{                            |
# # *   1|  array => [              *   1|  array => 'JSON_TYPE_INT',  *
# # *   2|    'JSON_TYPE_STRING',   *    |                             |
# # *   3|    'JSON_TYPE_INT'       *    |                             |
# # *   4|  ],                      *    |                             |
# # |   5|  int => 'JSON_TYPE_INT'  |   2|  int => 'JSON_TYPE_INT'     |
# # |   6|}                         |   3|}                            |
# # +----+--------------------------+----+-----------------------------+
# # Looks like you failed 1 test of 1.
#!/usr/bin/env perl

use strict;
use warnings;

use Test::JSON::Type;
use Test::More 'tests' => 1;

my $json_struct_err1 = <<'END';
{
  "int": 1,
  "string": "1"
}
END
my $json_struct_err2 = <<'END';
{
  "int": 1,
  "string": 1
}
END
cmp_json_types($json_struct_err1, $json_struct_err2, 'Structured JSON strings with error.');

# Output:
# 1..1
# not ok 1 - Structured JSON strings with error.
# #   Failed test 'Structured JSON strings with error.'
# #   at ./ex2.pl line 21.
# # +----+--------------------------------+-----------------------------+
# # | Elt|Got                             |Expected                     |
# # +----+--------------------------------+-----------------------------+
# # |   0|{                               |{                            |
# # |   1|  int => 'JSON_TYPE_INT',       |  int => 'JSON_TYPE_INT',    |
# # *   2|  string => 'JSON_TYPE_STRING'  |  string => 'JSON_TYPE_INT'  *
# # |   3|}                               |}                            |
# # +----+--------------------------------+-----------------------------+
# # Looks like you failed 1 test of 1.
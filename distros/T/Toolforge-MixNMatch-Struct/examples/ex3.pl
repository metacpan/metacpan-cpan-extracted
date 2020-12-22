#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use Toolforge::MixNMatch::Object::Catalog;
use Toolforge::MixNMatch::Struct::Catalog qw(obj2struct);

# Object.
my $obj = Toolforge::MixNMatch::Object::Catalog->new(
        'count' => 10,
        'type' => 'Q5',
        'users' => [
                Toolforge::MixNMatch::Object::User->new(
                        'count' => 6,
                        'uid' => 1,
                        'username' => 'Skim',
                ),
                Toolforge::MixNMatch::Object::User->new(
                        'count' => 4,
                        'uid' => 2,
                        'username' => 'Foo',
                ),
        ],
        'year_months' => [
                Toolforge::MixNMatch::Object::YearMonth->new(
                        'count' => 2,
                        'month' => 9,
                        'year' => 2020,
                ),
                Toolforge::MixNMatch::Object::YearMonth->new(
                        'count' => 8,
                        'month' => 10,
                        'year' => 2020,
                ),
        ],
);

# Get structure.
my $struct_hr = obj2struct($obj);

# Dump to output.
p $struct_hr;

# Output:
# \ {
#     type   [
#         [0] {
#             cnt    10,
#             type   "Q5"
#         }
#     ],
#     user   [
#         [0] {
#             cnt        6,
#             uid        1,
#             username   "Skim"
#         },
#         [1] {
#             cnt        4,
#             uid        2,
#             username   "Foo"
#         }
#     ],
#     ym     [
#         [0] {
#             cnt   2,
#             ym    202009
#         },
#         [1] {
#             cnt   8,
#             ym    202010
#         }
#     ]
# }
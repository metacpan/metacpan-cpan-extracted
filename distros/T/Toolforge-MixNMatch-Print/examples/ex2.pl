#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use Toolforge::MixNMatch::Object::Catalog;
use Toolforge::MixNMatch::Object::User;
use Toolforge::MixNMatch::Object::YearMonth;
use Toolforge::MixNMatch::Print::Catalog;

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

# Print.
print Toolforge::MixNMatch::Print::Catalog::print($obj)."\n";

# Output:
# Type: Q5
# Count: 10
# Year/months:
#         2020/9: 2
#         2020/10: 8
# Users:
#         Skim (1): 6
#         Foo (2): 4
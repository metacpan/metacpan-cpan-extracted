#!/usr/bin/env perl

use strict;
use warnings;

use Toolforge::MixNMatch::Diff;
use Toolforge::MixNMatch::Object::Catalog;
use Toolforge::MixNMatch::Object::User;
use Toolforge::MixNMatch::Object::YearMonth;
use Toolforge::MixNMatch::Print::Catalog;

# Catalogs.
my $cat1 = Toolforge::MixNMatch::Object::Catalog->new(
        'count' => 10,
        'type' => 'Q5',
        'users' => [
                Toolforge::MixNMatch::Object::User->new(
                        'count' => 2,
                        'uid' => 1,
                        'username' => 'Skim',
                ),
                Toolforge::MixNMatch::Object::User->new(
                        'count' => 1,
                        'uid' => 2,
                        'username' => 'Foo',
                ),
        ],
        'year_months' => [
                Toolforge::MixNMatch::Object::YearMonth->new(
                        'count' => 3,
                        'month' => 9,
                        'year' => 2020,
                ),
        ],
);
my $cat2 = Toolforge::MixNMatch::Object::Catalog->new(
        'count' => 10,
        'type' => 'Q5',
        'users' => [
                Toolforge::MixNMatch::Object::User->new(
                        'count' => 3,
                        'uid' => 1,
                        'username' => 'Skim',
                ),
                Toolforge::MixNMatch::Object::User->new(
                        'count' => 2,
                        'uid' => 2,
                        'username' => 'Foo',
                ),
        ],
        'year_months' => [
                Toolforge::MixNMatch::Object::YearMonth->new(
                        'count' => 3,
                        'month' => 9,
                        'year' => 2020,
                ),
                Toolforge::MixNMatch::Object::YearMonth->new(
                        'count' => 2,
                        'month' => 10,
                        'year' => 2020,
                ),
        ],
);

my $diff_cat = Toolforge::MixNMatch::Diff::diff($cat1, $cat2);

# Print out.
print "Catalog #1:\n";
print Toolforge::MixNMatch::Print::Catalog::print($cat1)."\n\n";
print "Catalog #2:\n";
print Toolforge::MixNMatch::Print::Catalog::print($cat2)."\n\n";
print "Diff catalog:\n";
print Toolforge::MixNMatch::Print::Catalog::print($diff_cat)."\n";

# Output:
# Catalog #1:
# Type: Q5
# Count: 10
# Year/months:
#         2020/9: 3
# Users:
#         Skim (1): 2
#         Foo (2): 1
# 
# Catalog #2:
# Type: Q5
# Count: 10
# Year/months:
#         2020/9: 3
#         2020/10: 2
# Users:
#         Skim (1): 3
#         Foo (2): 2
# 
# Diff catalog:
# Type: Q5
# Count: 10
# Year/months:
#         2020/10: 2
# Users:
#         Foo (2): 1
#         Skim (1): 1
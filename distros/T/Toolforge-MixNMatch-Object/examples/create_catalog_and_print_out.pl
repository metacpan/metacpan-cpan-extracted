#!/usr/bin/env perl

use strict;
use warnings;

use Toolforge::MixNMatch::Object::Catalog;
use Toolforge::MixNMatch::Object::User;
use Toolforge::MixNMatch::Object::YearMonth;

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

# Get count.
my $count = $obj->count;

# Get type.
my $type = $obj->type;

# Get year months stats.
my $year_months_ar = $obj->year_months;

# Get users.
my $users_ar = $obj->users;

# Print out.
print "Count: $count\n";
print "Type: $type\n";
print "Number of month/year statistics: ".(scalar @{$year_months_ar})."\n";
print "Number of users: ".(scalar @{$users_ar})."\n";

# Output:
# Count: 10
# Type: Q5
# Number of month/year statistics: 2
# Number of users: 2
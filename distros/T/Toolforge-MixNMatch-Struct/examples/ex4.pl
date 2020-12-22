#!/usr/bin/env perl

use strict;
use warnings;

use Toolforge::MixNMatch::Struct::Catalog qw(struct2obj);

# Time structure.
my $struct_hr = {
        'user' => [{
                'cnt' => 6,
                'uid' => 1,
                'username' => 'Skim',
        }, {
                'cnt' => 4,
                'uid' => 2,
                'username' => 'Foo',
        }],
        'type' => [{
                'cnt' => 10,
                'type' => 'Q5',
        }],
        'ym' => [{
                'cnt' => 2,
                'ym' => 202009,
        }, {
                'cnt' => 8,
                'ym' => 202010,
        }],
};

# Get object.
my $obj = struct2obj($struct_hr);

# Get count.
my $count = $obj->count;

# Get type.
my $type = $obj->type;

# Get user statistics.
my $users_ar = $obj->users;

# Get year/month statistics.
my $year_months_ar = $obj->year_months;

# Print out.
print "Count: $count\n";
print "Type: $type\n";
print "Count of users: ".(scalar @{$users_ar})."\n";
print "Count of year/months: ".(scalar @{$year_months_ar})."\n";

# Output:
# Count: 10
# Type: Q5
# Count of users: 2
# Count of year/months: 2
#!/usr/bin/env perl

use strict;
use warnings;

use Toolforge::MixNMatch::Struct::User qw(struct2obj);

# Time structure.
my $struct_hr = {
       'cnt' => 6,
       'uid' => 1,
       'username' => 'Skim',
};

# Get object.
my $obj = struct2obj($struct_hr);

# Get count.
my $count = $obj->count;

# Get user UID.
my $uid = $obj->uid;

# Get user name.
my $username = $obj->username;

# Print out.
print "Count: $count\n";
print "User UID: $uid\n";
print "User name: $username\n";

# Output:
# Count: 6
# User UID: 1
# User name: Skim
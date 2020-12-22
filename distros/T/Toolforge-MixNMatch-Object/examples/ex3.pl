#!/usr/bin/env perl

use strict;
use warnings;

use Toolforge::MixNMatch::Object::User;

# Object.
my $obj = Toolforge::MixNMatch::Object::User->new(
        'count' => 6,
        'uid' => 1,
        'username' => 'Skim',
);

# Get count for user.
my $count = $obj->count;

# Get UID of user.
my $uid = $obj->uid;

# Get user name.
my $username = $obj->username;

# Print out.
print "Count: $count\n";
print "UID: $uid\n";
print "User name: $username\n";

# Output:
# Count: 6
# UID: 1
# User name: Skim
#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use Toolforge::MixNMatch::Object::User;
use Toolforge::MixNMatch::Print::User;

# Object.
my $obj = Toolforge::MixNMatch::Object::User->new(
        'count' => 6,
        'uid' => 1,
        'username' => 'Skim',
);

# Print.
print Toolforge::MixNMatch::Print::User::print($obj)."\n";

# Output:
# Skim (1): 6
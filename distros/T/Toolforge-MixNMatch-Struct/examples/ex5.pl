#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use Toolforge::MixNMatch::Object::User;
use Toolforge::MixNMatch::Struct::User qw(obj2struct);

# Object.
my $obj = Toolforge::MixNMatch::Object::User->new(
        'count' => 6,
        'uid' => 1,
        'username' => 'Skim',
);

# Get structure.
my $struct_hr = obj2struct($obj);

# Dump to output.
p $struct_hr;

# Output:
# \ {
#     cnt        6,
#     uid        1,
#     username   "Skim"
# }
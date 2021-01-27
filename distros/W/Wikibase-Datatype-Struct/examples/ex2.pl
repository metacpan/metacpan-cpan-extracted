#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use Wikibase::Datatype::Struct::Mediainfo qw(struct2obj);

# Item structure.
my $struct_hr = {
# TODO
};

# Get object.
my $obj = struct2obj($struct_hr);

# Print out.
p $obj;

# Output:
# TODO
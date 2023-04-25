#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use Wikibase::Datatype::Sitelink;
use Wikibase::Datatype::Struct::Sitelink qw(obj2struct);

# Object.
my $obj = Wikibase::Datatype::Sitelink->new(
        'site' => 'enwiki',
        'title' => 'Main page',
);

# Get structure.
my $struct_hr = obj2struct($obj);

# Dump to output.
p $struct_hr;

# Output:
# \ {
#     badges   [],
#     site     "enwiki",
#     title    "Main page"
# }
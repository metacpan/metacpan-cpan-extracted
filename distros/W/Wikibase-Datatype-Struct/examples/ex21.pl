#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use Wikibase::Datatype::Value::String;
use Wikibase::Datatype::Struct::Value::String qw(obj2struct);

# Object.
my $obj = Wikibase::Datatype::Value::String->new(
        'value' => 'foo',
);

# Get structure.
my $struct_hr = obj2struct($obj);

# Dump to output.
p $struct_hr;

# Output:
# \ {
#     type    "string",
#     value   "foo"
# }
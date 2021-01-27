#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use Wikibase::Datatype::Value::Property;
use Wikibase::Datatype::Struct::Value::Property qw(obj2struct);

# Object.
my $obj = Wikibase::Datatype::Value::Property->new(
        'value' => 'P123',
);

# Get structure.
my $struct_hr = obj2struct($obj);

# Dump to output.
p $struct_hr;

# Output:
# \ {
#     type    "wikibase-entityid",
#     value   {
#         entity-type   "property",
#         id            "P123",
#         numeric-id    123
#     }
# }
#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use Wikibase::Datatype::Value::Item;
use Wikibase::Datatype::Struct::Value::Item qw(obj2struct);

# Object.
my $obj = Wikibase::Datatype::Value::Item->new(
        'value' => 'Q123',
);

# Get structure.
my $struct_hr = obj2struct($obj);

# Dump to output.
p $struct_hr;

# Output:
# \ {
#     type    "wikibase-entityid",
#     value   {
#         entity-type   "item",
#         id            "Q123",
#         numeric-id    123
#     }
# }
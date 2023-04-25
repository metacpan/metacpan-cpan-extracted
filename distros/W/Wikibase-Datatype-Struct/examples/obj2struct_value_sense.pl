#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use Wikibase::Datatype::Value::Sense;
use Wikibase::Datatype::Struct::Value::Sense qw(obj2struct);

# Object.
my $obj = Wikibase::Datatype::Value::Sense->new(
        'value' => 'L34727-S1',
);

# Get structure.
my $struct_hr = obj2struct($obj);

# Dump to output.
p $struct_hr;

# Output:
# \ {
#     type    "wikibase-entityid",
#     value   {
#         entity-type   "sense",
#         id            "L34727-S1",
#     }
# }
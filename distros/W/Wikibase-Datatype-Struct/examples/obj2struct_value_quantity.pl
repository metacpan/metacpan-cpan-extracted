#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use Wikibase::Datatype::Value::Quantity;
use Wikibase::Datatype::Struct::Value::Quantity qw(obj2struct);

# Object.
my $obj = Wikibase::Datatype::Value::Quantity->new(
        'unit' => 'Q190900',
        'value' => 10,
);

# Get structure.
my $struct_hr = obj2struct($obj, 'http://test.wikidata.org/entity/');

# Dump to output.
p $struct_hr;

# Output:
# \ {
#     type    "quantity",
#     value   {
#         amount   "+10",
#         unit     "http://test.wikidata.org/entity/Q190900"
#     }
# }
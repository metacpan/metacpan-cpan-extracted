#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use Wikibase::Datatype::Value::Globecoordinate;
use Wikibase::Datatype::Struct::Value::Globecoordinate qw(obj2struct);

# Object.
my $obj = Wikibase::Datatype::Value::Globecoordinate->new(
        'value' => [49.6398383, 18.1484031],
);

# Get structure.
my $struct_hr = obj2struct($obj, 'http://test.wikidata.org/entity/');

# Dump to output.
p $struct_hr;

# Output:
# \ {
#     type    "globecoordinate",
#     value   {
#         altitude    "null",
#         globe       "http://test.wikidata.org/entity/Q2",
#         latitude    49.6398383,
#         longitude   18.1484031,
#         precision   1e-07
#     }
# }
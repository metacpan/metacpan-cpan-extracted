#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use Wikibase::Datatype::Value::Time;
use Wikibase::Datatype::Struct::Value::Time qw(obj2struct);

# Object.
my $obj = Wikibase::Datatype::Value::Time->new(
        'precision' => 10,
        'value' => '+2020-09-01T00:00:00Z',
);

# Get structure.
my $struct_hr = obj2struct($obj, 'http://test.wikidata.org/entity/');

# Dump to output.
p $struct_hr;

# Output:
# \ {
#     type    "time",
#     value   {
#         after           0,
#         before          0,
#         calendarmodel   "http://test.wikidata.org/entity/Q1985727",
#         precision       10,
#         time            "+2020-09-01T00:00:00Z",
#         timezone        0
#     }
# }
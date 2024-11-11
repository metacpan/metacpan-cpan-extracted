#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use Wikibase::Datatype::Value::Lexeme;
use Wikibase::Datatype::Struct::Value::Lexeme qw(obj2struct);

# Object.
my $obj = Wikibase::Datatype::Value::Lexeme->new(
        'value' => 'L42284',
);

# Get structure.
my $struct_hr = obj2struct($obj);

# Dump to output.
p $struct_hr;

# Output:
# \ {
#     type    "wikibase-entityid",
#     value   {
#         entity-type   "lexeme",
#         id            "L42284",
#         numeric-id    42284
#     }
# }
#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use Wikibase::Datatype::Value::Monolingual;
use Wikibase::Datatype::Struct::Value::Monolingual qw(obj2struct);

# Object.
my $obj = Wikibase::Datatype::Value::Monolingual->new(
        'language' => 'en',
        'value' => 'English text',
);

# Get structure.
my $struct_hr = obj2struct($obj);

# Dump to output.
p $struct_hr;

# Output:
# \ {
#     language   "en",
#     value      "English text"
# }
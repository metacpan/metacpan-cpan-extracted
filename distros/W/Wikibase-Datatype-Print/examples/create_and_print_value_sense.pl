#!/usr/bin/env perl

use strict;
use warnings;

use Wikibase::Datatype::Print::Value::Sense;
use Wikibase::Datatype::Value::Sense;

# Object.
my $obj = Wikibase::Datatype::Value::Sense->new(
        'value' => 'L34727-S1',
);

# Print.
print Wikibase::Datatype::Print::Value::Sense::print($obj)."\n";

# Output:
# L34727-S1
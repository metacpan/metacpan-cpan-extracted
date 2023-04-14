#!/usr/bin/env perl

use strict;
use warnings;

use Wikibase::Datatype::Print::Value::Quantity;
use Wikibase::Datatype::Value::Quantity;

# Object.
my $obj = Wikibase::Datatype::Value::Quantity->new(
        'unit' => 'Q190900',
        'value' => 10,
);

# Print.
print Wikibase::Datatype::Print::Value::Quantity::print($obj)."\n";

# Output:
# 10 (Q190900)
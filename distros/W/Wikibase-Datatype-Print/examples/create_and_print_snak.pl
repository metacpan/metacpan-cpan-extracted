#!/usr/bin/env perl

use strict;
use warnings;

use Wikibase::Datatype::Print::Snak;
use Wikibase::Datatype::Snak;
use Wikibase::Datatype::Value::Item;

# Object.
my $obj = Wikibase::Datatype::Snak->new(
        'datatype' => 'wikibase-item',
        'datavalue' => Wikibase::Datatype::Value::Item->new(
                'value' => 'Q5',
        ),
        'property' => 'P31',
);

# Print.
print Wikibase::Datatype::Print::Snak::print($obj)."\n";

# Output:
# P31: Q5
#!/usr/bin/env perl

use strict;
use warnings;

use Wikibase::Datatype::Print::MediainfoSnak;
use Wikibase::Datatype::MediainfoSnak;
use Wikibase::Datatype::Value::Item;

# Object.
my $obj = Wikibase::Datatype::MediainfoSnak->new(
        'datavalue' => Wikibase::Datatype::Value::Item->new(
                'value' => 'Q5',
        ),
        'property' => 'P31',
);

# Print.
print Wikibase::Datatype::Print::MediainfoSnak::print($obj)."\n";

# Output:
# P31: Q5
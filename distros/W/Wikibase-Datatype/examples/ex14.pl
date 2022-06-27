#!/usr/bin/env perl

use strict;
use warnings;

use Wikibase::Datatype::Reference;
use Wikibase::Datatype::Snak;
use Wikibase::Datatype::Value::String;

# Object.
my $obj = Wikibase::Datatype::Reference->new(
        'snaks' => [
                Wikibase::Datatype::Snak->new(
                        'datatype' => 'string',
                        'datavalue' => Wikibase::Datatype::Value::String->new(
                                'value' => 'text',
                        ),
                        'property' => 'P11',
                ),
        ],
);

# Get value.
my $snaks_ar = $obj->snaks;

# Print out number of snaks.
print "Number of snaks: ".@{$snaks_ar}."\n";

# Output:
# Number of snaks: 1
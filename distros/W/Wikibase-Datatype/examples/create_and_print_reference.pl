#!/usr/bin/env perl

use strict;
use warnings;

use Wikibase::Datatype::Reference;
use Wikibase::Datatype::Snak;
use Wikibase::Datatype::Value::String;
use Wikibase::Datatype::Value::Time;

# Object.
my $obj = Wikibase::Datatype::Reference->new(
        'snaks' => [
                Wikibase::Datatype::Snak->new(
                        'datatype' => 'url',
                        'datavalue' => Wikibase::Datatype::Value::String->new(
                                'value' => 'https://skim.cz',
                        ),
                        'property' => 'P854',
                ),
                Wikibase::Datatype::Snak->new(
                        'datatype' => 'time',
                        'datavalue' => Wikibase::Datatype::Value::Time->new(
                                'value' => '+2013-12-07T00:00:00Z',
                        ),
                        'property' => 'P813',
                ),
        ],
);

# Get value.
my $snaks_ar = $obj->snaks;

# Print out number of snaks.
print "Number of snaks: ".@{$snaks_ar}."\n";

# Output:
# Number of snaks: 2
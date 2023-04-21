#!/usr/bin/env perl

use strict;
use warnings;

use Wikibase::Datatype::Print::Reference;
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

# Print.
print Wikibase::Datatype::Print::Reference::print($obj)."\n";

# Output:
# {
#   P854: https://skim.cz
#   P813: 7 December 2013 (Q1985727)
# }
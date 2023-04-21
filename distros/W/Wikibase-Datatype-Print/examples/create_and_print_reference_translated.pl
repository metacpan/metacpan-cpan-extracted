#!/usr/bin/env perl

use strict;
use warnings;

use Wikibase::Cache;
use Wikibase::Cache::Backend::Basic;
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

# Cache.
my $cache = Wikibase::Cache->new(
        'backend' => 'Basic',
);

# Print.
print Wikibase::Datatype::Print::Reference::print($obj, {
        'cache' => $cache,
})."\n";

# Output:
# {
#   P854 (reference URL): https://skim.cz
#   P813 (retrieved): 7 December 2013 (Q1985727)
# }
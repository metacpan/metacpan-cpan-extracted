#!/usr/bin/env perl

use strict;
use warnings;

use Wikibase::Cache;
use Wikibase::Cache::Backend::Basic;
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

# Cache.
my $cache = Wikibase::Cache->new(
        'backend' => 'Basic',
);

# Print.
print Wikibase::Datatype::Print::Snak::print($obj, {
        'cache' => $cache,
})."\n";

# Output:
# P31 (instance of): Q5
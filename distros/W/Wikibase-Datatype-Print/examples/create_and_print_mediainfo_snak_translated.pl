#!/usr/bin/env perl

use strict;
use warnings;

use Wikibase::Cache;
use Wikibase::Cache::Backend::Basic;
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

# Cache.
my $cache = Wikibase::Cache->new(
        'backend' => 'Basic',
);

# Print.
print Wikibase::Datatype::Print::MediainfoSnak::print($obj, {
        'cache' => $cache,
})."\n";

# Output:
# P31 (instance of): Q5
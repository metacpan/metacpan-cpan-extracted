#!/usr/bin/env perl

use strict;
use warnings;

use Wikibase::Cache;
use Wikibase::Cache::Backend::Basic;
use Wikibase::Datatype::Print::Value::Quantity;
use Wikibase::Datatype::Value::Quantity;

# Object.
my $obj = Wikibase::Datatype::Value::Quantity->new(
        'unit' => 'Q11573',
        'value' => 10,
);

# Cache object.
my $cache = Wikibase::Cache->new(
        'backend' => 'Basic',
);

# Print.
print Wikibase::Datatype::Print::Value::Quantity::print($obj, {
        'cb' => $cache,
})."\n";

# Output:
# 10 (metre)
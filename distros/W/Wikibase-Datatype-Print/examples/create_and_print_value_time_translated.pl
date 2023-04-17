#!/usr/bin/env perl

use strict;
use warnings;

use Wikibase::Cache;
use Wikibase::Cache::Backend::Basic;
use Wikibase::Datatype::Print::Value::Time;
use Wikibase::Datatype::Value::Time;

# Object.
my $obj = Wikibase::Datatype::Value::Time->new(
        'precision' => 10,
        'value' => '+2020-09-01T00:00:00Z',
);

# Cache object.
my $cache = Wikibase::Cache->new(
        'backend' => 'Basic',
);

# Print.
print Wikibase::Datatype::Print::Value::Time::print($obj, {
        'cb' => $cache,
})."\n";

# Output:
# 01 September 2020 (proleptic Gregorian calendar)
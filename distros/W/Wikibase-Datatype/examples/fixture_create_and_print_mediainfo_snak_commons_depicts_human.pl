#!/usr/bin/env perl

use strict;
use warnings;

use Test::Shared::Fixture::Wikibase::Datatype::MediainfoSnak::Commons::Depicts::Human;
use Wikibase::Datatype::Print::MediainfoSnak;

# Object.
my $obj = Test::Shared::Fixture::Wikibase::Datatype::MediainfoSnak::Commons::Depicts::Human->new;

# Print out.
print scalar Wikibase::Datatype::Print::MediainfoSnak::print($obj);

# Output:
# P180: Q42
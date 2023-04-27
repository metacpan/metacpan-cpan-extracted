#!/usr/bin/env perl

use strict;
use warnings;

use Test::Shared::Fixture::Wikibase::Datatype::Property::Wikidata::InstanceOf;
use Wikibase::Datatype::Print::Property;

# Object.
my $obj = Test::Shared::Fixture::Wikibase::Datatype::Property::Wikidata::InstanceOf->new;

# Print out.
print scalar Wikibase::Datatype::Print::Property::print($obj);

# Output:
# Data type: wikibase-item
# Label: instance of (en)
# Description: that class of which this subject is a particular example and member (en)
# Aliases:
#   is a (en)
#   is an (en)
# Statements:
#   P31: Q32753077 (normal)
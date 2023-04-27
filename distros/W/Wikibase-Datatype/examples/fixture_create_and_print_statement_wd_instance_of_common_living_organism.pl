#!/usr/bin/env perl

use strict;
use warnings;

use Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::InstanceOf::CommonLivingOrganism;
use Wikibase::Datatype::Print::Statement;

# Object.
my $obj = Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::InstanceOf::CommonLivingOrganism->new;

# Print out.
print scalar Wikibase::Datatype::Print::Statement::print($obj);

# Output:
# P31: Q55983715 (normal)
#  P642: Q20717272
#  P642: Q26972265
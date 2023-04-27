#!/usr/bin/env perl

use strict;
use warnings;

use Test::Shared::Fixture::Wikibase::Datatype::MediainfoStatement::Commons::Depicts::Human;
use Wikibase::Datatype::Print::MediainfoStatement;

# Object.
my $obj = Test::Shared::Fixture::Wikibase::Datatype::MediainfoStatement::Commons::Depicts::Human->new;

# Print out.
print scalar Wikibase::Datatype::Print::MediainfoStatement::print($obj);

# Output:
# P180: Q42 (normal)
#!/usr/bin/env perl

use strict;
use warnings;

use Wikibase::Cache::Backend::Basic;

my $obj = Wikibase::Cache::Backend::Basic->new;

# Print out.
print 'P31 label: '.$obj->get('label', 'P31')."\n";
print 'P31 description: '.$obj->get('description', 'P31')."\n";

# Output:
# TODO
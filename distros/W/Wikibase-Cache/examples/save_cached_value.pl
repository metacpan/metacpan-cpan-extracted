#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure qw(err);
use Wikibase::Cache;

$Error::Pure::TYPE = 'Error';

# Object.
my $obj = Wikibase::Cache->new;

# Save label for 'Q42'.
$obj->save('label', 'Q42', 'Douglas Adams');

# Get translated QID.
my $translated_qid = $obj->get('label', 'Q42');

# Print out.
print $translated_qid."\n";

# Output:
# #Error [../Wikibase/Cache/Backend/Basic.pm:60] Wikibase::Cache::Backend::Basic doesn't implement save() method.
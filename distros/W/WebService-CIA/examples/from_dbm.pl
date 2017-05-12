use strict;
use warnings;

use WebService::CIA;
use WebService::CIA::Source::DBM;

# Get data from a pre-compiled DBM file
# The webservice-cia-makedbm.pl script can make such a DBM
# for you

my $source = WebService::CIA::Source::DBM->new({ DBM => "factbook.dbm" });


# Create the WebService::CIA object, and tell it to use the
# DBM source

my $cia = WebService::CIA->new({ Source => $source });


# Get your data

my $fact = $cia->get("uk", "Population");
print $fact;


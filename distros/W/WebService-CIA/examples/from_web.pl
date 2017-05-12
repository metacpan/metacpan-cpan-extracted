use strict;
use warnings;

use WebService::CIA;
use WebService::CIA::Source::Web;

# Get data straight from the CIA Factbook web site
# Good for one-off fetches, testing, etc.

my $source = WebService::CIA::Source::Web->new();


# Create the WebService::CIA object, and tell it to use the
# DBM source

my $cia = WebService::CIA->new({ Source => $source });


# Get your data

my $fact = $cia->get("uk", "Population");
print $fact;


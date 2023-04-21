#!/usr/bin/env perl

use strict;
use warnings;

use Wikibase::Datatype::Utils qw(check_datetime);

my $self = {
        'key' => '+0134-11-00T00:00:00Z',
        'precision' => 10
};
check_datetime($self, 'key');

# Print out.
print "ok\n";

# Output:
# ok
#!/usr/bin/env perl

use strict;
use warnings;

use Wikibase::Datatype::Utils qw(check_sense);

my $self = {
        'key' => 'L34727-S1',
};
check_sense($self, 'key');

# Print out.
print "ok\n";

# Output:
# ok
#!/usr/bin/env perl

use strict;
use warnings;

use Wikibase::Datatype::Utils qw(check_property);

my $self = {
        'key' => 'P123',
};
check_property($self, 'key');

# Print out.
print "ok\n";

# Output:
# ok
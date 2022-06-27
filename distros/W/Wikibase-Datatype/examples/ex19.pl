#!/usr/bin/env perl

use strict;
use warnings;

use Wikibase::Datatype::Utils qw(check_entity);

my $self = {
        'key' => 'Q123',
};
check_entity($self, 'key');

# Print out.
print "ok\n";

# Output:
# ok
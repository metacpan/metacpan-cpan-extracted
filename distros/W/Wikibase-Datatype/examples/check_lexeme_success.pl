#!/usr/bin/env perl

use strict;
use warnings;

use Wikibase::Datatype::Utils qw(check_lexeme);

my $self = {
        'key' => 'L123',
};
check_lexeme($self, 'key');

# Print out.
print "ok\n";

# Output:
# ok
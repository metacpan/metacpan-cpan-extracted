#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure;
use Wikibase::Datatype::Utils qw(check_lexeme);

$Error::Pure::TYPE = 'Error';

my $self = {
        'key' => 'bad_entity',
};
check_lexeme($self, 'key');

# Print out.
print "ok\n";

# Output like:
# #Error [/../Wikibase/Datatype/Utils.pm:?] Parameter 'key' must begin with 'L' and number after it.
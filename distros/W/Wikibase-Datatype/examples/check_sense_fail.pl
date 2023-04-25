#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure;
use Wikibase::Datatype::Utils qw(check_sense);

$Error::Pure::TYPE = 'Error';

my $self = {
        'key' => 'bad_sense',
};
check_sense($self, 'key');

# Print out.
print "ok\n";

# Output like:
# #Error [/../Wikibase/Datatype/Utils.pm:?] Parameter 'key' must begin with 'L' and number, dash, S and number after it.
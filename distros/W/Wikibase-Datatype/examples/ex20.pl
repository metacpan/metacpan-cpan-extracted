#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure;
use Wikibase::Datatype::Utils qw(check_property);

$Error::Pure::TYPE = 'Error';

my $self = {
        'key' => 'bad_property',
};
check_property($self, 'key');

# Print out.
print "ok\n";

# Output like:
# #Error [/../Wikibase/Datatype/Utils.pm:?] Parameter 'key' must begin with 'P' and number after it.
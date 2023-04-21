#!/usr/bin/env perl

use strict;
use warnings;

use Wikibase::Datatype::Utils qw(check_datetime);

$Error::Pure::TYPE = 'Error';

my $self = {
        'key' => '+0134-34-00T00:01:00Z',
};
check_datetime($self, 'key');

# Print out.
print "ok\n";

# Output:
# #Error [/../Wikibase/Datatype/Utils.pm:?] Parameter 'key' has bad date time month value.
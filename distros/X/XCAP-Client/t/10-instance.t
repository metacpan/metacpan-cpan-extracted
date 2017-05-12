#!/usr/bin/perl 

use strict;
use warnings;

use Test::More qw(no_plan);

use XCAP::Client;

BEGIN {
	use_ok ('XCAP::Client');
}

ok(ref (my $conn = XCAP::Client->new) eq 'XCAP::Client');

1;


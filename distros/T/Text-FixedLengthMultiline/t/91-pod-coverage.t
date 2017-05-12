#!perl
use strict;
use warnings;
use Test::More ($ENV{RELEASE_TESTING} ? ()
				      : (skip_all => 'only for release Kwalitee'));

use Test::Pod::Coverage;
all_pod_coverage_ok({
    coverage_class => 'Pod::Coverage::CountParents',
    also_private => [ qr/^RE_/ ],
});

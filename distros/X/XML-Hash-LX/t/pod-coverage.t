#!/usr/bin/env perl -w

use strict;
use Test::More;
eval "use Test::Pod::Coverage 1.08; use Pod::Coverage 0.18; 1"
	or diag($@),
	plan skip_all => "Test::Pod::Coverage 1.08 and Pod::Coverage 0.18 required for testing POD coverage";

all_pod_coverage_ok();
exit 0;
require Test::Pod::Coverage; # hack for kwalitee
require Test::NoWarnings;
__END__
print "1..1\n";
print "ok 1 - No coverage yet\n";

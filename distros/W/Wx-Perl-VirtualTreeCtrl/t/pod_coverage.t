#!/usr/local/bin/perl

use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD Coverage" if $@;
# Ignore all caps (e.g. Log::Trace stubs) and methods already documented by
# wxWidgets
all_pod_coverage_ok({
	also_private => [ qr/^[A-Z_]+$/],
	trustme => [ qr/AddRoot/ ],
});

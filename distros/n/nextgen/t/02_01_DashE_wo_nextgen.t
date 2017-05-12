#!/usr/bin/env perl
use Test::More tests => 2;

BEGIN
{
	use_ok( 'nextgen' ) or exit;
	nextgen->import();
}

eval { Class->new };
like (
	$@
	, qr/Can't locate object method "new" via package "Class"/
	, "No source oose.pm source filter on real for $0"
);


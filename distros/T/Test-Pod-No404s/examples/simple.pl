#!/usr/bin/perl
#
# This file is part of Test-Pod-No404s
#
# This software is copyright (c) 2014 by Apocalypse.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict; use warnings;
use strict; use warnings;

use Test::More;

eval "use Test::Pod::No404s";
if ( $@ ) {
	plan skip_all => 'Test::Pod::No404s required for testing POD';
} else {
	all_pod_files_ok();
}

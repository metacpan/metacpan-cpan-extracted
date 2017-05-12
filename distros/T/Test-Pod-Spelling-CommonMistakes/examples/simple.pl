#!/usr/bin/perl
#
# This file is part of Test-Pod-Spelling-CommonMistakes
#
# This software is copyright (c) 2014 by Apocalypse.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict; use warnings;

use Test::More;

eval "use Test::Pod::Spelling::CommonMistakes";
if ( $@ ) {
	plan skip_all => 'Test::Pod::Spelling::CommonMistakes required for testing POD';
} else {
	all_pod_files_ok();
}

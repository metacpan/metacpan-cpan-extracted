#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

# -------------

eval 'use Test::CPAN::Changes';

plan skip_all => 'Test::CPAN::Changes required for this test' if $@;

# Warning: Because of the 'eval' above the '()' are mandatory if using changes_ok().

changes_ok();

done_testing();

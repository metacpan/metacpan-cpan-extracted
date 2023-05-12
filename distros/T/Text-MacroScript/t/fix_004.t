#!/usr/bin/perl

# Copyright (c) 2015 Paulo Custodio. All Rights Reserved.
# May be used/distributed under the GPL.

use strict;
use warnings;
use Test::More;

my $ms;
use_ok 'Text::MacroScript';
require_ok 't/mytests.pl';

$ms = new_ok('Text::MacroScript');
eval {$ms->undefine_all()};
check_error(__LINE__-1, $@, " method not supported __LOC__.\n");
eval {$ms->undefine_all(-xxx)};
check_error(__LINE__-1, $@, "-xxx method not supported __LOC__.\n");

done_testing;

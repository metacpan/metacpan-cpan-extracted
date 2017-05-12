#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/dynamic3';

my $warnings;
local $SIG{__WARN__} = sub { $warnings .= $_[0] };
use_ok('Foo');
is($warnings, "Circular require detected:\n  Bar2.pm\n  Bar3.pm\n  Bar2.pm\n", "correct warnings");

done_testing;

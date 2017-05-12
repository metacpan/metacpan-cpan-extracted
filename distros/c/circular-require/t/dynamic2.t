#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/dynamic2';

my $warnings;
local $SIG{__WARN__} = sub { $warnings .= $_[0] };
use_ok('Foo');
is($warnings, "Circular require detected:\n  Bar.pm\n  Baz.pm\n  Bar.pm\n", "correct warnings");

done_testing;

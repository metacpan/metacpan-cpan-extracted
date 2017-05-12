#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/injection';

no circular::require;

eval "require('Foo; die q[bar]'); 1";
like($@, qr/Can't locate Foo; die q\[bar\] in \@INC/,
     "can't inject extra code via require");

eval 'require(q[Foo$bar])';
like($@, qr/Can't locate Foo\$bar in \@INC/,
     "can't inject extra code via require");

done_testing;

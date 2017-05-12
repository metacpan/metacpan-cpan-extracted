#!/usr/bin/perl -w
use strict;
use warnings;

use Test::Module::Used;

my $used = Test::Module::Used->new(
    exclude_in_testdir => ['Test::Module::Used'],
);
$used->ok;

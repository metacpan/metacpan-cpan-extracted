#!/usr/bin/perl

use strict;
use warnings;

use File::Which qw(which);
use Test::More tests => 1;

BEGIN
{
    BAIL_OUT('OS unsupported') unless which('du');

    use_ok('Tie::DiskUsage');
}

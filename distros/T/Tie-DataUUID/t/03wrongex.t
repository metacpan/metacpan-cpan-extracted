#!/usr/bin/perl

use strict;

use Test::More tests => 1;

eval "use Tie::DataUUID qw(wombles)";
like $@, '/^"wombles" is not exported by the Tie::DataUUID module/', 'wrong exports break';
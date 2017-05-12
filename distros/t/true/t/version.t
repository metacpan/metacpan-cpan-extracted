#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin qw($Bin);
use Test::More tests => 3;

use lib (File::Spec->catdir($Bin, 'lib'));

require_ok 'true::VERSION';

ok $true::VERSION::VERSION, 'true::VERSION exists';
is $true::VERSION, $true::VERSION::VERSION, 'same $VERSION as true';

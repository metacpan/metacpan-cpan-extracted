#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use FindBin qw($Bin);
use lib "$Bin/../lib", "$Bin/lib";

use_ok('LoadRel');
use_ok('VMod');

done_testing();

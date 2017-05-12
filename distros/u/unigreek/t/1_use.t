#!/usr/bin/env perl
use strict;
use utf8;
use warnings;
use Test::More tests => 1;
use FindBin;
use lib "$FindBin::Bin/../lib";

use_ok("UniGreek");

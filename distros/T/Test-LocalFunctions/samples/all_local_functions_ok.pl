#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use 5.012000;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::LocalFunctions;

all_local_functions_ok();

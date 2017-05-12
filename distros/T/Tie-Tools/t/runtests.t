#!/usr/bin/env perl

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib", "$Bin/../t";

use Test::Class::Tie::Parent;

Test::Class->runtests();

#!/usr/bin/perl

# This script can be run from anywhere, disrespecting cwd,
# and always will found Module-No1/lib and Module-No2/lib

use lib::abs '*/lib';
use Module::No1;
use Module::No2;

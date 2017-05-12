#!perl -w
use strict;
use Test::More tests => 2;

use_ok("Unicode::ICU::Collator");
use_ok("Unicode::ICU::Collator", ":constants");

#!perl

use v5.14;
use warnings;

use Test2::Require::AuthorTesting;

use Test2::V0;

eval "use Test::PPPort";

plan skip_all => "Test::PPPort required for testing ppport.h" if $@;
ppport_ok();

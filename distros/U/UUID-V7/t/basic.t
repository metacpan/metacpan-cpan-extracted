#! perl

use strict;
use warnings;

use Test::More;

use UUID::V7 'generate_uuid_v7';

my @unsorted = map { generate_uuid_v7() } 0..999999;
my @sorted = sort @unsorted;

is(join('|', @sorted), join('|', @unsorted), 'UUIDs came in sorted order');

done_testing;

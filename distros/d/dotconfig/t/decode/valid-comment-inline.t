use strict;
use warnings;
use t::Runner;
use Test::More;
use JSON();
use utf8;

run 'valid-comment-inline-01', [ JSON::null, 0xDEADBEEF ];

done_testing;


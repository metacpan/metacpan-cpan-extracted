#!perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

require namespace::local; # not use

throws_ok {
    namespace::local->import( "-foobar" );
} qr/[Uu]nknown.*-foobar/, "descriptive error";

done_testing;

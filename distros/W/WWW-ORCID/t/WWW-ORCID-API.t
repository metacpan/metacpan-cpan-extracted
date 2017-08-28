#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'WWW::ORCID::API';
    use_ok $pkg;
}

done_testing;

#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

BEGIN {
    use_ok 'Test::Regexp', import => [qw [no_match]];
}


ok !defined &match;
ok  defined &no_match;


__END__

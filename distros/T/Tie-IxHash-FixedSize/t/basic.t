#!/usr/bin/env perl

use strict;
use Test::More tests => 6;

use_ok('Tie::IxHash::FixedSize');

tie my %h, 'Tie::IxHash::FixedSize', { size => 3 },
    one   => 1,
    two   => 2,
    three => 3;

is_deeply \%h, {one => 1, two => 2, three => 3};
is keys %h, 3;

$h{four} = 4;
is_deeply \%h, {two => 2, three => 3, four => 4};
is keys %h, 3;

@h{qw/five six seven/} = qw(5 6 7);
is_deeply \%h, {five => 5, six => 6, seven => 7};

# vim: ft=perl

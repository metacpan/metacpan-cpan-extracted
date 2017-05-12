#!/usr/bin/env perl
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

use strict;
use warnings;
use Test::TableDriven (
    hash  => { 1 => '1',
               2 => '2',
             },
    array => [[ 1 => 1 ],
              [ 2 => 2 ],
             ],
);

sub hash  { $_[0] }
sub array { $_[0] }

runtests;

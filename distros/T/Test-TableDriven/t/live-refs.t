#!/usr/bin/env perl
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

use strict;
use warnings;
use Test::TableDriven (
    refs => [[ [qw/1/]          => [qw/1/]         ],
             [ { foo => 'bar' } => { foo => 'bar'} ],
             [ [qw/1 3 5/]      => [qw/1 3 5/]     ],
            ],
);

sub refs { $_[0] }

runtests;

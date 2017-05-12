#!/usr/bin/perl

use strict;
use warnings;

use WWW::StatusBadge::Service;

no warnings 'redefine';

sub common_args {(
        'user'    => 'USER',
        'repo'    => 'REPO',
        'branch'  => 'BRANCH',
        'private' => 1,
);}

sub common_img { 'https://coveralls.io/repos/USER/REPO/badge.png?branch=BRANCH'; }

1;

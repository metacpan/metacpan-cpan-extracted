#!/usr/bin/perl

use strict;
use warnings;

use WWW::StatusBadge::Service;

no warnings 'redefine';

sub common_class { 'WWW::StatusBadge::Service::Coveralls' }

sub common_args {(
        'user'   => 'USER',
        'repo'   => 'REPO',
        'branch' => 'BRANCH',
);}

sub common_txt { 'Coverage Status'; }
sub common_img { 'https://img.shields.io/coveralls/USER/REPO.svg'; }
sub common_url { 'https://coveralls.io/r/USER/REPO?branch=BRANCH'; }

1;

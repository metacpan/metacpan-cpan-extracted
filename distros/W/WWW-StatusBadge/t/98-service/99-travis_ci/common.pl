#!/usr/bin/perl

use strict;
use warnings;

use WWW::StatusBadge::Service;

no warnings 'redefine';

sub common_class { 'WWW::StatusBadge::Service::TravisCI' }

sub common_args {(
        'user' => 'USER',
        'repo' => 'REPO',
);}

sub common_txt { 'Build Status'; }
sub common_img { 'https://travis-ci.org/USER/REPO.svg'; }
sub common_url { 'https://travis-ci.org/USER/REPO'; }

1;

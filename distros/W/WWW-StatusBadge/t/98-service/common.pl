#!/usr/bin/perl

use strict;
use warnings;

use WWW::StatusBadge::Service;

no warnings 'redefine';

sub common_class { 'WWW::StatusBadge::Service' }

sub common_args {(
    'txt' => 'Build Text',
    'img' => 'build.svg',
    'url' => 'http://build.txt',
);}

sub common_txt { my %arg = common_args(); $arg{'txt'}; }
sub common_img { my %arg = common_args(); $arg{'img'}; }
sub common_url { my %arg = common_args(); $arg{'url'}; }

1;

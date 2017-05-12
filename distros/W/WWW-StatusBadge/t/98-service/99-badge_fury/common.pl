#!/usr/bin/perl

use strict;
use warnings;

use WWW::StatusBadge::Service;

no warnings 'redefine';

sub common_class { 'WWW::StatusBadge::Service::BadgeFury' }

sub common_args {(
        'dist' => 'DIST',
        'for'  => common_for(),
);}

sub common_txt { sprintf '%s version', common_name(); }
sub common_img { sprintf 'https://badge.fury.io/%s/DIST.svg', common_for(); }
sub common_url { sprintf 'http://badge.fury.io/%s/DIST', common_for(); }

1;

#!/usr/bin/env perl
use warnings;
use strict;
use Plack::App::File;
use Plack::App::XAO;
use Plack::Builder;

my $site=$ENV{'XAO_SITE_NAME'} ||
    die "\n\nUsage: XAO_SITE_NAME=example plackup xao.psgi\n\n";

builder {
    enable_if { $ENV{'PLACK_ENABLE_DEBUG'} } 'Debug';
    ### enable 'LogWarn';
    ### mount '/images' => Plack::App::File->new(root => '/path/to/images')->to_app();
    mount '/' => Plack::App::XAO->new(site => $site)->to_app();
};

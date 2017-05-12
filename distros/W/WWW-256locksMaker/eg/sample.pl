#!/usr/bin/env perl
use strict;
use warnings;
use File::Spec;
use File::Basename 'dirname';
use lib File::Spec->catfile(dirname(__FILE__), '..', 'lib');
use WWW::256locksMaker;

my $data = WWW::256locksMaker->make('ytnobody');
warn $data->image_url;
warn $data->tweet_link;
$data->image->write(file => '/tmp/ytnobody.png');

#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Web::Request::Upload;

my $upload = Web::Request::Upload->new(
    filename => '/tmp/foo/bar/hoge.txt',
);
is $upload->basename, 'hoge.txt';

done_testing;

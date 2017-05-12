#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 2;
use Test::Pod;
use Test::Pod::Coverage;

use FindBin;
use File::Spec;
use File::Basename qw(dirname);

pod_file_ok(File::Spec -> catfile(dirname($FindBin::RealBin), 'lib/WebService/CDNetworks/Purge.pm'), 'Valid POD file');
pod_coverage_ok('WebService::CDNetworks::Purge');


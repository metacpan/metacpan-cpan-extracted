#!/usr/bin/perl
# $Id: /mirror/youri/soft/Media/trunk/t/pod.t 2315 2007-03-22T13:45:11.684364Z guillomovitch  $

use strict;
use warnings;
use Test::More;

eval "use Test::Pod 1.14";
plan(skip_all => 'Test::Pod >= 1.14 required, skipping') if $@;

all_pod_files_ok();

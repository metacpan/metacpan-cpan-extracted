#-*- perl -*-
#-*- coding: utf-8 -*-

use strict;
use Test::More;
BEGIN { eval 'use Test::Pod 1.00'; }
plan skip_all => 'Test::Pod 1.00 or later required for testing POD'
    unless $Test::Pod::VERSION;

all_pod_files_ok();

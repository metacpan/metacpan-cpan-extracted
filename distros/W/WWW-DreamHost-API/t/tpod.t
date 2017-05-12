#!/usr/bin/env perl -w

# $Id: tpod.t 8 2009-10-18 11:43:13Z stro $

use strict;
use warnings;

eval 'use Test::More';
if ($@) {
    eval 'use Test; plan tests => 1;';
    skip('Test::More is required for testing POD',);
} else {
    require Test::More;
    eval 'use Test::Pod 1.00';
    plan ('skip_all' => 'Test::Pod is required for testing POD') if $@;
    my @poddirs = qw( blib script );
    all_pod_files_ok( all_pod_files( @poddirs ) );
}
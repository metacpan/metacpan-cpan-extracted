#!/usr/bin/env perl
use strict;
use warnings;
use Web::Library::Test qw(:all);
use Test::More;
for my $version (qw(3.3.3 3.3.12)) {
    library_ok(
        name              => 'D3',
        version           => $version,
        css_assets        => [],
        javascript_assets => ['/js/d3.min.js'],
    );
    get_manager()->reset;
}
done_testing;

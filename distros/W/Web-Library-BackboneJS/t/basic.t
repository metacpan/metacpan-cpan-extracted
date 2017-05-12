#!/usr/bin/env perl
use strict;
use warnings;
use Web::Library::Test qw(:all);
use Test::More;
for my $version (qw(1.0.0 1.1.0)) {
    library_ok(
        name              => 'BackboneJS',
        version           => $version,
        css_assets        => [],
        javascript_assets => ['/js/backbone-min.js']
    );
    get_manager()->reset;
}
done_testing;

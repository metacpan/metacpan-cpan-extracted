#!/usr/bin/env perl
use strict;
use warnings;
use Web::Library::Test qw(:all);
use Test::More;
for my $version (qw(1.4.4 1.5.0 1.5.1 1.5.2)) {
    library_ok(
        name              => 'UnderscoreJS',
        version           => $version,
        css_assets        => [],
        javascript_assets => ['/js/underscore-min.js']
    );
    get_manager()->reset;
}
done_testing;

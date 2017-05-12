#!/usr/bin/env perl
use strict;
use warnings;
use Web::Library::Test qw(:all);
use Test::More;
for my $version (qw(1.9.1 1.10.1 1.10.2 2.0.0 2.0.2 2.0.3)) {
    library_ok(
        name              => 'jQuery',
        version           => $version,
        css_assets        => [],
        javascript_assets => ['/js/jquery.min.js']
    );
    get_manager()->reset;
}
done_testing;

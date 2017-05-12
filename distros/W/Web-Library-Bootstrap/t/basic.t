#!/usr/bin/env perl
use strict;
use warnings;
use Web::Library::Test qw(:all);
use Test::More;
for my $version (qw(2.3.0 2.3.1 2.3.2 3.0.3)) {
    library_ok(
        name              => 'Bootstrap',
        version           => $version,
        css_assets        => ['/css/bootstrap.min.css'],
        javascript_assets => ['/js/bootstrap.min.js'],
    );
    get_manager()->reset;
}
done_testing;

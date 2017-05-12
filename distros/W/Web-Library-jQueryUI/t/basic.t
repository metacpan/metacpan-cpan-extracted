#!/usr/bin/env perl
use strict;
use warnings;
use Web::Library::Test qw(:all);
use Test::More;
for my $version (qw(1.10.2 1.10.3)) {
    library_ok(
        name              => 'jQueryUI',
        version           => $version,
        css_assets        => ['/css/jquery-ui.min.css'],
        javascript_assets => ['/js/jquery-ui.min.js']
    );
    get_manager()->reset;
}
done_testing;

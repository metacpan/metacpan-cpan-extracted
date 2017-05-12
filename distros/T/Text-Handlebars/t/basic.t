#!/usr/bin/env perl
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Test::Handlebars;

render_ok(
    'Hello, {{dialect}} world!',
    { dialect => 'Handlebars' },
    'Hello, Handlebars world!',
    "basic test"
);

done_testing;

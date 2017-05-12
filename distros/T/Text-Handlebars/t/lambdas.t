#!/usr/bin/env perl
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Test::Handlebars;

render_ok(
    '{{foo.bar.baz}} / {{{foo.bar.baz}}}',
    { foo => { bar => { baz => sub { '<BAZ>' } } } },
    '&lt;BAZ&gt; / <BAZ>',
    "lambdas with field access"
);

done_testing;

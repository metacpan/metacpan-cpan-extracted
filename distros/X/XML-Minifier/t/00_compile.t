use strict;
use warnings;

use Test::More 0.98;

use_ok $_ for qw(
    XML::Minifier
);

use XML::Minifier;

is(minify("<tag/>"), minify("<tag/>"), "Test import by default");

# Test resiliency to empty or undefined parameter
is(minify(""), minify(""), "Test call with empty string");
is(minify(qw//), minify(qw//), "Test call with empty string");
is(minify("<tag/>"), minify("<tag/>"), "Test call with one tag");
is(minify(undef), minify(undef), "Test call with undefined string");

done_testing;


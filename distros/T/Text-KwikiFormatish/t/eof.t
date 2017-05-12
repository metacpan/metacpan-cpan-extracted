#!perl -w

use Test::More;

my @tests = (
    [ "heading, no trailing newline",
        "=== this is a heading", "<h3>this is a heading</h3>\n" ],
    [   "bullets, no trailing newline", "* no newline\n* at the end",
        "<ul>\n<li>no newline\n</li><li>at the end\n</li></ul>\n"
    ],
);

plan tests => (@tests * 2) + 1;

use_ok('Text::KwikiFormatish');

foreach my $test (@tests) {
    my ( $name, $in, $expected ) = @$test;
    my $got = eval { Text::KwikiFormatish::format($in) };
    is( $@, q{}, "$name, no error" );
    is( $got, $expected, "$name, output" );
}


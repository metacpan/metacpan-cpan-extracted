use strict;
use warnings;

use Test::More;

use URI::Builder;

my @cases;
BEGIN {
    @cases = (
        {
            args => {
                uri => 'http://localhost',
            },
            expect => 'http://localhost',
        }, {
            args => {
                uri => URI->new('http://localhost'),
            },
            expect => 'http://localhost',
        }, {
            args => {
                uri => 'http://localhost:80',
            },
            expect => 'http://localhost',
        }, {
            args => {
                uri => URI->new('http://localhost:80'),
            },
            expect => 'http://localhost',
        }, {
            # host-only. Scheme-relative
            args => {
                host => 'localhost',
            },
            expect => '//localhost',
        }, {
            # host + scheme
            args => {
                host   => 'localhost',
                scheme => 'https',
            },
            expect => 'https://localhost',
        }, {
            # unusual port
            args => {
                host   => 'localhost',
                scheme => 'https',
                port   => 5443
            },
            expect => 'https://localhost:5443',
        }, {
            args => {
                host   => 'localhost',
                scheme => 'https',
                userinfo => 'mattlaw:mysupersafepassword',
            },
            expect => 'https://mattlaw:mysupersafepassword@localhost',
        }, {
            args => {
                path => 'one'
            },
            expect => 'one',
        }, {
            args => {
                path => '/one///'
            },
            expect => '/one///',
        }, {
            args => {
                path_segments => [ 'one', 'two' ],
            },
            expect => 'one/two',
        }, {
            args => {
                path_segments => [ '', 'one', 'two' ],
            },
            expect => '/one/two',
        }, {
            args => {
                path => 'one',
                host => 'localhost',
                scheme => 'http',
            },
            expect => 'http://localhost/one',
        }, {
            args => {
                path => '/one',
                host => 'localhost',
                scheme => 'http',
            },
            expect => 'http://localhost/one',
        }, {
            args => {
                path_segments => [ 'one', 'two' ],
                host => 'localhost',
                scheme => 'http',
            },
            expect => 'http://localhost/one/two',
        }, {
            args => {
                path_segments => [ '', 'one', 'two' ],
                host => 'localhost',
                scheme => 'http',
            },
            expect => 'http://localhost/one/two',
        }, {
            args => {
                query_form => [ foo => 1, bar => 2, baz => 3 ],
            },
            expect => '?foo=1;bar=2;baz=3',
        }, {
            args => {
                query_keywords => [qw( a b c )],
            },
            expect => '?a+b+c',
        }, {
            args => {
                query_keywords => [qw( a b c )],
                query_form => [ foo => 1, bar => 2, baz => 3 ],
            },
            expect => '?foo=1;bar=2;baz=3',
        }, {
            args => {
                query_keywords => 'foo',
            },
            expect => '?foo',
        }, {
            args => {
                query_keywords => 'foo',
                host => 'localhost',
            },
            expect => '//localhost?foo',
        }, {
            args => {
                query_keywords => 'foo',
                host => 'localhost',
                path => '/',
            },
            expect => '//localhost/?foo',
        }, {
            args => {
                query_keywords => 'foo',
                host => 'localhost',
                path_segments => [qw( one two three )],
            },
            expect => '//localhost/one/two/three?foo',
        }, {
            args => {
                # one pair only to avoid relying on hash order
                query_form => { a => "b" },
            },
            expect => '?a=b',
        }
    );

    plan tests => @cases + 0;
}

for my $case (@cases) {
    is( URI::Builder->new(%{$case->{args}})->as_string, $case->{expect} );
}

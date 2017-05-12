use strict;
use warnings;
use utf8;
use Test::More;
use URL::Builder;

my @CASES = (
    +{
        base_uri => 'http://example.com/',
        path => '/foo/bar',
    } => 'http://example.com/foo/bar',

    +{
        base_uri => 'http://example.com',
        path => '/foo/bar',
    } => 'http://example.com/foo/bar',

    +{
        base_uri => 'http://example.com',
        path => '/foo/bar',
        query => [a => 'b', a => 'c'],
    } => 'http://example.com/foo/bar?a=b&a=c',

    +{
        base_uri => 'http://example.com',
        path => '/foo/bar',
        query => +{a => 'b'},
    } => 'http://example.com/foo/bar?a=b',

    +{
        path => '/foo/bar',
        query => [a => 'b', c => 'd'],
    } => '/foo/bar?a=b&c=d',

    +{
        path => './foo/bar',
        query => [a => 'b', c => 'd'],
    } => './foo/bar?a=b&c=d',

    +{
        path => './foo/bar',
        query => [a => 'にほんご'],
    } => './foo/bar?a=%E3%81%AB%E3%81%BB%E3%82%93%E3%81%94',

    +{
        path => './foo/bar',
        query => {a => 'にほんご'},
    } => './foo/bar?a=%E3%81%AB%E3%81%BB%E3%82%93%E3%81%94',

    +{
        path => './foo/bar',
        query => [a => "\xE5", b => "\x{263A}"],
    } => './foo/bar?a=%C3%A5&b=%E2%98%BA',


);

while (my ($k, $v) = splice @CASES, 0, 2) {
    is build_url_utf8(%$k), $v;
}

done_testing;


#!/usr/bin/perl
use 5.016;
use strict;

use Test::More;

use File::Spec;

use WWW::Noss::Util qw(dir resolve_url);

my $TESDIR = File::Spec->catfile(qw/t data dir/);

my @TEST_URLS = (
    [ [ '/test', 'https://example.com/home' ] => 'https://example.com/test' ],
    [ [ '//test.com', 'https://example.com/home' ] => 'https://test.com' ],
    [ [ 'test', 'https://example.com/home' ] => 'https://example.com/test' ],
    [ [ './test', 'https://example.com/home' ] => 'https://example.com/test' ],
);

is_deeply(
    [ dir($TESDIR) ],
    [ map { File::Spec->catfile($TESDIR, $_) } qw(a.txt b.txt c.txt) ],
    'dir ok'
);

is_deeply(
    [ dir($TESDIR, hidden => 1) ],
    [ map { File::Spec->catfile($TESDIR, $_) } qw(.hidden.txt a.txt b.txt c.txt) ],
    'dir(hidden => 1) ok'
);

for my $t (@TEST_URLS) {
    my $res = resolve_url(@{ $t->[0] });
    is($res, $t->[1], 'resolve_url ok');
}

done_testing;

# vim: expandtab shiftwidth=4

use strict;
use warnings;

use Test::More;
use Text::Gitignore qw(build_gitignore_matcher);

my $matcher = build_gitignore_matcher(['f*', '!foo*', 'foobar']);

subtest 'matched' => sub {
    my $matched = $matcher->('foobar');
    ok $matched;
};

subtest 'unmatched' => sub {
    my $matched = $matcher->('bar');
    ok ! defined($matched);
};

subtest 'excluded' => sub {
    my $matched = $matcher->('foolish');
    ok defined($matched) && !$matched;
};

done_testing;

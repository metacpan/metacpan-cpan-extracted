use warnings;
use strict;

# Tests in this file are solely for coverage purposes

use Test::More;

BEGIN {
    if (! $ENV{RELEASE_TESTING} && ! $ENV{WORD_RHYMES_MOCK}) {
        plan skip_all => "RELEASE_TESTING or WORD_RHYMES_MOCK env var not set";
    }
}

use Mock::Sub no_warnings => 1;
use Word::Rhymes;
use LWP::UserAgent;

my $o = Word::Rhymes->new;
my $m = Mock::Sub->new;

my $request_sub = $m->mock(
    'LWP::UserAgent::request',
    return_value => 99
);
my $ret = eval { $o->fetch('zoo'); 1 };
is $request_sub->called, 1, "request() called ok";
is $ret, undef, "mock of request() ok";

$request_sub->unmock;

my $is_success_sub = $m->mock(
    'HTTP::Response::is_success',
    return_value => 0
);

$ret = $o->fetch('zoo');
is $is_success_sub->called, 1, "is_success() called ok";
is $ret, undef, "mock of is_success() ok";

done_testing();


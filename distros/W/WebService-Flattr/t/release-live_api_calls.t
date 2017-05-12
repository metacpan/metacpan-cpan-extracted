#!perl

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}


use strict;
use warnings;

# +1 for Test::NoWarnings
use Test::More tests => 34 + 1;
use Test::NoWarnings;
use WebService::Flattr ();

my $flattr = WebService::Flattr->new();

{
    # This will fail if the "flattr" user does not have any publicly
    # viewable flattrs.
    my $result = $flattr->user_flattrs({
        username => 'flattr',
    })->data;
    isa_ok $result, 'ARRAY', 'Expected result structure';
    is $result->[0]{type}, 'flattr', 'Expected result type';
    isa_ok $result->[0]{thing}, 'HASH', 'Expected result thing structure';
}

{
    # This will fail if the thing has less than 1 flattr
    my $result = $flattr->thing_flattrs({
        id => 189147,
    })->data;
    isa_ok $result, 'ARRAY', 'Expected result structure';
    is $result->[0]{type}, 'flattr', 'Expected result type';
    isa_ok $result->[0]{thing}, 'HASH', 'Expected result thing structure';
}

{
    # This will fail if the user "flattr" owns less than 3 things
    my $result = $flattr->things_owned_by({
        username => 'flattr',
        count => 3,
    })->data;
    isa_ok $result, 'ARRAY', 'Expected result structure';
    is @$result, 3, 'Expected number of results';
    is $result->[0]{type}, 'thing', 'Expected result type';
    is $result->[0]{owner}{username}, 'flattr', 'Expected username';
}

{
    # This will fail if the thing with ID 123 goes away
    my $response = $flattr->get_thing(123);
    my $result = $response->data;
    isa_ok $result, 'HASH', 'Expected result structure';
    is $result->{type}, 'thing', 'Expected result type';
    is $result->{id}, 123, 'Expected ID';

    # Test rate limiting from a WebService::Flattr::Response object
    cmp_ok $response->rate_limit, '>', 10, 'Non miserly hourly limit';
    cmp_ok $response->limit_reset, '>', 1360678568, 'Sane timestamp';
    like $response->rate_limit, qr/\A[0-9]+\z/, 'Numeric rate limit';
    like $response->limit_remaining, qr/\A[0-9]+\z/, 'Numeric remaining';
    like $response->limit_reset, qr/\A[0-9]+\z/, 'Numeric reset time';
}

{
    # This will fail if the requested things leave Flattr's directory
    my $result = $flattr->get_things(10, 101, 1002)->data;
    isa_ok $result, 'ARRAY', 'Expected result structure';
    is @$result, 3, 'Expected number of results';
    is $result->[0]{type}, 'thing', 'Expected first result type';
    is $result->[0]{id}, 10, 'Expected first result ID';
    is $result->[1]{id}, 101, 'Expected second result ID';
    is $result->[2]{id}, 1002, 'Expected third result ID';
}

{
    # This will fail if the requested URL leaves Flattr's directory
    my $result = $flattr->thing_exists('http://f-droid.org/')->data;
    isa_ok $result, 'HASH', 'Expected result structure';
    is $result->{message}, 'found', 'Expected result message';
    like $result->{location}, qr/^http/, 'Expected location type';
}

{
    # Test the rate_limit() call
    my $result = $flattr->rate_limit->data;
    isa_ok $result, 'HASH', 'Expected result structure';
    cmp_ok $result->{hourly_limit}, '>', 10, 'Non miserly hourly limit';
    # This will fail if the rate limits reset while this script runs
    cmp_ok $result->{current_hits}, '>', 6, 'We already made requests';
}

{
    my $result = $flattr->search_things({ tags => 'perl' })->data;
    isa_ok $result, 'HASH', 'Expected result structure';
    my $things = $result->{things};
    isa_ok $things, 'ARRAY', 'Results in an array';
    # These will fail if nothing exists tagged "perl"
    like $things->[0]{id}, qr/^\d+$/, 'First result has a numeric ID';
    my %tag;
    $tag{$_} = 1 foreach @{ $things->[0]{tags} };
    ok exists $tag{perl}, 'Searching for things tagged perl works';
}

# TODO:
# - user
# - user_activities
# - categories
# - languages

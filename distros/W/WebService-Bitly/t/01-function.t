package Test::Function;
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::WebService::Bitly;
use Test::WebService::Bitly::Mock::UserAgent;
use Test::More;
use Test::Exception;
use Path::Class qw(file);
use JSON;

use WebService::Bitly;

use base qw(Test::Class Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw( args ));

sub api_input : Test(startup) {
    my $self = shift;

    my $user_name    = 'test_user';
    my $user_api_key = 'test_key';

    $self->{args} = {
        user_name         => $user_name,
        user_api_key      => $user_api_key,
        end_user_name     => $user_name,
        end_user_api_key  => $user_api_key,
        ua                => Test::WebService::Bitly::Mock::UserAgent->new,
    };
}

sub test_010_instance : Test(8) {
    my $self = shift;
    my $args = $self->args;

    ok my $bitly = WebService::Bitly->new(
        %$args,
        domain  => 'j.mp',
        version => 'v3',
    );

    isa_ok $bitly, 'WebService::Bitly', 'is correct object';
    is $bitly->user_name, $args->{user_name}, 'can get correct user_name';
    is $bitly->user_api_key, $args->{user_api_key}, 'can get correct user_api_key';
    is $bitly->end_user_name, $args->{end_user_name}, 'can get correct end_user_name';
    is $bitly->end_user_api_key, $args->{end_user_api_key}, 'can get correct end_user_api_key';
    is $bitly->domain, 'j.mp', 'can get correct domain';
    is $bitly->version, 'v3', 'can get correct version';
}

sub test_011_shorten : Test(10) {
    my $self = shift;
    my $args = $self->args;

    ok my $bitly = WebService::Bitly->new(%$args);

    dies_ok(sub{$bitly->shorten}, 'should die');

    ok my $result_shorten = $bitly->shorten('http://betaworks.com/');

    isa_ok $result_shorten, 'WebService::Bitly::Result::Shorten', 'is correct object';
    ok !$result_shorten->is_error, 'not http error';
    is $result_shorten->short_url, 'http://bit.ly/cmeH01', 'can get correct short_url';
    is $result_shorten->hash, 'cmeH01', 'can get correct hash';
    is $result_shorten->global_hash, '1YKMfY', 'can get correct gobal hash';
    is $result_shorten->long_url, 'http://betaworks.com/', 'can get correct long url';
    is $result_shorten->is_new_hash, 0, 'can get correct new hash';
}

sub test_012_set_end_user_info : Test(7) {
    my $self = shift;
    my $args = $self->args;

    ok my $bitly = WebService::Bitly->new(
        user_name => $args->{user_name},
        user_api_key => $args->{user_api_key},
    );

    dies_ok( sub {$bitly->set_user_info}, 'wrong parameter');
    dies_ok( sub {$bitly->set_user_info('', 'key')}, 'wrong parameter');
    dies_ok( sub {$bitly->set_user_info('user', '')}, 'wrong parameter');

    ok $bitly->set_end_user_info($args->{end_user_name}, $args->{end_user_api_key});
    is $bitly->end_user_name, $args->{end_user_name};
    is $bitly->end_user_api_key, $args->{end_user_api_key};
}

sub test_013_validate : Test(4) {
    my $self = shift;
    my $args = $self->args;

    ok my $bitly = WebService::Bitly->new(%$args);
    ok my $validate_result = $bitly->validate;
    isa_ok $validate_result, 'WebService::Bitly::Result::Validate', 'is correct object';
    ok $validate_result->is_valid;
}

sub test_014_expand : Test(10) {
    my $self = shift;
    my $args = $self->args;

    ok my $bitly = WebService::Bitly->new(%$args);

    dies_ok( sub {$bitly->expand}, 'wrong parameter');

    ok my $result_expand = $bitly->expand(
        short_urls => ['http://tcrn.ch/a4MSUH'],
        hashes     => ['a35.'],
    );
    isa_ok $result_expand, 'WebService::Bitly::Result::Expand', 'is correct object';
    ok !$result_expand->is_error;

    my @expand_list = $result_expand->results;

    is $expand_list[0]->short_url, 'http://tcrn.ch/a4MSUH', 'correct short_url';
    is $expand_list[0]->global_hash, 'bWw49z', 'correct global_hash';
    is $expand_list[0]->long_url, 'http://www.techcrunch.com/2010/01/29/windows-mobile-foursquare/', 'correct long_url';
    is $expand_list[0]->user_hash, 'a4MSUH', 'correct user_hash';

    ok $expand_list[1]->is_error, 'error should occur';
}

sub test_015_clicks : Test(12) {
    my $self = shift;
    my $args = $self->args;

    ok my $bitly = WebService::Bitly->new(%$args);

    dies_ok( sub {$bitly->clicks}, 'wrong parameter');

    ok my $result_clicks = $bitly->clicks(
        short_urls => ['http://tcrn.ch/a4MSUH'],
        hashes     => ['a35.'],
    );
    isa_ok $result_clicks, 'WebService::Bitly::Result::Clicks', 'is correct object';
    ok !$result_clicks->is_error;

    my @clicks_list = $result_clicks->results;
    is $clicks_list[0]->short_url, 'http://tcrn.ch/a4MSUH', 'correct short_url';
    is $clicks_list[0]->global_hash, 'bWw49z', 'correct global_hash';
    is $clicks_list[0]->user_clicks, '0', 'correct user_clicks';
    is $clicks_list[0]->user_hash, 'a4MSUH', 'correct user_hash';
    is $clicks_list[0]->global_clicks, '1105', 'correct global_clicks';

    is $clicks_list[1]->hash, 'a35.', 'correct hash';
    ok $clicks_list[1]->is_error, 'error should occur';
}

sub test_016_bitly_pro_domain : Test(4) {
    my $self = shift;
    my $args = $self->args;

    ok my $bitly = WebService::Bitly->new(%$args);

    dies_ok( sub {$bitly->bitly_pro_domain}, 'wrong parameter');

    my $pro_result = $bitly->bitly_pro_domain('nyti.ms');

    is $pro_result->is_pro_domain, 1, 'should pro domain';

    $pro_result->{data}->{bitly_pro_domain} = 0;
    is $pro_result->is_pro_domain, 0, 'should not pro domain';
}

sub test_017_lookup : Test(9) {
    my $self = shift;
    my $args = $self->args;

    ok my $bitly = WebService::Bitly->new(%$args);

    dies_ok( sub {$bitly->lookup}, 'wrong parameter');

    ok my $lookup = $bitly->lookup([
        'http://betaworks.com/',
        'asdf://www.google.com/not/a/real/link',
    ]);

    isa_ok $lookup, 'WebService::Bitly::Result::Lookup', 'is correct object';
    ok !$lookup->is_error;

    my @lookup = $lookup->results;

    is $lookup[0]->global_hash, 'beta', 'correct global_hash';
    is $lookup[0]->short_url, 'http://bit.ly/beta', 'correct short_url';
    is $lookup[0]->url, 'http://betaworks.com/', 'correct url';
    ok $lookup[1]->is_error, 'error should occur';
}

sub test_018_info : Test(14) {
    my $self = shift;
    my $args = $self->args;

    ok my $bitly = WebService::Bitly->new(%$args);

    dies_ok( sub {$bitly->info}, 'wrong parameter');

    ok my $result_info = $bitly->info(
        short_urls   => ['http://bit.ly/a.35'],
        hashes       => ['j3'],
    );
    isa_ok $result_info, 'WebService::Bitly::Result::Info', 'is correct object';
    ok !$result_info->is_error;
    isa_ok $result_info, 'WebService::Bitly::Result::Info', 'is correct object';

    my @info_list = $result_info->results;

    is $info_list[0]->short_url, 'http://bit.ly/a.35', 'correct short_url';
    ok $info_list[0]->is_error, 'error should occur';

    ok !$info_list[1]->is_error, 'error should not occur';
    is $info_list[1]->created_by, 'scotster', 'should get created_by';
    is $info_list[1]->global_hash, 'lLWr', 'should get correct global_hash';
    is $info_list[1]->hash, 'j3', 'should get correct hash';
    is $info_list[1]->title, 'test title', 'should get correct title';
    is $info_list[1]->user_hash, 'j3', 'should get correct short url';
}

sub test_019_http_error : Test(3) {
    my $self = shift;
    my $args = $self->args;

    ok my $bitly = WebService::Bitly->new(
        %$args,
    );
    $bitly->{base_url} = 'http://aaa/';

    my $shorten = $bitly->shorten('http://www.google.co.jp/');
    isa_ok $shorten, 'WebService::Bitly::Result::HTTPError', 'is correct object';
    ok $shorten->is_error, 'error should occur';
}

sub test_020_referrers : Test(11) {
    my $self = shift;
    my $args = $self->args;

    ok my $bitly = WebService::Bitly->new(
        %$args,
    );

    dies_ok(sub {$bitly->referrers}, 'Either short_url or hash is required');
    dies_ok(sub {
        $bitly->referrers(
            short_url => 'http://bit.ly/djZ9g4',
            hash      => 'djZ9g4',
        );
    }, 'Either short_url or hash is required');

    my $result_referrer = $bitly->referrers(short_url => 'http://bit.ly/djZ9g4');
    is $result_referrer->global_hash, 'djZ9g4', 'can access global hash';
    is $result_referrer->short_url, 'http://bit.ly/djZ9g4', 'can access short_url';
    is $result_referrer->user_hash, 'djZ9g4', 'can access user hash';

    my $referrers = $result_referrer->referrers;
    is $referrers->[0]->clicks, 42, 'correct clicks';
    is $referrers->[0]->referrer, 'direct', 'correct referrer';
    is $referrers->[1]->clicks, 8, 'correct clicks';
    is $referrers->[1]->referrer_app, 'TweetDeck', 'correct referrer_app';
    is $referrers->[1]->url, 'http://www.tweetdeck.com/', 'correct url';
}

sub test_021_countries : Test(11) {
    my $self = shift;
    my $args = $self->args;

    ok my $bitly = WebService::Bitly->new(
        %$args,
    );

    dies_ok(sub {$bitly->countries}, 'Either short_url or hash is required');
    dies_ok(sub {
        $bitly->countries(
            short_url => 'http://bit.ly/djZ9g4',
            hash      => 'djZ9g4',
        );
    }, 'Either short_url or hash is required');

    my $result_country = $bitly->countries(hash => 'djZ9g4');
    is $result_country->created_by, 'bitly', 'correct created_by';
    is $result_country->global_hash, 'djZ9g4', 'correct global_hash';
    is $result_country->short_url, 'http://bit.ly/djZ9g4', 'correct user_hash';
    is $result_country->user_hash, 'djZ9g4', 'correct user hash';

    my $countries = $result_country->countries;
    is $countries->[0]->clicks, 40, 'correct clicks';
    is $countries->[0]->country, 'US', 'correct country';
    is $countries->[1]->clicks, 1, 'correct clicks';
    is $countries->[1]->country, 'SE', 'correct country';
}

sub test_022_clicks_by_minute : Test(13) {
    my $self = shift;
    my $args = $self->args;

    ok my $bitly = WebService::Bitly->new(
        %$args,
    );

    dies_ok(sub {$bitly->clicks_by_minute}, 'Either short_url, hash or multi is required');

    ok my $result_clicks = $bitly->clicks_by_minute(
        short_urls   => ['http://j.mp/9DguyN'],
    );

    isa_ok $result_clicks, 'WebService::Bitly::Result::ClicksByMinute', 'is correct object';
    ok !$result_clicks->is_error;

    my $clicks_list = $result_clicks->results;

    is $clicks_list->[0]->global_hash, '9DguyN', 'correct global_hash';
    is $clicks_list->[0]->short_url, 'http://j.mp/9DguyN', 'correct short_url';
    is $clicks_list->[0]->user_hash, 'user9Gg', 'correct user_hash';
    is $clicks_list->[0]->clicks->[0], 5, 'correct global_hash';
    is $clicks_list->[0]->clicks->[1], 10, 'correct global_hash';
    is $clicks_list->[0]->clicks->[2], 15, 'correct global_hash';

    ok $clicks_list->[1]->is_error, 'error should occur';
    is $clicks_list->[1]->hash, '9N', 'correct hash';
}

sub test_024_clicks_by_day : Test(14) {
    my $self = shift;
    my $args = $self->args;

    ok my $bitly = WebService::Bitly->new(
        %$args,
    );

    dies_ok(sub {$bitly->clicks_by_day}, 'Either short_url, hash or multi is required');

    ok my $result_clicks = $bitly->clicks_by_day(
        short_urls => ['http://j.mp/9DguyN'],
        hashes     => ['9N'],
    );

    isa_ok $result_clicks, 'WebService::Bitly::Result::ClicksByDay', 'is correct object';
    ok !$result_clicks->is_error;

    my $clicks = $result_clicks->results;

    is $clicks->[0]->short_url, 'http://j.mp/9DguyN', 'correct short_url';
    is $clicks->[0]->global_hash, '9DguyN', 'correct global_hash';
    is $clicks->[0]->user_hash, 'user9Dg', 'correct user_hash';
    is $clicks->[0]->clicks->[0]->clicks, 5, 'correct clicks';
    is $clicks->[0]->clicks->[0]->day_start, 1290920400, 'correct day_start';
    is $clicks->[0]->clicks->[1]->clicks, 10, 'correct clicks';
    is $clicks->[0]->clicks->[1]->day_start, 1290834000, 'correct day_start';

    is $clicks->[1]->hash, '9N', 'correct hash';
    ok $clicks->[1]->is_error, 'error should occur';
}

__PACKAGE__->runtests;

1;

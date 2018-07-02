#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use lib 't/lib';

use WWW::YNAB;
use WWW::YNAB::MockUA;

my $ua = WWW::YNAB::MockUA->new;
my $ynab = WWW::YNAB->new(
    access_token => 'abcdef',
    ua           => $ua,
);

is(scalar $ua->test_requests, 0);
ok(!$ynab->knows_rate_limit);
ok(!$ynab->knows_total_rate_limit);

my @budgets = $ynab->budgets;
is(scalar @budgets, 1);
isa_ok($budgets[0], 'WWW::YNAB::Budget');
is($budgets[0]->id, 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa');
is($budgets[0]->name, 'My Budget');
is($budgets[0]->last_modified_on, "2018-06-23T17:04:12+00:00");
is($budgets[0]->first_month, "2016-06-01");
is($budgets[0]->last_month, "2018-07-01");

is(scalar $ua->test_requests, 1);
is(($ua->test_requests)[0][0], 'https://api.youneedabudget.com/v1/budgets');
ok($ynab->knows_rate_limit);
ok($ynab->knows_total_rate_limit);
is($ynab->rate_limit, 1);
is($ynab->total_rate_limit, 200);

my $user = $ynab->user;
isa_ok($user, 'WWW::YNAB::User');
is($user->id, 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb');

is(scalar $ua->test_requests, 2);
is(($ua->test_requests)[1][0], 'https://api.youneedabudget.com/v1/user');
ok($ynab->knows_rate_limit);
ok($ynab->knows_total_rate_limit);
is($ynab->rate_limit, 2);
is($ynab->total_rate_limit, 200);

done_testing;

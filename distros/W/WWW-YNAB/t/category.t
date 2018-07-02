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

my $budget = $ynab->budget('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa');
is(scalar $ua->test_requests, 1);
isa_ok($budget, 'WWW::YNAB::Budget');

my $category = $budget->category('33333333-3333-3333-3333-333333333333');
is(scalar $ua->test_requests, 2);
isa_ok($category, 'WWW::YNAB::Category');
is($category->id, "33333333-3333-3333-3333-333333333333");
is($category->category_group_id, "22222222-2222-2222-2222-333333333333");
is($category->name, "Restaurants");
ok(!$category->hidden);
is($category->note, undef);
is($category->budgeted, 234560);
is($category->activity, -34560);
is($category->balance, 200000);
ok(!$category->deleted);

done_testing;

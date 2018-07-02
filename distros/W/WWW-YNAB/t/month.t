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

my $month = $budget->month('2018-07-01');
is(scalar $ua->test_requests, 2);
isa_ok($month, 'WWW::YNAB::Month');
is($month->month, "2018-07-01");
is($month->note, undef);
is($month->to_be_budgeted, 0);
is($month->age_of_money, 88);

my @categories = $month->categories;
is(scalar @categories, 3);
is($categories[0]->id, "33333333-3333-3333-3333-555555555555");
is($categories[0]->category_group_id, "22222222-2222-2222-2222-333333333333");
is($categories[0]->name, "Groceries");
ok(!$categories[0]->hidden);
is($categories[0]->note, undef);
is($categories[0]->budgeted, 345670);
is($categories[0]->activity, -123450);
is($categories[0]->balance, 222220);
ok(!$categories[0]->deleted);

done_testing;

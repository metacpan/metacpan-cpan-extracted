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

my $account = $budget->account('00000000-0000-0000-0000-222222222222');
is(scalar $ua->test_requests, 2);
isa_ok($account, 'WWW::YNAB::Account');
is($account->id, "00000000-0000-0000-0000-222222222222");
is($account->name, "Credit Card");
is($account->type, "creditCard");
ok($account->on_budget);
ok(!$account->closed);
is($account->note, undef);
is($account->balance, -6543210);
is($account->cleared_balance, -5432100);
is($account->uncleared_balance, -1111110);
ok(!$account->deleted);

done_testing;

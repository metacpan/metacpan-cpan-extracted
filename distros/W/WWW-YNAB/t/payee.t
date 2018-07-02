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

my $payee = $budget->payee('11111111-1111-1111-1111-333333333333');
is(scalar $ua->test_requests, 2);
isa_ok($payee, 'WWW::YNAB::Payee');
is($payee->id, "11111111-1111-1111-1111-333333333333");
is($payee->name, "candy shop");
is($payee->transfer_account_id, undef);
ok(!$payee->deleted);

done_testing;

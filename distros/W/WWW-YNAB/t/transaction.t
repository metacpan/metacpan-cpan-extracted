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

my $transaction = $budget->transaction('44444444-4444-4444-4444-666666666666');
is(scalar $ua->test_requests, 2);
isa_ok($transaction, 'WWW::YNAB::Transaction');
is($transaction->id, "44444444-4444-4444-4444-666666666666");
is($transaction->date, "2018-06-02");
is($transaction->amount, -200000);
is($transaction->memo, undef);
is($transaction->cleared, "cleared");
ok($transaction->approved);
is($transaction->flag_color, undef);
is($transaction->account_id, "00000000-0000-0000-0000-222222222222");
is($transaction->payee_id, "11111111-1111-1111-1111-111111111111");
is($transaction->category_id, "33333333-3333-3333-3333-666666666666");
is($transaction->transfer_account_id, undef);
is($transaction->import_id, "YNAB:-200000:2018-05-31:1");
ok(!$transaction->deleted);

my @subtransactions = $transaction->subtransactions;
is(scalar @subtransactions, 3);
is($subtransactions[0]->id, "55555555-5555-5555-5555-555555555555");
is($subtransactions[0]->transaction_id, "44444444-4444-4444-4444-666666666666");
is($subtransactions[0]->amount, -100000);
is($subtransactions[0]->memo, undef);
is($subtransactions[0]->payee_id, undef);
is($subtransactions[0]->category_id, "33333333-3333-3333-3333-444444444444");
is($subtransactions[0]->transfer_account_id, undef);
ok(!$subtransactions[0]->deleted);

done_testing;

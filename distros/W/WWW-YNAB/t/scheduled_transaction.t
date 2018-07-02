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

my $scheduled_transaction = $budget->scheduled_transaction('66666666-6666-6666-6666-666666666666');
is(scalar $ua->test_requests, 2);
isa_ok($scheduled_transaction, 'WWW::YNAB::ScheduledTransaction');

is($scheduled_transaction->id, "66666666-6666-6666-6666-666666666666");
is($scheduled_transaction->date_first, "2018-06-05");
is($scheduled_transaction->date_next, "2018-07-05");
is($scheduled_transaction->frequency, "monthly");
is($scheduled_transaction->amount, -100000);
is($scheduled_transaction->memo, "cable");
is($scheduled_transaction->flag_color, "purple");
is($scheduled_transaction->account_id, "00000000-0000-0000-0000-111111111111");
is($scheduled_transaction->payee_id, undef);
is($scheduled_transaction->category_id, "33333333-3333-3333-3333-666666666666");
is($scheduled_transaction->transfer_account_id, undef);
ok(!$scheduled_transaction->deleted);
is($scheduled_transaction->account_name, "Checking Account");
is($scheduled_transaction->payee_name, undef);
is($scheduled_transaction->category_name, "Split (Multiple Categories)...");
is(scalar $scheduled_transaction->subtransactions, 2);

my @scheduled_subtransactions = $scheduled_transaction->subtransactions;
is(scalar @scheduled_subtransactions, 2);
is($scheduled_subtransactions[0]->id, "77777777-7777-7777-7777-777777777777");
is($scheduled_subtransactions[0]->scheduled_transaction_id, "66666666-6666-6666-6666-666666666666");
is($scheduled_subtransactions[0]->amount, -50000);
is($scheduled_subtransactions[0]->memo, "tv");
is($scheduled_subtransactions[0]->payee_id, undef);
is($scheduled_subtransactions[0]->category_id, "33333333-3333-3333-3333-444444444444");
is($scheduled_subtransactions[0]->transfer_account_id, undef);
ok(!$scheduled_subtransactions[0]->deleted);

done_testing;

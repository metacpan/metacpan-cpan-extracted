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
isa_ok($budget, 'WWW::YNAB::Budget');
is($budget->id, 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa');
is($budget->name, 'My Budget');
is($budget->last_modified_on, "2018-06-23T17:04:12+00:00");
is($budget->first_month, "2018-06-01");
is($budget->last_month, "2018-07-01");

is(scalar $ua->test_requests, 1);
is(($ua->test_requests)[0][0], 'https://api.youneedabudget.com/v1/budgets/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa');

my @accounts = $budget->accounts;
is(scalar @accounts, 3);
isa_ok($accounts[0], 'WWW::YNAB::Account');
is($accounts[0]->id, "00000000-0000-0000-0000-000000000000");
is($accounts[0]->name, "Savings Account");
is($accounts[0]->type, "savings");
ok($accounts[0]->on_budget);
ok(!$accounts[0]->closed);
is($accounts[0]->note, undef);
is($accounts[0]->balance, 12345670);
is($accounts[0]->cleared_balance, 12345670);
is($accounts[0]->uncleared_balance, 0);
ok(!$accounts[0]->deleted);

my @payees = $budget->payees;
is(scalar @payees, 3);
isa_ok($payees[0], 'WWW::YNAB::Payee');
is($payees[0]->id, "11111111-1111-1111-1111-111111111111");
is($payees[0]->name, "a restaurant");
is($payees[0]->transfer_account_id, undef);
ok(!$payees[0]->deleted);

my @category_groups = $budget->category_groups;
is(scalar @category_groups, 2);
isa_ok($category_groups[0], 'WWW::YNAB::CategoryGroup');
is($category_groups[0]->id, "22222222-2222-2222-2222-222222222222");
is($category_groups[0]->name, "Home");
ok(!$category_groups[0]->hidden);
ok(!$category_groups[0]->deleted);

my @home_categories = $category_groups[0]->categories;
is(scalar @home_categories, 1);
isa_ok($home_categories[0], 'WWW::YNAB::Category');
is($home_categories[0]->id, "33333333-3333-3333-3333-444444444444");
is($home_categories[0]->category_group_id, "22222222-2222-2222-2222-222222222222");
is($home_categories[0]->name, "Utilities");
ok(!$home_categories[0]->hidden);
is($home_categories[0]->note, undef);
is($home_categories[0]->budgeted, 123450);
is($home_categories[0]->activity, -123450);
is($home_categories[0]->balance, 0);
ok(!$home_categories[0]->deleted);

is(scalar $category_groups[1]->categories, 2);

my @months = $budget->months;
is(scalar @months, 3);
isa_ok($months[0], 'WWW::YNAB::Month');
is($months[0]->month, "2018-08-01");
is($months[0]->note, undef);
is($months[0]->to_be_budgeted, 0);
is($months[0]->age_of_money, 88);
is(scalar $months[0]->categories, 3);

my @transactions = $budget->transactions;
is(scalar @transactions, 3);
isa_ok($transactions[0], 'WWW::YNAB::Transaction');
is($transactions[0]->id, "44444444-4444-4444-4444-444444444444");
is($transactions[0]->date, "2018-06-18");
is($transactions[0]->amount, -98760);
is($transactions[0]->memo, undef);
is($transactions[0]->cleared, "cleared");
ok($transactions[0]->approved);
is($transactions[0]->flag_color, undef);
is($transactions[0]->account_id, "00000000-0000-0000-0000-111111111111");
is($transactions[0]->payee_id, "11111111-1111-1111-1111-222222222222");
is($transactions[0]->category_id, "33333333-3333-3333-3333-444444444444");
is($transactions[0]->transfer_account_id, undef);
is($transactions[0]->import_id, "YNAB:-98760:2018-06-18:1");
ok(!$transactions[0]->deleted);
is($transactions[0]->account_name, "Checking Account");
is($transactions[0]->payee_name, "the power company");
is($transactions[0]->category_name, "Utilities");
is(scalar $transactions[0]->subtransactions, 0);

my @subtransactions = $transactions[2]->subtransactions;
is(scalar @subtransactions, 3);
is($subtransactions[0]->id, "55555555-5555-5555-5555-555555555555");
is($subtransactions[0]->transaction_id, "44444444-4444-4444-4444-666666666666");
is($subtransactions[0]->amount, -100000);
is($subtransactions[0]->memo, undef);
is($subtransactions[0]->payee_id, undef);
is($subtransactions[0]->category_id, "33333333-3333-3333-3333-444444444444");
is($subtransactions[0]->transfer_account_id, undef);
ok(!$subtransactions[0]->deleted);

my @scheduled_transactions = $budget->scheduled_transactions;
is(scalar @scheduled_transactions, 1);
isa_ok($scheduled_transactions[0], 'WWW::YNAB::ScheduledTransaction');
is($scheduled_transactions[0]->id, "66666666-6666-6666-6666-666666666666");
is($scheduled_transactions[0]->date_first, "2018-06-05");
is($scheduled_transactions[0]->date_next, "2018-07-05");
is($scheduled_transactions[0]->frequency, "monthly");
is($scheduled_transactions[0]->amount, -100000);
is($scheduled_transactions[0]->memo, "cable");
is($scheduled_transactions[0]->flag_color, "purple");
is($scheduled_transactions[0]->account_id, "00000000-0000-0000-0000-111111111111");
is($scheduled_transactions[0]->payee_id, undef);
is($scheduled_transactions[0]->category_id, "33333333-3333-3333-3333-666666666666");
is($scheduled_transactions[0]->transfer_account_id, undef);
ok(!$scheduled_transactions[0]->deleted);
is($scheduled_transactions[0]->account_name, "Checking Account");
is($scheduled_transactions[0]->payee_name, undef);
# this is i think a bug in their api - they don't return a category object for
# "split" even though they have a category id for it, and the name shows up in
# the direct transaction/scheduled_transaction individual object request
is($scheduled_transactions[0]->category_name, undef);
is(scalar $scheduled_transactions[0]->subtransactions, 2);

my @scheduled_subtransactions = $scheduled_transactions[0]->subtransactions;
is(scalar @scheduled_subtransactions, 2);
is($scheduled_subtransactions[0]->id, "77777777-7777-7777-7777-777777777777");
is($scheduled_subtransactions[0]->scheduled_transaction_id, "66666666-6666-6666-6666-666666666666");
is($scheduled_subtransactions[0]->amount, -50000);
is($scheduled_subtransactions[0]->memo, "tv");
is($scheduled_subtransactions[0]->payee_id, undef);
is($scheduled_subtransactions[0]->category_id, "33333333-3333-3333-3333-444444444444");
is($scheduled_subtransactions[0]->transfer_account_id, undef);
ok(!$scheduled_subtransactions[0]->deleted);

is(scalar $ua->test_requests, 1);

done_testing;

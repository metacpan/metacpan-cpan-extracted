use strict;
use warnings;
use Test::More;

use WebService::Coincheck;

my $coincheck = WebService::Coincheck->new(
    access_key => 'YOUR_ACCESS_KEY',
    secret_key => 'YOUR_SECRET_KEY',
);

isa_ok $coincheck, 'WebService::Coincheck';

isa_ok $coincheck->ticker,       'WebService::Coincheck::Ticker';
isa_ok $coincheck->trade,        'WebService::Coincheck::Trade';
isa_ok $coincheck->order_book,   'WebService::Coincheck::OrderBook';
isa_ok $coincheck->order,        'WebService::Coincheck::Order';
isa_ok $coincheck->leverage,     'WebService::Coincheck::Leverage';
isa_ok $coincheck->account,      'WebService::Coincheck::Account';
isa_ok $coincheck->send,         'WebService::Coincheck::Send';
isa_ok $coincheck->deposit,      'WebService::Coincheck::Deposit';
isa_ok $coincheck->bank_account, 'WebService::Coincheck::BankAccount';
isa_ok $coincheck->withdraw,     'WebService::Coincheck::Withdraw';
isa_ok $coincheck->borrow,       'WebService::Coincheck::Borrow';
isa_ok $coincheck->transfer,     'WebService::Coincheck::Transfer';

done_testing;

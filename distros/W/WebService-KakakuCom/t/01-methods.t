#!perl -T
use strict;
use warnings;

use Test::More tests => 21;
use WebService::KakakuCom;

my $api = WebService::KakakuCom->new;
ok $api;

ok $api->ua;
isa_ok $api->ua, 'LWP::UserAgent';
is $api->ua->agent, sprintf "%s/%s", 'WebService::KakakuCom', WebService::KakakuCom->VERSION;

my $rs = $api->search('Vaio');
ok $rs;
isa_ok $rs, 'WebService::KakakuCom::ResultSet';
isa_ok $rs->[0], 'WebService::KakakuCom::Product';
ok $rs->pager;
isa_ok $rs->pager, 'Data::Page';
ok $rs->pager->total_entries > 0;
is $rs->pager->current_page, 1;
is $rs->pager->next_page, 2;

$rs = $api->search('Vaio', { PageNum => 2 });
ok $rs;
ok $rs->pager;
is $rs->pager->current_page, 2;
is $rs->pager->next_page, 3;

ok @$rs > 0;
ok $rs->[0]->ProductName;

my $product = $api->product($rs->[0]->ProductID);
ok $product;
isa_ok $rs->[0], 'WebService::KakakuCom::Product';
is $rs->[0]->ProductName, $product->ProductName;


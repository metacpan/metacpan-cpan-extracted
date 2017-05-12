use 5.010;
use Test::More tests => 3;
use common::sense;
use WebService::Yes24;

my $query = 'Learning Perl';
my $page = 1;

my $yes24 = WebService::Yes24->new( category => 'foreign-book' );
my $total = $yes24->search($query);

cmp_ok($total, '>', 0, "fetch result: $total");

my $item = $yes24->result->[0];
ok $item;
isa_ok $item, 'WebService::Yes24::Item';

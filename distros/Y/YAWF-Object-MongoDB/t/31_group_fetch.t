use strict;
use warnings;

use Test::More tests => 15;

use_ok('YAWF::Object::MongoDB');
use_ok('t::lib::Forest');

# Clean up test space
t::lib::Forest->_collection->drop;

# Plant a forest
my $forest = t::lib::Forest->new;
$forest->birch(1);
$forest->oak(2);
$forest->color(3);
$forest->deer(4);
$forest->boar(5);
$forest->set_column('factory','not wanted');
ok($forest->flush,'Flush forest');

my $forest1 = t::lib::Forest->new($forest->id);
ok($forest1,'Load forest');
for ('birch','oak','color'){
    is($forest1->{_document}->{$_},$forest->$_,$_);
}
for ('deer','boar','factory'){
    ok(!exists $forest1->{_document}->{$_},$_);
}
is($forest1->deer,$forest->deer,'Load 2nd part');
for ('deer','boar'){
    is($forest1->{_document}->{$_},$forest->$_,$_);
}
ok(!exists $forest1->{_document}->{factory},'factory');
is($forest1->get_column('factory'),$forest->get_column('factory'),'Load undefined key');

END {
    t::lib::Forest->_collection->drop;
}

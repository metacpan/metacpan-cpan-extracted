use strict;
use warnings;

use Test::More tests => 31;
use Test::Exception;

BEGIN {
    use_ok('Tree::Binary::Search');
}

my $btree = Tree::Binary::Search->new();
isa_ok($btree, 'Tree::Binary::Search');

## setComparisonFunction

throws_ok {
    $btree->setComparisonFunction()
} qr/Incorrect Object Type/, '... this should die';

throws_ok {
    $btree->setComparisonFunction("Fail")
} qr/Incorrect Object Type/, '... this should die';

throws_ok {
    $btree->setComparisonFunction([])
} qr/Incorrect Object Type/, '... this should die';

## check on things before anything is inserted

throws_ok {
    $btree->update(A => 'a')
} qr/Illegal Operation/, '... this should die';

throws_ok {
    $btree->select("A")
} qr/Illegal Operation/, '... this should die';

throws_ok {
    $btree->max()
} qr/Illegal Operation/, '... this should die';

throws_ok {
    $btree->min()
} qr/Illegal Operation/, '... this should die';

throws_ok {
    $btree->delete()
} qr/Illegal Operation/, '... this should die';

## insert

throws_ok {
    $btree->insert()
} qr/Insufficient Arguments/, '... this should die';

throws_ok {
    $btree->insert("Fail")
} qr/Insufficient Arguments/, '... this should die';

throws_ok {
    $btree->insert([])
} qr/Insufficient Arguments/, '... this should die';

throws_ok {
    $btree->insert(bless({}, "Fail"))
} qr/Insufficient Arguments/, '... this should die';

# test that things die without a comparison function
throws_ok {
    $btree->insert(F => 'f')
} qr/Illegal Operation/, '... this should die';

$btree->useStringComparison();
$btree->insert(E => 'e');

throws_ok {
    $btree->insert(E => 'e')
} qr/Illegal Operation/, '... this should die';

# test update after we have something in the tree

throws_ok {
    $btree->update()
} qr/Insufficient Arguments/, '... this should die';

throws_ok {
    $btree->update("A")
} qr/Insufficient Arguments/, '... this should die';

throws_ok {
    $btree->update(undef, "A")
} qr/Insufficient Arguments/, '... this should die';

throws_ok {
    $btree->update(B => 'b')
} qr/Key Does Not Exist/, '... this should die';

throws_ok {
    $btree->update(G => 'g')
} qr/Key Does Not Exist/, '... this should die';

## delete

throws_ok {
    $btree->delete(B => 'b')
} qr/Key Does Not Exist/, '... this should die';

throws_ok {
    $btree->delete(G => 'g')
} qr/Key Does Not Exist/, '... this should die';

throws_ok {
    $btree->delete()
} qr/Insufficient Arguments/, '... this should die';

## select

throws_ok {
    $btree->select()
} qr/Insufficient Arguments/, '... this should die';

throws_ok {
    $btree->select(B => 'b')
} qr/Key Does Not Exist/, '... this should die';

throws_ok {
    $btree->select(G => 'g')
} qr/Key Does Not Exist/, '... this should die';

## exists

throws_ok {
    $btree->exists()
} qr/Insufficient Arguments/, '... this should die';

# test bad comparison functions as well

$btree->setComparisonFunction(sub { "Fail" });

throws_ok {
    $btree->insert(B => 'b')
} qr/Bad Value/, '... this should die';

$btree->setComparisonFunction(sub { 100 });

throws_ok {
    $btree->insert(B => 'b')
} qr/Bad Value/, '... this should die';

$btree->setComparisonFunction(sub { -10 });

throws_ok {
    $btree->insert(B => 'b')
} qr/Bad Value/, '... this should die';





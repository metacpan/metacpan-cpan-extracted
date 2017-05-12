use strict;
use warnings;

use Test::More tests => 22;
use Test::Exception;

BEGIN {
    use_ok('Tree::Binary');
}

my $BAD_OBJECT = bless({}, "Fail");


my $btree = Tree::Binary->new("ROOT");
isa_ok($btree, 'Tree::Binary');

## test constructor

throws_ok {
    my $btree = Tree::Binary->new();
} qr/Insufficient Arguments/, '... this should die';

## test some mutators

throws_ok {
    $btree->setNodeValue();
} qr/Insufficient Arguments/, '... this should die';

throws_ok {
    $btree->setUID();
} qr/Insufficient Arguments/, '... this should die';

## test setLeft

throws_ok {
    $btree->setLeft();
} qr/Insufficient Arguments/, '... this should die';

throws_ok {
    $btree->setLeft("Fail");
} qr/Insufficient Arguments/, '... this should die';

throws_ok {
    $btree->setLeft([]);
} qr/Insufficient Arguments/, '... this should die';

throws_ok {
    $btree->setLeft($BAD_OBJECT);
} qr/Insufficient Arguments/, '... this should die';

## test removeLeft

throws_ok {
    $btree->removeLeft();
} qr/Illegal Operation/, '... this should die';

## test setRight

throws_ok {
    $btree->setRight();
} qr/Insufficient Arguments/, '... this should die';

throws_ok {
    $btree->setRight("Fail");
} qr/Insufficient Arguments/, '... this should die';

throws_ok {
    $btree->setRight([]);
} qr/Insufficient Arguments/, '... this should die';

throws_ok {
    $btree->setRight($BAD_OBJECT);
} qr/Insufficient Arguments/, '... this should die';

## test removeRight

throws_ok {
    $btree->removeRight();
} qr/Illegal Operation/, '... this should die';

## test traverse

throws_ok {
    $btree->traverse();
} qr/Insufficient Arguments/, '... this should die';

throws_ok {
    $btree->traverse("Fail");
} qr/Incorrect Object Type/, '... this should die';

## test accept

throws_ok {
	$btree->accept();
} qr/^Insufficient Arguments/, '... this should die';

throws_ok {
	$btree->accept("Fail");
} qr/^Insufficient Arguments/, '... this should die';

throws_ok {
	$btree->accept([]);
} qr/^Insufficient Arguments/, '... this should die';

throws_ok {
	$btree->accept($BAD_OBJECT);
} qr/^Insufficient Arguments/, '... this should die';

{
    package TestPackage;
    sub visit {}
}

# passing non-Tree::Binary::Visitor arg to accept
lives_ok {
	$btree->accept(bless({}, "TestPackage"));
} '... but, this should live';


use Test::More tests => 36;

use lib 'lib';
use strict;
use XML::Parser::Lite::Tree::XPath::Test;


test_tree(q!/aaa!,		'[LocationPath:absolute[Step[NameTest:aaa]]]');
test_tree(q!/aaa/bbb!,		'[LocationPath:absolute[Step[NameTest:aaa]][Step[NameTest:bbb]]]');
test_tree(q!/aaa/bbb/ccc!,	'[LocationPath:absolute[Step[NameTest:aaa]][Step[NameTest:bbb]][Step[NameTest:ccc]]]');
test_tree(q!//bbb!,		'[LocationPath:absolute[Step::descendant-or-self[NodeTypeTest:node]][Step[NameTest:bbb]]]');
test_tree(q!//aaa/bbb!,		'[LocationPath:absolute[Step::descendant-or-self[NodeTypeTest:node]][Step[NameTest:aaa]][Step[NameTest:bbb]]]');
test_tree(q!/aaa/*!,		'[LocationPath:absolute[Step[NameTest:aaa]][Step[NameTest:*]]]');
test_tree(q!/*/bbb!,		'[LocationPath:absolute[Step[NameTest:*]][Step[NameTest:bbb]]]');
test_tree(q!//*!,		'[LocationPath:absolute[Step::descendant-or-self[NodeTypeTest:node]][Step[NameTest:*]]]');
test_tree(q!/aaa/bbb[1]!,	'[LocationPath:absolute[Step[NameTest:aaa]][Step[NameTest:bbb][Predicate[Number:1]]]]');
test_tree(q!/aaa/bbb[last()]!,	'[LocationPath:absolute[Step[NameTest:aaa]][Step[NameTest:bbb][Predicate[FunctionCall:last]]]]');
test_tree(q!/@id!,		'[LocationPath:absolute[Step::attribute[NameTest:id]]]');
test_tree(q!/bbb[@id]!,		'[LocationPath:absolute[Step[NameTest:bbb][Predicate[LocationPath[Step::attribute[NameTest:id]]]]]]');
test_tree(q!/bbb[@name]!,	'[LocationPath:absolute[Step[NameTest:bbb][Predicate[LocationPath[Step::attribute[NameTest:name]]]]]]');
test_tree(q!/bbb[@*]!,		'[LocationPath:absolute[Step[NameTest:bbb][Predicate[LocationPath[Step::attribute[NameTest:*]]]]]]');
test_tree(q!/bbb[not(@*)]!,	'[LocationPath:absolute[Step[NameTest:bbb][Predicate[FunctionCall:not[FunctionArg[LocationPath[Step::attribute[NameTest:*]]]]]]]]');
test_tree(q!/bbb[@id='b1']!,	'[LocationPath:absolute[Step[NameTest:bbb][Predicate[EqualityExpr:=[LocationPath[Step::attribute[NameTest:id]]][Literal:b1]]]]]');
test_tree(q!/*[count(bbb)=2]!,	'[LocationPath:absolute[Step[NameTest:*][Predicate[EqualityExpr:=[FunctionCall:count[FunctionArg[LocationPath[Step[NameTest:bbb]]]]][Number:2]]]]]');
test_tree(q!/*[count(*)=2]!,	'[LocationPath:absolute[Step[NameTest:*][Predicate[EqualityExpr:=[FunctionCall:count[FunctionArg[LocationPath[Step[NameTest:*]]]]][Number:2]]]]]');
test_tree(q!/*[name()='bbb']!,	'[LocationPath:absolute[Step[NameTest:*][Predicate[EqualityExpr:=[FunctionCall:name][Literal:bbb]]]]]');
test_tree(q!/aaa | /bbb!,	'[UnionExpr:|[LocationPath:absolute[Step[NameTest:aaa]]][LocationPath:absolute[Step[NameTest:bbb]]]]');
test_tree(q!/child::aaa!,	'[LocationPath:absolute[Step::child[NameTest:aaa]]]');
test_tree(q!/child::aaa/bbb!,	'[LocationPath:absolute[Step::child[NameTest:aaa]][Step[NameTest:bbb]]]');
test_tree(q!/descendant::*!,	'[LocationPath:absolute[Step::descendant[NameTest:*]]]');
test_tree(q!/ddd/parent::*!,	'[LocationPath:absolute[Step[NameTest:ddd]][Step::parent[NameTest:*]]]');
test_tree(q!/./aaa!,		'[LocationPath:absolute[Step::self[NodeTypeTest:node]][Step[NameTest:aaa]]]');
test_tree(q!/../aaa!,		'[LocationPath:absolute[Step::parent[NodeTypeTest:node]][Step[NameTest:aaa]]]');

test_tree(q!/descendant-or-self::aaa!,	'[LocationPath:absolute[Step::descendant-or-self[NameTest:aaa]]]');
test_tree(q!/aaa | /bbb | /ccc[1]!,	'[UnionExpr:|[UnionExpr:|[LocationPath:absolute[Step[NameTest:aaa]]][LocationPath:absolute[Step[NameTest:bbb]]]][LocationPath:absolute[Step[NameTest:ccc][Predicate[Number:1]]]]]');
test_tree(q!/*[contains(name(),'c')]!,	'[LocationPath:absolute[Step[NameTest:*][Predicate[FunctionCall:contains[FunctionArg[FunctionCall:name]][FunctionArg[Literal:c]]]]]]');

test_tree(q!/*[starts-with(name(),'b')]!,	'[LocationPath:absolute[Step[NameTest:*][Predicate[FunctionCall:starts-with[FunctionArg[FunctionCall:name]][FunctionArg[Literal:b]]]]]]');
test_tree(q!/*[string-length(name()) = 3]!,	'[LocationPath:absolute[Step[NameTest:*][Predicate[EqualityExpr:=[FunctionCall:string-length[FunctionArg[FunctionCall:name]]][Number:3]]]]]');
test_tree(q!/*[string-length(name()) < 3]!,	'[LocationPath:absolute[Step[NameTest:*][Predicate[RelationalExpr:<[FunctionCall:string-length[FunctionArg[FunctionCall:name]]][Number:3]]]]]');
test_tree(q!/*[string-length(name()) > 3]!,	'[LocationPath:absolute[Step[NameTest:*][Predicate[RelationalExpr:>[FunctionCall:string-length[FunctionArg[FunctionCall:name]]][Number:3]]]]]');
test_tree(q!/bbb[position() mod 2 = 0 ]!,	'[LocationPath:absolute[Step[NameTest:bbb][Predicate[EqualityExpr:=[MultiplicativeExpr:mod[FunctionCall:position][Number:2]][Number:0]]]]]');
test_tree(q!/bbb[normalize-space(@name)='a']!,	'[LocationPath:absolute[Step[NameTest:bbb][Predicate[EqualityExpr:=[FunctionCall:normalize-space[FunctionArg[LocationPath[Step::attribute[NameTest:name]]]]][Literal:a]]]]]');

test_tree(q!/bbb[ position() = floor(last-id() div 2 + 0.5) or position() = ceiling(last-id() div 2 + 0.5) ]!,
	'[LocationPath:absolute[Step[NameTest:bbb][Predicate[OrExpr:or[EqualityExpr:=[FunctionCall:position]'.
	'[FunctionCall:floor[FunctionArg[AdditiveExpr:+[MultiplicativeExpr:div[FunctionCall:last-id][Number:2]]'.
	'[Number:0.5]]]]][EqualityExpr:=[FunctionCall:position][FunctionCall:ceiling[FunctionArg[AdditiveExpr:+'.
	'[MultiplicativeExpr:div[FunctionCall:last-id][Number:2]][Number:0.5]]]]]]]]]');


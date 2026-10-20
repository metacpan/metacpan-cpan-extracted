#! perl

use strict;
use warnings;

use lib 'lib', 't/lib';

use Test::More;
use Test::FitNesse::Slim::ListExecutor;

my $list = Test::FitNesse::Slim::ListExecutor->new;
my @setup = $list->execute(
  ['i', 'import', 'fitnesse.slim.test'],
  ['m', 'make', 'actor', 'TestSlim'],
  ['c', 'callAndAssign', 'NULL_VALUE', 'actor', 'null'],
);
is_deeply(\@setup, [['i', 'OK'], ['m', 'OK'], ['c', 'null']],
  'callAndAssign returns the wire null token for an undefined fixture result');

my $executor = $list->executor;
ok(exists $executor->{symbol}{NULL_VALUE}, 'callAndAssign stores the null-valued symbol');
ok(!defined $executor->get_symbol('NULL_VALUE'), 'callAndAssign retains null internally');

my @exact = $executor->replace_symbols('$NULL_VALUE');
ok(!defined $exact[0], 'exact reference to a stored null remains null');

my @embedded = $executor->replace_symbols('value=$NULL_VALUE');
is($embedded[0], 'value=null', 'embedded reference to a stored null uses null text');

my @undefined = $executor->replace_symbols('$NOT_ASSIGNED');
is($undefined[0], '$NOT_ASSIGNED', 'missing symbol reference remains unchanged');

my $object = bless {}, 'SymbolNullTest::Object';
$executor->set_symbol('OBJECT', $object);
my @object = $executor->replace_symbols('$OBJECT');
is($object[0], $object, 'exact symbol reference preserves object identity');

done_testing;

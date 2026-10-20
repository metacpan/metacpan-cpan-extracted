#! perl

use strict;
use warnings;

use lib 't/lib';

use Test::More;

use Fitnesse::Fixtures::SplitFixture;
use Fitnesse::Fixtures::DuplicateRows;

my $split = Fitnesse::Fixtures::SplitFixture->new('Bob,Martin;Bill,Jones;Ben,Jacobs');
is_deeply($split->query, [
  [['1', 'Bob'], ['2', 'Martin']],
  [['1', 'Bill'], ['2', 'Jones']],
  [['1', 'Ben'], ['2', 'Jacobs']],
], 'SplitFixture returns ordered column/value pairs');

my $single_column = Fitnesse::Fixtures::SplitFixture->new('Bob;Bill;Ben');
is_deeply($single_column->query, [[['1', 'Bob']], [['1', 'Bill']], [['1', 'Ben']]], 'SplitFixture supports one column');

my $numeric = Fitnesse::Fixtures::SplitFixture->new('1.1,2.3;5.5,6.9;3.1,5');
is_deeply($numeric->query, [[['1', '1.1'], ['2', '2.3']], [['1', '5.5'], ['2', '6.9']], [['1', '3.1'], ['2', '5']]], 'SplitFixture preserves numeric text');

my $unicode = Fitnesse::Fixtures::SplitFixture->new("東京,🙂;é,漢字");
is_deeply($unicode->query, [[['1', "東京"], ['2', "🙂"]], [['1', "é"], ['2', "漢字"]]], 'SplitFixture preserves Unicode cells');

my $empty = Fitnesse::Fixtures::SplitFixture->new('');
is_deeply($empty->query, [[['1', '']]], 'SplitFixture represents an empty schema as an empty cell');
my $trailing = Fitnesse::Fixtures::SplitFixture->new('Alice,;Bob,,Jones;');
is_deeply($trailing->query, [[['1', 'Alice']], [['1', 'Bob'], ['2', ''], ['3', 'Jones']]], 'SplitFixture drops trailing split fields but retains interior empty cells');
my $null_schema = Fitnesse::Fixtures::SplitFixture->new(undef);
ok(!eval { $null_schema->query; 1 }, 'SplitFixture raises an exception for a null schema');

my $rows_a = Fitnesse::Fixtures::DuplicateRows->new('A')->query;
is_deeply($rows_a, [
  [['x', 'SuiteChildOne.SuiteSetUp']],
  [['x', 'SuiteChildOne.TestOneOne']],
  [['x', 'SuiteChildOne.TestOneTwo']],
  [['x', 'SuiteChildOne.SuiteTearDown']],
  [['x', 'SuiteChildOne.SuiteSetUp']],
  [['x', 'SuiteChildOne.TestOneThree']],
  [['x', 'SuiteChildOne.SuiteTearDown']],
], 'DuplicateRows phase A preserves upstream row order and duplicates');

my $rows_b = Fitnesse::Fixtures::DuplicateRows->new('B')->query;
is_deeply($rows_b, [
  [['x', 'SuiteChildOne.SuiteSetUp']],
  [['x', 'SuiteChildOne.TestOneThree']],
  [['x', 'SuiteChildOne.SuiteTearDown']],
  [['x', 'SuiteChildOne.SuiteSetUp']],
  [['x', 'SuiteChildOne.TestOneOne']],
  [['x', 'SuiteChildOne.TestOneTwo']],
  [['x', 'SuiteChildOne.SuiteTearDown']],
], 'DuplicateRows phase B returns its alternate upstream row order');
is_deeply(Fitnesse::Fixtures::DuplicateRows->new('a')->query, $rows_a, 'DuplicateRows compares phase names without case sensitivity');

is(scalar(grep { $_->[0][1] eq 'SuiteChildOne.SuiteSetUp' } @$rows_a), 2, 'DuplicateRows retains repeated rows');
is(scalar(grep { $_->[0][1] eq 'SuiteChildOne.SuiteTearDown' } @$rows_b), 2, 'DuplicateRows retains duplicate teardown rows');
my $null_phase = Fitnesse::Fixtures::DuplicateRows->new(undef);
ok(!eval { $null_phase->query; 1 }, 'DuplicateRows raises an exception for a null phase');

done_testing;

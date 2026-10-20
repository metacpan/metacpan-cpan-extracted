#! perl

use strict;
use warnings;

use lib 'lib';

use Test::More;
use Test::FitNesse::Slim::ListExecutor;

my $list_executor = Test::FitNesse::Slim::ListExecutor->new;
my $value = 'table-cell-value';
my @assigned = $list_executor->execute(['a1', 'assign', 'TABLE', $value]);
is_deeply($assigned[0], ['a1', 'OK'], 'assign returns OK');
is($list_executor->executor->get_symbol('TABLE'), $value, 'assign stores its value as a symbol');

my @null = $list_executor->execute(['a2', 'assign', 'NULL_VALUE', undef]);
is_deeply($null[0], ['a2', 'OK'], 'assign accepts a null value');
ok(exists $list_executor->executor->{symbol}{NULL_VALUE}, 'null assignment creates the symbol');
is(defined $list_executor->executor->get_symbol('NULL_VALUE'), '', 'null assignment preserves undefined');

done_testing;

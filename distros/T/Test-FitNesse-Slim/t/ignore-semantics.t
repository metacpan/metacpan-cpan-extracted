#! perl

use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::FitNesse::Slim::ListExecutor;
use Test::FitNesse::Slim::StatementExecutor;

for my $case (
  [ script => 'throwIgnoreScriptStopping', '__EXCEPTION__:IGNORE_SCRIPT_TEST:' ],
  [ all    => 'throwIgnoreAllStopping',    '__EXCEPTION__:IGNORE_ALL_TESTS:' ],
) {
  my($scope, $method, $marker) = @$case;
  my $list = Test::FitNesse::Slim::ListExecutor->new;
  my @result = $list->execute(
    ['import', 'import', 'fitnesse.slim.test'],
    ['make', 'make', 'actor', 'TestSlim'],
    ['ignore', 'call', 'actor', $method],
    ['skipped', 'call', 'actor', 'dieInside'],
  );
  is($result[2][1], $marker, "$scope ignore exception returns the exact protocol marker");
  is(scalar @result, 3, "$scope ignore skips remaining instructions in the current batch");

  my @next = $list->execute(['next', 'call', 'actor', 'returnString']);
  is_deeply(\@next, [['next', 'string']], "$scope ignore state resets at the next batch boundary");
}

my $executor = Test::FitNesse::Slim::StatementExecutor->new;
is($executor->create('actor', 'Fitnesse::Slim::Test::TestSlim', []), 'OK',
  'create actor for ordinary exception check');
my $ordinary = $executor->call('actor', 'throwNormalMentioningIgnore');
is($ordinary, '__EXCEPTION__:java.lang.Exception: IgnoreAllTests is only mentioned here',
  'text resembling an ignore name does not trigger ignore handling');

my $sut_list = Test::FitNesse::Slim::ListExecutor->new;
my @sut_ignore = $sut_list->execute(
  ['make', 'make', 'actor', 'Fitnesse::Slim::Test::SystemUnderTestDriver'],
  ['ignore', 'callAndAssign', 'ignored', 'actor', 'throwIgnoreAll'],
  ['skipped', 'call', 'actor', 'sutOnly'],
);
is($sut_ignore[1][1], '__EXCEPTION__:IGNORE_ALL_TESTS:',
  'ignore exceptions raised by a delegated SUT retain their protocol marker');
is(scalar @sut_ignore, 2, 'delegated SUT ignore stops the rest of its current batch');
ok(!exists $sut_list->executor->{symbol}{ignored},
  'callAndAssign does not bind a symbol when the delegated call throws an ignore exception');
my @sut_next = $sut_list->execute(['next', 'call', 'actor', 'sutOnly']);
is_deeply(\@sut_next, [['next', 'sut']], 'the following SLiM batch can execute after an ignore marker');

my $constructor_list = Test::FitNesse::Slim::ListExecutor->new;
my @constructor = $constructor_list->execute(
  ['make', 'make', 'actor', 'Fitnesse::Slim::Test::IgnoreConstructor'],
  ['skipped', 'call', 'actor', 'anything'],
);
is($constructor[0][1], '__EXCEPTION__:IGNORE_ALL_TESTS:',
  'ignore exceptions from fixture construction use the all-tests marker');
is(scalar @constructor, 1, 'constructor ignore stops the current instruction batch');

done_testing;

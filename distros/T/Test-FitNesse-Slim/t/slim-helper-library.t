#! perl

use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Scalar::Util qw(refaddr);
use Test::FitNesse::Slim::StatementExecutor;
use Test::FitNesse::Slim::Statement;
use Test::FitNesse::Slim::List;

my $empty_executor = Test::FitNesse::Slim::StatementExecutor->new;
my $missing_actor = Test::FitNesse::Slim::Statement->execute(
  $empty_executor, 'get-missing-actor', 'call', 'scriptTableActor', 'get_fixture'
)->[1];
like($missing_actor, qr/^__EXCEPTION__:message:<<NO_INSTANCE scriptTableActor\./,
  'getFixture reports the upstream missing-actor exception');

my $executor = Test::FitNesse::Slim::StatementExecutor->new;
$executor->add_import('fitnesse.slim.test');
isa_ok(
  $executor->{instance}{__slim_helper_library},
  'Test::FitNesse::Slim::SlimHelperLibrary',
  'each executor constructs its automatic helper library'
);

is_deeply(
  Test::FitNesse::Slim::Statement->execute($executor, 'make-actor', 'make', 'scriptTableActor', 'TestSlim'),
  [ 'make-actor' => 'OK' ],
  'the executor creates the script table actor'
);
Test::FitNesse::Slim::Statement->execute($executor, 'set-actor', 'call', 'scriptTableActor', 'set_string', 'Uncle');

my $actor = Test::FitNesse::Slim::Statement->execute(
  $executor, 'get-actor', 'call', 'scriptTableActor', 'get_fixture'
)->[1];
isa_ok($actor, 'Fitnesse::Slim::Test::TestSlim', 'getFixture returns the current actor');
is($actor->get_string_arg, 'Uncle', 'getFixture retains the actor state');
is(
  Test::FitNesse::Slim::List->new([ 'result' => $actor ])->serialize,
  '[000002:000006:result:000018:TestSlim: 0, Uncle:]',
  'the fixture stringifies like upstream TestSlim when returned over SLiM'
);

is_deeply(
  Test::FitNesse::Slim::Statement->execute($executor, 'push-actor', 'call', 'scriptTableActor', 'push_fixture'),
  [ 'push-actor' => 'null' ],
  'pushFixture has no return value'
);
Test::FitNesse::Slim::Statement->execute($executor, 'make-next', 'make', 'scriptTableActor', 'TestSlim');
Test::FitNesse::Slim::Statement->execute($executor, 'set-next', 'call', 'scriptTableActor', 'set_string', 'Bob');
my $next_actor = Test::FitNesse::Slim::Statement->execute(
  $executor, 'get-next', 'call', 'scriptTableActor', 'get_fixture'
)->[1];
isnt(refaddr($next_actor), refaddr($actor), 'replacing the actor creates a distinct fixture instance');
is($next_actor->get_string_arg, 'Bob', 'the replacement actor has independent state');
Test::FitNesse::Slim::Statement->execute($executor, 'push-nested-actor', 'call', 'scriptTableActor', 'push_fixture');
Test::FitNesse::Slim::Statement->execute($executor, 'make-third', 'make', 'scriptTableActor', 'TestSlim');
Test::FitNesse::Slim::Statement->execute($executor, 'set-third', 'call', 'scriptTableActor', 'set_string', 'Carol');
Test::FitNesse::Slim::Statement->execute($executor, 'pop-nested-actor', 'call', 'scriptTableActor', 'pop_fixture');
my $nested_restored = Test::FitNesse::Slim::Statement->execute(
  $executor, 'get-nested-restored', 'call', 'scriptTableActor', 'get_fixture'
)->[1];
is(refaddr($nested_restored), refaddr($next_actor), 'nested pop restores the most recently pushed actor');
is($nested_restored->get_string_arg, 'Bob', 'nested pop preserves that actor state');

is_deeply(
  Test::FitNesse::Slim::Statement->execute($executor, 'pop-actor', 'call', 'scriptTableActor', 'pop_fixture'),
  [ 'pop-actor' => 'null' ],
  'popFixture has no return value'
);
my $restored = Test::FitNesse::Slim::Statement->execute(
  $executor, 'get-restored', 'call', 'scriptTableActor', 'get_fixture'
)->[1];
is(refaddr($restored), refaddr($actor), 'popFixture restores the exact actor reference');
is($restored->get_string_arg, 'Uncle', 'restored actor state is preserved');

{
  package SlimHelperActorOverride;
  sub get_fixture { 'actor method' }
}
$executor->{instance}{scriptTableActor} = bless {}, 'SlimHelperActorOverride';
is_deeply(
  Test::FitNesse::Slim::Statement->execute($executor, 'actor-precedence', 'call', 'scriptTableActor', 'get_fixture'),
  [ 'actor-precedence' => 'actor method' ],
  'the actor method takes precedence over the automatic library'
);
$executor->{instance}{scriptTableActor} = $restored;

my $nested = Test::FitNesse::Slim::StatementExecutor->new;
$nested->add_import('fitnesse.slim.test');
Test::FitNesse::Slim::Statement->execute($nested, 'make-nested', 'make', 'scriptTableActor', 'TestSlim');
Test::FitNesse::Slim::Statement->execute($executor, 'push-again', 'call', 'scriptTableActor', 'push_fixture');
Test::FitNesse::Slim::Statement->execute($nested, 'push-nested', 'call', 'scriptTableActor', 'push_fixture');
is_deeply(
  Test::FitNesse::Slim::Statement->execute($executor, 'pop-again', 'call', 'scriptTableActor', 'pop_fixture'),
  [ 'pop-again' => 'null' ],
  'another executor has an independent actor stack'
);
is_deeply(
  Test::FitNesse::Slim::Statement->execute($nested, 'pop-nested', 'call', 'scriptTableActor', 'pop_fixture'),
  [ 'pop-nested' => 'null' ],
  'the nested executor can still pop its own actor'
);

my $empty_pop = Test::FitNesse::Slim::Statement->execute(
  $nested, 'pop-empty', 'call', 'scriptTableActor', 'pop_fixture'
);
is($empty_pop->[0], 'pop-empty', 'empty-stack response retains the statement id');
like($empty_pop->[1], qr/^__EXCEPTION__:message:<<EmptyStackException\b/,
  'popFixture reports the upstream empty-stack exception');

done_testing;

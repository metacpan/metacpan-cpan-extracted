#! perl

use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::FitNesse::Slim::StatementExecutor;

my $executor = Test::FitNesse::Slim::StatementExecutor->new;
is($executor->create('actor', 'Fitnesse::Slim::Test::SystemUnderTestDriver', []), 'OK',
  'make actor with system under test');
is($executor->create('library1', 'Fitnesse::Slim::Test::Library::SystemUnderTestFallback', []), 'OK',
  'make fallback library');

is($executor->call('actor', 'shared'), 'actor', 'actor method takes precedence over SUT');
is($executor->call('actor', 'sutOnly'), 'sut', 'missing actor method delegates to SUT');
is($executor->call('actor', 'libraryOnly'), 'library', 'missing actor and SUT methods fall through to library');
like($executor->call('actor', 'noSuchMethod'), qr/^__EXCEPTION__:message:<<NO_METHOD_IN_CLASS /,
  'missing method after actor, SUT, and library lookup is reported');

my $camel_actor = bless {
  systemUnderTest => Fitnesse::Slim::Test::SystemUnderTestService->new,
}, 'Fitnesse::Slim::Test::SystemUnderTestDriver';
is($executor->create('camel_actor', $camel_actor, []), 'OK',
  'register an actor using Java-compatible SUT field spelling');
is($executor->call('camel_actor', 'sutOnly'), 'sut',
  'Java-compatible systemUnderTest field spelling delegates');

my $driver = $executor->instance('actor');
my $token = $executor->call_and_assign('token', 'actor', 'makeToken');
is(ref($token), 'Fitnesse::Slim::Test::SystemUnderTestToken', 'actor can assign an object symbol');
is($executor->call('actor', 'keepToken', '$token'), 'stored', 'SUT accepts the exact object symbol');
is($executor->call('actor', 'sameToken', '$token'), 'true', 'symbol object identity is preserved through SUT dispatch');

like($executor->call('actor', 'fail'), qr/^__EXCEPTION__:java\.lang\.IllegalStateException: SUT failed$/,
  'SUT exception is returned and does not fall through to a library');

done_testing;

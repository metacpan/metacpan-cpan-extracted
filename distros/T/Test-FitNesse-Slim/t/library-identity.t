use strict;
use warnings;
use Test::More;

use lib 'lib', 't/lib';

use Test::FitNesse::Slim::StatementExecutor;
use Test::FitNesse::Slim::Statement;

my $executor = Test::FitNesse::Slim::StatementExecutor->new;
$executor->add_import('fitnesse.slim.test.library');

is_deeply(
    Test::FitNesse::Slim::Statement->execute($executor, 'custom-actor', 'make', 'customActor', 'LibraryFixture'),
    ['custom-actor', 'OK'],
    'make actor for prefixed library ID coverage',
);
is_deeply(
    Test::FitNesse::Slim::Statement->execute($executor, 'custom-library', 'make', 'libraryCustom', 'EchoSupport'),
    ['custom-library', 'OK'],
    'register library with a nonnumeric suffix',
);
is_deeply(
    Test::FitNesse::Slim::Statement->execute($executor, 'custom-library-call', 'call', 'customActor', 'echo'),
    ['custom-library-call', 'null'],
    'method lookup includes library IDs that begin with library',
);
is_deeply(
    Test::FitNesse::Slim::Statement->execute($executor, 'custom-library-state', 'call', 'customActor', 'echoSupportCalled'),
    ['custom-library-state', 'true'],
    'prefixed library receives the delegated call',
);

is_deeply(
    Test::FitNesse::Slim::Statement->execute($executor, 'actor', 'make', 'actor', 'LibraryFixture'),
    ['actor', 'OK'],
    'make a fixture actor',
);
is_deeply(
    Test::FitNesse::Slim::Statement->execute($executor, 'setup', 'make', 'library1', 'LibraryInSetUp'),
    ['setup', 'OK'],
    'register the setup library',
);
is_deeply(
    Test::FitNesse::Slim::Statement->execute($executor, 'page', 'make', 'library1', 'EchoSupport'),
    ['page', 'OK'],
    'register the page library with the reused library ID',
);
isa_ok(
    $executor->instance('library1'),
    'Fitnesse::Slim::Test::Library::LibraryInSetUp',
    'instance lookup returns the first registered library with that ID',
);
is_deeply(
    Test::FitNesse::Slim::Statement->execute($executor, 'named-library', 'call', 'library1', 'echoInSetUpLibraryCalled'),
    ['named-library', 'false'],
    'direct lookup by a reused library ID follows upstream first-registration behavior',
);
is_deeply(
    Test::FitNesse::Slim::Statement->execute($executor, 'echo', 'call', 'actor', 'echo'),
    ['echo', 'null'],
    'call resolves to the newest library',
);
is_deeply(
    Test::FitNesse::Slim::Statement->execute($executor, 'page-state', 'call', 'actor', 'echoSupportCalled'),
    ['page-state', 'true'],
    'newest library retains its own call state',
);
is_deeply(
    Test::FitNesse::Slim::Statement->execute($executor, 'setup-state', 'call', 'actor', 'echoInSetUpLibraryCalled'),
    ['setup-state', 'false'],
    'earlier same-ID library remains available for methods absent in newer libraries',
);

done_testing;

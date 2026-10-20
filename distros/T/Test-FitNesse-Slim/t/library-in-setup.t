use strict;
use warnings;
use Test::More;

use lib 'lib', 't/lib';

use_ok('Test::FitNesse::Slim::StatementExecutor');
use_ok('Test::FitNesse::Slim::Statement');

my $executor = Test::FitNesse::Slim::StatementExecutor->new;
$executor->add_import('fitnesse.slim.test');
$executor->add_import('fitnesse.slim.test.library');

is_deeply(
    Test::FitNesse::Slim::Statement->execute($executor, 'actor', 'make', 'actor', 'LibraryFixture'),
    ['actor', 'OK'],
    'make the fixture whose missing calls are delegated to libraries',
);
is_deeply(
    Test::FitNesse::Slim::Statement->execute($executor, 'library', 'make', 'library1', 'LibraryInSetUp'),
    ['library', 'OK'],
    'load the setup library by its graceful name',
);
is_deeply(
    Test::FitNesse::Slim::Statement->execute($executor, 'echo', 'call', 'actor', 'echo'),
    ['echo', 'null'],
    'delegate the fixture-missing method to the setup library',
);
is_deeply(
    Test::FitNesse::Slim::Statement->execute($executor, 'called', 'call', 'library1', 'echoInSetUpLibraryCalled'),
    ['called', 'true'],
    'retain call tracking on the library instance for later inspection',
);

done_testing;

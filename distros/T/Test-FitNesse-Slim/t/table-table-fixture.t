use strict;
use warnings;
use Test::More;

use lib 'lib', 't/lib';

use Test::FitNesse::Slim::StatementExecutor;
use Test::FitNesse::Slim::Statement;

my $executor = Test::FitNesse::Slim::StatementExecutor->new;
$executor->add_import('fitnesse.slim.test');
$executor->add_import('fitnesse.slim.test.statementexecutorconsumer');
$executor->add_import('fitnesse.slim.test');

is_deeply(
    Test::FitNesse::Slim::Statement->execute($executor, 'actor', 'make', 'scriptTableActor', 'TestSlim'),
    ['actor', 'OK'],
    'make the fixture used to check assigned symbols',
);
$executor->set_symbol('X', 99);
is_deeply(
    Test::FitNesse::Slim::Statement->execute($executor, 'table', 'make', 'tableTable_1', 'TableTableIncFirstCol'),
    ['table', 'OK'],
    'make the fixture that manages symbols inside its table',
);

my $rows = [
    (map { [ '$X', '$X=' ] } 1 .. 5),
    [ '$X', '$Y=' ],
];
is_deeply(
    Test::FitNesse::Slim::Statement->execute($executor, 'run', 'call', 'tableTable_1', 'doTable', $rows),
    ['run', [ map { [ 'no change', 'pass:' . (99 + $_) ] } 1 .. 6 ]],
    'table results retain row order and report each increment',
);
is_deeply(
    Test::FitNesse::Slim::Statement->execute($executor, 'x', 'call', 'scriptTableActor', 'echoInt', '$X'),
    ['x', 104],
    'symbol X retains the fifth in-table assignment after normal substitution resumes',
);
is_deeply(
    Test::FitNesse::Slim::Statement->execute($executor, 'y', 'call', 'scriptTableActor', 'echoInt', '$Y'),
    ['y', 105],
    'symbol Y receives the final in-table assignment',
);

done_testing;

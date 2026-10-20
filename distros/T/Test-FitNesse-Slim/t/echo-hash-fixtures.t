use strict;
use warnings;
use Test::More;

use lib 'lib', 't/lib';

use Test::FitNesse::Slim::StatementExecutor;
use Test::FitNesse::Slim::Statement;

my $executor = Test::FitNesse::Slim::StatementExecutor->new;
$executor->add_import('fitnesse.fixtures');

is_deeply(
    Test::FitNesse::Slim::Statement->execute($executor, 'echo-make', 'make', 'echo', 'EchoFixture'),
    ['echo-make', 'OK'],
    'make EchoFixture',
);
is_deeply(
    Test::FitNesse::Slim::Statement->execute($executor, 'set-name', 'call', 'echo', 'setName', 'foobar'),
    ['set-name', 'null'],
    'setName stores the fixture name and has no return value',
);
is_deeply(
    Test::FitNesse::Slim::Statement->execute($executor, 'name', 'call', 'echo', 'name'),
    ['name', 'foobar'],
    'name returns the stored value',
);
is_deeply(
    Test::FitNesse::Slim::Statement->execute($executor, 'log', 'call', 'echo', 'echoAndLog', '<em>bold</em>'),
    ['log', '<em>bold</em>'],
    'echoAndLog returns markup unchanged',
);

is_deeply(
    Test::FitNesse::Slim::Statement->execute($executor, 'hash-make', 'make', 'hash', 'HashFixture'),
    ['hash-make', 'OK'],
    'make HashFixture',
);
is_deeply(
    Test::FitNesse::Slim::Statement->execute($executor, 'send', 'call', 'hash', 'sendAsHash', {
        script => '<em><b>bold</b></em>',
    }),
    ['send', 'null'],
    'send the upstream HTML map argument',
);
is_deeply(
    Test::FitNesse::Slim::Statement->execute($executor, 'lookup', 'call', 'hash', 'hashIs', 'script'),
    ['lookup', '<em><b>bold</b></em>'],
    'hashIs returns the stored value with markup intact',
);

done_testing;

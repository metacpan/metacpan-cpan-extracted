use strict;
use warnings;
use Test::More;

use lib 'lib';

use Test::FitNesse::Slim::StatementExecutor;
use Test::FitNesse::Slim::Statement;

{
    package TestSlim::SymbolConsumerFixture;

    sub new { bless {}, shift }
    sub set_statement_executor {
        my ($self, $executor) = @_;
        $self->{executor} = $executor;
        $executor->set_symbol('SLIM_AGENT_FIXTURE_HANDLES_SYMBOLS', 'table\\.doTable');
    }
    sub do_table {
        my ($self, $table) = @_;
        $self->{executor}->set_symbol('SLIM_AGENT_FIXTURE_HANDLES_SYMBOLS', undef);
        return $table;
    }
    sub echo { return $_[1] }
}

my $executor = Test::FitNesse::Slim::StatementExecutor->new;
$executor->set_symbol('X', 99);
my $fixture = TestSlim::SymbolConsumerFixture->new;
$executor->set_symbol('fixture', $fixture);

is_deeply(
    Test::FitNesse::Slim::Statement->execute($executor, 'make', 'make', 'table', '$fixture'),
    ['make', 'OK'],
    'make injects the statement executor into consumer fixtures',
);
ok($fixture->{executor} == $executor, 'consumer receives the live executor object');
is_deeply(
    Test::FitNesse::Slim::Statement->execute($executor, 'table', 'call', 'table', 'doTable', [[ '$X' ]]),
    ['table', [[ '$X' ]]],
    'consumer-managed table calls receive symbols without automatic substitution',
);
is_deeply(
    Test::FitNesse::Slim::Statement->execute($executor, 'echo', 'call', 'table', 'echo', '$X'),
    ['echo', 99],
    'automatic symbol substitution resumes when the fixture releases control',
);

done_testing;

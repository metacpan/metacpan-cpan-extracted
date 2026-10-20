use strict;
use warnings;

use lib 'lib', 't/lib';

use Test::More;
use Test::FitNesse::Slim::List;
use Test::FitNesse::Slim::ListExecutor;

sub execute_wire {
    my ($executor, @instructions) = @_;
    my $wire = Test::FitNesse::Slim::List->new(\@instructions)->serialize;
    my @decoded = Test::FitNesse::Slim::List->new($wire)->list;
    return $executor->execute(@decoded);
}

my $list = Test::FitNesse::Slim::ListExecutor->new;
my @setup = execute_wire($list,
    ['import-test', 'import', 'fitnesse.slim.test'],
    ['make-actor', 'make', 'scriptTableActor', 'TestSlim'],
    ['set-a', 'assign', 'A', 99],
    ['set-b', 'assign', 'B', 5],
    ['set-c', 'assign', 'C', 14],
    ['make-table', 'make', 'tableTable_1', 'TableTableIncFirstCol'],
);
my $executor = $list->executor;
is_deeply(
    \@setup,
    [map { [$_, 'OK'] } qw(import-test make-actor set-a set-b set-c make-table)],
    'construct the ordinary Table Table fixture through SLiM instructions',
);

my @table = execute_wire($list,
    ['ordinary-table', 'call', 'tableTable_1', 'doTable', [
        ['$A', '$resultA='],
        ['$B', '$resultB='],
        ['$C', '$C='],
    ]],
);
is_deeply(
    $table[0],
    ['ordinary-table', [
        ['no change', 'pass:100'],
        ['no change', 'pass:6'],
        ['no change', 'pass:15'],
    ]],
    'ordinary symbols are substituted before the Table Table fixture runs',
);

my @boundaries = execute_wire($list,
    ['integer-boundaries', 'call', 'tableTable_1', 'doTable', [
        ['2147483647', 'ignored'],
        ['-2147483648', 'ignored'],
    ]],
);
is_deeply(
    $boundaries[0],
    ['integer-boundaries', [
        ['no change', 'pass:-2147483648'],
        ['no change', 'pass:-2147483647'],
    ]],
    'integer parsing and increment match Java signed-int boundaries',
);

my @empty = execute_wire($list,
    ['empty-value', 'call', 'tableTable_1', 'doTable', [['', 'ignored']]],
);
like($empty[0][1], qr/^__EXCEPTION__:.*NumberFormatException/,
    'an empty value follows Java Integer.parseInt failure behavior');
my $null_error;
eval { $executor->{instance}{tableTable_1}->do_table([[undef, 'ignored']]) };
$null_error = $@;
like($null_error, qr/^java\.lang\.NullPointerException/,
    'a null value follows the Java fixture toString failure behavior');

is_deeply(
    [map { $executor->get_symbol($_) } qw(A B C resultA resultB)],
    [99, 5, 14, undef, undef],
    'fixture execution does not mutate or leak symbols between rows',
);
ok(
    !defined $executor->{fixture_symbol_pattern},
    'ordinary fixture leaves normal symbol handling enabled',
);

my $isolated = Test::FitNesse::Slim::ListExecutor->new;
my @isolated_setup = execute_wire($isolated,
    ['import-test', 'import', 'fitnesse.slim.test'],
    ['make-table', 'make', 'tableTable_1', 'TableTableIncFirstCol'],
);
is_deeply(\@isolated_setup, [['import-test', 'OK'], ['make-table', 'OK']],
    'a separate SLiM executor constructs its own fixture instance');
ok(!defined $isolated->executor->get_symbol('A'),
    'symbols from the first executor do not leak into another session');
my @isolated_result = execute_wire($isolated,
    ['ordinary-table', 'call', 'tableTable_1', 'doTable', [[7, '$X=']]],
);
is_deeply(
    $isolated_result[0],
    ['ordinary-table', [['no change', 'pass:8']]],
    'the isolated fixture has no shared mutable row state',
);

done_testing;

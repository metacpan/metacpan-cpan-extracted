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

my $slim = Test::FitNesse::Slim::ListExecutor->new;
is_deeply(
    [execute_wire($slim,
        ['import-test', 'import', 'fitnesse.slim.test'],
        ['make-table', 'make', 'tableTable_1', 'DummyTableTableReturnsNull'],
    )],
    [['import-test', 'OK'], ['make-table', 'OK']],
    'construct the null-returning table fixture through SLiM instructions',
);

my $fixture = $slim->executor->instance('tableTable_1');
is(ref($fixture), 'Fitnesse::Slim::Test::DummyTableTableReturnsNull',
    'the imported upstream fixture name resolves to the matching Perl adapter');

my $request = Test::FitNesse::Slim::List->new([
    ['table-call', 'call', 'tableTable_1', 'doTable', [[]]],
]);
my @instructions = Test::FitNesse::Slim::List->new($request->serialize)->list;
my @response = $slim->execute(@instructions);
is_deeply(\@response, [['table-call', 'null']],
    'a null table result follows ordinary statement execution');
is(Test::FitNesse::Slim::List->new(\@response)->serialize,
    '[000001:000039:[000002:000010:table-call:000004:null:]:]',
    'the null table result uses the existing SLiM null wire representation');

my $wire_values = Test::FitNesse::Slim::List->new([undef, '', []])->serialize;
is_deeply([Test::FitNesse::Slim::List->new($wire_values)->list], ['null', '', []],
    'null, empty string, and empty list retain distinct serialized values');

my @again = execute_wire($slim,
    ['again', 'call', 'tableTable_1', 'doTable', [[['x']]]],
);
is_deeply(\@again, [['again', 'null']], 'the fixture returns null on repeated calls');

my @missing = execute_wire($slim,
    ['missing-method', 'call', 'tableTable_1', 'noSuchMethod'],
);
like($missing[0][1], qr/^__EXCEPTION__:.*NO_METHOD_IN_CLASS/,
    'an absent fixture method remains distinct from a null return');

my $other = Test::FitNesse::Slim::ListExecutor->new;
my @other_result = execute_wire($other,
    ['import-test', 'import', 'fitnesse.slim.test'],
    ['make-table', 'make', 'table_2', 'DummyTableTableReturnsNull'],
    ['null-result', 'call', 'table_2', 'doTable', [[]]],
);
is_deeply(\@other_result,
    [['import-test', 'OK'], ['make-table', 'OK'], ['null-result', 'null']],
    'a separate executor constructs and invokes an independent fixture');

done_testing;

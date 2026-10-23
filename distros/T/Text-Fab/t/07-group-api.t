use strict;
use warnings;
use Test::More;
use Test::Exception;
use Text::Fab;

use_ok('Text::Fab');

my $fab = Text::Fab->new();

$fab->cfg__set('foo', 'initial');
$fab->group__start();
$fab->cfg__set('foo', 'modified');
is($fab->cfg__get('foo'), 'modified', 'value modified inside untagged group');
$fab->group__end();
is($fab->cfg__get('foo'), 'initial', 'value restored after untagged group__end');

$fab->group__start('scope1');
is_deeply($fab->cfg__get('opened_groups'), ['scope1'], 'opened_groups updated on start');
$fab->cfg__set('foo', 'in_scope1');
lives_ok { $fab->group__end('scope1') } 'matching flavor group__end lives';
is($fab->cfg__get('foo'), 'initial', 'value restored after scope1');
is_deeply($fab->cfg__get('opened_groups'), [], 'opened_groups cleared on end');

$fab->group__start('outer');
throws_ok { $fab->group__end('wrong_flavor') } qr/E_MISMATCHED_END_GROUP/,
    'mismatched flavor dies with E_MISMATCHED_END_GROUP';
$fab->group__end('outer');

throws_ok { $fab->group__end() } qr/E_DANGLING_END_GROUP/,
    'dangling group__end dies with E_DANGLING_END_GROUP';

subtest 'Group nesting constraints (E_INVALID_GROUP_NESTING)' => sub {
    my $fab_nest = Text::Fab->new(config => {
        'Fab/group_nesting/inner_flavor/allowed_parents' => ['valid_outer']
    });

    $fab_nest->group__start('valid_outer');
    lives_ok { $fab_nest->group__start('inner_flavor') }
        'nested group inside allowed parent succeeds';
    $fab_nest->group__end('inner_flavor');
    $fab_nest->group__end('valid_outer');

    $fab_nest->group__start('forbidden_outer');
    throws_ok { $fab_nest->group__start('inner_flavor') } qr/E_INVALID_GROUP_NESTING/,
        'nested group inside forbidden parent dies with E_INVALID_GROUP_NESTING';
    $fab_nest->group__end('forbidden_outer');
};

subtest 'Unified undo semantics: failures do not abort remaining undos or rollback' => sub {
    my $fab_guard = Text::Fab->new();
    $fab_guard->cfg__set('target', 'initial_val');

    $fab_guard->group__start('guarded_scope');
    $fab_guard->cfg__set('target', 'modified_val');

    my @executed_stages;

    $fab_guard->group__postpone(0, -20.0, 'append', sub {
        push @executed_stages, 'pre_fail';
        die "error_at_pre_20\n";
    });

    $fab_guard->group__postpone(0, -10.0, 'append', sub {
        push @executed_stages, 'pre_subsequent';
    });

    $fab_guard->group__postpone(0, 5.0, 'append', sub {
        push @executed_stages, 'post_fail';
        die "error_at_post_5\n";
    });

    $fab_guard->group__postpone(0, 10.0, 'append', sub {
        push @executed_stages, 'post_subsequent';
    });

    throws_ok { $fab_guard->group__end('guarded_scope') } qr/error_at_pre_20/,
        'group__end rethrows the primary error caught during undo';

    is_deeply(\@executed_stages,
        ['pre_fail', 'pre_subsequent', 'post_fail', 'post_subsequent'],
        'all undo actions ran despite intermediate errors');

    is($fab_guard->cfg__get('target'), 'initial_val',
        'snapshot rollback restored configuration despite errors in both pre and post phases');
    is_deeply($fab_guard->cfg__get('opened_groups'), [],
        'group stack was safely unwound');
};

subtest 'Equal priority ordering delegated to user (prepend vs append)' => sub {
    my $fab_prio = Text::Fab->new();
    my @order;

    $fab_prio->group__start();

    $fab_prio->group__postpone(0, -5.0, 'append',  sub { push @order, 'pre_mid' });
    $fab_prio->group__postpone(0, -5.0, 'append',  sub { push @order, 'pre_tail' });
    $fab_prio->group__postpone(0, -5.0, 'prepend', sub { push @order, 'pre_head' });

    $fab_prio->group__postpone(0, 2.5, 'append',  sub { push @order, 'post_mid' });
    $fab_prio->group__postpone(0, 2.5, 'append',  sub { push @order, 'post_tail' });
    $fab_prio->group__postpone(0, 2.5, 'prepend', sub { push @order, 'post_head' });

    $fab_prio->group__end();

    is_deeply(\@order,
        ['pre_head', 'pre_mid', 'pre_tail', 'post_head', 'post_mid', 'post_tail'],
        'actions executed strictly by priority ascending, respecting prepend/append within each priority');
};

subtest 'File closing priority formula' => sub {
    my $fab_file = Text::Fab->new();

    is($fab_file->priority_for_file_close(0),    -1000.0, '0th from end is -1000.0');
    is($fab_file->priority_for_file_close(1),    -1001.0, '1st from end is -1001.0');
    is($fab_file->priority_for_file_close(999),  -1999.0, '999th from end is -1999.0');
    is($fab_file->priority_for_file_close(1000), -2000.0, '1000th from end is -2000.0 (overflow boundary)');
    is($fab_file->priority_for_file_close(5000), -2000.0, 'distance > 1000 clamps to -2000.0');

    throws_ok { $fab_file->priority_for_file_close(-1) } qr/E_TYPE_MISMATCH/,
        'negative distance dies with E_TYPE_MISMATCH';
    throws_ok { $fab_file->priority_for_file_close('abc') } qr/E_TYPE_MISMATCH/,
        'non-integer distance dies with E_TYPE_MISMATCH';
};

subtest 'Fast-path insertion vs time-machine recalculation' => sub {
    my $fab_tm = Text::Fab->new();
    my @trace;

    $fab_tm->group__start();

    $fab_tm->group__postpone(0, -500.0, 'append', sub {
        my ($self) = @_;
        push @trace, 'run_-500_first';

        # Fast path: existing bucket (-500)
        $self->group__postpone(0, -500.0, 'append', sub {
            push @trace, 'run_-500_dynamically_appended';
        });

        # Fast path: future existing bucket (10.0)
        $self->group__postpone(0, 10.0, 'prepend', sub {
            push @trace, 'run_10_prepended';
        });

        # Time-machine insertion in the past (-800.0) -> triggers recalculation
        $self->group__postpone(0, -800.0, 'append', sub {
            push @trace, 'run_-800_time_machine';
        });
    });

    $fab_tm->group__postpone(0, 10.0, 'append', sub {
        push @trace, 'run_10_original';
    });

    $fab_tm->group__end();

    is_deeply(\@trace, [
        'run_-500_first',
        'run_-800_time_machine',
        'run_-500_dynamically_appended',
        'run_10_prepended',
        'run_10_original'
    ], 'fast-path insertions and time-machine recalculations executed in exact priority order');
};

my $fab_select = Text::Fab->new(config => {
    'Fab/group_flavors/isolated/keys' => ['temporary_var']
});
$fab_select->cfg__set('permanent_var', 'perm_orig');
$fab_select->cfg__set('temporary_var', 'temp_orig');

$fab_select->group__start('isolated');
$fab_select->cfg__set('permanent_var', 'perm_changed');
$fab_select->cfg__set('temporary_var', 'temp_changed');
$fab_select->group__end('isolated');

is($fab_select->cfg__get('temporary_var'), 'temp_orig',
   'selective group restored watched key');
is($fab_select->cfg__get('permanent_var'), 'perm_changed',
   'selective group preserved unwatched key');

done_testing();

use strict;
use warnings;
use Test::More;
use Test::Exception;
use File::Temp qw(tempdir);
use File::Spec;
use Text::Fab;

use_ok('Text::Fab');

subtest 'Group lifecycle inside postponed undo action' => sub {
    my $fab = Text::Fab->new();
    $fab->cfg__set('outer_var', 'initial');

    my @events;
    $fab->group__start('main_group');

    $fab->group__postpone(0, -10.0, 'append', sub {
        my ($self) = @_;
        push @events, 'undo_started';

        # Start and end a completely new nested group during an undo action
        $self->group__start('inner_undo_group');
        $self->cfg__set('outer_var', 'temp_during_undo');
        push @events, 'inner_val:' . $self->cfg__get('outer_var');
        $self->group__end('inner_undo_group');

        push @events, 'after_inner_end:' . $self->cfg__get('outer_var');
    });

    $fab->group__end('main_group');

    is_deeply(\@events, [
        'undo_started',
        'inner_val:temp_during_undo',
        'after_inner_end:initial'
    ], 'nested group starts, modifies, and restores cleanly inside postponed action');
};

subtest 'Postpone to parent group (depth > 0) during undo' => sub {
    my $fab = Text::Fab->new();
    my @parent_log;

    $fab->group__start('parent');
    $fab->group__start('child');

    $fab->group__postpone(0, -10.0, 'append', sub {
        my ($self) = @_;
        $self->group__postpone(1, 5.0, 'append', sub {
            push @parent_log, 'parent_action_executed';
        });
    });

    $fab->group__end('child');
    is_deeply(\@parent_log, [], 'parent action not executed yet upon child close');

    $fab->group__end('parent');
    is_deeply(\@parent_log, ['parent_action_executed'], 'action postponed to depth 1 ran during parent close');
};

subtest 'Cascading multi-level time-machine rewinds' => sub {
    my $fab = Text::Fab->new();
    my @trace;

    $fab->group__start();

    $fab->group__postpone(0, -100.0, 'append', sub {
        my ($self) = @_;
        push @trace, '-100';

        $self->group__postpone(0, -500.0, 'append', sub {
            my ($s2) = @_;
            push @trace, '-500';

            $s2->group__postpone(0, -800.0, 'append', sub {
                push @trace, '-800';
            });
        });
    });

    $fab->group__end();

    is_deeply(\@trace, ['-100', '-500', '-800'],
        'time-machine rewinds chain cleanly and execute in priority order');
};

subtest 'Selective group key deletion on rollback' => sub {
    my $fab = Text::Fab->new(config => {
        'Fab/group_flavors' => {
            scoped => { keys => ['new_tracked_var'] }
        }
    });

    ok(!exists $fab->{config}{new_tracked_var}, 'new_tracked_var does not exist initially');

    $fab->group__start('scoped');
    $fab->cfg__set('new_tracked_var', 'created_in_scope');
    is($fab->cfg__get('new_tracked_var'), 'created_in_scope', 'key created in group');
    $fab->group__end('scoped');

    ok(!exists $fab->{config}{new_tracked_var}, 'key was deleted on rollback because it was not in snapshot');
};

subtest 'Prefix API edge cases (empty stack and negative level)' => sub {
    my $fab = Text::Fab->new(config => { 'Fab/call_stack_prefixes' => [] });

    throws_ok { $fab->cfg__set_prefixed('k', 'v') } qr/E_UPLEVEL_TOO_DEEP/,
        'cfg__set_prefixed with empty prefix stack dies with E_UPLEVEL_TOO_DEEP';

    $fab->cfg__set('Fab/call_stack_prefixes', ['Fab/']);
    throws_ok { $fab->cfg__get_uplevel_scan(-1, 'k') } qr/E_UPLEVEL_TOO_DEEP/,
        'cfg__get_uplevel_scan with negative level dies with E_UPLEVEL_TOO_DEEP';
    throws_ok { $fab->cfg__set_prefixed_uplevel(-1, 'k', 'v') } qr/E_UPLEVEL_TOO_DEEP/,
        'cfg__set_prefixed_uplevel with negative level dies with E_UPLEVEL_TOO_DEEP';
};

subtest 'Fixup deep cloning ensures isolation between prefix levels' => sub {
    my $fab = Text::Fab->new();
    $fab->cfg__set('Fab/call_stack_prefixes', ['Fab/', 'Fab/L1/', 'Fab/L2/']);

    $fab->cfg__set('Fab/my_list', ['orig_item']);
    $fab->cfg__set_prefixed_uplevel_fixup(2, 'my_list', ['new_root_item']);

    my $l1_list = $fab->cfg__get('Fab/L1/my_list');
    my $l2_list = $fab->cfg__get('Fab/L2/my_list');
    is_deeply($l1_list, ['orig_item'], 'L1 received orig list');
    is_deeply($l2_list, ['orig_item'], 'L2 received orig list');

    push @$l1_list, 'mutated_in_l1';
    is_deeply($fab->cfg__get('Fab/L2/my_list'), ['orig_item'],
        'L2 list unaffected by L1 mutation (deep clone isolation verified)');
};

subtest 'Include scoped unwinds properly on exception' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $broken_file = File::Spec->catfile($dir, 'broken.fab');
    open my $fh, '>', $broken_file or die $!;
    print $fh "#set temp_var=should_be_undone\n#malformed directive here\n";
    close $fh;

    my $fab = Text::Fab->new();
    $fab->cfg__set('temp_var', 'original');

    throws_ok { $fab->process_string("#include_scoped $broken_file test_flavor") } qr/unknown_directive/,
        'broken included file dies with unknown_directive';

    is($fab->cfg__get('temp_var'), 'original',
        'configuration was cleanly rolled back despite exception inside included file');
    is_deeply($fab->cfg__get('opened_groups'), [],
        'group stack was safely popped and cleaned up');
};

subtest 'Consecutive and boundary comments fusion' => sub {
    my $fab = Text::Fab->new(config => {
        'Fab/callbacks' => {
            %{Text::Fab->new->cfg__get('Fab/callbacks')},
            chunk_preprocessor => sub { "<" . $_[1] . ">" },
        }
    });

    $fab->out__create_section('body', '_main');
    $fab->out__target_section('body', '_main');

    my $input = "## Comment at start\nLine 1\n## Comment A\n## Comment B\nLine 2\n## Comment at end";
    $fab->process_string($input);

    is($fab->assemble('_main:body'), "<Line 1\nLine 2\n>",
        'consecutive comments and start/end comments fuse chunks seamlessly');
};

subtest 'Diamond inheritance topology' => sub {
    my $fab = Text::Fab->new();

    # Topology:
    #      Base
    #     /    \
    #   Left   Right
    #     \    /
    #      Leaf

    $fab->out__target_section('common', 'Base');
    push @{$fab->{sections}{Base}{common}}, ['text', 'Base Common'];

    $fab->out__target_section('left_only', 'Left');
    push @{$fab->{sections}{Left}{left_only}}, ['text', 'Left Content'];

    $fab->out__target_section('override_me', 'Left');
    push @{$fab->{sections}{Left}{override_me}}, ['text', 'Left Override'];

    $fab->out__target_section('override_me', 'Right');
    push @{$fab->{sections}{Right}{override_me}}, ['text', 'Right Override'];

    $fab->NS__set_parents('Left', 'Base');
    $fab->NS__set_parents('Right', 'Base');
    $fab->NS__set_parents('Leaf', 'Left', 'Right');

    $fab->out__target_section('body', 'Leaf');
    $fab->out__embed('override_me', 'Leaf');
    push @{$fab->{sections}{Leaf}{body}}, ['text', ' | '];
    $fab->out__embed('common', 'Leaf');

    is($fab->assemble('Leaf:body'), 'Left Override | Base Common',
        'diamond inheritance resolves Left before Right, and reaches Base without looping');
};

done_testing();

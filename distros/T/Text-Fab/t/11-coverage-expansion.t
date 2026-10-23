use strict;
use warnings;
use Test::More;
use Test::Exception;
use File::Temp qw(tempdir);
use File::Spec;
use Text::Fab;

use_ok('Text::Fab');

subtest 'priority_for_file_close default argument' => sub {
    my $fab = Text::Fab->new();
    is($fab->priority_for_file_close(), -1000.0,
       'priority_for_file_close() defaults $dist_from_end to 0 and returns -1000.0');
};

subtest 'assemble namespace defaulting' => sub {
    my $fab = Text::Fab->new();
    $fab->out__create_section('standalone_body', '_main');
    $fab->out__target_section('standalone_body', '_main');
    $fab->process_string("Standalone body content");

    is($fab->assemble('standalone_body'), 'Standalone body content',
       'assemble() without namespace prefix defaults to _main');
};

subtest '#include with explicit how argument' => sub {
    my $fab = Text::Fab->new();
    $fab->process_string("#include string #set from_explicit_how=success");
    is($fab->cfg__get('from_explicit_how'), 'success',
       '#include parses explicit [how] parameter');
};

subtest '#include_scoped with 3 tokens (how data flavor)' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $inc_file = File::Spec->catfile($dir, 'token3.fab');
    open my $fh, '>', $inc_file or die $!;
    print $fh "#set scoped_token3=modified\n";
    close $fh;

    my $fab = Text::Fab->new();
    $fab->cfg__set('scoped_token3', 'original');
    $fab->process_string("#include_scoped filename $inc_file test_flavor");

    is($fab->cfg__get('scoped_token3'), 'original',
       '#include_scoped with 3 tokens runs and rolls back successfully');
};

subtest '#emb directive parsing with in, aim, and with_blinder' => sub {
    my $fab = Text::Fab->new();
    $fab->out__target_section('widget', 'Parent');
    push @{$fab->{sections}{Parent}{widget}}, ['text', 'Parent Widget'];

    $fab->out__target_section('widget', 'GrandParent');
    push @{$fab->{sections}{GrandParent}{widget}}, ['text', 'GrandParent Widget'];

    $fab->NS__set_parents('Parent', 'GrandParent');
    $fab->NS__set_parents('Child', 'Parent');
    $fab->cfg__set('Fab/blinders/hide_parent', sub { return ('Parent') });

    $fab->out__target_section('main', 'Child');
    $fab->process_string("#emb[in=Child, aim=Child, with_blinder=hide_parent] widget");

    is($fab->assemble('Child:main'), 'GrandParent Widget',
       '#emb directive with bracketed options parsed and evaluated correctly');
};

subtest 'group__postpone method name as string' => sub {
    my $fab = Text::Fab->new();
    $fab->cfg__set('str_var', 'initial');

    $fab->group__start();
    $fab->group__postpone(0, -10.0, 'append', 'cfg__set', 'str_var', 'pre_undo_val');
    $fab->group__postpone(0,  10.0, 'append', 'cfg__set', 'str_var', 'post_undo_val');
    $fab->group__end();

    is($fab->cfg__get('str_var'), 'post_undo_val',
       'group__postpone dispatches method name string via $self->$method(@args)');
};

subtest 'group__postpone validation exceptions' => sub {
    my $fab = Text::Fab->new();
    $fab->group__start();

    throws_ok { $fab->group__postpone(0, 0, 'invalid_order', sub {}) } qr/E_TYPE_MISMATCH/,
        'group__postpone with invalid $how dies with E_TYPE_MISMATCH';

    throws_ok { $fab->group__postpone(0, 0, 'append', undef) } qr/E_TYPE_MISMATCH/,
        'group__postpone with undef $method dies with E_TYPE_MISMATCH';

    throws_ok { $fab->group__postpone(0, 0, 'append', '') } qr/E_TYPE_MISMATCH/,
        'group__postpone with empty $method dies with E_TYPE_MISMATCH';

    throws_ok { $fab->group__postpone(5, 0, 'append', sub {}) } qr/E_UPLEVEL_TOO_DEEP/,
        'group__postpone with $depth > group stack depth dies with E_UPLEVEL_TOO_DEEP';

    $fab->group__end();
};

subtest '_handle_error fallback to _default_error_handler' => sub {
    my $fab = Text::Fab->new();
    $fab->{config}{'Fab/callbacks_bundle/dbg0'}{error_handler} = undef;
    $fab->{config}{'Fab/callbacks'} = 'dbg0';

    throws_ok { $fab->process_string("#unrecognized_cmd arg") } qr/Fab Error \(unknown_directive\):/,
        '_handle_error invokes _default_error_handler when error_handler callback is undef';
};

subtest 'cfg__set and cfg__get on Hashes edge cases' => sub {
    my $fab = Text::Fab->new(config => {
        'Fab/hash_keys' => { my_hash => 1, empty_hash => 1 },
        'Fab/list_keys' => { empty_list => 1 },
    });

    throws_ok { $fab->cfg__set('my_hash', 'key_without_value') } qr/E_TYPE_MISMATCH/,
        'cfg__set on hash key with odd number of elements dies with E_TYPE_MISMATCH';

    $fab->cfg__set('my_hash', { from => 'hashref' });
    is($fab->cfg__get('my_hash', 'from'), 'hashref',
       'cfg__set on hash key accepts a single HASH reference');

    is($fab->cfg__get('empty_hash', 'sub_key'), undef,
       'cfg__get with offset on undefined hash key returns undef');
    is($fab->cfg__get('empty_list', 0), undef,
       'cfg__get with offset on undefined list key returns undef');
};

subtest 'cfg__pop on undefined containers' => sub {
    my $fab = Text::Fab->new(config => {
        'Fab/list_keys' => { missing_list => 1 },
        'Fab/hash_keys' => { missing_hash => 1 },
    });

    my @l_popped = $fab->cfg__pop('missing_list');
    is_deeply(\@l_popped, [], 'cfg__pop on undefined list returns () in list context');
    my $l_scalar = $fab->cfg__pop('missing_list');
    is($l_scalar, undef, 'cfg__pop on undefined list returns undef in scalar context');

    my @h_popped = $fab->cfg__pop('missing_hash', 'k1');
    is_deeply(\@h_popped, [], 'cfg__pop on undefined hash returns () in list context');
    my $h_scalar = $fab->cfg__pop('missing_hash', 'k1');
    is($h_scalar, undef, 'cfg__pop on undefined hash returns undef in scalar context');
};

subtest 'Output primitives namespace defaulting' => sub {
    my $fab = Text::Fab->new();

    $fab->out__target_section('defaulted_sec');
    is_deeply($fab->{current_target}, ['_main', 'defaulted_sec'],
       'out__target_section defaults namespace to _main');

    $fab->out__create_section('another_sec');
    ok(exists $fab->{sections}{_main}{another_sec},
       'out__create_section defaults namespace to current target namespace');

    $fab->out__embed('embed_default_ns', '_main', [], {});
    my $last_chunk = $fab->{sections}{_main}{defaulted_sec}[-1];
    is($last_chunk->[1], '_main',
       'out__embed defaults namespace to target namespace');
};

subtest 'out__get_joined and _join_list edge cases' => sub {
    my $fab = Text::Fab->new(config => {
        'Fab/list_keys' => { single_item_list => 1, zero_item_list => 1 }
    });

    is($fab->out__get_joined('_main:nonexistent_section', [', ']), '',
       'out__get_joined on nonexistent section returns empty string');

    $fab->out__create_section('empty_sec', '_main');
    is($fab->out__get_joined('_main:empty_sec', [', ']), '',
       'out__get_joined on empty section returns empty string');

    $fab->out__create_section('mixed_sec', '_main');
    push @{$fab->{sections}{_main}{mixed_sec}}, ['text', 'first'];
    push @{$fab->{sections}{_main}{mixed_sec}}, ['embed', '_main', 'dummy', [], {}];
    push @{$fab->{sections}{_main}{mixed_sec}}, ['text', 'second'];
    is($fab->out__get_joined('_main:mixed_sec', [' + ']), 'first + second',
       'out__get_joined filters embed placeholders and joins text chunks');

    $fab->cfg__set('single_item_list', ['alone']);
    is($fab->cfg__get_joined('single_item_list', [', ']), 'alone',
       'cfg__get_joined with 1 element returns item without joiners');

    $fab->cfg__set('zero_item_list', []);
    is($fab->cfg__get_joined('zero_item_list', [', ']), '',
       'cfg__get_joined with 0 elements returns empty string');
};

subtest '#start_group and #end_group without flavor' => sub {
    my $fab = Text::Fab->new();
    $fab->process_string("#start_group\n#set anonymous_var=active\n#end_group");
    is($fab->cfg__get('anonymous_var'), undef,
       '#start_group and #end_group with no flavor name default to undef flavor and roll back');
};

done_testing();

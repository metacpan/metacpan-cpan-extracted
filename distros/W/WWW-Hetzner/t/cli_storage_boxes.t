use strict;
use warnings;
use Test::More;
use JSON::MaybeXS qw(decode_json);
use lib 't/lib';

use Test::WWW::Hetzner::Mock;

# Storage Box CLI routes use the real execute() methods against mock_storage.
# Storage actions poll only /storage_boxes/actions/{id}; the deprecated nested
# action path and Cloud's /actions path are intentionally never registered.
{
    package Test::CLIStorageMain;
    sub new     { my ($class, %args) = @_; return bless { %args }, $class }
    sub storage { $_[0]->{storage} }
    sub output  { $_[0]->{output} }
}

sub capture_stdout {
    my ($code) = @_;
    my $buf = '';
    open(my $capture, '>', \$buf) or die "can't open scalar filehandle: $!";
    my $old_fh = select($capture);
    my $ok = eval { $code->(); 1 };
    my $err = $@;
    select($old_fh);
    close($capture);
    die $err unless $ok;
    return $buf;
}

sub load_command_class {
    my ($class) = @_;
    (my $file = $class) =~ s!::!/!g;
    require "$file.pm";
}

sub finished_action {
    my $done = load_fixture('storage_boxes_action');
    $done->{action}{status} = 'success';
    $done->{action}{progress} = 100;
    return $done;
}

sub run_command {
    my (%case) = @_;
    load_command_class($case{class});
    my $storage = mock_storage(@{ $case{routes} });
    $storage->sleeper($case{sleeper}) if $case{sleeper};
    my $main = Test::CLIStorageMain->new(storage => $storage, output => ($case{output} // 'table'));

    local @ARGV = @{ $case{argv} // [] };
    my $cmd = $case{class}->new_with_options;
    ok($cmd->no_wait, "$case{name} parsed --no-wait") if $case{no_wait};

    my $out = eval { capture_stdout(sub { $cmd->execute($case{args} // [], [$main]) }) };
    my $err = $@;
    ok(!$err, "$case{name} executes")
        or do { diag("died with: $err"); return };
    return $out;
}

for my $case (
    {
        name   => 'storage-box default list',
        class  => 'WWW::Hetzner::CLI::Cmd::StorageBox',
        routes => [ 'GET /storage_boxes' => load_fixture('storage_boxes_list') ],
        like   => qr/my-resource/,
    },
    {
        name   => 'storage-box list',
        class  => 'WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::List',
        routes => [ 'GET /storage_boxes' => load_fixture('storage_boxes_list') ],
        like   => qr/bx20/,
    },
    {
        name   => 'storage-box describe',
        class  => 'WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::Describe',
        args   => [ '42' ],
        routes => [ 'GET /storage_boxes/42' => load_fixture('storage_boxes_get') ],
        like   => qr/u45321/,
    },
    {
        name   => 'storage-box folders',
        class  => 'WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::Folders',
        args   => [ '42' ],
        routes => [ 'GET /storage_boxes/42/folders' => load_fixture('storage_boxes_folders') ],
        like   => qr/backup/,
    },
) {
    subtest $case->{name} => sub {
        my $out = run_command(%$case);
        like($out, $case->{like}, "$case->{name} displays fixture data") if defined $out;
    };
}

subtest 'storage-box describe emits decodable entity JSON' => sub {
    my $out = run_command(
        name   => 'storage-box describe JSON',
        class  => 'WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::Describe',
        args   => [ '42' ],
        output => 'json',
        routes => [ 'GET /storage_boxes/42' => load_fixture('storage_boxes_get') ],
    );
    return unless defined $out;

    my $decoded = eval { decode_json($out) };
    ok(!$@, 'Storage Box JSON output decodes') or diag("decode failed: $@; output: $out");
    is($decoded->{name}, 'my-resource', 'JSON output preserves the box name') if $decoded;
    is($decoded->{storage_box_type}{name}, 'bx20', 'JSON output preserves nested type data') if $decoded;
};

subtest 'storage-box create waits for its entity action and never prints the input password' => sub {
    my @slept;
    my $out = run_command(
        name   => 'storage-box create',
        class  => 'WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::Create',
        argv   => [ '--name', 'new-box', '--type', 'bx20', '--location', 'fsn1', '--password', 'secret-input' ],
        routes => [
            'POST /storage_boxes' => sub {
                my ($method, $path, %opts) = @_;
                is_deeply(
                    $opts{body},
                    { name => 'new-box', storage_box_type => 'bx20', location => 'fsn1', password => 'secret-input' },
                    'create maps CLI fields to the documented Storage Box body',
                );
                return load_fixture('storage_boxes_create');
            },
            'GET /storage_boxes/actions/13' => sub { finished_action() },
        ],
        sleeper => sub { push @slept, $_[0] },
    );
    is_deeply(\@slept, [1], 'create polls the Storage action path without real sleep');
    unlike($out // '', qr/secret-input/, 'password input is never echoed');
};

subtest 'storage-box delete waits for its action' => sub {
    my @slept;
    my $out = run_command(
        name   => 'storage-box delete',
        class  => 'WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::Delete',
        args   => [ '42' ],
        routes => [
            'DELETE /storage_boxes/42' => sub {
                my $running = load_fixture('storage_boxes_action');
                $running->{action}{status} = 'running';
                $running->{action}{progress} = 0;
                return $running;
            },
            'GET /storage_boxes/actions/13' => sub { finished_action() },
        ],
        sleeper => sub { push @slept, $_[0] },
    );
    is_deeply(\@slept, [1], 'delete polls the returned Storage action');
    like($out // '', qr/deleted/i, 'delete reports completion') if defined $out;
};

subtest 'storage-box reset-password forwards input only and honours --no-wait' => sub {
    my $out = run_command(
        name    => 'storage-box reset-password',
        class   => 'WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::ResetPassword',
        args    => [ '42' ],
        argv    => [ '--password', 'replacement-secret', '--no-wait' ],
        no_wait => 1,
        routes  => [
            'POST /storage_boxes/42/actions/reset_password' => sub {
                my ($method, $path, %opts) = @_;
                is_deeply($opts{body}, { password => 'replacement-secret' }, 'reset password sends only the supplied password');
                return load_fixture('storage_boxes_action');
            },
        ],
    );
    unlike($out // '', qr/replacement-secret/, 'reset password input is never printed');
};

subtest 'storage-box update returns an entity without polling an action' => sub {
    my $out = run_command(
        name   => 'storage-box update',
        class  => 'WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::Update',
        args   => [ '42' ],
        argv   => [ '--name', 'renamed-box' ],
        routes => [
            'PUT /storage_boxes/42' => sub {
                my ($method, $path, %opts) = @_;
                is_deeply($opts{body}, { name => 'renamed-box' }, 'update sends only the requested entity field');
                my $updated = load_fixture('storage_boxes_get');
                $updated->{storage_box}{name} = 'renamed-box';
                return $updated;
            },
        ],
    );
    like($out // '', qr/renamed-box/, 'update displays the returned entity') if defined $out;
};

for my $case (
    {
        name => 'change type', class => 'WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::ChangeType',
        argv => [ '--type', 'bx30', '--no-wait' ], args => [ '42' ],
        path => 'change_type', body => { storage_box_type => 'bx30' },
    },
    {
        name => 'enable protection', class => 'WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::EnableProtection',
        argv => [ '--no-wait' ], args => [ '42' ], path => 'change_protection', body => { delete => 1 },
    },
    {
        name => 'disable protection', class => 'WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::DisableProtection',
        argv => [ '--no-wait' ], args => [ '42' ], path => 'change_protection', body => { delete => 0 },
    },
    {
        name => 'enable snapshot plan', class => 'WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::EnableSnapshotPlan',
        argv => [ '--max-snapshots', '7', '--minute', '15', '--hour', '3', '--day-of-week', '1', '--day-of-month', '12', '--no-wait' ],
        args => [ '42' ], path => 'enable_snapshot_plan',
        body => { max_snapshots => 7, minute => 15, hour => 3, day_of_week => 1, day_of_month => 12 },
    },
    {
        name => 'disable snapshot plan', class => 'WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::DisableSnapshotPlan',
        argv => [ '--no-wait' ], args => [ '42' ], path => 'disable_snapshot_plan', body => {},
    },
    {
        name => 'rollback snapshot', class => 'WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::RollbackSnapshot',
        argv => [ '--snapshot', '1', '--no-wait' ], args => [ '42' ], path => 'rollback_snapshot', body => { snapshot => 1 },
    },
) {
    subtest "storage-box $case->{name}: --no-wait forwards the documented action body" => sub {
        run_command(
            name    => "storage-box $case->{name}", class => $case->{class}, argv => $case->{argv}, args => $case->{args}, no_wait => 1,
            routes  => [
                "POST /storage_boxes/42/actions/$case->{path}" => sub {
                    my ($method, $path, %opts) = @_;
                    is_deeply($opts{body}, $case->{body}, "$case->{name} action body");
                    return load_fixture('storage_boxes_action');
                },
            ],
        );
    };
}

subtest 'storage-box access settings maps explicit enable flags' => sub {
    run_command(
        name    => 'storage-box update-access-settings',
        class   => 'WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::UpdateAccessSettings',
        argv    => [ '--enable-samba', '--enable-ssh', '--enable-webdav', '--enable-zfs', '--reachable-externally', '--no-wait' ],
        args    => [ '42' ],
        no_wait => 1,
        routes  => [
            'POST /storage_boxes/42/actions/update_access_settings' => sub {
                my ($method, $path, %opts) = @_;
                is_deeply(
                    $opts{body},
                    { samba_enabled => 1, ssh_enabled => 1, webdav_enabled => 1, zfs_enabled => 1, reachable_externally => 1 },
                    'access settings use API field names and include only enabled flags',
                );
                return load_fixture('storage_boxes_action');
            },
        ],
    );
};

for my $case (
    {
        name => 'add label', class => 'WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::AddLabel',
        args => [ '42', 'team=backup' ], expected => {
            'environment' => 'prod', 'example.com/my' => 'label', 'just-a-key' => '', team => 'backup',
        },
    },
    {
        name => 'remove label', class => 'WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::RemoveLabel',
        args => [ '42', 'environment' ], expected => {
            'example.com/my' => 'label', 'just-a-key' => '',
        },
    },
) {
    subtest "storage-box $case->{name} preserves all unrelated labels" => sub {
        run_command(
            name   => "storage-box $case->{name}", class => $case->{class}, args => $case->{args},
            routes => [
                'GET /storage_boxes/42' => load_fixture('storage_boxes_get'),
                'PUT /storage_boxes/42' => sub {
                    my ($method, $path, %opts) = @_;
                    is_deeply($opts{body}, { labels => $case->{expected} }, "$case->{name} sends the merged label set");
                    my $updated = load_fixture('storage_boxes_get');
                    $updated->{storage_box}{labels} = $case->{expected};
                    return $updated;
                },
            ],
        );
    };
}

subtest 'storage-box action errors propagate through the default wait path' => sub {
    load_command_class('WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::ChangeType');
    my $storage = mock_storage(
        'POST /storage_boxes/42/actions/change_type' => sub {
            my $failed = load_fixture('storage_boxes_action');
            $failed->{action}{status} = 'error';
            $failed->{action}{error} = { code => 'invalid_input', message => 'type unavailable' };
            return $failed;
        },
    );
    my $main = Test::CLIStorageMain->new(storage => $storage, output => 'table');
    local @ARGV = ('--type', 'bx99');
    my $cmd = WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::ChangeType->new_with_options;
    my $ok = eval { capture_stdout(sub { $cmd->execute(['42'], [$main]) }); 1 };
    ok(!$ok, 'action failure aborts the command');
    like($@, qr/type unavailable/, 'action failure message is retained');
};

done_testing;

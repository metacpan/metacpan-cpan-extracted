use strict;
use warnings;
use Test::More;
use JSON::MaybeXS qw(decode_json);
use lib 't/lib';

use Test::WWW::Hetzner::Mock;

# Exercises the Storage Box snapshot subtree through mock_storage.  The two
# positional identifiers are always <storage-box-id> <snapshot-id>.
{
    package Test::CLIStorageSnapshotMain;
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
    my $done = load_fixture('storage_box_snapshots_action');
    $done->{action}{status} = 'success';
    $done->{action}{progress} = 100;
    return $done;
}

sub run_command {
    my (%case) = @_;
    load_command_class($case{class});
    my $storage = mock_storage(@{ $case{routes} });
    $storage->sleeper($case{sleeper}) if $case{sleeper};
    my $main = Test::CLIStorageSnapshotMain->new(storage => $storage, output => ($case{output} // 'table'));

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
        name   => 'snapshot default list',
        class  => 'WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::Snapshot',
        args   => [ '42' ],
        routes => [ 'GET /storage_boxes/42/snapshots' => load_fixture('storage_box_snapshots_list') ],
        like   => qr/2025-02-12/,
    },
    {
        name   => 'snapshot list',
        class  => 'WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::Snapshot::Cmd::List',
        args   => [ '42' ],
        routes => [ 'GET /storage_boxes/42/snapshots' => load_fixture('storage_box_snapshots_list') ],
        like   => qr/my-description/,
    },
    {
        name   => 'snapshot describe',
        class  => 'WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::Snapshot::Cmd::Describe',
        args   => [ '42', '1' ],
        routes => [ 'GET /storage_boxes/42/snapshots/1' => load_fixture('storage_box_snapshots_get') ],
        like   => qr/my-description/,
    },
) {
    subtest $case->{name} => sub {
        my $out = run_command(%$case);
        like($out, $case->{like}, "$case->{name} displays fixture data") if defined $out;
    };
}

subtest 'snapshot describe JSON is decodable and preserves labels' => sub {
    my $out = run_command(
        name   => 'snapshot describe JSON',
        class  => 'WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::Snapshot::Cmd::Describe',
        args   => [ '42', '1' ],
        output => 'json',
        routes => [ 'GET /storage_boxes/42/snapshots/1' => load_fixture('storage_box_snapshots_get') ],
    );
    return unless defined $out;
    my $decoded = eval { decode_json($out) };
    ok(!$@, 'Snapshot JSON output decodes') or diag("decode failed: $@; output: $out");
    is($decoded->{labels}{environment}, 'prod', 'Snapshot JSON preserves labels') if $decoded;
};

subtest 'snapshot create waits for the entity action' => sub {
    my @slept;
    my $out = run_command(
        name   => 'snapshot create',
        class  => 'WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::Snapshot::Cmd::Create',
        args   => [ '42' ],
        argv   => [ '--description', 'before package upgrade' ],
        routes => [
            'POST /storage_boxes/42/snapshots' => sub {
                my ($method, $path, %opts) = @_;
                is_deeply($opts{body}, { description => 'before package upgrade' }, 'snapshot create forwards optional fields');
                return load_fixture('storage_box_snapshots_create');
            },
            'GET /storage_boxes/actions/13' => sub { finished_action() },
        ],
        sleeper => sub { push @slept, $_[0] },
    );
    is_deeply(\@slept, [1], 'snapshot create polls the global Storage action endpoint');
    like($out // '', qr/created/i, 'snapshot create reports completion') if defined $out;
};

subtest 'snapshot delete waits for its action' => sub {
    my @slept;
    my $out = run_command(
        name   => 'snapshot delete',
        class  => 'WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::Snapshot::Cmd::Delete',
        args   => [ '42', '1' ],
        routes => [
            'DELETE /storage_boxes/42/snapshots/1' => sub {
                my $running = load_fixture('storage_box_snapshots_action');
                $running->{action}{status} = 'running';
                $running->{action}{progress} = 0;
                return $running;
            },
            'GET /storage_boxes/actions/13' => sub { finished_action() },
        ],
        sleeper => sub { push @slept, $_[0] },
    );
    is_deeply(\@slept, [1], 'snapshot delete waits for its action');
    like($out // '', qr/deleted/i, 'snapshot delete reports completion') if defined $out;
};

subtest 'snapshot delete: --no-wait does not poll' => sub {
    run_command(
        name    => 'snapshot delete no-wait',
        class   => 'WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::Snapshot::Cmd::Delete',
        args    => [ '42', '1' ],
        argv    => [ '--no-wait' ],
        no_wait => 1,
        routes  => [
            'DELETE /storage_boxes/42/snapshots/1' => sub { load_fixture('storage_box_snapshots_action') },
        ],
    );
};

subtest 'snapshot update returns an entity without an action' => sub {
    my $out = run_command(
        name   => 'snapshot update',
        class  => 'WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::Snapshot::Cmd::Update',
        args   => [ '42', '1' ],
        argv   => [ '--description', 'after upgrade' ],
        routes => [
            'PUT /storage_boxes/42/snapshots/1' => sub {
                my ($method, $path, %opts) = @_;
                is_deeply($opts{body}, { description => 'after upgrade' }, 'snapshot update sends only description');
                my $updated = load_fixture('storage_box_snapshots_get');
                $updated->{snapshot}{description} = 'after upgrade';
                return $updated;
            },
        ],
    );
    like($out // '', qr/after upgrade/, 'snapshot update displays the returned entity') if defined $out;
};

for my $case (
    {
        name => 'add label', class => 'WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::Snapshot::Cmd::AddLabel',
        args => [ '42', '1', 'release=before-upgrade' ], expected => {
            'environment' => 'prod', 'example.com/my' => 'label', 'just-a-key' => '', release => 'before-upgrade',
        },
    },
    {
        name => 'remove label', class => 'WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::Snapshot::Cmd::RemoveLabel',
        args => [ '42', '1', 'environment' ], expected => {
            'example.com/my' => 'label', 'just-a-key' => '',
        },
    },
) {
    subtest "snapshot $case->{name} preserves unrelated labels" => sub {
        run_command(
            name   => "snapshot $case->{name}", class => $case->{class}, args => $case->{args},
            routes => [
                'GET /storage_boxes/42/snapshots/1' => load_fixture('storage_box_snapshots_get'),
                'PUT /storage_boxes/42/snapshots/1' => sub {
                    my ($method, $path, %opts) = @_;
                    is_deeply($opts{body}, { labels => $case->{expected} }, "$case->{name} sends the complete merged labels");
                    my $updated = load_fixture('storage_box_snapshots_get');
                    $updated->{snapshot}{labels} = $case->{expected};
                    return $updated;
                },
            ],
        );
    };
}

done_testing;

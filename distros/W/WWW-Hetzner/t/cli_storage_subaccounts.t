use strict;
use warnings;
use Test::More;
use JSON::MaybeXS qw(decode_json);
use lib 't/lib';

use Test::WWW::Hetzner::Mock;

# Exercises the Storage Box subaccount subtree through mock_storage.  Nested
# commands always receive <storage-box-id> <subaccount-id> positionally.
{
    package Test::CLIStorageSubaccountMain;
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
    my $done = load_fixture('storage_box_subaccounts_action');
    $done->{action}{status} = 'success';
    $done->{action}{progress} = 100;
    return $done;
}

sub run_command {
    my (%case) = @_;
    load_command_class($case{class});
    my $storage = mock_storage(@{ $case{routes} });
    $storage->sleeper($case{sleeper}) if $case{sleeper};
    my $main = Test::CLIStorageSubaccountMain->new(storage => $storage, output => ($case{output} // 'table'));

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
        name   => 'subaccount default list',
        class  => 'WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::Subaccount',
        args   => [ '42' ],
        routes => [ 'GET /storage_boxes/42/subaccounts' => load_fixture('storage_box_subaccounts_list') ],
        like   => qr/my-name/,
    },
    {
        name   => 'subaccount list',
        class  => 'WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::Subaccount::Cmd::List',
        args   => [ '42' ],
        routes => [ 'GET /storage_boxes/42/subaccounts' => load_fixture('storage_box_subaccounts_list') ],
        like   => qr/u1337-sub1/,
    },
    {
        name   => 'subaccount describe',
        class  => 'WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::Subaccount::Cmd::Describe',
        args   => [ '42', '42' ],
        routes => [ 'GET /storage_boxes/42/subaccounts/42' => load_fixture('storage_box_subaccounts_get') ],
        like   => qr/my_backups\/host01/,
    },
) {
    subtest $case->{name} => sub {
        my $out = run_command(%$case);
        like($out, $case->{like}, "$case->{name} displays fixture data") if defined $out;
    };
}

subtest 'subaccount describe JSON is decodable' => sub {
    my $out = run_command(
        name   => 'subaccount describe JSON',
        class  => 'WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::Subaccount::Cmd::Describe',
        args   => [ '42', '42' ],
        output => 'json',
        routes => [ 'GET /storage_boxes/42/subaccounts/42' => load_fixture('storage_box_subaccounts_get') ],
    );
    return unless defined $out;
    my $decoded = eval { decode_json($out) };
    ok(!$@, 'Subaccount JSON output decodes') or diag("decode failed: $@; output: $out");
    is($decoded->{home_directory}, 'my_backups/host01.my.company', 'JSON preserves home directory') if $decoded;
};

subtest 'subaccount create waits for its entity action and keeps password input private' => sub {
    my @slept;
    my $out = run_command(
        name   => 'subaccount create',
        class  => 'WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::Subaccount::Cmd::Create',
        args   => [ '42' ],
        argv   => [ '--home-directory', 'backup/host02', '--password', 'subaccount-secret' ],
        routes => [
            'POST /storage_boxes/42/subaccounts' => sub {
                my ($method, $path, %opts) = @_;
                is_deeply($opts{body}, { home_directory => 'backup/host02', password => 'subaccount-secret' }, 'subaccount create forwards required fields');
                return load_fixture('storage_box_subaccounts_create');
            },
            'GET /storage_boxes/actions/13' => sub { finished_action() },
        ],
        sleeper => sub { push @slept, $_[0] },
    );
    is_deeply(\@slept, [1], 'subaccount create polls the Storage action path');
    unlike($out // '', qr/subaccount-secret/, 'subaccount password is never printed');
};

subtest 'subaccount delete waits for its action' => sub {
    my @slept;
    my $out = run_command(
        name   => 'subaccount delete',
        class  => 'WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::Subaccount::Cmd::Delete',
        args   => [ '42', '42' ],
        routes => [
            'DELETE /storage_boxes/42/subaccounts/42' => sub {
                my $running = load_fixture('storage_box_subaccounts_action');
                $running->{action}{status} = 'running';
                $running->{action}{progress} = 0;
                return $running;
            },
            'GET /storage_boxes/actions/13' => sub { finished_action() },
        ],
        sleeper => sub { push @slept, $_[0] },
    );
    is_deeply(\@slept, [1], 'subaccount delete waits for its action');
    like($out // '', qr/deleted/i, 'subaccount delete reports completion') if defined $out;
};

subtest 'subaccount password reset is input-only and honours --no-wait' => sub {
    my $out = run_command(
        name    => 'subaccount reset-password',
        class   => 'WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::Subaccount::Cmd::ResetPassword',
        args    => [ '42', '42' ],
        argv    => [ '--password', 'subaccount-replacement', '--no-wait' ],
        no_wait => 1,
        routes  => [
            'POST /storage_boxes/42/subaccounts/42/actions/reset_subaccount_password' => sub {
                my ($method, $path, %opts) = @_;
                is_deeply($opts{body}, { password => 'subaccount-replacement' }, 'reset forwards only the supplied password');
                return load_fixture('storage_box_subaccounts_action');
            },
        ],
    );
    unlike($out // '', qr/subaccount-replacement/, 'reset password input is never printed');
};

subtest 'subaccount update returns an entity without waiting' => sub {
    my $out = run_command(
        name   => 'subaccount update',
        class  => 'WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::Subaccount::Cmd::Update',
        args   => [ '42', '42' ],
        argv   => [ '--name', 'host02', '--description', 'host02 backup' ],
        routes => [
            'PUT /storage_boxes/42/subaccounts/42' => sub {
                my ($method, $path, %opts) = @_;
                is_deeply($opts{body}, { name => 'host02', description => 'host02 backup' }, 'subaccount update sends requested fields only');
                my $updated = load_fixture('storage_box_subaccounts_get');
                $updated->{subaccount}{name} = 'host02';
                $updated->{subaccount}{description} = 'host02 backup';
                return $updated;
            },
        ],
    );
    like($out // '', qr/host02/, 'subaccount update displays the returned entity') if defined $out;
};

subtest 'subaccount change-home-directory honours --no-wait' => sub {
    run_command(
        name    => 'subaccount change-home-directory',
        class   => 'WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::Subaccount::Cmd::ChangeHomeDirectory',
        args    => [ '42', '42' ],
        argv    => [ '--home-directory', 'backup/host02', '--no-wait' ],
        no_wait => 1,
        routes  => [
            'POST /storage_boxes/42/subaccounts/42/actions/change_home_directory' => sub {
                my ($method, $path, %opts) = @_;
                is_deeply($opts{body}, { home_directory => 'backup/host02' }, 'home-directory action uses the nested IDs');
                return load_fixture('storage_box_subaccounts_action');
            },
        ],
    );
};

subtest 'subaccount access settings maps explicitly enabled protocols' => sub {
    run_command(
        name    => 'subaccount update-access-settings',
        class   => 'WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::Subaccount::Cmd::UpdateAccessSettings',
        args    => [ '42', '42' ],
        argv    => [ '--enable-samba', '--enable-ssh', '--enable-webdav', '--reachable-externally', '--readonly', '--no-wait' ],
        no_wait => 1,
        routes  => [
            'POST /storage_boxes/42/subaccounts/42/actions/update_access_settings' => sub {
                my ($method, $path, %opts) = @_;
                is_deeply(
                    $opts{body},
                    { samba_enabled => 1, ssh_enabled => 1, webdav_enabled => 1, reachable_externally => 1, readonly => 1 },
                    'subaccount access action uses documented keys',
                );
                return load_fixture('storage_box_subaccounts_action');
            },
        ],
    );
};

done_testing;

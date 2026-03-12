use strict;
use warnings;

use File::Spec;
use File::Temp;
use Test::More 0.98;

use Test::ValkeyServer;

sub _write_fake_valkey_cli {
    my ($dir) = @_;

    my $path = File::Spec->catfile($dir, 'valkey-cli');
    open my $fh, '>', $path or die "cannot write $path: $!";
    print {$fh} <<"END_SCRIPT";
#!$^X
use strict;
use warnings;

select STDOUT;
\$| = 1;
select STDERR;
\$| = 1;
select STDOUT;

if (\@ARGV && \$ARGV[0] eq 'success-one') {
    print "stdout one\\n";
    print STDERR "stderr one\\n";
    exit 0;
}

if (\@ARGV && \$ARGV[0] eq 'success-two') {
    print "stdout two\\n";
    exit 0;
}

if (\@ARGV && \$ARGV[0] eq 'sleep') {
    print "before timeout\\n";
    sleep 2;
    print "after timeout\\n";
    exit 0;
}

die "unexpected args: \@ARGV\\n";
END_SCRIPT
    close $fh;
    chmod 0755, $path or die "chmod failed for $path: $!";

    return $path;
}

sub _read_file {
    my ($path) = @_;

    open my $fh, '<', $path or die "cannot read $path: $!";
    my $content = do { local $/; <$fh> };
    close $fh;

    return $content;
}

subtest '_run_valkey_cli captures only new log output' => sub {
    my $tmpdir = File::Temp->newdir( CLEANUP => 1 );
    _write_fake_valkey_cli("$tmpdir");

    my $server = Test::ValkeyServer->new(
        auto_start => 0,
        tmpdir     => $tmpdir,
    );
    my $logfile = File::Spec->catfile("$tmpdir", 'valkey-server.log');

    open my $fh, '>', $logfile or die "cannot write $logfile: $!";
    print {$fh} "existing server log\n";
    close $fh;

    local $ENV{PATH} = "$tmpdir:$ENV{PATH}";

    my $first = $server->_run_valkey_cli('success-one');
    is $first->{timed_out}, 0, 'first call did not time out';
    like $first->{output}, qr/stdout one/, 'stdout is captured';
    like $first->{output}, qr/stderr one/, 'stderr is captured';
    unlike $first->{output}, qr/existing server log/, 'existing log is excluded';

    my $second = $server->_run_valkey_cli('success-two');
    is $second->{timed_out}, 0, 'second call did not time out';
    like $second->{output}, qr/stdout two/, 'second stdout is captured';
    unlike $second->{output}, qr/stdout one|stderr one|existing server log/,
        'second call only returns new output';

    my $server_log = _read_file($logfile);
    like $server_log, qr/existing server log/, 'existing server log remains in file';
    unlike $server_log, qr/stdout one/, 'cli output is not in server log';

    my $cli_logfile = File::Spec->catfile("$tmpdir", 'valkey-cli.log');
    my $cli_log = _read_file($cli_logfile);
    like $cli_log, qr/stdout one/, 'first output is in cli log';
    like $cli_log, qr/stderr one/, 'first stderr is in cli log';
    like $cli_log, qr/stdout two/, 'second output is in cli log';
};

subtest '_run_valkey_cli reports exec failure from log output' => sub {
    my $tmpdir = File::Temp->newdir( CLEANUP => 1 );
    my $server = Test::ValkeyServer->new(
        auto_start => 0,
        tmpdir     => $tmpdir,
    );

    local $ENV{PATH} = "$tmpdir";

    my $result = $server->_run_valkey_cli('missing');
    is $result->{timed_out}, 0, 'exec failure does not look like a timeout';
    like $result->{output}, qr/exec valkey-cli failed:/, 'exec failure is captured';
};

subtest '_run_valkey_cli times out and returns partial output' => sub {
    my $tmpdir = File::Temp->newdir( CLEANUP => 1 );
    _write_fake_valkey_cli("$tmpdir");

    my $server = Test::ValkeyServer->new(
        auto_start => 0,
        timeout    => 0.2,
        tmpdir     => $tmpdir,
    );

    local $ENV{PATH} = "$tmpdir:$ENV{PATH}";

    my $result = $server->_run_valkey_cli('sleep');
    is $result->{timed_out}, 1, 'timeout is reported';
    like $result->{output}, qr/before timeout/, 'output before timeout is captured';
    unlike $result->{output}, qr/after timeout/, 'output after timeout is not captured';
};

done_testing;

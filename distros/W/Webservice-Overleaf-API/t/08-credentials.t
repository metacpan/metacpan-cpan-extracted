use strict;
use warnings;

use Test::More;
use File::Temp qw/tempdir/;
use File::Spec;

my $loaded = do './bin/overleaf';
ok $loaded, 'loaded overleaf modulino'
    or diag $@ || $!;

my $home = tempdir(CLEANUP => 1);
my $config = File::Spec->catdir($home, '.overleaf');
mkdir $config or die "mkdir $config: $!";
chmod 0700, $config or die "chmod $config: $!";

sub write_credential {
    my ($name, $value, $mode) = @_;
    my $path = File::Spec->catfile($config, $name);
    open my $fh, '>:raw', $path or die "write $path: $!";
    print {$fh} $value, "\n";
    close $fh or die "close $path: $!";
    chmod $mode, $path or die "chmod $path: $!";
    return $path;
}

my $session_file = write_credential('session', 'session-value', 0600);
my $token_file   = write_credential('git-token', 'token-value', 0600);

{
    local $ENV{HOME} = $home;
    local $ENV{USERPROFILE};
    local $ENV{OVERLEAF_SESSION};
    local $ENV{OVERLEAF_GIT_TOKEN};

    my @argv;
    my $o = local::bin::overleaf::_options(\@argv);
    is local::bin::overleaf::_session_from_options($o),
        'session-value', 'default ~/.overleaf/session is discovered';
    is local::bin::overleaf::_git_token_from_options($o),
        'token-value', 'default ~/.overleaf/git-token is discovered';
}

{
    local $ENV{HOME} = $home;
    local $ENV{OVERLEAF_SESSION} = 'session-env';
    local $ENV{OVERLEAF_GIT_TOKEN} = 'token-env';

    my @argv;
    my $o = local::bin::overleaf::_options(\@argv);
    is local::bin::overleaf::_session_from_options($o),
        'session-env', 'OVERLEAF_SESSION overrides default file';
    is local::bin::overleaf::_git_token_from_options($o),
        'token-env', 'OVERLEAF_GIT_TOKEN overrides default file';
}

{
    local $ENV{HOME} = $home;
    local $ENV{OVERLEAF_SESSION} = 'session-env';

    my @argv = ('--session-file', $session_file);
    my $o = local::bin::overleaf::_options(\@argv);
    is local::bin::overleaf::_session_from_options($o),
        'session-value', '--session-file overrides OVERLEAF_SESSION';
}

{
    local $ENV{HOME} = $home;
    local $ENV{OVERLEAF_SESSION} = 'session-env';

    my @argv = ('--session', 'session-arg', '--session-file', $session_file);
    my $o = local::bin::overleaf::_options(\@argv);
    is local::bin::overleaf::_session_from_options($o),
        'session-arg', '--session remains highest-precedence session source';
}

SKIP: {
    skip 'filesystem does not expose enforceable POSIX mode bits', 2
        if !local::bin::overleaf::_posix_modes_are_enforceable($config);

    local $ENV{HOME} = $home;
    my $bad = write_credential('bad-mode', 'secret', 0644);
    my $ok = eval {
        local::bin::overleaf::_credential_from_file($bad, 'test credential');
        1;
    };
    ok !$ok, 'credential file with mode other than 0600 is rejected';
    like $@, qr/must have mode 0600/, 'bad-mode diagnostic names required mode';
}

{
    local $ENV{HOME} = $home;
    my $outside = File::Spec->catfile($home, 'outside-token');
    open my $fh, '>', $outside or die $!;
    print {$fh} "secret\n";
    close $fh;
    chmod 0600, $outside or die $!;

    my $ok = eval {
        local::bin::overleaf::_credential_from_file($outside, 'test credential');
        1;
    };
    ok !$ok, 'credential file outside ~/.overleaf is rejected';
    like $@, qr/must be stored under/, 'outside-directory diagnostic';
}

{
    my @argv = ('project-url', 'abc123');
    my $o = local::bin::overleaf::_options(\@argv);
    my $command = shift @argv;
    my %need = local::bin::overleaf::_credential_needs($command, \@argv, $o);
    is_deeply \%need, {}, 'project-url needs no credential';
}

{
    my @argv = ('clone', 'abc123', 'paper');
    my $o = local::bin::overleaf::_options(\@argv);
    my $command = shift @argv;
    my %need = local::bin::overleaf::_credential_needs($command, \@argv, $o);
    is_deeply \%need, { git_token => 1 }, 'clone needs only Git token';
}

{
    my @argv = ('projects');
    my $o = local::bin::overleaf::_options(\@argv);
    my $command = shift @argv;
    my %need = local::bin::overleaf::_credential_needs($command, \@argv, $o);
    is_deeply \%need, { session => 1 }, 'projects needs only browser session';
}

{
    my @argv = ('compile', 'main.tex');
    my $o = local::bin::overleaf::_options(\@argv);
    my $command = shift @argv;
    my %need = local::bin::overleaf::_credential_needs($command, \@argv, $o);
    is_deeply \%need, { session => 1, git_token => 1 },
        'local compile with push needs both credentials';
}

{
    my @argv = ('--no-push', 'compile', 'main.tex');
    my $o = local::bin::overleaf::_options(\@argv);
    my $command = shift @argv;
    my %need = local::bin::overleaf::_credential_needs($command, \@argv, $o);
    is_deeply \%need, { session => 1 },
        'local compile --no-push needs only browser session';
}

{
    my @argv = ('compile', 'abc123');
    my $o = local::bin::overleaf::_options(\@argv);
    my $command = shift @argv;
    my %need = local::bin::overleaf::_credential_needs($command, \@argv, $o);
    is_deeply \%need, { session => 1 },
        'legacy compile PROJECT_ID needs only browser session';
}

{
    my $fake_bin = tempdir(CLEANUP => 1);
    my $capture = File::Spec->catfile($fake_bin, 'capture.txt');
    my $git = File::Spec->catfile($fake_bin, 'git');

    open my $fh, '>', $git or die $!;
    print {$fh} <<'FAKE_GIT';
#!/usr/bin/env perl
use strict;
use warnings;

open my $out, '>', $ENV{OVERLEAF_TEST_CAPTURE} or die $!;
print {$out} "args=", join('|', @ARGV), "\n";

sub ask {
    my $prompt = shift;
    open my $ask, '-|', $ENV{GIT_ASKPASS}, $prompt or die $!;
    my $answer = <$ask>;
    close $ask;
    chomp $answer if defined $answer;
    return $answer;
}

print {$out} "username=", ask('Username for Overleaf:'), "\n";
print {$out} "password=", ask('Password for Overleaf:'), "\n";
close $out;
exit 0;
FAKE_GIT
    close $fh or die $!;
    chmod 0700, $git or die $!;

    local $ENV{PATH} = $fake_bin . ':' . ($ENV{PATH} || q{});
    local $ENV{OVERLEAF_TEST_CAPTURE} = $capture;

    my $runner = local::bin::overleaf::_git_runner_with_token('dummy-token');
    is $runner->('git', 'clone', 'https://git.overleaf.com/abc123', 'paper'),
        0, 'token-backed Git runner succeeds';

    open my $in, '<', $capture or die $!;
    local $/;
    my $seen = <$in>;
    close $in;

    like $seen, qr/username=git/, 'GIT_ASKPASS supplies documented git username';
    like $seen, qr/password=dummy-token/, 'GIT_ASKPASS supplies configured token';
    unlike $seen, qr/args=.*dummy-token/, 'token is not present in Git arguments';
    like $seen, qr/credential\.helper=\|.*credential\.username=git/,
        'runner disables stale helper and fixes username for token auth';
}

done_testing;

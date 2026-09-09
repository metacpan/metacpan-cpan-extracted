use strict;
use warnings;

use Test::More;
use File::Temp qw/tempdir/;
use Cwd qw/getcwd/;

my $loaded = do './bin/overleaf';
ok $loaded, 'loaded overleaf modulino'
    or diag $@ || $!;

{
    package Local::CompileOptions;
    sub new { bless { @_ > 1 ? @_[1 .. $#_] : () }, $_[0] }
    sub remote { $_[0]->{remote} }
    sub remote_branch { $_[0]->{remote_branch} }
    sub output        { $_[0]->{output} }
    sub resource_path { $_[0]->{resource_path} }
    sub push          { exists $_[0]->{push} ? $_[0]->{push} : 1 }
}

{
    package Local::CompileResult;
    sub new    { bless { status => 'success' }, $_[0] }
    sub status { $_[0]->{status} }
}

{
    package Local::CompileClient;
    sub new { bless { calls => [] }, $_[0] }
    sub git_base_url { 'https://git.overleaf.com' }
    sub git_push {
        my ($self, @args) = @_;
        push @{ $self->{calls} }, [ push => @args ];
        return 1;
    }
    sub compile {
        my ($self, @args) = @_;
        push @{ $self->{calls} }, [ compile => @args ];
        return Local::CompileResult->new;
    }
    sub download_pdf {
        my ($self, @args) = @_;
        push @{ $self->{calls} }, [ download_pdf => @args ];
        my %opts = @args[1 .. $#args];
        return $opts{to};
    }
}

sub capture_local_compile {
    my ($client, $args, $opts) = @_;
    my ($stdout, $stderr, $status);
    {
        local *STDOUT;
        local *STDERR;
        open STDOUT, '>', \$stdout or die $!;
        open STDERR, '>', \$stderr or die $!;
        $status = eval {
            local::bin::overleaf::_compile_local_project($client, $args, $opts)
        };
        $stderr .= $@ if $@;
    }
    return ($status, $stdout || q{}, $stderr || q{});
}

my $tmp = tempdir(CLEANUP => 1);
my $old = getcwd();
chdir $tmp or die $!;
open my $fh, '>', 'main.tex' or die $!;
print {$fh} "\\documentclass{article}\n\\begin{document}x\\end{document}\n";
close $fh;

my @git_calls;
{
    no warnings 'redefine';
    local *local::bin::overleaf::_git_capture = sub {
        my @cmd = @_;
        push @git_calls, [ @cmd ];
        my $joined = join q{ }, @cmd;
        return $tmp if $joined eq 'git rev-parse --show-toplevel';
        return 'origin' if $joined eq "git -C $tmp remote";
        return 'https://git@git.overleaf.com/abc123'
            if $joined eq "git -C $tmp remote get-url origin";
        return 'origin/main'
            if $joined eq "git -C $tmp rev-parse --abbrev-ref --symbolic-full-name \@{upstream}";
        return 'main.tex' if $joined eq "git -C $tmp ls-files -- main.tex";
        return q{} if $joined eq "git -C $tmp -c core.quotepath=false status --porcelain";
        die "unexpected git command: $joined";
    };

    my $client = Local::CompileClient->new;
    my $opts = Local::CompileOptions->new(push => 1);
    my @args = ('main.tex');
    my ($status, $out, $err) = capture_local_compile($client, \@args, $opts);

    is $status, 0, 'local compile succeeds';
    is $err, q{}, 'local compile has no stderr';
    like $out, qr/^project\tabc123$/m, 'project id inferred from Git remote';
    like $out, qr/^remote\torigin$/m, 'remote reported';
    like $out, qr/^branch\tmain$/m, 'remote branch reported';
    like $out, qr/^root\tmain\.tex$/m, 'root resource reported';
    like $out, qr/^push\tok$/m, 'push reported';
    like $out, qr/^status\tsuccess$/m, 'compile status reported';
    like $out, qr/^saved\tmain\.pdf$/m, 'PDF filename derived from TeX root';

    is_deeply $client->{calls}[0],
        [ push => $tmp, 'origin', 'HEAD:main' ],
        'complete committed project pushed to discovered Overleaf branch';
    is_deeply $client->{calls}[1],
        [ compile => 'abc123', resource_path => 'main.tex' ],
        'remote compile uses inferred project and root resource';
    is $client->{calls}[2][0], 'download_pdf',
        'PDF downloaded from compile result';
    is $client->{calls}[2][-1], 'main.pdf',
        'download destination is main.pdf';
}

{
    no warnings 'redefine';
    local *local::bin::overleaf::_git_capture = sub {
        my @cmd = @_;
        my $joined = join q{ }, @cmd;
        return $tmp if $joined eq 'git rev-parse --show-toplevel';
        return "origin\noverleaf" if $joined eq "git -C $tmp remote";
        return 'https://example.test/repo'
            if $joined eq "git -C $tmp remote get-url origin";
        return 'https://git.overleaf.com/def456'
            if $joined eq "git -C $tmp remote get-url overleaf";
        return 'origin/main'
            if $joined eq "git -C $tmp rev-parse --abbrev-ref --symbolic-full-name \@{upstream}";
        return 'overleaf/main'
            if $joined eq "git -C $tmp symbolic-ref --quiet --short refs/remotes/overleaf/HEAD";
        return 'main.tex' if $joined eq "git -C $tmp ls-files -- main.tex";
        return ' M main.tex' if $joined eq "git -C $tmp -c core.quotepath=false status --porcelain";
        die "unexpected git command: $joined";
    };

    my $client = Local::CompileClient->new;
    my $opts = Local::CompileOptions->new(push => 1);
    my @args = ('main.tex');
    my (undef, $out, $err) = capture_local_compile($client, \@args, $opts);
    like $err, qr/uncommitted changes/, 'dirty work tree is rejected';
    like $err, qr/--no-push/, 'dirty diagnostic explains remote-only escape hatch';
    is scalar(@{ $client->{calls} }), 0, 'dirty tree does not push or compile';
}

{
    no warnings 'redefine';
    local *local::bin::overleaf::_git_capture = sub {
        my @cmd = @_;
        my $joined = join q{ }, @cmd;
        return $tmp if $joined eq 'git rev-parse --show-toplevel';
        return 'origin' if $joined eq "git -C $tmp remote";
        return 'https://git.overleaf.com/abc123'
            if $joined eq "git -C $tmp remote get-url origin";
        return 'origin/main'
            if $joined eq "git -C $tmp rev-parse --abbrev-ref --symbolic-full-name \@{upstream}";
        die "status should not be queried with --no-push"
            if $joined eq "git -C $tmp -c core.quotepath=false status --porcelain";
        die "unexpected git command: $joined";
    };

    my $client = Local::CompileClient->new;
    my $opts = Local::CompileOptions->new(push => 0, output => 'remote.pdf');
    my @args = ('main.tex');
    my ($status, $out, $err) = capture_local_compile($client, \@args, $opts);
    is $status, 0, '--no-push local compile succeeds';
    is $err, q{}, '--no-push has no stderr';
    like $out, qr/existing Overleaf project \(--no-push\)/,
        '--no-push source is explicit';
    is $client->{calls}[0][0], 'compile', '--no-push skips Git push';
    is $client->{calls}[1][-1], 'remote.pdf', '--output controls downloaded PDF name';
}


{
    no warnings 'redefine';
    local *local::bin::overleaf::_git_capture = sub {
        my @cmd = @_;
        my $joined = join q{ }, @cmd;
        return $tmp if $joined eq 'git rev-parse --show-toplevel';
        return 'origin' if $joined eq "git -C $tmp remote";
        return 'https://git@git.overleaf.com/abc123'
            if $joined eq "git -C $tmp remote get-url origin";
        return 'origin/main'
            if $joined eq "git -C $tmp rev-parse --abbrev-ref --symbolic-full-name \@{upstream}";
        return 'main.tex' if $joined eq "git -C $tmp ls-files -- main.tex";
        return '?? main.pdf'
            if $joined eq "git -C $tmp -c core.quotepath=false status --porcelain";
        die "unexpected git command: $joined";
    };

    my $client = Local::CompileClient->new;
    my $opts = Local::CompileOptions->new(push => 1);
    my @args = ('main.tex');
    my ($status, $out, $err) = capture_local_compile($client, \@args, $opts);
    is $status, 0, 'previous untracked generated PDF does not block local compile';
    is $err, q{}, 'generated PDF exception is quiet';
    is $client->{calls}[0][0], 'push', 'generated PDF exception still permits push';
}

ok local::bin::overleaf::_looks_like_local_compile([]),
    'compile without an argument selects local workflow';
ok local::bin::overleaf::_looks_like_local_compile(['main.tex']),
    '.tex argument selects local workflow';
ok !local::bin::overleaf::_looks_like_local_compile(['abc123']),
    'project id retains legacy remote compile workflow';


{
    my @argv = (
        '--no-push',
        '--remote', 'overleaf',
        '--remote-branch', 'main',
        '--output', 'review.pdf',
        'compile', 'main.tex',
    );
    my $o = local::bin::overleaf::_options(\@argv);
    ok !$o->push, '--no-push is parsed';
    is $o->remote, 'overleaf', '--remote is parsed for local compile';
    is $o->remote_branch, 'main', '--remote-branch is parsed';
    is $o->output, 'review.pdf', '--output is parsed for local compile';
    is_deeply \@argv, [ 'compile', 'main.tex' ],
        'local compile command and root remain after option parsing';
}

{
    my @argv = ('compile', 'main.tex');
    my $o = local::bin::overleaf::_options(\@argv);
    ok $o->push, 'local compile pushes by default';
}

{
    no warnings 'redefine';
    local *local::bin::overleaf::_git_capture = sub {
        my @cmd = @_;
        my $joined = join q{ }, @cmd;
        return 'origin/main'
            if $joined eq "git -C $tmp rev-parse --abbrev-ref --symbolic-full-name \@{upstream}";
        die "unexpected git command: $joined";
    };
    is local::bin::overleaf::_overleaf_remote_branch($tmp, 'origin', undef),
        'main', 'branch discovered from upstream';
}

is local::bin::overleaf::_overleaf_remote_branch($tmp, 'origin', 'main'),
    'main', 'explicit branch override accepted';
my $bad_branch = eval {
    local::bin::overleaf::_overleaf_remote_branch($tmp, 'origin', '../bad');
    1;
};
ok !$bad_branch, 'unsafe branch override rejected';
like $@, qr/invalid remote branch/, 'unsafe branch diagnostic';

chdir $old or die $!;

done_testing;

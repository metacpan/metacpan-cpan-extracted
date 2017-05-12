#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
require Test::NoWarnings if $ENV{RELEASE_TESTING};

use IPC::Cmd qw( can_run run );
use IPC::Run ();
use Probe::Perl;

use Test::SVN::Repo;

my $svn;
unless ($svn = can_run('svn')) {
    plan skip_all => 'Subversion not installed';
    exit;
}


my %users = ( userA => 'passA', userB => 'passB' );

note 'Basic sanity checks'; {
    my $repo;
    lives_ok { $repo = Test::SVN::Repo->new( users => \%users ) }
        '... ctor lives';
    isa_ok($repo, 'Test::SVN::Repo', '...');
    like($repo->url, qr(^svn://), '... url is svn://');
    ok( run_ok($svn, 'info', $repo->url), '... is a valid repo');

    my $pid = $repo->server_pid;
    ok(process_exists($pid), '... server is running');
    undef $repo;
    ok(! process_exists($pid), '... server has shutdown')
}

note 'Check authentication'; {
    my $repo = Test::SVN::Repo->new( users => \%users );

    my $tempdir = $repo->root_path->subdir('test');
    my $file = create_file($tempdir->file('test.txt'), 'Test');

    my @cmd = qw( svn import --non-interactive --no-auth-cache );
    ok( ! run_ok(@cmd, '-m', 'import no auth', $tempdir, $repo->url),
        '... import without auth fails okay');

    ok( ! run_ok(@cmd, '-m', 'import bad user',
            '--username' => 'unknown', '--password' => 'wrong',
            $tempdir, $repo->url), '... unknown user rejected');

    ok( ! run_ok(@cmd, '-m', 'import bad password',
            '--username' => 'userA', '--password' => 'wrong',
            $tempdir, $repo->url), '... bad password rejected');

    for my $user (keys %users) {
        my $pass = $users{$user};
        ok(run_ok(@cmd, '-m', 'import correct auth',
            '--username' => $user, '--password' => $pass,
            create_file($tempdir->file($user, $user . '.txt'), $user)->dir,
            $repo->url), '... correct auth succeeds');
    }
}

Test::NoWarnings::had_no_warnings() if $ENV{RELEASE_TESTING};
done_testing();

#------------------------------------------------------------------------------

sub create_file {
    my ($path, @data) = @_;
    $path->dir->mkpath;
    print {$path->openw} @_;
    return $path;
}

sub process_exists {
    my ($pid) = @_;
    return kill(0, $pid);
}

sub run_ok {
    my (@cmd) = @_;
    return scalar run( command => \@cmd );
}

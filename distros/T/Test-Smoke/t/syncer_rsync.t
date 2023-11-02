#! /usr/bin/perl -w
use strict;
use lib 't';

use Data::Dumper;
use Cwd qw/cwd abs_path/;
use File::Spec;
use File::Spec::Functions;
use File::Temp qw/tempdir/;
use Test::More;
use TestLib;

use Test::Smoke::Syncer;
use Test::Smoke::Util::FindHelpers 'whereis';

my %df_rsync = (
    rsync => 'rsync',
    source => 'github.com/Perl::perl-current',
    opts   => '-az --delete',
    ddir   => File::Spec->canonpath(
        File::Spec->rel2abs('perl-current', abs_path(cwd()))
    ),
);

{ # UNCify_path
    my $path = 'c:\Program Files\Git\bin\git.exe';
    my $unc = UNCify_path($path);
    is($unc, '//localhost/c$/Program Files/Git/bin/git.exe', "UNCify_path");
}
{
    my $sync = eval { Test::Smoke::Syncer->new() };
    ok( !$@, "No error on no type" );
    isa_ok( $sync, 'Test::Smoke::Syncer::Rsync' );
    for my $field (sort keys %df_rsync ) {
        ok( exists $sync->{$field}, "{$field} exists" ) or
            skip "expected {$field} but is not there", 1;
        is( $sync->{$field}, $df_rsync{$field}, "{$field} value" );
    }
}
{
    my %rsync = %df_rsync;
    $rsync{source} = 'ftp.linux.ActiveState.com::perl-current';
    $rsync{ddir}   = File::Spec->canonpath(abs_path(cwd()));
    my $sync = eval {
        Test::Smoke::Syncer->new( 'rsync',
            source => $rsync{source},
            -ddir  => $rsync{ddir},
            nonsence => 'who cares',
        )
    };
    ok( !$@, "No error on type 'rsync'" );
    isa_ok( $sync, 'Test::Smoke::Syncer::Rsync' );
    for my $field (sort keys %rsync ) {
        ok( exists $sync->{ $field }, "{$field} exists" ) or
            skip "expected {$field} but is not there", 1;
        is( $sync->{ $field }, $rsync{ $field },
            "{$field} value $sync->{ $field }" );
    }
}
{
    my %rsync = %df_rsync;
    $rsync{source} = 'ftp.linux.ActiveState.com::perl-current';
    $rsync{ddir}   = File::Spec->canonpath(abs_path(cwd()));
    my $sync = eval {
        Test::Smoke::Syncer->new( rsync => {
            source => $rsync{source},
            -ddir  => $rsync{ddir},
            nonsense => 'who cares',
        })
    };
    ok( !$@, "No errror when options passed as hashref" );
    isa_ok( $sync, 'Test::Smoke::Syncer::Rsync' );
    for my $field (sort keys %rsync ) {
        ok( exists $sync->{ $field }, "{$field} exists" ) or
            skip "expected {$field} but is not there", 1;
        is( $sync->{ $field }, $rsync{ $field },
            "{$field} value $sync->{ $field }" );
    }
}

SKIP: {
    my $verbose = 0;
    my $gitbin = whereis('git');
    skip("No git found :(", 10) if ! $gitbin;

    my $branchname = 'master'; # for compatibility with old and new git version
    my $cwd = abs_path();

    # Set up a basic git repository
    my $git = Test::Smoke::Util::Execute->new(command => $gitbin);
    my $repopath = tempdir(CLEANUP => 1);
    my $diag = $git->run('-c' => "init.defaultBranch=$branchname", init => "-q", $repopath);
    unless (is($git->exitcode, 0, "$gitbin init $repopath")) {
        diag("git init: $diag");
        skip "git init failed! The tests require an empty/different repo";
    }

    unless(chdir $repopath) {
        diag("chdir to '$repopath' failed with error: $!");
        ok(0, "chdir repopath");
        die "chdir failed! Can't run the other tests (wrong cwd)";
    }
    ok(mkpath(catdir($repopath, "Porting")), "mkpath($repopath/Porting)");

    $git->run('config', 'user.name' => "syncer_rsync.t");
    is($git->exitcode, 0, "git config user.name");
    $git->run('config', 'user.email' => "syncer_rsync.t\@example.com");
    is($git->exitcode, 0, "git config user.email");

    (my $gitversion = $git->run('--version')) =~ s/git version (\S+).+/$1/si;
    put_file($gitversion => 'first.file');
    $git->run(add => 'first.file');
    is($git->exitcode, 0, "git add first.file");
    put_file("#! $^X -w\nsystem q/cat first.file/" => qw/Porting make_dot_patch.pl/);
    $git->run(add => 'Porting/make_dot_patch.pl');
    is($git->exitcode, 0, "git add Porting/make_dot_patch.pl");
    $git->run(commit => '-m', "'We need a first file committed'");
    is($git->exitcode, 0, "git commit");

    my $rsync_bin = whereis('rsync', $verbose);
    if (not $rsync_bin) {
        chdir $cwd;
        rmtree($repopath);
        skip "No rsync binary found...", 3;
    }

    my $source = catdir($cwd, 't', 'ftppub', 'perl-current');
    $source = UNCify_path($source) if $^O eq 'MSWin32';

    # make sure to include a space to check this gets split into 2 arguments
    my $options = '-az -v';
    my $ddir = tempdir(CLEANUP => 1);

    my $rsync = Test::Smoke::Syncer->new(
        rsync => (
            rsync  => $rsync_bin,
            opts   => $options,
            source => "$source/",
            ddir   => $ddir,
            v      => $verbose,
        ),
    );
    isa_ok($rsync, 'Test::Smoke::Syncer::Rsync');
    my $result = $rsync->sync;
    is($result, 20000, "->sync returned a patchlevel");
    require Test::Smoke::SourceTree;
    my $st = Test::Smoke::SourceTree->new($ddir, $verbose);
    my $check = $st->check_MANIFEST;

    is_deeply($check, { }, "MANIFEST check for $ddir");

    chdir $cwd;
    rmtree($ddir);
    rmtree($repopath);
}

{ # Set the line, helps predicting the error-message :-)
#line 500
    my $sync = eval { Test::Smoke::Syncer->new( 'nogo' ) };
    ok( $@, "Error on unknown type" );
    like( $@, qq|/Invalid sync_type 'nogo' at t.syncer_rsync\.t line 500/|,
        "Error message on unknown type" );
}

done_testing();

sub UNCify_path {
    my ($path) = @_;
    $path =~ s{\\}{/}g;
    $path =~ s{^([a-z]):}{//localhost/$1\$}i;
    return $path;
}

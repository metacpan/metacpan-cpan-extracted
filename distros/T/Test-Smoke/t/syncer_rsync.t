#! /usr/bin/perl -w
use strict;
use lib 't';

use Data::Dumper;
use Cwd qw/cwd abs_path/;
use File::Spec;
use File::Spec::Functions;
use Test::More;
use TestLib;

use Test::Smoke::Syncer;
use Test::Smoke::Util::FindHelpers 'whereis';

my %df_rsync = (
    rsync => 'rsync',
    source => 'perl5.git.perl.org::perl-current',
    opts   => '-az --delete',
    ddir   => File::Spec->canonpath(
        File::Spec->rel2abs('perl-current', abs_path(cwd()))
    ),
);

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

    my $cwd = abs_path();
    # Set up a basic git repository
    my $git = Test::Smoke::Util::Execute->new(command => $gitbin);
    my $repopath = 't/tsgit';
    $git->run(init => $repopath);
    is($git->exitcode, 0, "git init $repopath");

    mkpath("$repopath/Porting");
    chdir $repopath;
    (my $gitversion = $git->run('--version')) =~ s/git version (\S+).+/$1/si;
    put_file($gitversion => 'first.file');
    $git->run(add => 'first.file');
    put_file("#! $^X -w\nsystem q/cat first.file/" => qw/Porting make_dot_patch.pl/);
    $git->run(add => 'Porting/make_dot_patch.pl');
    $git->run(commit => '-m', "'We need a first file committed'");

    my $rsync_bin = whereis('rsync', $verbose);
    skip "No rsync binary found...", 3 if !$rsync_bin;

    my $source = catdir($cwd, 't', 'ftppub', 'perl-current');
    $source = UNCify_path($source) if $^O eq 'MSWin32';

    # make sure to include a space to check this gets split into 2 arguments
    my $options = '-az -v';
    my $ddir = catdir($cwd, 't', 'smoketest');

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

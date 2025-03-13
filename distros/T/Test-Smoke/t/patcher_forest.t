#! perl -w
use strict;

use File::Spec;
my $findbin;
use File::Basename;
BEGIN { $findbin = dirname $0; }
use lib $findbin;
use TestLib;
use Cwd 'abs_path';
use File::Temp 'tempdir';

my $win32_fat;
BEGIN { $win32_fat = $^O eq 'MSWin32' && Win32::FsType() ne 'NTFS' }

use Test::More $win32_fat
    ? ( skip_all => 'Win32 fat filesystem not supported' )
    : ( tests => 13 );

BEGIN {
    use_ok( 'Test::Smoke::Patcher' );
    use_ok( 'Test::Smoke::Syncer' );
}
my $verbose = exists $ENV{SMOKE_VERBOSE} ? $ENV{SMOKE_VERBOSE} : 0;

my $patch = find_a_patch();
$verbose and diag( "Found patch: '$patch'" );
my $untgz = find_untargz();
$verbose and diag( "found untargz: $untgz" );
my $unzipper = find_unzip();
$verbose and diag( "Found unzip: $unzipper" );

my $curdir = abs_path('.');
my $tmpdir = tempdir(CLEANUP => $ENV{SMOKE_DEBUG} ? 0 : 1);
my %config = (
    ddir     => File::Spec->catdir($tmpdir, 'perl-current'),
    fsync    => 'copy',
    cdir     => File::Spec->catdir($tmpdir, 'perl'),
    mdir     => File::Spec->catdir($tmpdir, 'perl-master'),
    fdir     => File::Spec->catdir($tmpdir, 'perl-inter'),
    patchbin => $patch,
    v        => $verbose,
);

my $has_forest = 0;
SKIP: {
    my $to_skip = 11;
    $patch    or skip "Cannot find a working 'patch' program.", $to_skip;
    $untgz    or skip "Cannot un-tar-gz",                       $to_skip;
    $unzipper or skip "No unzip found",                         $to_skip;

    chdir $tmpdir;
    my $untgz_ok = do_untargz(
        $untgz,
        File::Spec->catfile($curdir, qw( t ftppub snap perl@20000.tgz ))
    );
    my $p_content = do_unzip(
        $unzipper,
        File::Spec->catfile($curdir, qw( t ftppub perl-current-diffs 20005.gz ) )
    );
    chdir $curdir;
    ok( $untgz_ok, "Mockup sourcetree unpacked" );
    ok -d File::Spec->catdir( $tmpdir, 'perl' ), "sourcetree is there";
    like $p_content, '/^\+/m', "patch content ok";

    my $syncer = Test::Smoke::Syncer->new( forest => %config );
    ok my $pl = $syncer->sync, "Forest planted" or
        skip "No source forest ($tmpdir)", $to_skip -= 4;
    is $pl, '37800ef622734ef3d18eddf53581505ff036f4b6', "patchlevel $pl";
    $has_forest = 1;

    local *PINFO;
    my $relpatch = File::Spec->catfile($tmpdir, '20005');
    open PINFO, "> $relpatch" or
        skip "Cannot write patch: $!", $to_skip -= 1;
    print PINFO $p_content;
    ok close PINFO, "patch written";

    my $pinfo = File::Spec->catfile($tmpdir, 'test.patches');
    open PINFO, "> $pinfo" or skip "Cannot open '$pinfo': $!", $to_skip -= 2;
    select( (select(PINFO), $|++)[0] );
    print PINFO <<EOPINFO;
$relpatch;-p1
# Do some comments 
# This is to take out #20001, so we can see what happend
# $relpatch;-R
# $relpatch
EOPINFO
    ok close PINFO, "pfile written";

    # cheat with .patch
    unlink File::Spec->catfile($tmpdir, qw(perl-inter .patch));
    ok(
        my $patcher = Test::Smoke::Patcher->new(
            multi => {
                %config,
                pfile => File::Spec->catfile($tmpdir, 'test.patches'),
            }
        ),
        "Patcher created"
    );
    isa_ok $patcher, 'Test::Smoke::Patcher';

    ($ENV{SMOKE_DEBUG} || $verbose > 2) and diag(explain($patcher));
    ok eval { $patcher->patch }, "Patch the intermediate tree";
    diag("patching error: $@") if $@;

    chomp( my $plev = get_file($tmpdir, qw( perl-current .patch )) );
    is $plev, 20006, "Tree successfully patched";
}


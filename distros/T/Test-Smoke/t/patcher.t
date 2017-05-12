#! /usr/bin/perl -w
use strict;

# $Id$

use File::Spec;
my $findbin;
use File::Basename;
BEGIN { $findbin = dirname $0; }
use lib $findbin;
#use lib File::Spec->catdir( $findbin, File::Spec->updir, 'lib' );
use TestLib;
use Cwd;

use Test::More tests => 41;
BEGIN { use_ok( 'Test::Smoke::Patcher' ) };
my $verbose = exists $ENV{SMOKE_VERBOSE} ? $ENV{SMOKE_VERBOSE} : 0;

{
    my $df_vals = Test::Smoke::Patcher->config( 'all_defaults' );
    my $tdir = 't';
    my $fs_tdir = File::Spec->rel2abs( $tdir );
    my $patcher = Test::Smoke::Patcher->new( single => { ddir  => $tdir } );
    isa_ok( $patcher, 'Test::Smoke::Patcher' );
    is( $patcher->{pdir}, $fs_tdir, "destination dir ($fs_tdir)" );

    # Check that the default values are returned
    for my $attr (qw( pfile patchbin popts v )) {
        is( $patcher->{ $attr }, $df_vals->{ $attr }, 
            "'$attr' attribute" );
    }

    # now test the options stuff
    $patcher->{popts} = '-bp1';
    is( $patcher->_make_opts, '-bp1', "Patch option '-bp1'" );
}

my $patch = find_a_patch();
$verbose and diag( "Found patch: '$patch'" );
my $testpatch = File::Spec->catfile( 't', 'test.patch' );

SKIP: { # test Test::Smoke::Patcher->patch_single()
    my $to_skip = 13;
    skip "Cannot find a working 'patch' program.", $to_skip unless $patch;
    my $patcher = Test::Smoke::Patcher->new( single => { v => $verbose,
        -ddir     => File::Spec->catdir( 't', 'perl' ),
        -patchbin => $patch,
    });

    isa_ok( $patcher, 'Test::Smoke::Patcher' );
    my $untgz = find_untargz() or skip "Cannot un-tar-gz", --$to_skip;
    my $unzipper = find_unzip() or skip "No unzip found", $to_skip;

    chdir('t');
    my $untgz_ok = do_untargz( $untgz, File::Spec->catfile(
        qw( ftppub snap perl@20000.tgz ) ) );
    chdir( File::Spec->updir );

    my $p_content = do_unzip( $unzipper, File::Spec->catfile(
        qw(t ftppub perl-current-diffs 20001.gz ) ));

    ok( $untgz, "I found untar-gz ($untgz)");
    ok( $unzipper, "We have unzip ($unzipper)" );
    ok( $untgz_ok, "Mockup sourcetree" );
    ok( $p_content, "The patch was read..." );

    # check if it works for passing the patch as a ref2scalar
    eval { $patcher->patch_single( \$p_content ) };
    ok( ! $@, "patch applied (SCALAR ref): $@" );

    my $newfile = get_file(qw( t perl patchme.txt ));
    like( $newfile, '/^VERSION == 20001$/m', "Content seems ok" );

    my $reverse1 = File::Spec->catfile( File::Spec->updir, 'test.patch' );
    local *MYPATCH;
    open MYPATCH, "> $testpatch" or 
        skip "Cannont create '$testpatch': $!", $to_skip -= 4;
    binmode MYPATCH;
    print MYPATCH $p_content;
    close MYPATCH;

    eval{ $patcher->patch_single( $reverse1, '-R' ) };
    ok( !$@, "Reverse patch applied (filename): $@" );
    $newfile = get_file(qw( t perl patchme.txt ));
    unlike( $newfile, '/^VERSION == 20001$/m', "Content seems ok" );

    my @plines = map "$_\n" => split /\n/, $p_content;
    eval { $patcher->patch_single( \@plines ) };
    ok( !$@, "Patch reapplied (ARRAY ref): $@" );
    $newfile = get_file(qw( t perl patchme.txt ));
    like( $newfile, '/^VERSION == 20001$/m', "Content seems ok" );

    open MYPATCH, "< $testpatch" or
        skip "Cannot open '$testpatch': $!", $to_skip -= 4;
    eval { $patcher->patch_single( \*MYPATCH, '-R' ) };
    ok( ! $@, "Reverse patch applied (GLOB ref): $@" );
    close MYPATCH;
    $newfile = get_file(qw( t perl patchme.txt ));
    unlike( $newfile, '/^VERSION == 20001$/m', "Content seems ok" );

}

SKIP: { # Test multi mode
    my $to_skip = 12;

    skip "No patch program or test-patch found", $to_skip
        unless $patch && -e $testpatch;

    my $relpatch = File::Spec->catfile( File::Spec->updir, 'test.patch' );
    my $pi_content = "$relpatch\n";

    my $patcher = Test::Smoke::Patcher->new( multi => { v => $verbose,
        ddir     => File::Spec->catdir( 't', 'perl' ),
        patchbin => $patch,
    });
    isa_ok( $patcher, 'Test::Smoke::Patcher' );

    eval { $patcher->patch_multi( \$pi_content ) };
    ok( !$@, "No error while running patch $@" );
    my $newfile = get_file(qw( t perl patchme.txt ));
    like( $newfile, '/^VERSION == 20001$/m', "Content ok" );

    my @patches = map "$_\n" => ( "$relpatch;-R", $relpatch, "$relpatch;-R" );
    eval { $patcher->patch_multi( \@patches ) };
    ok( ! $@, "No error while running patch $@" );
    $newfile = get_file(qw( t perl patchme.txt ));
    unlike( $newfile, '/^VERSION == 20001$/m', "Content ok" );

    my $pinfo = File::Spec->catfile( 't', 'test.patches' );
    local *PINFO;
    open PINFO, "+> $pinfo" or skip "Cannot open '$pinfo': $!", $to_skip -= 5;
    select( (select(PINFO), $|++)[0] );
    print PINFO <<EOPINFO;
$relpatch
# Do some somments 
# This is to take out #20001, so we can see what happend
$relpatch;-R
$relpatch
EOPINFO
    seek PINFO, 0, 0;
    eval { $patcher->patch_multi( \*PINFO ) };
    ok( ! $@, "No Errors while running patch $@" );
    $newfile = get_file(qw( t perl patchme.txt ));
    like( $newfile, '/^VERSION == 20001$/m', "Conent OK" );
    close PINFO;
    1 while unlink $pinfo;

    open PINFO, "> $pinfo" or skip "Cannot open '$pinfo': $!", $to_skip -= 2;
    print PINFO "$relpatch;-R\n";
    close PINFO or skip "Error on write: $!", $to_skip;

    eval { $patcher->patch_multi( File::Spec->rel2abs($pinfo) ) };
    ok( ! $@, "No Errors while running patch $@" );
    $newfile = get_file(qw( t perl patchme.txt ));
    unlike( $newfile, '/^VERSION == 20001$/m', "Conent OK" );
    1 while unlink $pinfo;

    my $descr = '[PATCH] just testing comments';
    eval { $patcher->patch_single( $relpatch, '', $descr ) };
    ok ! $@, "Patch applied($descr) $@";
    $newfile = get_file(qw( t perl patchme.txt ));
    like( $newfile, '/^VERSION == 20001$/m', "Conent OK" );
    my $plevel = get_file(qw( t perl patchlevel.h ));
    like $plevel, qq{/^\\s*,"\Q$descr\E"/m},
         "Description added to patchlevel.h";
}

{
    ok( defined &TRY_REGEN_HEADERS, "Exported \&TRY_REGEN_HEADERS" );
    Test::Smoke::Patcher->config( flags => TRY_REGEN_HEADERS );
    my $patcher = Test::Smoke::Patcher->new( single => { v => $verbose,
        ddir => File::Spec->catdir(qw( t perl )),
    } );
    is( $patcher->{flags}, TRY_REGEN_HEADERS, "flags set from config()" );

    # Should test if it calls 'regen_headers.pl'
}

{
    my $pfile = File::Spec->catfile( 't', 'test.patch' );
    put_file( <<EOF, $pfile );
# Test patchinfo file
!perly
EOF

    my $ddir = File::Spec->catdir(qw( t perl ));
    -d $ddir or mkpath( $ddir, $verbose );
    my $rhd = File::Spec->catfile( $ddir, 'regen.pl' );
    put_file( <<EOF, $rhd );
#! perl -w
use File::Spec::Functions qw( :DEFAULT rel2abs );
my \$lib;
BEGIN { \$lib = rel2abs updir }
use lib catdir \$lib, updir(), 'lib';
use lib \$lib;
use TestLib;
my \$rhd = 'regen_pl.out';
put_file( "File \$rhd (\$0)\\n", \$rhd )
EOF

    my $rpy = File::Spec->catfile( $ddir, 'regen_perly.pl' );
    my @yfiles = qw( perly.tab perly.h perly.y );

    put_file( <<EOF, $rpy );
#! perl -w
use File::Spec::Functions qw( :DEFAULT rel2abs );
my \$lib;
BEGIN { \$lib = rel2abs updir }
use lib catdir \$lib, updir(), 'lib';
use lib \$lib;
use TestLib;
my \@files = qw( @yfiles );
for my \$yf ( \@files ) { put_file( "File \$yf (\$0)\\n", \$yf ) }
EOF

    my $patcher = Test::Smoke::Patcher->new( multi => { v => $verbose,
        ddir => $ddir,
        pfile => File::Spec->rel2abs( $pfile ),
    });

    isa_ok $patcher, 'Test::Smoke::Patcher';

    $patcher->patch;
    ok $patcher->{perly}, "regen_perly.pl";
    ok -f File::Spec->catfile( $ddir, 'regen_pl.out' ), "Check 'regen_pl.out'";
    for my $yf ( @yfiles ) {
        ok -f File::Spec->catfile( $ddir, $yf ), "Check '$yf'";
    }

    unless ( $ENV{SMOKE_DEBUG} ) {
        rmtree( $ddir, $verbose );
    }
}

END {
    unless ( $ENV{SMOKE_DEBUG} ) {
        rmtree( File::Spec->catdir(qw( t perl )) );
        1 while unlink $testpatch;
    }
}

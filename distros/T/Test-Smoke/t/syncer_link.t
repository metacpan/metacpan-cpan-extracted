#! /usr/bin/perl -w
use strict;

# $Id$

use Config;
use File::Spec;
use Cwd 'abs_path';
use lib File::Spec->rel2abs( 't', abs_path() );
use TestLib;

my $win32_fat;
BEGIN { $win32_fat = $^O eq 'MSWin32' && Win32::FsType() ne 'NTFS' }

use Test::More $win32_fat
    ? ( skip_all => 'Win32 fat filesystem not supported' )
    : ( tests => 12 );

use_ok( 'Test::Smoke::Syncer' );

my $verbose = $ENV{SMOKE_VERBOSE} ? $ENV{SMOKE_VERBOSE} : 0;
{
    my $syncer = Test::Smoke::Syncer->new( hardlink => { v => $verbose,
        ddir => File::Spec->catdir(qw( t perl-current )),
        hdir => File::Spec->catdir(qw( t perl )),
    } );

    isa_ok( $syncer, 'Test::Smoke::Syncer::Base' );
    isa_ok( $syncer, 'Test::Smoke::Syncer::Hardlink' );
}

{ # check that it croak()s
#line 100
    my $syncer = eval { Test::Smoke::Syncer->new( hardlink => { v => $verbose,
        ddir => File::Spec->catdir(qw( t perl-current )),
    } ) };

    ok( $@, "croak on omitted {hdir}" );
    like( $@, "/option 'hdir' missing.*?at \Q$0\E line 100/", "It's a croak()" );
}

SKIP: {
# Try to find tar/gzip, Archive::Tar/Compress::Zlib
# When found, t/ftppub/snap/perl@20000.tgz can be extracted
# and used as a base for the hardlink sync

    my $to_skip = 4;
    $Config{d_link} or skip "No links on $^O", $to_skip;
    my $tar = find_uncompress() or
        skip "Cannot find decompression stuff", $to_skip;

    do_uncompress( $tar, 't',
                   File::Spec->catfile(qw( ftppub snap perl@20000.tgz )) ) or
        skip "Cannot decompress testsnapshot", $to_skip;

    ok( -d File::Spec->catdir(qw( t perl )), "snapshot OK" );

    my $syncer = Test::Smoke::Syncer->new( hardlink => { v=> $verbose,
        ddir => File::Spec->catdir(abs_path(), qw( t perl-current )),
        hdir => File::Spec->catdir(abs_path(), qw( t perl )),
    } );

    my %perl = map { ($_ => 1) } get_dir( $syncer->{hdir} );
    $syncer->sync();
    my %perl_current = map { ($_ => 1) } get_dir( $syncer->{ddir} );

    is( scalar keys %perl_current, scalar keys %perl,
        "number of files the same" );
    is_deeply( \%perl_current, \%perl, "Same files in the two dirs" );

    if ( $^O ne 'MSWin32' ) {
        is_deeply( inodes( $syncer->{ddir} ), inodes( $syncer->{hdir} ),
                   "check inodes of hardlinks" );
    } else {
        skip "Cannot check inodes on Windows-fs", 1;
    }

    rmtree( File::Spec->catdir(qw( t perl )), $syncer->{v} );
    rmtree( File::Spec->catdir(qw( t perl-current )), $syncer->{v} );
}

SKIP: { # Check that the same works for {haslink} == 0
# Try to find tar/gzip, Archive::Tar/Compress::Zlib
# When found, t/ftppub/snap/perl@20000.tgz can be extracted
# and used as a base for the hardlink sync

    my $to_skip = 3;
    $Config{d_link} or skip "No links on $^O", $to_skip;
    my $tar = find_uncompress() or
        skip "Cannot find decompression stuff", $to_skip;

    do_uncompress( $tar, 't', 
                   File::Spec->catfile(qw( ftppub snap perl@20000.tgz )) ) or
        skip "Cannot decompress testsnapshot", $to_skip;

    ok( -d File::Spec->catdir(qw( t perl )), "snapshot OK" );

    my $syncer = Test::Smoke::Syncer->new( hardlink => { v=> $verbose,
        ddir    => File::Spec->catdir(abs_path(), qw( t perl-current )),
        hdir    => File::Spec->catdir(abs_path(), qw( t perl )),
        haslink => 0,
    } );

    my %perl = map { ($_ => 1) } get_dir( $syncer->{hdir} );
    $syncer->sync();
    my %perl_current = map { ($_ => 1) } get_dir( $syncer->{ddir} );

    is( scalar keys %perl_current, scalar keys %perl,
        "number of files the same [nolink]" );
    is_deeply( \%perl_current, \%perl, "Same files in the two dirs [nolink]" );


    rmtree( File::Spec->catdir(qw( t perl )), $syncer->{v} );
    rmtree( File::Spec->catdir(qw( t perl-current )), $syncer->{v} );
}

sub inodes {
    my $dir = shift;

    require File::Find;
    my %inodes;
    File::Find::find( sub {
        -f or return;
        $inodes{ (stat _)[1] } = 1;
    }, $dir );

    return \%inodes;
}

sub find_uncompress {
    return find_untargz;
}

sub do_uncompress {
    my( $tar, $ddir, $sfile ) = @_;

    chdir $ddir or do {
        warn "Cannot chdir($ddir): $!";
        return;
    };

    do_untargz( $tar, $sfile );

    # I cannot use Test::Smoke::Syncer::Snapshot to extract
    # but I need check_dot_patch() for the tests
    my $syncer = Test::Smoke::Syncer->new( snapshot => { 
        v    => 2,
        ddir => 'perl',
    });
    $syncer->check_dot_patch();

    chdir File::Spec->updir;

    return 1;
}

#! /usr/bin/perl -w
use strict;

##### syncer_ftp.t
#
# Here we try to test the actual syncing process from a snapshot
# This is done by overriding all the used Net::FTP handlers
# and provide a fake FTP mechanism through them
# For this there is the 't/ftppub' directory with:
#     't/ftppub/snap' contains two fake snapshots (with files)
#     't/ftppub/perl-current-diffs' contains a few fake diffs
# Now that we have controlable FTP (if you have Net::FTP),
# we can concentrate on doing the untargz and patch stuff
#
#####
my $findbin;
use File::Basename;
BEGIN { $findbin = dirname $0; }
use lib $findbin;
use TestLib;
use File::Spec;
use File::Temp 'tempdir';

use Test::More;

BEGIN {
    eval { require Net::FTP; };
    $@ and plan( skip_all => "No 'Net::FTP' found!\n" .
                             "!!!You will not be able to smoke from " .
                             "snapshots without it!!!" );
    plan tests => 7;
}

my $verbose = $ENV{SMOKE_VERBOSE} || 0;
$verbose and diag "SMOKE_VERBOSE = $verbose";

# Can we get away with redefining the Net::FTP stuff?

BEGIN { $^W = 0; } # no warnings 'redefine';
sub Net::FTP::new { bless {}, 'Net::FTP' }
sub Net::FTP::login { return 1 }
sub Net::FTP::binary { return 1 }
sub Net::FTP::quit {return 1 }
sub Net::FTP::cwd {
    my $self = shift;
    ( my $dir = shift ) =~ s|^.*/||;
    $self->{cwd} = File::Spec->catdir( 't', 'ftppub', $dir );
}
sub Net::FTP::ls {
    my $self = shift;
    local *DLDIR;
    opendir DLDIR, $self->{cwd} or return ( );
    return grep ! /\.{1,2}$/ => readdir DLDIR;
}
sub Net::FTP::size {
    my $self = shift;
    my $file = File::Spec->catfile( $self->{cwd}, shift );
    return -s $file;
}
sub Net::FTP::get {
    my $self = shift;
    my $source = shift;
    my $file = File::Spec->catfile( $self->{cwd}, $source );
    my $dest = shift || $source;
    local( *SRC, *DST );

    if ( open SRC, "< $file" ) {
        binmode SRC;
        if ( open DST, "> $dest" ) {
            binmode DST;
            print  DST do { local $/; <SRC> };
            close DST;
        } else {
            die "Can't write '$dest': $!";
        }
    } else {
        die "Can't write '$dest': $!";
    }
    return $dest;
}
sub Net::FTP::DESTROY { }
BEGIN { $^W = 1; }

require Test::Smoke::Patcher; # for testing only

# Now begin testing
use_ok( 'Test::Smoke::Syncer' );

my $patch = find_a_patch();
my $tmpdir = tempdir(CLEANUP => ($ENV{SMOKE_DEBUG} ? 0 : 1));

SKIP: { # Here we try for 'Archive::Tar'/'Compress::Zlib'

    eval { require Archive::Tar; };
    $@ and skip "Can't load 'Archive::Tar'", 3;

    eval { require Compress::Zlib; };
    $@ and skip "Can't load 'Compress::Zlib'", 3;

    my $syncer = Test::Smoke::Syncer->new(
        snapshot => {
            v        => $verbose,
            ddir     => File::Spec->catdir($tmpdir, 'perl-current'),
            sdir     => '/t/snap',
            tar      => 'Archive::Tar',
            unzip    => 'Compress::Zlib',
            snapext  => 'tgz',
            cleanup  => 3,
            patchbin => $patch,
        }
    );

    isa_ok( $syncer, 'Test::Smoke::Syncer::Snapshot' );

    my $plevel  = $syncer->sync;

    is( $plevel, 20000, "Patchlevel $plevel by $syncer->{tar}" );

    skip "Cannot find a 'patch' program", 1 unless $patch;
    my $plevel2 = $syncer->patch_a_snapshot( $plevel );

    is( $plevel2, 20005, "A patched snapshot $plevel2 by $syncer->{unzip}" );

}

SKIP: { # Here we try for gzip/tar

    my $tar = whereis( 'tar' ) or skip "Can't find a 'tar'", 3;

    my $gzip = whereis( 'gzip' );
    # lets try something...

    my $unpack = $gzip ? qq[$gzip -dc "%s" | $tar -xf -] : qq[$tar -xzf "%s"];

    $gzip .= " -dc" if $gzip;
    $gzip = whereis( 'gunzip' ) unless $gzip;
    $gzip = whereis( 'zcat' ) unless $gzip;

    my $syncer = Test::Smoke::Syncer->new(
        snapshot => {
            v        => $verbose,
            ddir     => File::Spec->catdir($tmpdir, 'perl-current'),
            sdir     => '/t/snap',
            tar      => $unpack,
            unzip    => $gzip,
            snapext  => 'tgz',
            cleanup  => 3,
            patchbin => $patch,
        }
    );

    isa_ok( $syncer, 'Test::Smoke::Syncer::Snapshot' );

    my $plevel  = $syncer->sync;

    is( $plevel, 20000, "Patchlevel $plevel by $syncer->{tar}" );

    skip "Can't seem to find 'gzip/gunzip/zcat'", 1 unless $gzip;
    skip "Cannot find a 'patch' program", 1 unless $patch;

    my $plevel2 = $syncer->patch_a_snapshot( $plevel );

    is( $plevel2, 20005, "A patched snapshot $plevel2 by $syncer->{unzip}" );

}

#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

# Create temp files BEFORE loading Test::MockFile to avoid
# File::Temp's internal stat/chmod hitting our overrides on older Perls.
my $dir;
my $euid;
my $egid;

BEGIN {
    $euid = $>;
    $egid = int $);

    $dir = "/tmp/tmf_passthrough_$$";
    CORE::mkdir($dir, 0700) or die "Cannot create $dir: $!";
}

use Test::MockFile qw< nostrict >;

# These tests exercise the passthrough path in __chmod and __chown
# where all files are unmocked and must be forwarded to CORE::chmod/chown
# with the correct arguments (mode for chmod, uid+gid for chown).

subtest(
    'chmod passthrough to real filesystem' => sub {
        my $file = "$dir/chmod_test";

        CORE::open( my $fh, '>', $file ) or die "Cannot create $file: $!";
        print {$fh} "test content\n";
        close $fh;

        # Set to 0644 first via the override (passthrough since not mocked)
        my $result = chmod 0644, $file;
        is( $result, 1, 'chmod returned 1 (one file changed)' );

        my $perms = ( CORE::stat($file) )[2] & 07777;
        is(
            sprintf( '%04o', $perms ),
            '0644',
            'chmod passthrough correctly applied mode 0644',
        );

        # Change to 0600
        $result = chmod 0600, $file;
        is( $result, 1, 'chmod returned 1 for mode change to 0600' );

        $perms = ( CORE::stat($file) )[2] & 07777;
        is(
            sprintf( '%04o', $perms ),
            '0600',
            'chmod passthrough correctly applied mode 0600',
        );

        # Multiple files
        my $file2 = "$dir/chmod_test2";
        CORE::open( my $fh2, '>', $file2 ) or die "Cannot create $file2: $!";
        print {$fh2} "test2\n";
        close $fh2;

        $result = chmod 0755, $file, $file2;
        is( $result, 2, 'chmod returned 2 (two files changed)' );

        for my $f ( $file, $file2 ) {
            $perms = ( CORE::stat($f) )[2] & 07777;
            is(
                sprintf( '%04o', $perms ),
                '0755',
                "chmod passthrough correctly applied mode 0755 to $f",
            );
        }
    }
);

subtest(
    'chown passthrough to real filesystem' => sub {
        my $file = "$dir/chown_test";

        CORE::open( my $fh, '>', $file ) or die "Cannot create $file: $!";
        print {$fh} "test content\n";
        close $fh;

        # chown -1, -1 means "keep as is" - should always succeed
        my $result = chown -1, -1, $file;
        is( $result, 1, 'chown -1, -1 passthrough returned 1' );

        my ( $uid, $gid ) = ( CORE::stat($file) )[ 4, 5 ];
        is( $uid, $euid, 'File UID unchanged after chown -1, -1' );

        # chown to current user/group - should always succeed
        $result = chown $euid, $egid, $file;
        is( $result, 1, 'chown to current user/group passthrough returned 1' );

        ( $uid, $gid ) = ( CORE::stat($file) )[ 4, 5 ];
        is( $uid, $euid, 'File UID correct after chown' );
        is( $gid, $egid, 'File GID correct after chown' );
    }
);

done_testing();

# Cleanup
END {
    if ( defined $dir && -d $dir ) {
        CORE::unlink glob("$dir/*");
        CORE::rmdir $dir;
    }
}

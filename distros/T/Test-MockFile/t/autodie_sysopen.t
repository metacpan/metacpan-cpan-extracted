#!/usr/bin/perl

# Test autodie compatibility with sysopen in Test::MockFile.
#
# autodie installs per-package wrappers that call CORE::sysopen directly,
# bypassing CORE::GLOBAL::sysopen. Test::MockFile's per-package overrides
# handle this. This test verifies that autodie exceptions are properly
# thrown when mocked sysopen operations fail.

use strict;
use warnings;

use Test::More;
use Fcntl qw( O_RDONLY O_WRONLY O_RDWR O_CREAT O_EXCL O_TRUNC );

# Skip if autodie is not available
BEGIN {
    eval { require autodie };
    if ($@) {
        plan skip_all => 'autodie not available';
    }
}

# Load both — autodie first, then Test::MockFile.
use autodie qw(sysopen);
use Test::MockFile qw(nostrict);

subtest 'sysopen mocked file succeeds with autodie active' => sub {
    my $file = "/autodie_sysopen_read_$$";
    my $mock = Test::MockFile->file( $file, "test content" );

    my $ok = eval {
        sysopen( my $fh, $file, O_RDONLY );
        ok( defined $fh, "filehandle defined" );
        close($fh);
        1;
    };
    ok( $ok, "sysopen O_RDONLY on existing mocked file does not die" )
      or diag("Error: $@");
};

subtest 'sysopen O_CREAT creates file with autodie active' => sub {
    my $file = "/autodie_sysopen_create_$$";
    my $mock = Test::MockFile->file( $file, undef );

    my $ok = eval {
        sysopen( my $fh, $file, O_WRONLY | O_CREAT );
        ok( defined $fh, "filehandle defined after O_CREAT" );
        close($fh);
        1;
    };
    ok( $ok, "sysopen O_CREAT on non-existent mocked file does not die" )
      or diag("Error: $@");

    is( $mock->contents(), '', "file created with empty contents" ) if $ok;
};

subtest 'sysopen O_RDWR on existing file with autodie active' => sub {
    my $file = "/autodie_sysopen_rdwr_$$";
    my $mock = Test::MockFile->file( $file, "existing data" );

    my $ok = eval {
        sysopen( my $fh, $file, O_RDWR );
        ok( defined $fh, "filehandle defined for O_RDWR" );
        close($fh);
        1;
    };
    ok( $ok, "sysopen O_RDWR on existing mocked file does not die" )
      or diag("Error: $@");
};

SKIP: {
    skip "autodie exception detection requires Perl 5.14+", 6
      if $] < 5.014;

    subtest 'autodie dies on sysopen O_RDONLY non-existent file' => sub {
        my $file = "/autodie_sysopen_noexist_$$";
        my $mock = Test::MockFile->file( $file, undef );

        my $died = !eval {
            sysopen( my $fh, $file, O_RDONLY );
            1;
        };

        ok( $died, "autodie dies when sysopen O_RDONLY on non-existent mocked file" );
        ok( defined $@, "exception is set" ) if $died;
    };

    subtest 'autodie exception is autodie::exception for sysopen' => sub {
        my $file = "/autodie_sysopen_exc_$$";
        my $mock = Test::MockFile->file( $file, undef );

        eval {
            sysopen( my $fh, $file, O_RDONLY );
        };
        my $err = $@;    # Save before next eval clobbers it

        if ( eval { require autodie::exception; 1 } ) {
            isa_ok( $err, 'autodie::exception', 'exception is autodie::exception object' );
            is( $err->function, 'CORE::sysopen', 'exception function is CORE::sysopen' );
        }
        else {
            ok( defined $err, "exception is set (autodie::exception not loadable)" );
        }
    };

    subtest 'autodie dies on sysopen O_EXCL existing file' => sub {
        my $file = "/autodie_sysopen_excl_$$";
        my $mock = Test::MockFile->file( $file, "already here" );

        my $died = !eval {
            sysopen( my $fh, $file, O_WRONLY | O_CREAT | O_EXCL );
            1;
        };
        my $err = $@;

        ok( $died, "autodie dies on O_EXCL when file exists" );
        if ( $died && eval { require autodie::exception; 1 } ) {
            isa_ok( $err, 'autodie::exception', 'O_EXCL exception type' );
        }
    };

    subtest 'autodie dies on sysopen directory' => sub {
        my $dir = "/autodie_sysopen_dir_$$";
        my $mock = Test::MockFile->new_dir( $dir );

        my $died = !eval {
            sysopen( my $fh, $dir, O_RDONLY );
            1;
        };
        my $err = $@;

        ok( $died, "autodie dies on sysopen of directory (EISDIR)" );
        if ( $died && eval { require autodie::exception; 1 } ) {
            isa_ok( $err, 'autodie::exception', 'EISDIR exception type' );
        }
    };

    subtest 'autodie dies on sysopen broken symlink' => sub {
        my $link = "/autodie_sysopen_brokenlink_$$";
        my $target = "/autodie_sysopen_missing_target_$$";
        my $mock_link = Test::MockFile->symlink( $target, $link );

        my $died = !eval {
            sysopen( my $fh, $link, O_RDONLY );
            1;
        };
        my $err = $@;

        ok( $died, "autodie dies on sysopen of broken symlink (ENOENT)" );
        if ( $died && eval { require autodie::exception; 1 } ) {
            isa_ok( $err, 'autodie::exception', 'broken symlink exception type' );
        }
    };

    subtest 'sysopen succeeds through valid symlink with autodie' => sub {
        my $link = "/autodie_sysopen_goodlink_$$";
        my $target = "/autodie_sysopen_target_$$";
        my $mock_target = Test::MockFile->file( $target, "via symlink" );
        my $mock_link = Test::MockFile->symlink( $target, $link );

        my $ok = eval {
            sysopen( my $fh, $link, O_RDONLY );
            ok( defined $fh, "filehandle defined through symlink" );
            close($fh);
            1;
        };
        ok( $ok, "sysopen through valid symlink does not die with autodie" )
          or diag("Error: $@");
    };
}

done_testing();

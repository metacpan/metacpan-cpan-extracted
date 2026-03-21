#!/usr/bin/perl

# Test autodie exception throwing for all CORE override functions.
# Covers issue #264: autodie exceptions were only thrown for open/sysopen,
# leaving 12 other functions silently returning false under autodie.

use strict;
use warnings;

use Test::More;

# Skip if autodie is not available
BEGIN {
    eval { require autodie };
    if ($@) {
        plan skip_all => 'autodie not available';
    }
}

use autodie qw(opendir closedir unlink readlink mkdir rmdir
               rename link symlink truncate chmod chown utime);
use Test::MockFile qw(nostrict);

SKIP: {
    skip "autodie exception detection requires Perl 5.14+", 1
      if $] < 5.014;

    # Helper to verify autodie exception
    my $check_autodie = sub {
        my ($err, $func_name, $test_label) = @_;
        ok( defined $err, "$test_label: exception thrown" );
        if ( eval { require autodie::exception; 1 } ) {
            isa_ok( $err, 'autodie::exception', "$test_label: is autodie::exception" );
            like( $err->function, qr/\Q$func_name\E/, "$test_label: function is $func_name" );
        }
    };

    # ---- opendir ----

    subtest 'opendir dies on non-existent mocked dir' => sub {
        my $dir = Test::MockFile->dir("/ad_opendir_noexist_$$");

        my $died = !eval {
            opendir( my $dh, "/ad_opendir_noexist_$$" );
            1;
        };
        my $err = $@;

        ok( $died, "opendir dies on non-existent dir" );
        $check_autodie->( $err, 'opendir', 'opendir ENOENT' );
    };

    subtest 'opendir dies on ENOTDIR' => sub {
        my $file = Test::MockFile->file( "/ad_opendir_notdir_$$", "content" );

        my $died = !eval {
            opendir( my $dh, "/ad_opendir_notdir_$$" );
            1;
        };
        my $err = $@;

        ok( $died, "opendir dies on regular file (ENOTDIR)" );
        $check_autodie->( $err, 'opendir', 'opendir ENOTDIR' );
    };

    # ---- closedir ----

    subtest 'closedir dies on double-close' => sub {
        my $dir = Test::MockFile->new_dir("/ad_closedir_$$");

        opendir( my $dh, "/ad_closedir_$$" );
        closedir($dh);

        # Second close should die
        my $died = !eval {
            no warnings 'io';    # suppress closedir warning
            closedir($dh);
            1;
        };
        my $err = $@;

        ok( $died, "closedir dies on already-closed handle" );
        $check_autodie->( $err, 'closedir', 'closedir EBADF' );
    };

    # ---- unlink ----

    subtest 'unlink dies on non-existent mocked file' => sub {
        my $file = Test::MockFile->file("/ad_unlink_noexist_$$");

        my $died = !eval {
            unlink("/ad_unlink_noexist_$$");
            1;
        };
        my $err = $@;

        ok( $died, "unlink dies on non-existent mocked file" );
        $check_autodie->( $err, 'unlink', 'unlink ENOENT' );
    };

    # ---- readlink ----

    subtest 'readlink dies on non-existent mocked path' => sub {
        my $file = Test::MockFile->file("/ad_readlink_noexist_$$");

        my $died = !eval {
            readlink("/ad_readlink_noexist_$$");
            1;
        };
        my $err = $@;

        ok( $died, "readlink dies on non-existent mock" );
        $check_autodie->( $err, 'readlink', 'readlink ENOENT' );
    };

    subtest 'readlink dies on regular file (EINVAL)' => sub {
        my $file = Test::MockFile->file( "/ad_readlink_file_$$", "data" );

        my $died = !eval {
            readlink("/ad_readlink_file_$$");
            1;
        };
        my $err = $@;

        ok( $died, "readlink dies on non-symlink" );
        $check_autodie->( $err, 'readlink', 'readlink EINVAL' );
    };

    # ---- symlink ----

    subtest 'symlink dies when target exists (EEXIST)' => sub {
        my $link = Test::MockFile->file( "/ad_symlink_exists_$$", "data" );

        my $died = !eval {
            symlink( '/some/target', "/ad_symlink_exists_$$" );
            1;
        };
        my $err = $@;

        ok( $died, "symlink dies when link already exists" );
        $check_autodie->( $err, 'symlink', 'symlink EEXIST' );
    };

    # ---- link ----

    subtest 'link dies when source does not exist (ENOENT)' => sub {
        my $src = Test::MockFile->file("/ad_link_nosrc_$$");
        my $dst = Test::MockFile->file("/ad_link_nodst_$$");

        my $died = !eval {
            link( "/ad_link_nosrc_$$", "/ad_link_nodst_$$" );
            1;
        };
        my $err = $@;

        ok( $died, "link dies when source doesn't exist" );
        $check_autodie->( $err, 'link', 'link ENOENT' );
    };

    subtest 'link dies when destination exists (EEXIST)' => sub {
        my $src = Test::MockFile->file( "/ad_link_src_$$",  "data" );
        my $dst = Test::MockFile->file( "/ad_link_dstx_$$", "exists" );

        my $died = !eval {
            link( "/ad_link_src_$$", "/ad_link_dstx_$$" );
            1;
        };
        my $err = $@;

        ok( $died, "link dies when dest already exists" );
        $check_autodie->( $err, 'link', 'link EEXIST' );
    };

    # ---- mkdir ----

    subtest 'mkdir dies when dir already exists (EEXIST)' => sub {
        my $dir = Test::MockFile->new_dir("/ad_mkdir_exists_$$");

        my $died = !eval {
            mkdir("/ad_mkdir_exists_$$");
            1;
        };
        my $err = $@;

        ok( $died, "mkdir dies on existing dir" );
        $check_autodie->( $err, 'mkdir', 'mkdir EEXIST' );
    };

    # ---- rmdir ----

    subtest 'rmdir dies on non-existent dir (ENOENT)' => sub {
        my $dir = Test::MockFile->dir("/ad_rmdir_noexist_$$");

        my $died = !eval {
            rmdir("/ad_rmdir_noexist_$$");
            1;
        };
        my $err = $@;

        ok( $died, "rmdir dies on non-existent dir" );
        $check_autodie->( $err, 'rmdir', 'rmdir ENOENT' );
    };

    subtest 'rmdir dies on regular file (ENOTDIR)' => sub {
        my $file = Test::MockFile->file( "/ad_rmdir_file_$$", "data" );

        my $died = !eval {
            rmdir("/ad_rmdir_file_$$");
            1;
        };
        my $err = $@;

        ok( $died, "rmdir dies on file (ENOTDIR)" );
        $check_autodie->( $err, 'rmdir', 'rmdir ENOTDIR' );
    };

    # ---- rename ----

    subtest 'rename dies when source does not exist (ENOENT)' => sub {
        my $src = Test::MockFile->file("/ad_rename_nosrc_$$");
        my $dst = Test::MockFile->file("/ad_rename_dst_$$");

        my $died = !eval {
            rename( "/ad_rename_nosrc_$$", "/ad_rename_dst_$$" );
            1;
        };
        my $err = $@;

        ok( $died, "rename dies when source doesn't exist" );
        $check_autodie->( $err, 'rename', 'rename ENOENT' );
    };

    # ---- truncate ----

    subtest 'truncate dies on non-existent file (ENOENT)' => sub {
        my $file = Test::MockFile->file("/ad_trunc_noexist_$$");

        my $died = !eval {
            truncate( "/ad_trunc_noexist_$$", 0 );
            1;
        };
        my $err = $@;

        ok( $died, "truncate dies on non-existent file" );
        $check_autodie->( $err, 'truncate', 'truncate ENOENT' );
    };

    subtest 'truncate dies on directory (EISDIR)' => sub {
        my $dir = Test::MockFile->new_dir("/ad_trunc_dir_$$");

        my $died = !eval {
            truncate( "/ad_trunc_dir_$$", 0 );
            1;
        };
        my $err = $@;

        ok( $died, "truncate dies on directory" );
        $check_autodie->( $err, 'truncate', 'truncate EISDIR' );
    };

    # ---- chmod ----

    subtest 'chmod dies on non-existent file' => sub {
        my $file = Test::MockFile->file("/ad_chmod_noexist_$$");

        my $died = !eval {
            chmod( 0644, "/ad_chmod_noexist_$$" );
            1;
        };
        my $err = $@;

        ok( $died, "chmod dies on non-existent mocked file" );
        $check_autodie->( $err, 'chmod', 'chmod ENOENT' );
    };

    # ---- chown ----

    subtest 'chown dies on non-existent file' => sub {
        my $file = Test::MockFile->file("/ad_chown_noexist_$$");

        my $died = !eval {
            chown( $>, (split /\s/, $))[0], "/ad_chown_noexist_$$" );
            1;
        };
        my $err = $@;

        ok( $died, "chown dies on non-existent mocked file" );
        $check_autodie->( $err, 'chown', 'chown ENOENT' );
    };

    # ---- utime ----

    subtest 'utime dies on non-existent file' => sub {
        my $file = Test::MockFile->file("/ad_utime_noexist_$$");

        my $died = !eval {
            utime( time, time, "/ad_utime_noexist_$$" );
            1;
        };
        my $err = $@;

        ok( $died, "utime dies on non-existent mocked file" );
        $check_autodie->( $err, 'utime', 'utime ENOENT' );
    };

    # ---- Success paths still work ----

    subtest 'successful operations do not throw under autodie' => sub {
        my $dir  = Test::MockFile->new_dir("/ad_success_dir_$$");
        my $file = Test::MockFile->file( "/ad_success_file_$$", "content" );
        my $link_target = Test::MockFile->file("/ad_success_link_$$");
        my $hard_dest   = Test::MockFile->file("/ad_success_hard_$$");
        my $rename_dst  = Test::MockFile->file("/ad_success_rdst_$$");
        my $mkdir_tgt   = Test::MockFile->dir("/ad_success_mkdir_$$");
        my $rmdir_tgt   = Test::MockFile->new_dir("/ad_success_rmdir_$$");

        my $ok = eval {
            # opendir + closedir
            opendir( my $dh, "/ad_success_dir_$$" );
            closedir($dh);

            # symlink
            symlink( '/target', "/ad_success_link_$$" );

            # readlink
            my $target = readlink("/ad_success_link_$$");

            # link
            link( "/ad_success_file_$$", "/ad_success_hard_$$" );

            # truncate
            truncate( "/ad_success_file_$$", 3 );

            # rename
            rename( "/ad_success_file_$$", "/ad_success_rdst_$$" );

            # mkdir
            mkdir("/ad_success_mkdir_$$");

            # rmdir
            rmdir("/ad_success_rmdir_$$");

            # chmod
            chmod( 0755, "/ad_success_rdst_$$" );

            # chown
            chown( $>, (split /\s/, $))[0], "/ad_success_rdst_$$" );

            # utime
            utime( time, time, "/ad_success_rdst_$$" );

            # unlink
            unlink("/ad_success_rdst_$$");

            1;
        };

        ok( $ok, "all successful operations work under autodie" )
          or diag("Error: $@");
    };
}

done_testing();

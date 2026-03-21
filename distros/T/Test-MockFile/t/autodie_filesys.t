#!/usr/bin/perl

# Test autodie compatibility for filesystem operations beyond open/sysopen.
#
# autodie installs per-package wrappers that call CORE::func directly,
# bypassing CORE::GLOBAL overrides (where T::MF installs its hooks).
# T::MF's _install_package_overrides must cover these functions so
# mocks are not silently bypassed under autodie.

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

use autodie qw(rename link symlink truncate);
use Test::MockFile qw(nostrict);

subtest 'rename works on mocked files under autodie' => sub {
    my $src = Test::MockFile->file( '/ad_rename_src', 'data' );
    my $dst = Test::MockFile->file('/ad_rename_dst');

    my $ok = eval {
        rename( '/ad_rename_src', '/ad_rename_dst' );
        1;
    };
    ok( $ok, 'rename does not die with autodie on mocked files' )
      or diag("Error: $@");

    is( $dst->contents(), 'data', 'destination has source contents after rename' ) if $ok;
};

subtest 'link works on mocked files under autodie' => sub {
    my $src = Test::MockFile->file( '/ad_link_src', 'linked' );
    my $dst = Test::MockFile->file('/ad_link_dst');

    my $ok = eval {
        link( '/ad_link_src', '/ad_link_dst' );
        1;
    };
    ok( $ok, 'link does not die with autodie on mocked files' )
      or diag("Error: $@");

    is( $dst->contents(), 'linked', 'destination has source contents after link' ) if $ok;
};

subtest 'symlink works on mocked files under autodie' => sub {
    my $link = Test::MockFile->file('/ad_sym_link');

    my $ok = eval {
        symlink( '/some/target', '/ad_sym_link' );
        1;
    };
    ok( $ok, 'symlink does not die with autodie on mocked files' )
      or diag("Error: $@");

    is( readlink('/ad_sym_link'), '/some/target', 'symlink points to correct target' ) if $ok;
};

subtest 'truncate works on mocked files under autodie' => sub {
    my $file = Test::MockFile->file( '/ad_trunc', 'hello world' );

    my $ok = eval {
        truncate( '/ad_trunc', 5 );
        1;
    };
    ok( $ok, 'truncate does not die with autodie on mocked files' )
      or diag("Error: $@");

    is( $file->contents(), 'hello', 'file truncated to 5 bytes' ) if $ok;
};

subtest 'flock succeeds on mocked file handle under autodie' => sub {
    my $file = Test::MockFile->file( '/ad_flock', 'content' );

    my $ok = eval {
        open( my $fh, '<', '/ad_flock' );
        flock( $fh, 1 );    # LOCK_SH
        close($fh);
        1;
    };
    ok( $ok, 'flock does not die with autodie on mocked file handle' )
      or diag("Error: $@");
};

done_testing();

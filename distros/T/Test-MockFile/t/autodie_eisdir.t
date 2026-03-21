#!/usr/bin/perl

# Test that open() on a directory with autodie active throws an exception.
# Previously, __open set EISDIR but didn't call _throw_autodie_open,
# so autodie's exception was silently swallowed.

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

use autodie qw(open);
use Test::MockFile qw(nostrict);

SKIP: {
    skip "autodie exception detection requires Perl 5.14+ (needs \${^GLOBAL_PHASE} and reliable caller hints)", 4
      if $] < 5.014;

    subtest 'autodie dies on open("<") of directory (EISDIR)' => sub {
        my $dir = Test::MockFile->new_dir("/autodie_eisdir_read_$$");

        my $died = !eval {
            open( my $fh, '<', "/autodie_eisdir_read_$$" );
            1;
        };
        my $err = $@;

        ok( $died, "autodie dies when opening directory for reading" );
        ok( defined $err, "exception is set" ) if $died;
    };

    subtest 'autodie dies on open(">") of directory (EISDIR)' => sub {
        my $dir = Test::MockFile->new_dir("/autodie_eisdir_write_$$");

        my $died = !eval {
            open( my $fh, '>', "/autodie_eisdir_write_$$" );
            1;
        };
        my $err = $@;

        ok( $died, "autodie dies when opening directory for writing" );
        ok( defined $err, "exception is set" ) if $died;
    };

    subtest 'EISDIR autodie exception is autodie::exception object' => sub {
        my $dir = Test::MockFile->new_dir("/autodie_eisdir_type_$$");

        eval {
            open( my $fh, '<', "/autodie_eisdir_type_$$" );
        };
        my $err = $@;    # Save before next eval clobbers it

        if ( eval { require autodie::exception; 1 } ) {
            isa_ok( $err, 'autodie::exception', 'EISDIR exception is autodie::exception' );
        }
        else {
            ok( defined $err, "exception is set (autodie::exception not loadable)" );
        }
    };

    subtest 'autodie dies on open("+<") of directory (EISDIR)' => sub {
        my $dir = Test::MockFile->new_dir("/autodie_eisdir_rw_$$");

        my $died = !eval {
            open( my $fh, '+<', "/autodie_eisdir_rw_$$" );
            1;
        };

        ok( $died, "autodie dies on +< open of directory" );
    };
}

done_testing();

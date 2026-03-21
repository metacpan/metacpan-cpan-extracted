#!/usr/bin/perl

# Test autodie compatibility with Test::MockFile (GH #44)
#
# The core problem: autodie installs per-package wrappers that call
# CORE::open directly, bypassing CORE::GLOBAL::open (where T::MF
# installs its overrides). This test verifies that T::MF's per-package
# override installation handles this correctly.

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

# Load both — autodie first, then Test::MockFile.
# autodie installs main::open = autodie wrapper at compile time.
# Test::MockFile then overwrites it with our goto wrapper.
use autodie qw(open);
use Test::MockFile qw(nostrict);

subtest 'open mocked file succeeds with autodie active' => sub {
    my $file = "/autodie_test_read_$$";
    my $mock = Test::MockFile->file( $file, "line one\nline two\n" );

    # This is the exact scenario from issue #44 — previously this would
    # fail with "Can't open '/autodie_test_read_...' for reading: 'No
    # such file or directory'" because autodie bypassed T::MF's override.
    my $ok = eval {
        open( my $fh, '<', $file );
        my $line = <$fh>;
        is( $line, "line one\n", "first line from mocked file" );
        close($fh);
        1;
    };
    ok( $ok, "open on mocked file does not die with autodie" )
      or diag("Error: $@");
};

subtest 'write to mocked file succeeds with autodie active' => sub {
    my $file = "/autodie_test_write_$$";
    my $mock = Test::MockFile->file( $file, '' );

    my $ok = eval {
        open( my $fh, '>', $file );
        print $fh "written data";
        close($fh);
        1;
    };
    ok( $ok, "open for writing does not die with autodie" )
      or diag("Error: $@");

    is( $mock->contents(), "written data", "mocked file has correct contents" ) if $ok;
};

subtest 'append to mocked file succeeds with autodie active' => sub {
    my $file = "/autodie_test_append_$$";
    my $mock = Test::MockFile->file( $file, "existing\n" );

    my $ok = eval {
        open( my $fh, '>>', $file );
        print $fh "appended\n";
        close($fh);
        1;
    };
    ok( $ok, "open for append does not die with autodie" )
      or diag("Error: $@");

    is( $mock->contents(), "existing\nappended\n", "appended content is correct" ) if $ok;
};

SKIP: {
    skip "autodie exception detection requires Perl 5.14+ (needs \${^GLOBAL_PHASE} and reliable caller hints)", 3
      if $] < 5.014;

    subtest 'autodie dies on non-existent mocked file' => sub {
        my $file = "/autodie_test_noexist_$$";

        # undef contents = file does not exist
        my $mock = Test::MockFile->file( $file, undef );

        my $died = !eval {
            open( my $fh, '<', $file );
            1;
        };

        ok( $died, "autodie dies when opening non-existent mocked file" );
        ok( defined $@, "exception is set" ) if $died;
    };

    subtest 'autodie exception is autodie::exception when possible' => sub {
        my $file = "/autodie_test_exception_$$";
        my $mock = Test::MockFile->file( $file, undef );

        eval {
            open( my $fh, '<', $file );
        };
        my $err = $@;    # Save before next eval clobbers it

        if ( eval { require autodie::exception; 1 } ) {
            isa_ok( $err, 'autodie::exception', 'exception is autodie::exception object' );
        }
        else {
            ok( defined $err, "exception is set (autodie::exception not loadable)" );
        }
    };

    subtest '+< mode on non-existent mocked file dies with autodie' => sub {
        my $file = "/autodie_test_rw_noexist_$$";
        my $mock = Test::MockFile->file( $file, undef );

        my $died = !eval {
            open( my $fh, '+<', $file );
            1;
        };

        ok( $died, "autodie dies on +< open of non-existent mocked file" );
    };
}

subtest 'mocked file read-write works with autodie' => sub {
    my $file = "/autodie_test_rw_$$";
    my $mock = Test::MockFile->file( $file, "content" );

    my $ok = eval {
        open( my $fh, '+<', $file );
        my $data = <$fh>;
        is( $data, "content", "read from +< opened file" );
        close($fh);
        1;
    };
    ok( $ok, "read-write open succeeds with autodie" )
      or diag("Error: $@");
};

done_testing();

#!/usr/bin/perl

# Test autodie + sysopen compatibility when Test::MockFile is loaded BEFORE autodie.
# This tests the CHECK block re-installation mechanism for sysopen.

use strict;
use warnings;

use Test::More;
use Fcntl qw( O_RDONLY O_WRONLY O_CREAT );

BEGIN {
    eval { require autodie };
    if ($@) {
        plan skip_all => 'autodie not available';
    }
}

# Load T::MF first, then autodie — reverse order tests CHECK block.
use Test::MockFile qw(nostrict);
use autodie qw(sysopen);

subtest 'sysopen mocking works when T::MF loaded before autodie' => sub {
    my $file = "/autodie_sysopen_rev_read_$$";
    my $mock = Test::MockFile->file( $file, "reverse order\n" );

    my $ok = eval {
        sysopen( my $fh, $file, O_RDONLY );
        ok( defined $fh, "filehandle defined" );
        close($fh);
        1;
    };
    ok( $ok, "mocked sysopen works when T::MF loaded before autodie" )
      or diag("Error: $@");
};

SKIP: {
    skip "autodie exception detection requires Perl 5.14+", 1
      if $] < 5.014;

    subtest 'autodie still dies on sysopen failure (reverse load order)' => sub {
        my $file = "/autodie_sysopen_rev_fail_$$";
        my $mock = Test::MockFile->file( $file, undef );

        my $died = !eval {
            sysopen( my $fh, $file, O_RDONLY );
            1;
        };

        ok( $died, "autodie dies on sysopen of non-existent mocked file (reverse load order)" );
    };
}

subtest 'sysopen O_CREAT works in reverse load order' => sub {
    my $file = "/autodie_sysopen_rev_create_$$";
    my $mock = Test::MockFile->file( $file, undef );

    my $ok = eval {
        sysopen( my $fh, $file, O_WRONLY | O_CREAT );
        ok( defined $fh, "filehandle defined after O_CREAT" );
        close($fh);
        1;
    };
    ok( $ok, "sysopen O_CREAT on mocked file works (reverse load order)" )
      or diag("Error: $@");

    is( $mock->contents(), '', "file created with empty contents" ) if $ok;
};

done_testing();

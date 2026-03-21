#!/usr/bin/perl

# Test autodie compatibility when Test::MockFile is loaded BEFORE autodie.
# This tests the CHECK block re-installation mechanism.

use strict;
use warnings;

use Test::More;

BEGIN {
    eval { require autodie };
    if ($@) {
        plan skip_all => 'autodie not available';
    }
}

# Load T::MF first, then autodie.
# T::MF's import() installs main::open = goto wrapper.
# autodie's import() overwrites main::open = autodie wrapper.
# T::MF's CHECK block re-installs main::open = goto wrapper.
use Test::MockFile qw(nostrict);
use autodie qw(open);

subtest 'mocking works when T::MF loaded before autodie' => sub {
    my $file = "/autodie_rev_read_$$";
    my $mock = Test::MockFile->file( $file, "reverse order\n" );

    my $ok = eval {
        open( my $fh, '<', $file );
        my $line = <$fh>;
        is( $line, "reverse order\n", "read from mocked file" );
        close($fh);
        1;
    };
    ok( $ok, "mocked file open works when T::MF loaded before autodie" )
      or diag("Error: $@");
};

subtest 'autodie still dies on failure' => sub {
    my $file = "/autodie_rev_fail_$$";
    my $mock = Test::MockFile->file( $file, undef );

    my $died = !eval {
        open( my $fh, '<', $file );
        1;
    };

    ok( $died, "autodie dies on non-existent mocked file (reverse load order)" );
};

subtest 'write works in reverse load order' => sub {
    my $file = "/autodie_rev_write_$$";
    my $mock = Test::MockFile->file( $file, '' );

    my $ok = eval {
        open( my $fh, '>', $file );
        print $fh "reverse write";
        close($fh);
        1;
    };
    ok( $ok, "write to mocked file works" ) or diag("Error: $@");
    is( $mock->contents(), "reverse write", "content is correct" ) if $ok;
};

done_testing();

#!/usr/bin/perl -w

# Tests for:
# 1. open() through a broken symlink with write-capable modes should create
#    the target file (matching real filesystem behavior)
# 2. sysopen() through a broken symlink with O_CREAT should create the target
# 3. autodie throws on EISDIR in open()

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Fcntl;
use Errno qw/EISDIR ENOENT ELOOP/;

use Test::MockFile qw< nostrict >;

# =======================================================
# open() through a broken symlink with write mode creates the target
# =======================================================

note "--- open('>') through broken symlink creates target file ---";

{
    my $dir     = Test::MockFile->new_dir('/bsym');
    my $symlink = Test::MockFile->symlink( '/bsym/target', '/bsym/link' );

    ok( -l '/bsym/link',     "Symlink exists" );
    ok( !-e '/bsym/target',  "Target does not exist yet" );

    # Write mode through broken symlink should create the target
    ok( open( my $fh, '>', '/bsym/link' ), "open('>') through broken symlink succeeds" )
      or diag "Error: $!";
    print $fh "created via symlink";
    close $fh;

    ok( -f '/bsym/target', "Target file now exists" );

    # Read back through the symlink to verify
    ok( open( $fh, '<', '/bsym/link' ), "Re-open for reading through symlink" );
    my $content = do { local $/; <$fh> };
    close $fh;
    is( $content, "created via symlink", "Content written through broken symlink" );
}

note "--- open('>>') through broken symlink creates target file ---";

{
    my $dir     = Test::MockFile->new_dir('/bsym2');
    my $symlink = Test::MockFile->symlink( '/bsym2/target', '/bsym2/link' );

    ok( !-e '/bsym2/target', "Target does not exist" );

    ok( open( my $fh, '>>', '/bsym2/link' ), "open('>>') through broken symlink succeeds" )
      or diag "Error: $!";
    print $fh "appended";
    close $fh;

    ok( -f '/bsym2/target', "Target file created by append" );
}

note "--- open('+>') through broken symlink creates target file ---";

{
    my $dir     = Test::MockFile->new_dir('/bsym3');
    my $symlink = Test::MockFile->symlink( '/bsym3/target', '/bsym3/link' );

    ok( !-e '/bsym3/target', "Target does not exist" );

    ok( open( my $fh, '+>', '/bsym3/link' ), "open('+>') through broken symlink succeeds" )
      or diag "Error: $!";
    print $fh "rw created";
    close $fh;

    ok( -f '/bsym3/target', "Target file created by +>" );
}

note "--- open('+>>') through broken symlink creates target file ---";

{
    my $dir     = Test::MockFile->new_dir('/bsym4');
    my $symlink = Test::MockFile->symlink( '/bsym4/target', '/bsym4/link' );

    ok( !-e '/bsym4/target', "Target does not exist" );

    ok( open( my $fh, '+>>', '/bsym4/link' ), "open('+>>') through broken symlink succeeds" )
      or diag "Error: $!";
    print $fh "rw appended";
    close $fh;

    ok( -f '/bsym4/target', "Target file created by +>>" );
}

# =======================================================
# open('<') through a broken symlink still returns ENOENT
# =======================================================

note "--- open('<') through broken symlink returns ENOENT ---";

{
    my $dir     = Test::MockFile->new_dir('/bsym5');
    my $symlink = Test::MockFile->symlink( '/bsym5/target', '/bsym5/link' );

    ok( !open( my $fh, '<', '/bsym5/link' ), "open('<') through broken symlink fails" );
    is( $! + 0, ENOENT, "errno is ENOENT for read-only open through broken symlink" );
}

note "--- open('+<') through broken symlink returns ENOENT ---";

{
    my $dir     = Test::MockFile->new_dir('/bsym6');
    my $symlink = Test::MockFile->symlink( '/bsym6/target', '/bsym6/link' );

    ok( !open( my $fh, '+<', '/bsym6/link' ), "open('+<') through broken symlink fails" );
    is( $! + 0, ENOENT, "errno is ENOENT for +< open through broken symlink" );
}

# =======================================================
# sysopen() through a broken symlink with O_CREAT creates the target
# =======================================================

note "--- sysopen(O_CREAT) through broken symlink creates target file ---";

{
    my $dir     = Test::MockFile->new_dir('/bsym7');
    my $symlink = Test::MockFile->symlink( '/bsym7/target', '/bsym7/link' );

    ok( !-e '/bsym7/target', "Target does not exist" );

    ok( sysopen( my $fh, '/bsym7/link', O_WRONLY | O_CREAT, 0644 ),
        "sysopen(O_WRONLY|O_CREAT) through broken symlink succeeds" )
      or diag "Error: $!";
    syswrite( $fh, "sysopen created" );
    close $fh;

    ok( -f '/bsym7/target', "Target file created by sysopen O_CREAT" );

    # Read back to verify
    ok( open( $fh, '<', '/bsym7/link' ), "Read back through symlink" );
    my $content = do { local $/; <$fh> };
    close $fh;
    is( $content, "sysopen created", "Content matches what was written" );
}

note "--- sysopen(O_RDWR|O_CREAT) through broken symlink creates target ---";

{
    my $dir     = Test::MockFile->new_dir('/bsym8');
    my $symlink = Test::MockFile->symlink( '/bsym8/target', '/bsym8/link' );

    ok( sysopen( my $fh, '/bsym8/link', O_RDWR | O_CREAT, 0644 ),
        "sysopen(O_RDWR|O_CREAT) through broken symlink succeeds" )
      or diag "Error: $!";
    close $fh;

    ok( -f '/bsym8/target', "Target file created by sysopen O_RDWR|O_CREAT" );
}

# =======================================================
# sysopen() without O_CREAT through broken symlink still fails
# =======================================================

note "--- sysopen without O_CREAT through broken symlink returns ENOENT ---";

{
    my $dir     = Test::MockFile->new_dir('/bsym9');
    my $symlink = Test::MockFile->symlink( '/bsym9/target', '/bsym9/link' );

    ok( !sysopen( my $fh, '/bsym9/link', O_RDONLY ), "sysopen(O_RDONLY) through broken symlink fails" );
    is( $! + 0, ENOENT, "errno is ENOENT for O_RDONLY through broken symlink" );

    ok( !sysopen( $fh, '/bsym9/link', O_WRONLY ), "sysopen(O_WRONLY) without O_CREAT fails" );
    is( $! + 0, ENOENT, "errno is ENOENT for O_WRONLY without O_CREAT" );
}

# =======================================================
# Symlink chain (multiple levels) — create through double symlink
# =======================================================

note "--- open through chained broken symlink creates target ---";

{
    my $dir   = Test::MockFile->new_dir('/chain');
    my $link1 = Test::MockFile->symlink( '/chain/link2',  '/chain/link1' );
    my $link2 = Test::MockFile->symlink( '/chain/target', '/chain/link2' );

    ok( -l '/chain/link1', "First symlink exists" );
    ok( -l '/chain/link2', "Second symlink exists" );
    ok( !-e '/chain/target', "Target does not exist" );

    ok( open( my $fh, '>', '/chain/link1' ), "open('>') through double symlink succeeds" )
      or diag "Error: $!";
    print $fh "chain created";
    close $fh;

    ok( -f '/chain/target', "Target file created through symlink chain" );
}

# =======================================================
# Circular symlink still returns ELOOP (not affected by write mode)
# =======================================================

note "--- open('>') through circular symlink still returns ELOOP ---";

{
    my $link_a = Test::MockFile->symlink( '/circ/b', '/circ/a' );
    my $link_b = Test::MockFile->symlink( '/circ/a', '/circ/b' );

    ok( !open( my $fh, '>', '/circ/a' ), "open('>') through circular symlink fails" );
    is( $! + 0, ELOOP, "errno is ELOOP for circular symlink even with write mode" );
}

done_testing();

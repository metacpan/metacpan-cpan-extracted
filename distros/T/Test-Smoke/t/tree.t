#! /usr/bin/perl -w
use strict;

# $Id$

use Data::Dumper;
use File::Spec::Functions qw( :DEFAULT abs2rel rel2abs splitpath splitdir );
use File::Find;
use Cwd;

use Test::More tests => 22;

# We need to test SourceTree.pm
sub mani_file_from_list($;@) {
    my( $mani_file, @list ) = @_;
    local *MANIFEST;
    open MANIFEST, "> $mani_file" or die "Can't create '$mani_file': $!";
    print MANIFEST "$_\n" for grep length $_ => @list;
    close MANIFEST;
}
    
sub MANIFEST_from_dir($) {
    my( $path ) = @_;

    my $cwd = cwd();
    chdir $path or die "Cannot chdir($path): $!\n";
    my @files = qw( MANIFEST );

    find sub {
        -f or return;
        $_ eq '.gitignore' and return;
        my $relfile = canonpath( $File::Find::name );
        my( undef, $dirs, $file ) = splitpath( $relfile );
        my @dirs = grep $_ && length $_ => splitdir( $dirs );
        $^O eq 'VMS' and $file =~ s/\.$//;
        push @dirs, $file;
        push @files, join '/', @dirs;
    }, '.';

    chdir $cwd;
    my $mani_file = File::Spec->catfile( $path, 'MANIFEST' );
    mani_file_from_list( $mani_file => @files );
}

BEGIN { use_ok( 'Test::Smoke::SourceTree', ':const' ); }

my $cwd = cwd();
chdir 't' or die "Cannot chdir(t): $!";
my $path = File::Spec->canonpath( cwd() );
chdir $cwd;
{
    my $tree = Test::Smoke::SourceTree->new( 't' );
    isa_ok( $tree, 'Test::Smoke::SourceTree' );

    is( $tree->canonpath, File::Spec->canonpath( $path ) , "canonpath" );

    is( $tree->rel2abs, $path, "rel2abs" );
    my $rel = File::Spec->abs2rel( $path );
    is( $tree->abs2rel, $rel, "abs2rel" );

    is( $tree->mani2abs( 'win32/Makefile' ),
        File::Spec->catfile( $path, split m|/|, 'win32/Makefile' ),
        "mani2abs complex" );

}

SKIP: {
    eval { MANIFEST_from_dir 't' };
    $@ and skip $@, 3;

    my $tree = Test::Smoke::SourceTree->new( 't' );
    isa_ok( $tree, 'Test::Smoke::SourceTree' );

    my $mani_check = $tree->check_MANIFEST;

    is( keys %$mani_check, 0, "No dubious files" ) or
        diag Dumper $mani_check;

    my $mani_file = File::Spec->catfile( $tree->canonpath, 'MANIFEST' );

    is( $tree->abs2mani( $mani_file ), 'MANIFEST', "abs2mani" );
    1 while unlink $mani_file;
}

SKIP: { # Check that we can pass extra files to check_MANIFEST()
    eval { MANIFEST_from_dir 't' };
    $@ and skip $@, 1;

    my $tree = Test::Smoke::SourceTree->new( 't' );

    my $mani_check = $tree->check_MANIFEST( 'does_not_exist' );

    is( keys %$mani_check, 0, "No dubious files [skips are not reported]" ) or
        diag Dumper $mani_check;

    my $mani_file = File::Spec->catfile( $tree->canonpath, 'MANIFEST' );
    1 while unlink $mani_file;
}

SKIP: { # Check that check_MANIFEST() finds dubious files
    my $missing = File::Spec->catfile( 't', 'missing' );
    $missing = File::Spec->rel2abs( $missing );
    local *FH;
    {
        open FH, "> $missing" or skip "Cannot create '$missing': $!", 3;
        close FH;
    }
    eval { MANIFEST_from_dir 't' };
    $@ and skip $@, 3;
    1 while unlink $missing;
    my $undeclared = File::Spec->catfile( 't', 'undeclared' );
    $undeclared = File::Spec->rel2abs( $undeclared );
    {
        open FH, "> $undeclared" or 
            skip "Cannot create '$undeclared': $!", 3;
        close FH;
    }
    my $skipit = File::Spec->catfile( 't', 'skip_it' );
    $skipit = File::Spec->rel2abs( $skipit );
    {
        open FH, "> $skipit" or 
            skip "Cannot create '$skipit': $!", 3;
        close FH;
    }

    my $tree = Test::Smoke::SourceTree->new( 't' );

    my $mani_check = $tree->check_MANIFEST( 'skip_it' );

    is( keys %$mani_check, 2, "Two dubious files" ) or
        diag Dumper $mani_check;

    my $check = { undeclared => ST_UNDECLARED, missing => ST_MISSING };
    if ( $Test::Smoke::SourceTree::NOCASE ) {
        my %uccheck = map { ( uc $_ => $check->{ $_ } ) } keys %$check;
        $check = \%uccheck;
    }

    is_deeply( $mani_check, $check, "Hash contents" );

    my $und_cnt = grep $mani_check->{ $_ } == ST_UNDECLARED()
        => keys %$mani_check;
    is( $und_cnt, 1, "One undeclared file" );
    my $mis_cnt = grep $mani_check->{ $_ } == ST_MISSING()
        => keys %$mani_check;
    is( $mis_cnt, 1, "One missing file" );

    my $mani_file = File::Spec->catfile( $tree->canonpath, 'MANIFEST' );
    1 while unlink $mani_file;
    1 while unlink $undeclared;
    1 while unlink $skipit;
}

SKIP: { # Check that check_MANIFEST() finds dubious files with MANIFEST.SKIP
    my $missing = File::Spec->catfile( 't', 'missing' );
    $missing = File::Spec->rel2abs( $missing );
    local *FH;
    {
        open FH, "> $missing" or skip "Cannot create '$missing': $!", 3;
        close FH;
    }
    eval { MANIFEST_from_dir 't' };
    $@ and skip $@, 3;
    1 while unlink $missing; # make it missing!

    my $undeclared = File::Spec->catfile( 't', 'undeclared' );
    $undeclared = File::Spec->rel2abs( $undeclared );
    {
        open FH, "> $undeclared" or 
            skip "Cannot create '$undeclared': $!", 3;
        close FH;
    }
    my $skipit = File::Spec->catfile( 't', 'skip_it' );
    $skipit = File::Spec->rel2abs( $skipit );
    {
        open FH, "> $skipit" or 
            skip "Cannot create '$skipit': $!", 3;
        close FH;
    }
    my $mani_skip = File::Spec->catfile( 't', 'MANIFEST.SKIP' );
    mani_file_from_list( $mani_skip, 'skip_it' );

    my $tree = Test::Smoke::SourceTree->new( 't' );

    my $mani_check = $tree->check_MANIFEST( );

    is( keys %$mani_check, 2, "[MANIFEST.SKIP] Two dubious files" ) or
        diag Dumper $mani_check;

    my $check = { undeclared => ST_UNDECLARED, missing => ST_MISSING };
    if ( $Test::Smoke::SourceTree::NOCASE ) {
        my %uccheck = map { ( uc $_ => $check->{ $_ } ) } keys %$check;
        $check = \%uccheck;
    }

    is_deeply( $mani_check, $check, "[MANIFEST.SKIP] Hash contents" );

    my $und_cnt = grep $mani_check->{ $_ } == ST_UNDECLARED()
        => keys %$mani_check;
    is( $und_cnt, 1, "[MANIFEST.SKIP] One undeclared file" );
    my $mis_cnt = grep $mani_check->{ $_ } == ST_MISSING()
        => keys %$mani_check;
    is( $mis_cnt, 1, "[MANIFEST.SKIP] One missing file" );

    my $mani_file = File::Spec->catfile( $tree->canonpath, 'MANIFEST' );
    1 while unlink $mani_file;
    1 while unlink $mani_skip;
    1 while unlink $undeclared;
    1 while unlink $skipit;
}

{ #
    my $tree1 = Test::Smoke::SourceTree->new( 't' );
    my $tree2 = $tree1->new( 't' );
    isa_ok $tree2, 'Test::Smoke::SourceTree';
    my $empty = $tree2->_read_mani_file( 'MANIFEST.SKIP', 1 );
    is_deeply $empty, { }, "Return empty hashref [no MANIFEST]";
}

{ # check new() croak()s without an argument

#line 300
    my $tree = eval { Test::Smoke::SourceTree->new() };
    ok( $@, "new() must have arguments" );
    like( $@, "/Usage:.*?at \Q$0\E line 300/", "it croak()s alright" );
}

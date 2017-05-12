use 5.006;
use strict;
use warnings;
use Cwd qw/abs_path/;
use File::Copy qw/copy/;
use File::Spec;
use File::Temp;
use Test::More;

# make Capture::Tiny optional
BEGIN {
    my $class = "Capture::Tiny"; # hide from scanners
    eval "use $class 'capture'"; ## no critic
    if ($@) {
        *capture = sub(&) {
            diag "START SUBTEST OUTPUT";
            shift->();
            diag "END SUBTEST OUTPUT";
            return '(not captured)';
        };
    }
}

sub _unixify {
    ( my $path = shift ) =~ s{\\}{/}g;
    return $path;
}

# dogfood
use Test::TempDir::Tiny;

plan tests => 15;

my $cwd  = abs_path('.');
my $lib  = abs_path('lib');
my $perl = abs_path($^X);

# default directory
my $dir       = tempdir();
my $root      = Test::TempDir::Tiny::_root_dir();
my $unix_root = _unixify($root);

ok( -d $root, "root dir exists" );
like(
    _unixify($dir),
    qr{\Q$unix_root\E/t_basic_t/default_1$},
    "default directory created"
);

my $dir2 = tempdir();
like(
    _unixify($dir2),
    qr{\Q$unix_root\E/t_basic_t/default_2$},
    "second default directory created"
);

# non-word chars
my $bang = tempdir("!!bang!!");
like(
    _unixify($bang),
    qr{\Q$unix_root\E/t_basic_t/_bang__1$},
    "!!bang!! directory created"
);

# set up pass/fail dirs
my $passing = _unixify( tempdir("passing") );
mkdir "$passing/t";
copy "corpus/01-pass.t", "$passing/t/01-pass.t";
like(
    _unixify($passing),
    qr{\Q$unix_root\E/t_basic_t/passing_1$},
    "passing directory created"
);

my $failing = _unixify( tempdir("failing") );
mkdir "$failing/t";
copy "corpus/01-fail.t", "$failing/t/01-fail.t" or die $!;
like(
    _unixify($failing),
    qr{\Q$unix_root\E/t_basic_t/failing_1$},
    "failing directory created"
);

# passing

chdir $passing;
my ( $out, $err, $rc ) = capture {
    system( $perl, "-I$lib", qw/-MTest::Harness -e runtests(@ARGV)/, 't/01-pass.t' )
};
chdir $cwd;

ok( !-d "$passing/tmp/t_01-pass_t", "passing test directory was cleaned up" )
  or diag "OUT: $out";
ok( !-d "$passing/tmp", "passing root directory was cleaned up" );

# failing

chdir $failing;
( $out, $err, $rc ) = capture {
    system( $perl, "-I$lib", qw/-MTest::Harness -e runtests(@ARGV)/, 't/01-fail.t' )
};
chdir $cwd;

ok( -d "$failing/tmp/t_01-fail_t", "failing test directory was not cleaned up" )
  or diag "OUT: $out";
ok( -d "$failing/tmp", "failing root directory was not cleaned up" );

# can't do some tests portably if Perl or lib has spaces in path
SKIP: {
    skip "Perl or lib has spaces in path", 2
      if $perl =~ /\s/ || $lib =~ /\s/;

    # test when not in dist directory with t
    my $without_t_dir = abs_path( File::Temp::tempdir( TMPDIR => 1, CLEANUP => 1 ) );
    chdir $without_t_dir;
    my $tmpdir1   = qx/$perl -I$lib -MTest::TempDir::Tiny -wl -e print -e tempdir/;
    my $real_temp = _unixify( abs_path( File::Spec->tmpdir ) );
    like( _unixify($tmpdir1), qr{^\Q$real_temp\E},
        "without t, tempdir is in File::Spec->tmpdir" );

    # test when *inside* a t directory
    mkdir "t";
    chdir "t";
    my $tmpdir2 = qx/$perl -I$lib -MTest::TempDir::Tiny -wl -e print -e tempdir/;
    my $expect = _unixify( File::Spec->catdir( $without_t_dir, 'tmp' ) );
    like( _unixify($tmpdir2), qr{^\Q$expect\E}, "inside t, tempdir is in ../tmp" );

    chdir $cwd;
}

# in_tempdir

my $from_sub;
in_tempdir "this is a test" => sub {
    my $arg = _unixify( shift @_ );
    my $cur = _unixify( abs_path(".") );
    is( $arg, $cur, "in_tempdir passes tempdir as argument" );
    like( $cur, qr{\Q$unix_root\E/t_basic_t/this_is_a_test_1}, "cwd is correct" );
};
is( abs_path("."), $cwd, "back to original dir after in_tempdir" );

#
# This file is part of Test-TempDir-Tiny
#
# This software is Copyright (c) 2014 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#

# vim: ts=4 sts=4 sw=4 et:

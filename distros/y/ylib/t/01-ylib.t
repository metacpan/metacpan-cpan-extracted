# Copyright (c) 2009 by David Golden. All rights reserved.
# Licensed under Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License was distributed with this file or you may obtain a
# copy of the License from http://www.apache.org/licenses/LICENSE-2.0

use strict;
use warnings;

use Test::More;
use File::pushd 1.00 qw/tempd pushd/;
use File::Copy qw/copy/;
use File::Basename qw/basename dirname/;
use Path::Tiny;

# Work around buffering that can show diags out of order
Test::More->builder->failure_output(*STDOUT) if $ENV{HARNESS_VERBOSE};

#--------------------------------------------------------------------------#
# fixtures
#--------------------------------------------------------------------------#

my $t_libs = path(qw/. t libs/)->absolute;
my %libs   = (
    one   => $t_libs->child('lib1'),
    two   => $t_libs->child('lib2'),
    three => $t_libs->child('lib3'),
);

sub make_mylib {
    my ( $file, @libs ) = @_;
    path($file)->spew( join( "\n", @libs ) );
}

sub check_inc {
    my ($lib) = @_;
    return scalar grep { $_ eq $lib } @INC;
}

#--------------------------------------------------------------------------#
# start tests
#--------------------------------------------------------------------------#

plan tests => 33;

ok( eval "require ylib; 1", "ylib compiles" ) or BAIL_OUT("ylib.pm failed to load");

#--------------------------------------------------------------------------#
# change to a temp directory until end of testing
#--------------------------------------------------------------------------#

my $tempd = tempd;

my $home_dir = path('home')->absolute;
$home_dir->mkpath or die $!;

my $local_mylib = path(qw/local mylib/)->absolute;
$local_mylib->mkpath or die $!;

#--------------------------------------------------------------------------#
# single lib in .mylib
#--------------------------------------------------------------------------#

{
    local @INC = @INC;
    ok( make_mylib( '.mylib', $libs{one} ), "created .mylib" );
    ok( eval("use ylib; 1"), "localized load of ylib.pm" );
    my $base = basename $libs{one};
    ok( check_inc( $libs{one} ), "directory '$base' in ./.mylib added to \@INC" )
      or diag "\@INC:\n", map { "  $_\n" } @INC;
    ok( unlink('.mylib'), "cleaned up .mylib" );
}

#--------------------------------------------------------------------------#
# multiple libs in .mylib
#--------------------------------------------------------------------------#

{
    local @INC = @INC;
    ok( make_mylib( '.mylib', $libs{one}, $libs{two} ), "created .mylib" );
    ok( eval("use ylib; 1"), "localized load of ylib.pm" );
    for my $key (qw/one two/) {
        my $base = basename $libs{$key};
        ok( check_inc( $libs{$key} ), "directory '$base' in ./.mylib added to \@INC" )
          or diag "\@INC:\n", map { "  $_\n" } @INC;
    }
    ok( unlink('.mylib'), "cleaned up .mylib" );
}

#--------------------------------------------------------------------------#
# multiple libs in ~/.mydir
#--------------------------------------------------------------------------#

{
    local @INC = @INC;
    local $ENV{HOME} = $home_dir;
    ok( make_mylib( $home_dir->child('.mylib'), $libs{one}, $libs{two} ),
        "created ~/.mylib" );
    ok( eval("use ylib; 1"), "localized load of ylib.pm" );
    for my $key (qw/one two/) {
        my $base = basename $libs{$key};
        ok( check_inc( $libs{$key} ), "directory '$base' in ~/.mylib added to \@INC" )
          or diag "\@INC:\n", map { "  $_\n" } @INC;
    }
    ok( unlink( $home_dir->child('.mylib') ), "cleaned up ~/.mylib" );
}

#--------------------------------------------------------------------------#
# .mylib comes in @INC before ~/.mylib
#--------------------------------------------------------------------------#

{
    local @INC = @INC;
    local $ENV{HOME} = $home_dir;
    ok( make_mylib( '.mylib', $libs{three} ), "created .mylib" );
    ok( make_mylib( $home_dir->child('.mylib'), $libs{one}, $libs{two} ),
        "created ~/.mylib" );

    ok( eval("use ylib; 1"), "localized load of ylib.pm" );

    for my $key (qw/one two/) {
        my $base = basename $libs{$key};
        ok( check_inc( $libs{$key} ), "directory '$base' in ~/.mylib added to \@INC" )
          or diag "\@INC:\n", map { "  $_\n" } @INC;
    }

    my $base = basename $libs{three};
    ok( check_inc( $libs{three} ), "directory '$base' in ./.mylib added to \@INC" )
      or diag "\@INC:\n", map { "  $_\n" } @INC;

    my $inc_cat = join( q{ }, @INC );
    like( $inc_cat, qr/lib3.+?lib1/, "local .mylib in \@INC before \$ENV{HOME}/.mylib" );
    ok( unlink( $home_dir->child('.mylib') ), "cleaned up ~/.mylib" );
    ok( unlink('.mylib'),                     "cleaned up .mylib" );
}

#--------------------------------------------------------------------------#
# bad directory in .mylib
#--------------------------------------------------------------------------#

{
    my $warn;
    local $SIG{__WARN__} = sub { $warn = join q{}, @_ };
    local @INC = @INC;
    my $bad = 'xyzygy';
    ok( make_mylib( '.mylib', $bad ), "created .mylib" );
    ok( eval("use ylib; 1"), "localized load of ylib.pm" );
    my $base = basename $libs{one};
    ok( !check_inc($bad), "bad directory '$bad' in ./.mylib NOT added to \@INC" )
      or diag "\@INC:\n", map { "  $_\n" } @INC;
    like( $warn, qr/lib.+?$bad.+?not found/, "got warning about bad '$bad'" );
    ok( unlink('.mylib'), "cleaned up .mylib" );
}

#--------------------------------------------------------------------------#
# relative paths
#--------------------------------------------------------------------------#

{
    local @INC = @INC;
    my $wd = pushd('home');
    ok( make_mylib( '.mylib', "../local/mylib" ), "created .mylib" );
    ok( eval("use ylib; 1"), "localized load of ylib.pm" );
    ok( check_inc("../local/mylib"),
        "directory '../local/mylib' in ./.mylib added to \@INC" )
      or diag "\@INC:\n", map { "  $_\n" } @INC;
    ok( unlink('.mylib'), "cleaned up .mylib" );
}


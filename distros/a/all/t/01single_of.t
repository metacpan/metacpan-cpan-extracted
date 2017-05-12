#!/usr/bin/perl

use strict;
use warnings;

use File::Spec;
use Cwd;

BEGIN {
    unshift @INC, map { /(.*)/; $1 } split( /:/, $ENV{PERL5LIB} ) if defined $ENV{PERL5LIB} and ${^TAINT};
    my $cwd = ${^TAINT} ? do { local $_ = getcwd; /(.*)/; $1 } : '.';
    unshift @INC, File::Spec->catdir( $cwd, 'inc' );
    unshift @INC, File::Spec->catdir( $cwd, 'lib' );
    unshift @INC, File::Spec->catdir( $cwd, 't/tlib' );
}

use Carp ();

$SIG{__WARN__} = sub { local $Carp::CarpLevel = 1; Carp::confess("Warning: ", @_) };

use Test::More tests => 13;

eval q{
  use all of => 'all::Test1::';
};

is( $@,                         '',    'use all' );
is( all::Test1->VERSION,        undef, 'all::Test1 is not loaded' );
is( all::Test1::Test1->VERSION, 11,    'all::Test1::Test1 is loaded' );
is( all::Test1::Test2->VERSION, 12,    'all::Test1::Test2 is loaded' );
is( all::Test1::Test3->VERSION, 13,    'all::Test1::Test3 is loaded' );
is( all::Test2->VERSION,        undef, 'all::Test2 is not loaded' );
is( all::Test2::Test1->VERSION, undef, 'all::Test2::Test1 is not loaded' );
is( all::Test2::Test2->VERSION, undef, 'all::Test2::Test2 is not loaded' );
is( all::Test2::Test3->VERSION, undef, 'all::Test2::Test3 is not loaded' );
is( all::Test3->VERSION,        undef, 'all::Test3 is not loaded' );
is( all::Test3::Test1->VERSION, undef, 'all::Test3::Test1 is not loaded' );
is( all::Test3::Test2->VERSION, undef, 'all::Test3::Test2 is not loaded' );
is( all::Test3::Test3->VERSION, undef, 'all::Test3::Test3 is not loaded' );

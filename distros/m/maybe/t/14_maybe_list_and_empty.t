#!/usr/bin/perl

use strict;
use warnings;

use File::Spec;
use Cwd;

BEGIN {
    my $cwd = ${^TAINT} ? do { local $_=getcwd; /(.*)/; $1 } : '.';
    unshift @INC, File::Spec->catdir($cwd, 't/tlib');
}

use Test::More tests => 5;

local $SIG{__WARN__} = sub { BAIL_OUT( $_[0] ) };

no warnings 'once';


eval q{
    use maybe 'maybe::Test1' => 'string', '';
};
is( $@, '',                                              'use maybe "maybe::Test1" succeed' );
ok( maybe->HAVE_MAYBE_TEST1,                             'maybe->HAVE_MAYBE_TEST1 is true' );
isnt( $INC{'maybe/Test1.pm'}, undef,                     '%INC for maybe/Test1.pm is set' );
is( maybe::Test1->VERSION, 123,                          'maybe::Test1->VERSION == 123' );
is( $maybe::Test1::is_ok, 'string',                      '$maybe::Test1::is_ok eq "string"' );

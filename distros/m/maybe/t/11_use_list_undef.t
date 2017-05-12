#!/usr/bin/perl

use strict;
use warnings;

use File::Spec;
use Cwd;

BEGIN {
    my $cwd = ${^TAINT} ? do { local $_=getcwd; /(.*)/; $1 } : '.';
    unshift @INC, File::Spec->catdir($cwd, 't/tlib');
}

use Test::More tests => 4;

local $SIG{__WARN__} = sub { BAIL_OUT( $_[0] ) };

no warnings 'once';


eval q{
    use maybe::Test1 undef;
};
is( $@, '',                                          'use maybe "maybe::Test1" succeed' );
isnt( $INC{'maybe/Test1.pm'}, undef,                 '%INC for maybe/Test1.pm is set' );
is( maybe::Test1->VERSION, 123,                      'maybe::Test1->VERSION == 123' );
is( $maybe::Test1::is_ok, '1',                       '$maybe::Test1::is_ok == 1' );

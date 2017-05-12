#!/usr/bin/perl

use strict;
use warnings;

use Carp ();

$SIG{__WARN__} = sub { local $Carp::CarpLevel = 1; Carp::confess("Warning: ", @_) };

use Test::More tests => 10;

eval q{
    package constant::boolean::Test10;
    use constant::boolean;
};

is( $@, '', 'use constant::boolean' );
is_deeply( [ sort keys %{*constant::boolean::Test10::} ], [ qw( BEGIN FALSE TRUE ) ], 'constants are imported' );

my $true;
eval q{
    $true = constant::boolean::Test10::TRUE;
};

ok( defined $true, 'defined TRUE' );
ok( $true, 'TRUE is true' );
is( prototype('constant::boolean::Test10::TRUE'), '', 'TRUE is constant' );

my $false;
eval q{
    $false = constant::boolean::Test10::FALSE;
};

ok( defined $false, 'defined FALSE' );
ok( ! $false, 'FALSE is not true' );
is( prototype('constant::boolean::Test10::FALSE'), '', 'FALSE is constant' );

eval q{
    package constant::boolean::Test10;
    no constant::boolean;
};

is( $@, '', 'no constant::boolean' );
is_deeply( [ sort keys %{*constant::boolean::Test10::} ], [ qw( BEGIN ) ], 'constants are unimported' );


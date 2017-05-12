#!perl
#   ---------------------------------------------------------------------- copyright and license ---
#
#   file: t/03-version-dotted-semantic.pm
#
#   Copyright © 2017 Van de Bugger.
#
#   This file is part of perl-Version-Dotted.
#
#   perl-Version-Dotted is free software: you can redistribute it and/or modify it under the terms
#   of the GNU General Public License as published by the Free Software Foundation, either version
#   3 of the License, or (at your option) any later version.
#
#   perl-Version-Dotted is distributed in the hope that it will be useful, but WITHOUT ANY
#   WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#   PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with
#   perl-Version-Dotted. If not, see <http://www.gnu.org/licenses/>.
#
#   ---------------------------------------------------------------------- copyright and license ---

use strict;
use warnings;
use if $ENV{AUTOMATED_TESTING}, 'Test::DiagINC'; use version 0.77 qw{};
use lib 't/lib';

use Scalar::Util qw{ blessed };
use Test::Builder;
use Test::More;
use Test::Warn;

use ok 'Version::Dotted::Semantic', 'qv';
use VersionTester qv => \&qv;

my $invalid  = 'Invalid version part name';
my $warnings = 0;

{

local $SIG{ __WARN__ } = sub {
    ++ $warnings;
    STDERR->print( @_ );
};

my $v;

$v = qv( 1 );                                   is( blessed( $v ), 'Version::Dotted::Semantic' );
$v = Version::Dotted::Semantic->declare( 1 );   is( blessed( $v ), 'Version::Dotted::Semantic' );

# Trailing zeros truncated, but result has at least 3 components:
$v = qv( v1.0.0.0.0.0 );    ver_ok( $v, 'v1.0.0' );
$v = qv( 'v1.2.3.0.0.0' );  ver_ok( $v, 'v1.2.3' );

# Part accessors:
$v = qv( 'v1.2.3' );
ok( $v->part( 0 ) == 1 );      ok( $v->part( 'major' ) == 1 );      ok( $v->major == 1 );
ok( $v->part( 1 ) == 2 );      ok( $v->part( 'minor' ) == 2 );      ok( $v->minor == 2 );
ok( $v->part( 2 ) == 3 );      ok( $v->part( 'patch' ) == 3 );      ok( $v->patch == 3 );
ok( ! defined $v->part( 3 ) ); ok( ! defined $v->part( 'trial' ) ); ok( ! defined $v->trial );
ok( ! $v->is_trial );
$v = qv( 'v2.3.4.5' );
ok( $v->part( 0 ) == 2 );      ok( $v->part( 'major' ) == 2 );      ok( $v->major == 2 );
ok( $v->part( 1 ) == 3 );      ok( $v->part( 'minor' ) == 3 );      ok( $v->minor == 3 );
ok( $v->part( 2 ) == 4 );      ok( $v->part( 'patch' ) == 4 );      ok( $v->patch == 4 );
ok( $v->part( 3 ) == 5 );      ok( $v->part( 'trial' ) == 5 );      ok( $v->trial == 5 );
ok( $v->is_trial );

# Bumping:
$v = qv( 'v1.2.3' );
$v->bump( 'trial' );    ver_ok( $v, 'v1.2.3.1' );
$v->bump( 'patch' );    ver_ok( $v, 'v1.2.4' );
$v->bump( 'minor' );    ver_ok( $v, 'v1.3.0' );
$v->bump( 'major' );    ver_ok( $v, 'v2.0.0' );

# Invalid part names:
$v = qv( 'v1.2.3' );
warning_like( sub { ok( ! defined $v->part( 'mojor' ) ); }, qr{$invalid 'mojor'} );
warning_like( sub { ok( ! defined $v->bump( 'minir' ) ); }, qr{$invalid 'minir'} );

# Export:
{
    package Dummy1;
    use Version::Dotted::Odd;
    use Test::More;
    eval "qv( v1.2.3 )";
    like( $@, qr{Undefined subroutine &Dummy1::qv}, "no export by default" );
}
{
    package Dummy2;
    use Test::More;
    use Test::Warn;
    warning_like(
        sub { eval "use Version::Dotted::Odd 'qw';"; },
        qr{Bad Version::Dotted::Odd import: 'qw'}
    );
    is( $@, '' );
}

}

if ( $ENV{ AUTHOR_TESTING } ) {
    is( $warnings, 0, "no warnings are expected" );
};

done_testing;

exit( 0 );

# end of file #

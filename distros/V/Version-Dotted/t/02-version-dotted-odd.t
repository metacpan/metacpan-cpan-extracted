#!perl
#   ---------------------------------------------------------------------- copyright and license ---
#
#   file: t/02-version-dotted-odd.pm
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

use ok 'Version::Dotted::Odd', 'qv';
use VersionTester qv => \&qv;

my $warnings = 0;

{

local $SIG{ __WARN__ } = sub {
    ++ $warnings;
    STDERR->print( @_ );
};

my $v;

$v = qv( 1 );                              is( blessed( $v ), 'Version::Dotted::Odd' );
$v = Version::Dotted::Odd->declare( 1 );   is( blessed( $v ), 'Version::Dotted::Odd' );

# Trailing zeros truncated, but result has at least 3 components:
ver_ok(  v1.0.0.0.0.0 , 'v1.0.0' );
ver_ok( 'v1.2.3.0.0.0', 'v1.2.3' );

$v = qv( v1.0.0 );      ok( ! $v->is_trial );
$v = qv( v1.1.0 );      ok(   $v->is_trial );
$v = qv( v1.2.0 );      ok( ! $v->is_trial );
$v = qv( v1.3.0 );      ok(   $v->is_trial );
$v = qv( v1.2.0.1 );    ok( ! $v->is_trial );
$v = qv( v1.3.0.1 );    ok(   $v->is_trial );

# Export:
{
    package Dummy1;
    use Version::Dotted::Semantic;
    use Test::More;
    eval "qv( v1.2.3 )";
    like( $@, qr{Undefined subroutine &Dummy1::qv}, "no export by default" );
}
{
    package Dummy2;
    use Test::More;
    use Test::Warn;
    warning_like(
        sub { eval "use Version::Dotted::Semantic 'qw';"; },
        qr{Bad Version::Dotted::Semantic import: 'qw'}
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

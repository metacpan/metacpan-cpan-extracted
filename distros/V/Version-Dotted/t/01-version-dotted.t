#!perl
#   ---------------------------------------------------------------------- copyright and license ---
#
#   file: t/01-version-dotted.pm
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
use Test::More;
use Test::Warn;

use ok 'Version::Dotted', 'qv';
use VersionTester qv => \&qv;

my %RE = (
    negative  => qr{^Negative version part index},
    invalid   => qr{^Invalid version part index},
    too_large => qr{too large part},
    undefined => qr{^Use of undefined value to construct version},
    redefined => qr{^Subroutine '.*?' redefined},
);
my $warnings = 0;

{

local $SIG{ __WARN__ } = sub {
    ++ $warnings;
    STDERR->print( @_ );
};

my $v;

is( Version::Dotted->min_len, 1, 'minimun number of parts' );

$v = Version::Dotted->new( 'v1' );      is( blessed( $v ), 'Version::Dotted' );
$v = Version::Dotted->declare( '1' );   is( blessed( $v ), 'Version::Dotted' );
$v = qv( v1 );                          is( blessed( $v ), 'Version::Dotted' );

{
    my @a = ( qv 1, 2, 3 );
    ok( @a == 3, "qv takes one argument" );
};

# One-part versions:
ver_ok(  v1 , 'v1' );
ver_ok(   1 , 'v1' );
ver_ok( 'v1', 'v1' );
ver_ok(  '1', 'v1' );

# Two-part versions:
ver_ok(  v1.2 ,  'v1.2' );
ver_ok(   1.2 ,  'v1.2' );
ver_ok( 'v1.2',  'v1.2' );
ver_ok(  '1.2',  'v1.2' );

# Three-part versions:
ver_ok(  v1.2.3 , 'v1.2.3' );
ver_ok(   1.2.3 , 'v1.2.3' );
ver_ok( 'v1.2.3', 'v1.2.3' );
ver_ok(  '1.2.3', 'v1.2.3' );

# Four-part versions:
ver_ok(  v1.2.3.4 , 'v1.2.3.4' );
ver_ok(   1.2.3.4 , 'v1.2.3.4' );
ver_ok( 'v1.2.3.4', 'v1.2.3.4' );
ver_ok(  '1.2.3.4', 'v1.2.3.4' );

# Integer numbers:
ver_ok(   1,   'v1' );
ver_ok(  10,  'v10' );
ver_ok( 101, 'v101' );

# Floating-point numbers:
ver_ok( 0.1  , 'v0.1' );
ver_ok( 0.001, 'v0.1' );
ver_ok( 0.100, 'v0.1' );    # oops TODO: Document it

# Copy constructors:
ver_ok( version->declare( v1.2    ), 'v1.2'   );
ver_ok( version->parse(   '1.200' ), 'v1.200' );
ver_ok( qv(               v1.2    ), 'v1.2'   );
{
    my $a = qv( v1.2 );
    my $b = qv( $a );
    ok( $a == $b, 'qv copies value' );
    ok( $a->{ version } != $b->{ version }, 'qv does not share version attribute' );
}

# Undefined value:
warning_like( sub { ver_ok( undef, 'v0' ); }, $RE{ undefined } );

# Bad value:
warning_like( sub { qv( 'xxx' ); }, qr{ at t/01-version-dotted\.t line \d+\.\n?$} );

# Leading zeros in parts are ignored:
ver_ok(  v000.001 , 'v0.1' );
ver_ok( 'v000.001', 'v0.1' );
ver_ok(  '000.001', 'v0.1' );

# Trailing zero parts are truncated:
ver_ok(  v1.2.0.0.0 , 'v1.2' );
ver_ok(   1.2.0.0.0 , 'v1.2' );
ver_ok( 'v1.2.0.0.0', 'v1.2' );
ver_ok(  '1.2.0.0.0', 'v1.2' );

# Parts larger than 999:
ver_ok(  v1000.2.3.4 , 'v1000.2.3.4' );
ver_ok(   1.2000.3.4 , 'v1.2000.3.4' );
ver_ok( 'v1.2.3000.4', 'v1.2.3000.4' );
ver_ok(  '1.2.3.4000', 'v1.2.3.4000' );

# Parts:
$v = qv( 'v1.2.3' );
is( $v->parts, 3 );
is_deeply( [ $v->parts ], [ 1, 2, 3 ] );
is( $v->part( 0 ), 1 );
is( $v->part( 1 ), 2 );
is( $v->part( 2 ), 3 );
ok( ! defined $v->part( 3 ) );

# Negative part index causes warning:
warning_like( sub { $v->part( -1 ) }, qr{$RE{ negative } '-1'} );
{
    no warnings 'Version::Dotted';  # Warning can be disabled.
    # In such a case negative index counts parts from the end:
    is( $v->part( -1 ), 3 );        # The last part.
    is( $v->part( -2 ), 2 );        # The second last part.
    is( $v->part( -3 ), 1 );        # The third last part.
    ok( ! defined $v->part( -4 ) ); # Oops.
}

# Bumping:
$v = qv( 'v1.2.3' );
ver_ok( $v->bump( 3 ), 'v1.2.3.1'     );      ver_ok( $v, 'v1.2.3.1'     );
ver_ok( $v->bump( 5 ), 'v1.2.3.1.0.1' );      ver_ok( $v, 'v1.2.3.1.0.1' );
ver_ok( $v->bump( 5 ), 'v1.2.3.1.0.2' );      ver_ok( $v, 'v1.2.3.1.0.2' );
ver_ok( $v->bump( 4 ), 'v1.2.3.1.1'   );      ver_ok( $v, 'v1.2.3.1.1'   );
ver_ok( $v->bump( 3 ), 'v1.2.3.2'     );      ver_ok( $v, 'v1.2.3.2'     );
ver_ok( $v->bump( 2 ), 'v1.2.4'       );      ver_ok( $v, 'v1.2.4'       );
ver_ok( $v->bump( 1 ), 'v1.3'         );      ver_ok( $v, 'v1.3'         );
ver_ok( $v->bump( 0 ), 'v2'           );      ver_ok( $v, 'v2'           );

# Bumping with negative index:
$v = qv( 'v1.2.3.4' );
warning_like( sub { ver_ok( $v->bump( -1 ), 'v1.2.3.5' ); }, qr{$RE{ negative } '-1'} );
                    ver_ok( $v,             'v1.2.3.5' );
warning_like( sub { ver_ok( $v->bump( -2 ), 'v1.2.4'   ); }, qr{$RE{ negative } '-2'} );
                    ver_ok( $v,             'v1.2.4' );
warning_like( sub { ver_ok( $v->bump( -3 ), 'v2'       ); }, qr{$RE{ negative } '-3'} );
                    ver_ok( $v,             'v2' );
warning_like( sub { ok( ! defined $v->bump( -2 ) ); }, qr{$RE{ invalid } '-2'}  );
ver_ok( $v, 'v2', "failed bump does not change object" );

# Compare:
ok( qv( v1.2 ) == v1.2 );

# Normal:
$v = qv( v1 );
is( ref( $v->normal ), '', 'normal returns string, not ref' );
is( $v->normal, 'v1',      'normal does not append zero parts' );

# Release status:
trial_ok( v1.2.3,   '', 'is_trial returns false' );
trial_ok( v1.3.3,   '', 'is_trial returns false' );
trial_ok( v1.2.3.4, '', 'is_trial returns false' );
trial_ok( v1.3.3.4, '', 'is_trial returns false' );
warning_like( sub { $v->is_alpha }, qr{'is_alpha' is not recommended}, 'is_alpha warns' );


# Not supported methods:
$v = qv( 'v1.2.3' );
warning_like( sub { $v->numify   }, qr{'numify' is not supported}   );
warning_like( sub { Version::Dotted->parse( 'v1.2.3' ) }, qr{'parse' is not supported} );
{
    no warnings 'Version::Dotted';
    ok( ! defined $v->numify, 'numify returns undef' );
    ok( ! defined Version::Dotted->parse( 'v1.2.3' ), 'parse returns undef' );
}

# Export:
{
    package Dummy1;
    use Version::Dotted;
    use Test::More;
    eval "qv( v1.2.3 )";
    like( $@, qr{^Undefined subroutine &Dummy1::qv}, "no export by default" );
}
{
    package Dummy2;
    use Test::More;
    use Test::Warn;
    warning_like( sub { eval "use Version::Dotted 'qw'" }, qr{^Bad Version::Dotted import: 'qw'} );
    is( $@, '' );
}
{
    package Dummy3;
    use version;
    use Scalar::Util 'blessed';
    use Test::More;
    use Test::Warn;
    warning_like( sub { eval "use Version::Dotted 'qv'" }, qr{^Subroutine 'Dummy3::qv' redefined} );
    $v = qv( v1 );
    is( blessed( $v ), 'Version::Dotted' );
}

}

if ( $ENV{ AUTHOR_TESTING } ) {
    is( $warnings, 0, "no warnings are expected" );
};

done_testing;

exit( 0 );

# end of file #

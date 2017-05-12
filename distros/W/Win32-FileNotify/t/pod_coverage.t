#!perl -T

use Test::More;

my $error;

eval "use Test::Pod::Coverage 1.08; 1;" or $error = 1;
plan skip_all => "Test::Pod::Coverage 1.08 required for testing POD coverage" if $error;

if ( !$error ) {
    plan tests    => 1;
    pod_coverage_ok( 'Win32::FileNotify' );
}

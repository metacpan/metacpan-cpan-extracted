#!perl -T

use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;
plan tests => 5;
my $prefix = 'Variable::Strongly::Typed';

pod_coverage_ok($prefix, 'Typed.pm covered');

foreach my $lib (qw(Scalar Array Hash)) {
    pod_coverage_ok( 
        $prefix . '::' . $lib, 
        { also_private => [ qr/^[A-Z_]+$/ ], }, 
        $prefix . "::$lib, with all-caps functions as privates",
    );
}

pod_coverage_ok( $prefix . '::Validators', 'Validators.pm covered');

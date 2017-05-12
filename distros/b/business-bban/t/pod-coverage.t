use Test::More;
my $min_tpc = '1.10';
eval "use Test::Pod::Coverage $min_tpc";
$@ and plan skip_all =>
    "Test::Pod::Coverage $min_tpc required for testing POD coverage";

map {
    pod_coverage_ok( $_ => "Documentation covering the module $_")
} qw(
    Business::BBAN
    Business::myIBAN
);

done_testing;

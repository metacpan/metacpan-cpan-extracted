use Test::More;
my $min_tpc = '1.10';
eval "use Test::Pod::Coverage $min_tpc";
$@ and plan skip_all =>
    "Test::Pod::Coverage $min_tpc required for testing POD coverage";

pod_coverage_ok(Eirotic => "Eirotic POD covering");
done_testing;

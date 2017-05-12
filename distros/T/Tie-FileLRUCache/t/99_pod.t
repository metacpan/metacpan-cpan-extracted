use Test::More;
eval {
    require Test::Pod;
};
if ($@ or (not defined $Test::Pod::VERSION) or ($Test::Pod::VERSION < 1.00)) {
    plan skip_all => "Test::Pod 1.00 required for testing POD";
    exit;
}

Test::Pod::all_pod_files_ok();


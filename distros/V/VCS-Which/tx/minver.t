#!perl

eval {
    require Test::MinimumVersion;
};

if ($@) {
    require Test::More;
    Test::More->import;

    plan( skip_all => 'Test::MinimumVersion required to run this test' );
}

Test::MinimumVersion->import;
all_minimum_version_from_metayml_ok();

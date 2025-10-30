use Test2::V0;
use Test2::Plugin::SubtestFilter;

subtest 'apply_plugin can be called directly' => sub {
    # Create a test package
    my $package = 'TestPackage' . $$;

    # Load Test2::V0 into the package to get the subtest function
    eval qq{
        package $package;
        use Test2::V0;
        1;
    } or die $@;

    # Verify the package has subtest before applying plugin
    ok($package->can('subtest'), 'package has subtest function');

    # Create a temporary test file
    my $test_file = "t/examples/apply_plugin_test_$$.t";
    open my $fh, '>', $test_file or die "Cannot create $test_file: $!";
    print $fh qq{
        use Test2::V0;
        subtest 'test1' => sub { ok 1 };
        subtest 'test2' => sub { ok 1 };
        done_testing;
    };
    close $fh;

    # Apply plugin directly
    Test2::Plugin::SubtestFilter->apply_plugin($package, $test_file);

    # Verify the subtest function still exists
    ok($package->can('subtest'), 'package still has subtest function after apply_plugin');

    # Clean up
    unlink $test_file;
};

subtest 'apply_plugin does nothing if package has no subtest' => sub {
    # Create a test package without subtest
    my $package = 'TestPackageNoSubtest' . $$;

    eval qq{
        package $package;
        1;
    } or die $@;

    # Verify the package has no subtest
    ok(!$package->can('subtest'), 'package has no subtest function');

    # Create a temporary test file
    my $test_file = "t/examples/apply_plugin_test2_$$.t";
    open my $fh, '>', $test_file or die "Cannot create $test_file: $!";
    print $fh qq{
        use Test2::V0;
        subtest 'test1' => sub { ok 1 };
        done_testing;
    };
    close $fh;

    # Apply plugin - should do nothing
    Test2::Plugin::SubtestFilter->apply_plugin($package, $test_file);

    # Verify the package still has no subtest
    ok(!$package->can('subtest'), 'package still has no subtest function');

    # Clean up
    unlink $test_file;
};

subtest 'apply_plugin multiple times on same package' => sub {
    # Create a test package
    my $package = 'TestPackageMultiple' . $$;

    eval qq{
        package $package;
        use Test2::V0;
        1;
    } or die $@;

    # Create temporary test files
    my $test_file1 = "t/examples/apply_plugin_test3_$$.t";
    open my $fh, '>', $test_file1 or die "Cannot create $test_file1: $!";
    print $fh qq{
        use Test2::V0;
        subtest 'test1' => sub { ok 1 };
        done_testing;
    };
    close $fh;

    # Apply plugin first time
    Test2::Plugin::SubtestFilter->apply_plugin($package, $test_file1);
    ok($package->can('subtest'), 'package has subtest after first apply_plugin');

    # Apply plugin second time with different file
    my $test_file2 = "t/examples/apply_plugin_test4_$$.t";
    open $fh, '>', $test_file2 or die "Cannot create $test_file2: $!";
    print $fh qq{
        use Test2::V0;
        subtest 'test2' => sub { ok 1 };
        done_testing;
    };
    close $fh;

    Test2::Plugin::SubtestFilter->apply_plugin($package, $test_file2);
    ok($package->can('subtest'), 'package still has subtest after second apply_plugin');

    # Clean up
    unlink $test_file1, $test_file2;
};

done_testing;

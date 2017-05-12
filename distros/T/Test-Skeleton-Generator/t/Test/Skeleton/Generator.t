use Test::Most;

BEGIN {
    use_ok( 'Test::Skeleton::Generator' );
}

if ( $ARGV[ 0 ] ) {
    no strict 'refs';
    &{$ARGV[ 0 ]}();
    done_testing;
    exit 0;
}

test_analyze_t_file();
test_get_package_functions();
test_get_package_name();
test_new();
test_prepare_template();
test_prepare_test_file_path();
test_get_test();
test_get_updated_calls();
test_write_test_file();

done_testing;


sub get_object {
    return Test::Skeleton::Generator->new( @_ );
}

sub test_analyze_t_file {
    can_ok 'Test::Skeleton::Generator', 'analyze_t_file';
    my $obj = get_object( { test_file => './t/Test/Skeleton/Generator.t' } );

    my $test_subs = $obj->analyze_t_file;
    is scalar keys %$test_subs, 10, 'correct number of subs found';
    ok $test_subs->{ get_object }, 'get_object was found';
    ok $test_subs->{ test_analyze_t_file }, 'this test subroutine was found';
}

sub test_get_package_functions {
    can_ok 'Test::Skeleton::Generator', 'get_package_functions';
    my $obj = get_object(
        {
            package_file => 'lib/Test/Skeleton/Generator.pm',
            test_file    => '/tmp/foo.t',
        }
    );
    $obj->{ skip_private_methods } = 0;
    my $funs = $obj->get_package_functions( 'Test::Skeleton::Generator', {} );
    is $#$funs, 9, 'correct number of subs extracted';
    ok( ( grep { $_->{ function } eq '_debug' } @$funs ), 'private sub correctly found' );

    $obj->{ skip_private_methods } = 1;
    $funs = $obj->get_package_functions( 'Test::Skeleton::Generator', {} );
    is $#$funs, 8, 'correct number of subs extracted';

    dies_ok { $obj->get_package_functions( 'Does::Not::Exist' ) } 'Dies when it cannot use the module';

    $funs = $obj->get_package_functions( 'Test::Skeleton::Generator', { test_get_package_functions => 1 } );
    is $#$funs, 7, 'correct number of subs extracted - existing sub was skipped';
    ok(  ! ( grep { $_->{ function } eq 'get_package_functions' } @$funs ), 'get_package_functions was skipped' );
}

sub test_get_package_name {
    can_ok 'Test::Skeleton::Generator', 'get_package_name';

    subtest 'package name' => sub {
        my $obj = get_object( { package_file => 'Test::Skeleton::Generator' } );
        is $obj->get_package_name, 'Test::Skeleton::Generator', 'package name is correct';
    };

    subtest 'package path' => sub {
        my $obj = get_object( { package_file => './lib/Test/Skeleton/Generator.pm' } );
        is $obj->get_package_name, 'Test::Skeleton::Generator', 'package name is correct';
    };
}

sub test_new {
    can_ok 'Test::Skeleton::Generator', 'new';

    dies_ok { Test::Skeleton::Generator->new } 'dies when no options are provided';

    my $obj = Test::Skeleton::Generator->new( {
            test_file            => 'a test file',
            package_file         => 'a package file',
            debug                => 'a debug flag',
            skip_private_methods => 'a skip_private_methods flag',
        }
    );
    isa_ok $obj, 'Test::Skeleton::Generator';
    is $obj->{ test_file }, 'a test file', 'test_file correctly set';
    is $obj->{ package_file }, 'a package file', 'package_file correctly set';
    is $obj->{ debug }, 'a debug flag', 'debug correctly set';
    is $obj->{ skip_private_methods }, 'a skip_private_methods flag', 'skip_private_methods correctly set';
}

sub test_prepare_template {
    can_ok 'Test::Skeleton::Generator', 'prepare_template';

    my $obj = get_object( {} );
    my $template = $obj->prepare_template(
        'Test::Package::Name',
        [
            { function => 'a_sub' },
            { function => 'another_sub' },
        ]
    );
    isa_ok $template, 'HTML::Template';
    my @params = $template->param;
    is scalar @params, 4, 'four parameter in template';
    foreach my $param ( qw/ package function functions update / ) {
        ok( ( grep { $_ eq $param } @params ), "params $param is present" );
    }
    is $template->query( name => 'functions' ), 'LOOP', 'functions is a template loop';
    is $template->query( name => 'package' ), 'VAR', 'package is a template VAR';
    is $template->query( name => 'function' ), 'VAR', 'function is a template VAR';
    is $template->query( name => 'update' ), 'VAR', 'function is a template VAR';

    my $content = $template->output;

    like $content, qr'use Test::Most;', 'use Test::Most is in the content';
    like $content, qr|use_ok\( 'Test::Package::Name' \);|, 'the use_ok for the package name is present';
    like $content, qr|sub get_object {|, 'sub get_object was generated';
    like $content, qr|sub test_a_sub {|, 'sub test_a_sub was generated';
    like $content, qr|test_a_sub\(\);|, 'call to test_a_sub was generated';
    like $content, qr|sub test_another_sub {|, 'sub test_another_sub was generated';
    like $content, qr|test_another_sub\(\);|, 'call to test_another_sub was generated';
    like $content, qr|done_testing;|, 'the call to done_testing was generated';
}

sub test_prepare_test_file_path {
    can_ok 'Test::Skeleton::Generator', 'prepare_test_file_path';
    my $obj = get_object( { test_file => './t/tmp.t' } );
    lives_ok { $obj->prepare_test_file_path } 'no lives were lost';

    $obj = get_object( { test_file => './t/Garbage/tmp.t' } );
    lives_ok { $obj->prepare_test_file_path } 'no lives were lost';
    ok -d './t/Garbage', 'directory was created';

    $obj = get_object( { test_file => './t/Foo/Bar/tmp.t' } );
    lives_ok { $obj->prepare_test_file_path } 'no lives were lost';
    ok -d './t/Foo', 'directory 1 was created';
    ok -d './t/Foo/Bar', 'directory 2 was created';

    rmdir './t/Foo/Bar';
    rmdir './t/Foo';
    rmdir './t/Garbage';
}

sub test_get_test {
    can_ok 'Test::Skeleton::Generator', 'get_test';
}

sub test_get_updated_calls {
    can_ok 'Test::Skeleton::Generator', 'get_updated_calls';

    my $obj = get_object( { test_file => './t/Test/Skeleton/Generator.t' } );
    my $content = $obj->get_updated_calls( [ { function => 'new_sub_1' }, { function => 'new_sub_2' } ] );
    like $content, qr|test_write_test_file\(\);\n\ntest_new_sub_1\(\);\ntest_new_sub_2\(\);\n\ndone_testing;|, 'new calls were correctly inserted';

    $obj = get_object( { test_file => './t/Does/not/Exist.t' } );
    $content = $obj->get_updated_calls( [ { function => 'new_sub_1' }, { function => 'new_sub_2' } ] );
    is $content, '', 'no test file, no content';
}

sub test_write_test_file {
    can_ok 'Test::Skeleton::Generator', 'write_test_file';
}


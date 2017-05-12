use strict;
use Test::More tests => 5;

BEGIN { use_ok("WSST::Generator"); }

can_ok("WSST::Generator", qw(generator_names generate));

my $schema = WSST::Schema->new({
    company_name => 'Test',
    service_name => 'TestService',
    methods => [
        {
            name => 'do_something',
            url => 'http://localhost/ws/doSomething',
        },
        {
            name => 'doSomething2',
            url => 'http://localhost/ws/doSomething2',
        },
    ],
});

my $res_test1 = [
    'output/test1/Test.TestService.test',
    'output/test1/Test.TestService.DoSomething.test',
    'output/test1/Test.TestService.DoSomething2.test',
];

my $res_test2 = [
    'output/test2/Test_TestService_DoSomething.test',
    'output/test2/Test_TestService_DoSomething2.test',
    'output/test2/Test_TestService.test',
];

my $obj = WSST::Generator->new('tmpl_dir' => 't/test_templates');
ok(ref $obj, '$obj->new()');
is($obj->{tmpl_dir}, 't/test_templates', '$obj->{tmpl_dir}');
is_deeply($obj->generator_names, [qw(test1 test2)], '$obj->generator_names');
#is_deeply($obj->generate('test1', $schema), $res_test1, '$obj->generate(test1)');
#is_deeply($obj->generate('test2', $schema), $res_test2, '$obj->generate(test2)');

1;

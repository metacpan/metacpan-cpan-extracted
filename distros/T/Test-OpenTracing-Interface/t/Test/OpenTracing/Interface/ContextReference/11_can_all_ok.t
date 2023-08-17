use Test::More;

use Test::OpenTracing::Interface::ContextReference;

use lib 't/lib/';
use Test::OpenTracing::Tester::CanAll;

my $Test = Test::OpenTracing::Tester::CanAll->new(
    interface_name => 'ContextReference',
    interface_methods => [
        'new_child_of',
        'new_follows_from',
        'get_referenced_context',
        'type_is_child_of',
        'type_is_follows_from',
    ],
);

$Test->run_tests_can_all_ok;

done_testing();



package MyTest::ContextReference;

sub new_child_of;
sub new_follows_from;
sub get_referenced_context;
sub type_is_child_of;
sub type_is_follows_from;

1;

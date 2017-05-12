package Test::Mock::Class::GenerateTest;

use Test::Unit::Lite;

use Moose;
extends 'Test::Unit::TestCase';

use Test::Assert ':all';

use Test::Mock::Class;

sub test_mock_class {
    my $meta = Test::Mock::Class->create_mock_class(
        'Test::Mock::Class::Test::Dummy::MockGenerated',
        class => 'Test::Mock::Class::Test::Dummy',
    );
    assert_true($meta->isa('Moose::Meta::Class'));
    assert_true(Test::Mock::Class::Test::Dummy::MockGenerated->isa('Test::Mock::Class::Test::Dummy::MockGenerated'));
};

1;

package Test::Mock::Class::UseTest;

use Test::Unit::Lite;

use Moose;
extends 'Test::Unit::TestCase';

use Test::Assert ':all';

use Test::Mock::Class ':all';

sub test_mock_class {
    {
        my $mock = eval q{
            mock_class 'Test::Mock::Class::Test::Dummy';
        };
        assert_equals('', $@);
        assert_true($mock->isa('Moose::Meta::Class'));
        assert_true(Test::Mock::Class::Test::Dummy::Mock->isa('Test::Mock::Class::Test::Dummy::Mock'));
    };

    {
        my $mock = eval q{
            mock_class 'Test::Mock::Class::Test::Dummy' => 'Test::Mock::Class::Test::Dummy::Mock::Another';
        };
        assert_equals('', $@);
        assert_true($mock->isa('Moose::Meta::Class'));
        assert_true(Test::Mock::Class::Test::Dummy::Mock::Another->isa('Test::Mock::Class::Test::Dummy::Mock::Another'));
    };
};

sub test_mock_anon_class {
    my $mock = eval q{
        mock_anon_class 'Test::Mock::Class::Test::Dummy';
    };
    assert_equals('', $@);
    assert_true($mock->isa('Moose::Meta::Class'));
};

1;

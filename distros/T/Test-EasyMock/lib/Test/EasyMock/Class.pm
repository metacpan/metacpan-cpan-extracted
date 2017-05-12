package Test::EasyMock::Class;
use strict;
use warnings;

=head1 NAME

Test::EasyMock::Class - support class method mocking.

=head1 SYNOPSIS

    use Test::EasyMock qw(:all);
    use Test::EasyMock::Class qw(create_class_mock);
    
    my $mock = create_class_mock('Foo::Bar');
    expect($mock->foo(1))->and_scalar_return('a');
    replay($mock);
    Foo::Bar->foo(1); # return 'a'
    Foo::Bar->foo(2); # Unexpected method call.(A test is failed)
    verify($mock); # verify all expectations is invoked.

=cut
use Exporter qw(import);
use Test::EasyMock::MockControl::Class;

our @EXPORT_OK = qw(
    create_class_mock
);
our %EXPORT_TAGS = (all => [@EXPORT_OK]);

=head1 FUNCTIONS

=head2 create_class_mock($class)

Creates a mock object for class.

=cut
sub create_class_mock {
    my $control = Test::EasyMock::MockControl::Class->create_control(@_);
    return $control->create_mock;
}

1;

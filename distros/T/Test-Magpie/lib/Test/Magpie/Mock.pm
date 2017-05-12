package Test::Magpie::Mock;
{
  $Test::Magpie::Mock::VERSION = '0.11';
}
# ABSTRACT: Mock objects


use Moose -metaclass => 'Test::Magpie::Meta::Class';
use namespace::autoclean;

use aliased 'Test::Magpie::Invocation';
use aliased 'Test::Magpie::Stub';

use Test::Magpie::Util qw(
    extract_method_name
    get_attribute_value
    has_caller_package
);

use MooseX::Types::Moose qw( ArrayRef Int Str );
use MooseX::Types::Structured qw( Map );
use UNIVERSAL::ref;

our $AUTOLOAD;


has 'class' => (
    isa => Str,
    reader => 'ref',
    default => __PACKAGE__,
);


has 'invocations' => (
    isa => ArrayRef[Invocation],
    is => 'bare',
    default => sub { [] }
);


has 'stubs' => (
    isa => Map[ Str, ArrayRef[Stub] ],
    is => 'bare',
    default => sub { {} }
);

sub AUTOLOAD {
    my $self = shift;
    my $method_name = extract_method_name($AUTOLOAD);

    # record the method invocation for verification
    my $invocation  = Invocation->new(
        method_name => $method_name,
        arguments   => \@_,
    );

    my $invocations = get_attribute_value($self, 'invocations');
    push @$invocations, $invocation;

    # find a stub to return a response
    if (
        my $stubs = get_attribute_value($self, 'stubs')->{ $method_name }
    ) {
        for my $stub (@$stubs) {
            return $stub->execute if (
                $stub->satisfied_by($invocation) &&
                $stub->_has_executions
            );
        }
    }
    return;
}


sub isa {
    my ($self, $package) = @_;
    return if (
        has_caller_package('UNIVERSAL::ref') ||
        $package =~ /^Class::MOP::*/
    );
    return 1;
}


sub does {
    return if has_caller_package('UNIVERSAL::ref');
    return 1;
}



sub can {
    my ($self, $method_name) = @_;
    return sub {
        $AUTOLOAD = $method_name;
        goto &AUTOLOAD;
    };
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding utf-8

=head1 NAME

Test::Magpie::Mock - Mock objects

=head1 SYNOPSIS

    # create a mock object
    my $mock = mock(); # from Test::Magpie
    my $mock_with_class = mock('AnyRef');

    # mock objects pretend to be anything you want them to be
    $true = $mock->isa('AnyClass');
    $true = $mock->does('AnyRole');
    $true = $mock->DOES('AnyRole');
    $ref  = ref($mock_with_class); # AnyRef

    # call any method with any arguments
    $method_ref = $mock->can('any_method');
    $mock->any_method(@arguments);

=head1 DESCRIPTION

Mock objects are the objects you pass around as if they were real objects. They
do not have a defined API; any method may be called. Additionally, you can
create stubs to specify responses (return values or exceptions) to method
calls.

A mock objects records every method called on it along with their arguments.
These records may then be used for verifying that the correct interactions
occured.

=head1 ATTRIBUTES

=head2 class

The name of the class that the object is pretending to be blessed into. Calling
C<ref()> on the mock object will return this class name.

=head2 invocations

An array reference containing a record of all methods invoked on this mock.
These are used for verification and inspection.

This attribute is internal, and not publically accessible.

=head2 stubs

Contains all of the methods stubbed for this mock. It maps the method name to
an array of stubs. Stubs are matched against invocation arguments to determine
which stub to dispatch to.

This attribute is internal, and not publically accessible.

=head1 METHODS

=head2 isa

Always returns true. It allows the mock object to C<isa()> any class that
is required.

    $true = $mock->isa('AnyClass');

=head2 does

Always returns true. It allows the mock object to C<does()> any role that
is required.

    $true = $mock->does('AnyRole');
    $true = $mock->DOES('AnyRole');

=head2 ref

Returns the object's C<class> attribute value. This also works if you call
C<ref()> as a function instead of a method.

    $mock  = mock('AnyRef');
    $class = $mock->ref;  # or ref($mock)

If the object's C<class> attribute has not been set, then it will fallback to
returning the name of this class.

=head2 can

Always returns a reference to the C<AUTOLOAD()> method. It allows the mock
object to C<can()> do any method that is required.

    $method_ref = $mock->can('any_method');

=head1 AUTHORS

=over 4

=item *

Oliver Charles <oliver.g.charles@googlemail.com>

=item *

Steven Lee <stevenwh.lee@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Oliver Charles.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

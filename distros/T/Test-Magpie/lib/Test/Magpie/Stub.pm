package Test::Magpie::Stub;
{
  $Test::Magpie::Stub::VERSION = '0.11';
}
# ABSTRACT: The declaration of a stubbed method


use Moose;
use namespace::autoclean;

use MooseX::Types::Moose qw( ArrayRef );
use Scalar::Util qw( blessed );

with 'Test::Magpie::Role::MethodCall';


has 'executions' => (
    isa => ArrayRef,
    traits => [ 'Array' ],
    default => sub { [] },
    handles => {
        _store_execution => 'push',
        _next_execution => 'shift',
        _has_executions => 'count',
    }
);


sub then_return {
    my $self = shift;
    my @ret = @_;
    $self->_store_execution(sub {
        return wantarray ? (@ret) : $ret[0];
    });
    return $self;
}


sub then_die {
    my $self = shift;
    my $exception = shift;
    $self->_store_execution(sub {
        if (blessed($exception) && $exception->can('throw')) {
            $exception->throw;
        }
        else {
            die $exception;
        }
    });
    return $self;
}


sub execute {
    my $self = shift;
    #$self->_has_executions || confess "Stub has no more executions";

    return ( $self->_next_execution )->();
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding utf-8

=head1 NAME

Test::Magpie::Stub - The declaration of a stubbed method

=head1 DESCRIPTION

Represents a stub method - a method that may have some sort of action when
called. Stub methods are created by invoking the method name (with a set of
possible argument matchers/arguments) on the object returned by C<when> in
L<Test::Magpie>.

Stub methods have a stack of executions. Every time the stub method is called
(matching arguments), the next execution is taken from the front of the queue
and called. As stubs are matched via arguments, you may have multiple stubs for
the same method name.

=head1 ATTRIBUTES

=head2 executions

Internal. An array reference containing all stub executions.

=head1 METHODS

=head2 then_return $return_value

Pushes a stub method that will return $return_value to the end of the execution
queue.

=head2 then_die $exception

Pushes a stub method that will throw C<$exception> when called to the end of the
execution stack.

=head2 execute

Internal. Executes the next execution, if possible

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

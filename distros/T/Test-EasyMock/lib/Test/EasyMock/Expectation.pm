package Test::EasyMock::Expectation;
use strict;
use warnings;

=head1 NAME

Test::EasyMock::Expectation - A expected behavior object.

=cut
use Carp qw(croak);

=head1 CONSTRUCTORS

=head2 new(method=>$method, args=>$args})

Create a instance.

=cut
sub new {
    my ($class, $args) = @_;
    return bless {
        _method => $args->{method},
        _args => $args->{args},
        _results => [ { code => sub { return; }, implicit => 1 } ],
    }, $class;
}

=head1 PROPERTIES

=head2 method - An expected method name.

=cut
sub method {
    my ($self) = @_;
    return $self->{_method};
}

=head1 METHODS

=head2 push_result($code)

Add a method result behavior.

=cut
sub push_result {
    my ($self, $code) = @_;
    $self->remove_implicit_result();
    push @{$self->{_results}}, { code => $code };
}

=head2 set_stub_result($code)

Set a method result behavior as stub.

=cut
sub set_stub_result {
    my ($self, $code) = @_;
    $self->remove_implicit_result();
    $self->{_stub_result} = { code => $code };
}

=head2 remove_implicit_result()

Remove results which flagged with 'implicit'.

=cut
sub remove_implicit_result {
    my ($self) = @_;
    $self->{_results} = [
        grep { !$_->{implicit} } @{$self->{_results}}
    ];
}

=head2 retrieve_result()

Retrieve a result value.

=cut
sub retrieve_result {
    my ($self) = @_;
    my $result = shift @{$self->{_results}} || $self->{_stub_result};
    croak('no result.') unless $result;
    return $result->{code}->();
}

=head2 has_result

It is tested whether it has a result.

=cut
sub has_result {
    my ($self) = @_;
    return @{$self->{_results}} > 0;
}

=head2 has_stub_result

It is tested whether it has a stub result.

=cut
sub has_stub_result {
    my ($self) = @_;
    return exists $self->{_stub_result};
}

=head2 matches($args)

It is tested whether the specified argument matches.

=cut
sub matches {
    my ($self, $args) = @_;
    return $self->{_method} eq $args->{method}
        && $self->{_args}->matches($args->{args});
}

=head2 is_satisfied()

The call to expect tests whether it was called briefly.

=cut
sub is_satisfied {
    my ($self) = @_;
    return !$self->has_result;
}

=head2 unsatisfied_message()

The message showing a lacking call is acquired.

=cut
sub unsatisfied_message {
    my ($self) = @_;
    return sprintf(
        '%d calls of the `%s` method expected exist.',
        scalar(@{$self->{_results}}),
        $self->{_method}
    ) if $self->has_result;

    return;
}

1;

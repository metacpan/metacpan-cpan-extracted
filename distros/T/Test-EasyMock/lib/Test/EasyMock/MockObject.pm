package Test::EasyMock::MockObject;
use strict;
use warnings;

=head1 NAME

Test::EasyMock::MockObject - Mock object.

=cut

=head1 METHOD

=head2 isa($module)

Mock to I<isa> method.

=cut
# Override
sub isa {
    # TODO: expect 時の引数に eq や not(eq(...)) を使えるようになり次第
    #       and_stub_return として定義する
    my ($self, $module) = @_;
    return unless $module;

    my $self_module = $self->{_control}->{_module};
    return unless $self_module;

    return $module eq $self_module;
}

=head2 can($method)

Mock to I<can> method.

=cut
sub can {
    my $self = shift;
    return $self->{_control}->process_method_invocation($self, 'can', @_);
}

=head2 AUTOLOAD

Mock to any method.

=cut
sub AUTOLOAD {
    our $AUTOLOAD;
    my $self = shift;
    my ($sub) = do {
        local $1;
        $AUTOLOAD =~ m{::(\w+)\z}xms;
    };
    return if $sub eq 'DESTROY';
    return $self->{_control}->process_method_invocation($self, $sub, @_);
}

1;

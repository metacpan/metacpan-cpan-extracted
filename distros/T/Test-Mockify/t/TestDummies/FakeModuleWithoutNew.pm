package TestDummies::FakeModuleWithoutNew;

use strict;

sub DummyMethodForTestOverriding {
    my $self = shift;
    return 'A dummy method';
}

sub secondDummyMethodForTestOverriding {
    my $self = shift;
    return 'A second dummy method';
}

sub dummyMethodWithParameterReturn {
    my $self = shift;
    my ( $Parameter ) = @_;
    return $Parameter;
}

sub returnParameterListNew {
    my $self = shift;
    return $self->{'ParameterListNew'};
}

1;
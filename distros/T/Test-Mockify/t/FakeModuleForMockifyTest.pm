package FakeModuleForMockifyTest;

use strict;

sub new {
    my $class = shift;
    my @ParameterList = @_;
    my $self  = bless {
        'ParameterListNew' => \@ParameterList
    }, $class;
    return $self;
}

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
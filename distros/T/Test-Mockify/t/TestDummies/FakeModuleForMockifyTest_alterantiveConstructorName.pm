package TestDummies::FakeModuleForMockifyTest_alterantiveConstructorName;

use strict;

sub _new {
    my $class = shift;
    my @ParameterList = @_;
    my $self  = bless {
        'ParameterListNew' => \@ParameterList
    }, $class;
    return $self;
}

sub build{
    return _new('TestDummies::FakeModuleForMockifyTest_alterantiveConstructorName', @_);
}

sub create {
    my $class = shift;
    my @ParameterList = @_;
    my $self  = bless {
        'ParameterListNew_create' => \@ParameterList
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
sub returnParameterListCreate {
    my $self = shift;
    return $self->{'ParameterListNew_create'};
}

1;
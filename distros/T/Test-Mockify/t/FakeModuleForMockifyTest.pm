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

sub DummmyMethodForTestOverriding {
    my $self = shift;
    return 'A dummmy method';
}

sub secondDummmyMethodForTestOverriding {
    my $self = shift;
    return 'A second dummmy method';
}

sub dummmyMethodWithParameterReturn {
    my $self = shift;
    my ( $Parameter ) = @_;
    return $Parameter;
}

sub returnParameterListNew {
    my $self = shift;
    return $self->{'ParameterListNew'};
}

1;
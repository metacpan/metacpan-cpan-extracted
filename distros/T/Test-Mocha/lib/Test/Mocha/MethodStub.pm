package Test::Mocha::MethodStub;
# ABSTRACT: Objects to represent stubbed methods with arguments and responses
$Test::Mocha::MethodStub::VERSION = '0.64';
use parent 'Test::Mocha::Method';
use strict;
use warnings;

sub new {
    # uncoverable pod
    my $class = shift;
    my $self  = $class->SUPER::new(@_);

    $self->{responses} ||= [];  # ArrayRef[ CodeRef ]

    return $self;
}

sub __responses {
    my ($self) = @_;
    return $self->{responses};
}

sub cast {
    # """Convert the type of the given object to this class"""
    # uncoverable pod
    my ( $class, $obj ) = @_;
    $obj->{responses} ||= [];
    return bless $obj, $class;
}

sub execute_next_response {
    # uncoverable pod
    my ( $self, @args ) = @_;
    my $responses = $self->__responses;

    # return undef by default
    return if @{$responses} == 0;

    # shift the next response off the front of the queue
    # ... except for the last one
    my $response =
      @{$responses} > 1 ? shift( @{$responses} ) : $responses->[0];

    return $response->(@args);
}

1;

package WebService::OpenSky::Response::States;

# ABSTRACT: A class representing a states response from the OpenSky Network API
use WebService::OpenSky::Moose;
use WebService::OpenSky::Core::StateVector;
extends 'WebService::OpenSky::Response';

our $VERSION = '0.5';

method _create_response_objects() {
    return [ map { WebService::OpenSky::Core::StateVector->new($_) } $self->raw_response->{states}->@* ];
}

method _empty_response() {
    return {
        time   => 0,
        states => [],
    };
}

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OpenSky::Response::States - A class representing a states response from the OpenSky Network API

=head1 VERSION

version 0.5

=head1 DESCRIPTION

This class inherits from L<WebService::OpenSky::Response>. Please see that
module for the available methods. Individual responses are from the
L<WebService::OpenSky::Core::StateVector> class.

=head1 AUTHOR

Curtis "Ovid" Poe <curtis.poe@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023 by Curtis "Ovid" Poe.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

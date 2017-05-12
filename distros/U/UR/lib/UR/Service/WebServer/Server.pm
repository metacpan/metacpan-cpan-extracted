package UR::Service::WebServer::Server;

use strict;
use warnings;
use base 'HTTP::Server::PSGI';

# Override new because the default constructor doesn't accept a 'port' argument of
# undef to make the system pick a port
sub new {
    my($class, %args) = @_;

    my %supplied_port_arg;
    if (exists $args{port}) {
        $supplied_port_arg{port} = delete $args{port};
    }

    my $self = $class->SUPER::new(%args);
    if (%supplied_port_arg) {
        $self->{port} = $supplied_port_arg{port};
    }
    return $self;
}

sub listen_sock {
    return shift->{listen_sock};
}

# pre-fill read data for the test
sub buffer_input {
    my $self = shift;
    $self->{__buffer_input__} = shift;
}

sub read_timeout {
    my $self = shift;
    my($sock, $buf, $len, $off, $timeout) = @_;
    if ($self->{__buffer_input__}) {
        $$buf = ref $self->{__buffer_input__}
                ? $self->{__buffer_input__}->()
                : $self->{__buffer_input__};
        delete $self->{__buffer_input__};
        return length($$buf);
    }
    $self->SUPER::read_timeout(@_);
}

1;



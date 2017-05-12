package UR::Service::RPC::TcpConnectionListener;

use UR;

use strict;
use warnings;
our $VERSION = "0.46"; # UR $VERSION;

class UR::Service::RPC::TcpConnectionListener {
    is => 'UR::Service::RPC::Executer',
};

sub execute {
    my($self,$rpcserver) = @_;

    my $fh = $self->fh;

    my $socket = $fh->accept();

    unless ($self->authenticate($socket)) {
        $socket->close();
        return;
    }

    my $exec = $self->create_worker($socket);
    $rpcserver->add_executer($exec);
    return $exec;
}
    

# Sub classes can override this
sub authenticate {
#    my($self,$new_socket) = @_;

    return 1;
}

# Child classes can override either of these to get custom behavior
sub worker_class_name {
    'UR::Service::RPC::Executer';
}

sub create_worker {
    my($self,$new_socket) = @_;

    my $class = $self->worker_class_name;

    my $exec = $class->create(fh => $new_socket);
    return $exec;
}


1;

package UR::Service::RPC::Server;

use UR;
use IO::Select;

use strict;
use warnings;
our $VERSION = "0.47"; # UR $VERSION;

# We're going to be essentially reimplementing an Event queue here. :(

class UR::Service::RPC::Server {
    has => [
        'select' => { is => 'IO::Select' },
        timeout  => { is => 'Float', default_value => undef },
        executers  => { is => 'HASH', doc => 'maps file handles to the UR::Service::RPC::Executer objects we are working with' },
    ], 
};

sub create {
    my($class, %args) = @_;

    unless ($args{'executers'}) {
        $args{'executers'} = {};
    }
    
    unless ($args{'select'}) {
        my @fh = map { $_->fh } values %{$args{'executers'}};
        $args{'select'} = IO::Select->new(@fh);
    }

    my $self = $class->SUPER::create(%args);

    return $self;
}

sub add_executer {
    my($self,$executer,$fh) = @_;

    unless ($fh) {
        if ($executer->can('fh')) {
            $fh = $executer->fh;
        } else {
            $self->error_message("Cannot determine file handle for RPC executer $executer");
            return;
        }
    }

    $self->{'executers'}->{$fh} = $executer;
    $self->select->add($fh);
}

sub loop {
    my $self = shift;

    my $timeout;
    if (@_) {
        $timeout = shift;
    } else {
         $timeout = $self->timeout;
    }

    my @ready = $self->select->can_read($timeout);

    my $count = 0;
    foreach my $fh ( @ready ) {
        my $executer = $self->{'executers'}->{$fh};
        unless ($executer) {
            $self->error_message("Cannot determine RPC executer for file handle $fh fileno ",$fh->fileno);
            return;
        }

        $count++;
        unless ($executer->execute($self) ) {
            # they told us they were done
            $self->select->remove($fh);
            delete $self->{'executers'}->{$fh};
        }
    }

    return $count;
}

1;


=pod

=head1 NAME

UR::Service::RPC::Server - Class for implementing RPC servers

=head1 SYNOPSIS

  my $executer = Some::Exec::Class->create(fh => $fh);

  my $server = UR::Service::RPC::Server->create();
  $server->add_executer($executer);

  $server->loop(5);  # Process messages for 5 seconds

=head1 DESCRIPTION

The RPC server implementation isn't fleshed out very well yet, and may change
in the future.

=head1 METHODS

=over 4

=item add_executer

  $server->add_executer($exec);

Incorporate a new UR::Service::RPC::Executer instance to this server.  It
adds the Executer's filehandle to its own internal IO::Select object.

=item loop

  $server->loop();

  $server->loop(0);

  $server->loop($timeout);

Enter the Server's event loop for the given number of seconds.  If the timeout
is undef, it will stay in the loop forever.  If the timeout is 0, it will make
a single pass though the readable filehandles and call C<execute> on their
Executer objects.  

If the return value of an Executer's C<execute> method is false, that Executer's
file handle is removed from the internal Select object.

=back

=head1 SEE ALSO

UR::Service::RPC::Executer, UR::Service::RPC::Message

=cut

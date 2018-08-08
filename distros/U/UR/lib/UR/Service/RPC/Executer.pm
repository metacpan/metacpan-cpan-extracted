package UR::Service::RPC::Executer;

use UR;

use strict;
use warnings;
our $VERSION = "0.47"; # UR $VERSION;

class UR::Service::RPC::Executer {
    has => [
        fh => { is => 'IO::Handle', doc => 'handle we will send and receive messages across' },
    ],
    has_optional => [
        use_sigio => { is => 'Boolean', default_value => 0 },
    ],
    is_transactional => 0,
};


sub create {
    my $class = shift;

    my $obj = $class->SUPER::create(@_);
    return unless $obj;

    if ($obj->use_sigio) {
        UR::Service::RPC->enable_sigio_processing($obj);
    }

    $obj->create_subscription(method => 'use_sigio',
                              callback => sub {
                                  my ($changed_object, $changed_property, $old_value, $new_value) = @_;
                                  return 1 if ($old_value == $new_value);

                                  if ($new_value) {
                                      UR::Service::RPC->enable_sigio_processing($obj);
                                  } else {
                                      UR::Service::RPC->disable_sigio_processing($obj);
                                  }
                             });
    return $obj;
}


# sub classes can override this
# If they're going to reject the request, $msg should be modified in place
# with a return value and exception, because we're going to return it right back
# to the requester
sub authenticate {
#    my($self,$msg) = @_;
    return 1;
}

# Process one message off of the file handle
sub execute {
    my $self = shift;
    
    my $msg = UR::Service::RPC::Message->recv($self->fh);
    unless ($msg) {
        # The other end probably closed the socket
        $self->close_connection();
        return 1;
    }

    my $response;

    if ($self->authenticate($msg)) {

        my $target_class = $msg->target_class || ref($self);
        my $method = $msg->method_name;
        my @arglist = $msg->param_list;
        my $wantarray = $msg->wantarray;
        my %resp_msg_args = ( target_class => $target_class,
                              method_name  => $method,
                              params       => \@arglist,
                              'wantarray'  => $wantarray,
                              fh           => $self->fh );


        my $method_name = join('::',$target_class, $method);
        if (! $target_class->can($method)) {
            $resp_msg_args{exception} =
                qq(Can't locate object method "$method" via package "$target_class" (perhaps you forgot to load "$target_class"?));

        } else {
            local $@;
            if ($wantarray) {
                my @retval;
                eval { no strict 'refs'; @retval = &{$method_name}(@arglist); };
                $resp_msg_args{return_values} = \@retval unless ($@);
            } elsif (defined $wantarray) {
                my $retval;
                eval { no strict 'refs'; no warnings; $retval = &{$method_name}(@arglist); };
                $resp_msg_args{return_values} = [$retval] unless ($@);
            } else {
                eval { no strict 'refs'; &{$method_name}(@arglist); };
            }
            $resp_msg_args{exception} = $@ if $@;
        }
        $response = UR::Service::RPC::Message->create(%resp_msg_args);

    } else {
        # didn't authenticate.
        $response = $msg;
    }

    unless ($response->send()) {
        $self->fh->close();
    }

    return 1;
}



sub close_connection {
    my $self = shift;
  
    $self->use_sigio(0);

    $self->fh->close();
}

 
1;


=pod

=head1 NAME

UR::Service::RPC::Executer - Base class for modules implementing RPC executers

=head1 DESCRIPTION

This class is an abstract base class used to implement RPC executers.  That
is, modules meant to have their methods called from another process, and have
the results passed back to the original caller.  The communication happens
over a read-write filehandle such as a socket by passing L<UR::Service::RPC::Message>
objects back and forth.

Executors are subordinate to a L<UR::Service::RPC::Server> object which
handles decoding the message passed over the socket, calling the method
on the correct executor in the right context, and returning the result 
back through the file handle.

=head1 PROPERTIES

=over 4

=item fh => IO::Handle

File handle messages are received on and responses are sent to

=item use_sigio => Boolean

If true, the Server will set up a callback on the IO signal to handle
execution, so the Server does not need to block in loop().

=back

=head1 METHODS

=over 4

=item authenticate

  $bool = $exec->authenticate($msg);

This is called by execute() after the message object is deserialized from the
filehandle.  The default implementation just returns true.  Subclasses can
override this to examine the UR::Service::RPC::Message object and return 
true or fale whether it should allow or disallow execution.  If authentication
fails, the Executor should modify the Message object in-place with a proper
return value and exception.

=item execute

  $exec->execute();

Called when the Server detects data is available to read on its file handle.
It deserializes the message and calls authenticate.  If authentication fails,
it immediately passes the message object back to the caller.

If authentication succeeds, it calls the appropriate method in the Executor
package, and creates a new Message object with the return value to pass back
to the caller.

=item close_connection

  $exec->close_connection();

Called by execute() when it detects that the file handle has closed.

=back

Derived classes should define additional methods that then become callable
by execute().

=head1 SEE ALSO

UR::Service::RPC::Server, UR::Service::RPC::Message

=cut


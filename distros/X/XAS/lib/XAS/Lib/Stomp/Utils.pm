package XAS::Lib::Stomp::Utils;

our $VERSION = '0.03';

use XAS::Lib::Stomp::Frame;
use XAS::Constants ':stomp';

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'XAS::Base',
  utils   => ':validation',
  vars => {
    PARAMS => {
      -target  => { optional => 1, default => undef, regex => STOMP_LEVELS },
    }
  }
;

#use Data::Dumper;

# -----------------------------------------------------------
# Public Methods
# -----------------------------------------------------------

sub connect {
    my $self = shift;
    my $p = validate_params(\@_, {
        -login      => { optional => 1, default => undef },
        -passcode   => { optional => 1, default => undef },
        -host       => { optional => 1, default => 'localhost' },
        -heart_beat => { optional => 1, default => '0,0', regex => qr/\d+,\d+/ },
        -acceptable => { optional => 1, default => '1.0,1.1,1.2', 
            callbacks => {
                'valid target' => \&_match
            }
        }
    });

    my $frame;
    my $header = {};

    $header->{'login'}    = $p->{'login'}    if (defined($p->{'login'}));
    $header->{'passcode'} = $p->{'passcode'} if (defined($p->{'passcode'}));

    if ($self->target > 1.0) {

        $header->{'host'}           = $p->{'host'};
        $header->{'heart-beat'}     = $p->{'heart_beat'};
        $header->{'accept-version'} = $p->{'acceptable'};

    }

    $frame = XAS::Lib::Stomp::Frame->new(
        -command => 'CONNECT',
        -headers => $header,
        -body    => ''
    );

    return $frame;

}

sub stomp {
    my $self = shift;
    my $p = validate_params(\@_, {
        -login      => { optional => 1, default => undef },
        -passcode   => { optional => 1, default => undef },
        -prefetch   => { optional => 1, default => undef },
        -host       => { optional => 1, default => 'localhost' },
        -heart_beat => { optional => 1, default => '0,0', regex => qr/\d+,\d+/ },
        -acceptable => {
            optional => 1,
            default  => '1.0,1.1,1.2',
            callbacks => {
                'valid target' => \&_match
            }
        }
    });

    my $frame;
    my $header = {};

    if ($self->target == 1.0) {

        $self->throw_msg(
            'xas.lib.stomp.utils.stomp.nosup',
            'stomp_no_support',
            $self->target,
            'stomp'
        );

    }

    $header->{'login'}         = $p->{'login'}    if (defined($p->{'login'}));
    $header->{'passcode'}      = $p->{'passcode'} if (defined($p->{'passcode'}));
    $header->{'prefetch-size'} = $p->{'prefetch'} if (defined($p->{'prefetch'}));

    if ($self->target > 1.0) {

        $header->{'host'}           = $p->{'host'};
        $header->{'heart-beat'}     = $p->{'heart_beat'};
        $header->{'accept-version'} = $p->{'acceptable'};

    }

    $frame = XAS::Lib::Stomp::Frame->new(
        -command => 'STOMP',
        -headers => $header,
        -body    => ''
    );

    return $frame;

}

sub subscribe {
    my $self = shift;
    my $p = validate_params(\@_, {
        -destination  => 1,
        -prefetch     => { optional => 1, default => 0 },
        -id           => { optional => 1, default => undef },
        -receipt      => { optional => 1, default => undef },
        -ack          => { optional => 1, default => 'auto', regex => qr/auto|client|client\-individual/ }, 
    });

    my $frame;
    my $header = {};

    $header->{'ack'}            = $p->{'ack'};
    $header->{'prefetch-count'} = $p->{'prefetch'};
    $header->{'destination'}    = $p->{'destination'};
    $header->{'receipt'}        = $p->{'receipt'} if (defined($p->{'receipt'}));

    if (defined($p->{'id'})) {

        $header->{'id'} = $p->{'id'};

    } else {

        # v1.1 and greater must have an id header

        if ($self->target > 1.0) {

            $self->throw_msg(
                'xas.lib.stomp.utils.subscribe',
                'stomp_no_id',
                $self->target
                
            );

        }

    }

    $frame = XAS::Lib::Stomp::Frame->new(
        -command => 'SUBSCRIBE',
        -headers => $header,
        -body    => ''
    );

    return $frame;

}

sub unsubscribe {
    my $self = shift;
    my $p = validate_params(\@_, {
        -id           => { optional => 1, default => undef },
        -destination  => { optional => 1, default => undef },
        -receipt      => { optional => 1, default => undef },
    });

    my $frame;
    my $header = {};

    $header->{'receipt'} = $p->{'receipt'} if (defined($p->{'receipt'}));

    # v1.0 should have either a destination and/or id header
    # v1.1 and greater may have a destination header

    if (defined($p->{'destination'}) && defined($p->{'id'})) {

        $header->{'id'}          = $p->{'id'};
        $header->{'destination'} = $p->{'destination'};

    } elsif (defined($p->{'destination'})) {

        $header->{'destination'} = $p->{'destination'};

    } elsif (defined($p->{'id'})) {

        $header->{'id'} = $p->{'id'};

    } else {

        $self->throw_msg(
            'xas.lib.stomp.utils.unsubscribe.invparams',
            'stomp_invalid_params',
            $self->target
        );

    }

    if ($self->target > 1.0) {

        # v1.1 and greater must have an id header

        unless (defined($header->{'id'})) {

            $self->throw_msg(
                'xas.lib.stomp.utils.unsubscribe.noid',
                'stomp_no_id',
                $self->target
            );

        }

    }

    $frame = XAS::Lib::Stomp::Frame->new(
        -command => 'UNSUBSCRIBE',
        -headers => $header,
        -body    => ''
    );

    return $frame;

}

sub begin {
    my $self = shift;
    my $p = validate_params(\@_, {
        -transaction => 1,
        -receipt     => { optional => 1, default => undef },
    });

    my $frame;
    my $header = {};

    $header->{'transaction'} = $p->{'transaction'};
    $header->{'receipt'}     = $p->{'receipt'} if (defined($p->{'receipt'}));

    $frame = XAS::Lib::Stomp::Frame->new(
        -command => 'BEGIN',
        -headers => $header,
        -body    => ''
    );

    return $frame;

}

sub commit {
    my $self = shift;
    my $p = validate_params(\@_, {
        -transaction => 1,
        -receipt     => { optional => 1, default => undef },
    });

    my $frame;
    my $header = {};

    $header->{'transaction'} = $p->{'transaction'};
    $header->{'receipt'}     = $p->{'receipt'} if (defined($p->{'receipt'}));

    $frame = XAS::Lib::Stomp::Frame->new(
        -command => 'COMMIT',
        -headers => $header,
        -body    => ''
    );

    return $frame;

}

sub abort {
    my $self = shift;
    my $p = validate_params(\@_, {
        -transaction => 1,
        -receipt     => { optional => 1, default => undef },
    });

    my $frame;
    my $header = {};

    $header->{'transaction'} = $p->{'transaction'};
    $header->{'receipt'}     = $p->{'receipt'} if (defined($p->{'receipt'}));

    $frame = XAS::Lib::Stomp::Frame->new(
        -command => 'ABORT',
        -headers => $header,
        -body    => ''
    );

    return $frame;

}

sub ack {
    my $self = shift;
    my $p = validate_params(\@_, {
        -message_id   => 1,
        -subscription => { optional => 1, default => undef },
        -receipt      => { optional => 1, default => undef },
        -transaction  => { optional => 1, default => undef },
    });

    my $frame;
    my $header = {};

    $header->{'receipt'}     = $p->{'receipt'}     if (defined($p->{'receipt'}));
    $header->{'transaction'} = $p->{'transaction'} if (defined($p->{'transaction'}));

    if ($self->target < 1.2) {

        $header->{'message-id'} = $p->{'message_id'};

    } else {

        $header->{'id'} = $p->{'message_id'};

    }

    if (defined($p->{'subscription'})) {

        $header->{'subscription'} = $p->{'subscription'};

    } else {

        if ($self->target > 1.0) {

            $self->throw_msg(
                'xas.lib.stomp.utils.ack.nosup',
                'stomp_no_subscription',
                $self->target
            );

        }

    }

    $frame = XAS::Lib::Stomp::Frame->new(
        -command => 'ACK',
        -headers => $header,
        -body    => ''
    );

    return $frame;

}

sub nack {
    my $self = shift;
    my $p = validate_params(\@_, {
        -message_id   => 1,
        -receipt      => { optional => 1, default => undef },
        -subscription => { optional => 1, default => undef },
        -transaction  => { optional => 1, default => undef },
    });

    my $frame;
    my $header = {};

    $header->{'receipt'}     = $p->{'receipt'}     if (defined($p->{'receipt'}));
    $header->{'transaction'} = $p->{'transaction'} if (defined($p->{'transaction'}));

    if ($self->target == 1.0) {

        $self->throw_msg(
            'xas.lib.stomp.utils.nack',
            'stomp_no_support',
            $self->target,
            'nack'
        );

    }

    if ($self->target < 1.2) {

        $header->{'message-id'} = $p->{'message_id'};

    } else {

        $header->{'id'} = $p->{'message_id'};

    }

    if (defined($p->{'subscription'})) {

        $header->{'subscription'} = $p->{'subscription'};

    } else {

        if ($self->target > 1.0) {

            $self->throw_msg(
                'xas.lib.stomp.utils.nact',
                'stomp_no_support',
                $self->target,
                'nack'
            );

        }

    }

    $frame = XAS::Lib::Stomp::Frame->new(
        -command => 'NACK',
        -headers => $header,
        -body    => ''
    );

    return $frame;

}

sub disconnect {
    my $self = shift;
    my $p = validate_params(\@_, {
        -receipt => { optional => 1, default => undef }
    });

    my $frame;
    my $header = {};

    $header->{'receipt'} = $p->{'receipt'} if (defined($p->{'receipt'}));

    $frame = XAS::Lib::Stomp::Frame->new(
        -command => 'DISCONNECT',
        -headers => $header,
        -body    => ''
    );

    return $frame;

}

sub send {
    my $self = shift;
    my $p = validate_params(\@_, {
        -destination => 1,
        -message     => 1,
        -receipt     => { optional => 1, default => undef },
        -persistent  => { optional => 1, default => undef },
        -transaction => { optional => 1, default => undef },
        -length      => { optional => 1, default => undef },
        -type        => { optional => 1, default => 'text/plain' },
    });

    my $frame;
    my $header = {};
    my $body = $p->{'message'};

    $header->{'destination'} = $p->{'destination'};
    $header->{'receipt'}     = $p->{'receipt'}     if (defined($p->{'receipt'}));
    $header->{'persistent'}  = $p->{'persistent'}  if (defined($p->{'presistent'}));
    $header->{'transaction'} = $p->{'transaction'} if (defined($p->{'transaction'}));
    {
        use bytes;
        $header->{'content-length'} = defined($p->{'length'}) ? $p->{'length'} : length($body);
    }

    if ($self->target > 1.0) {

        $header->{'content-type'} = $p->{'type'};

    }

    $frame = XAS::Lib::Stomp::Frame->new(
        -command => 'SEND',
        -headers => $header,
        -body    => $body
    );

    return $frame;

}

sub noop {
    my $self = shift;

    my $frame;

    if ($self->target == 1.0) {

        $self->throw_msg(
            'xas.lib.stomp.utils.noop.nosup',
            'stomp_no_support',
            $self->target,
            'noop'
        );

    }

    $frame = XAS::Lib::Stomp::Frame->new(
        -command => 'NOOP',
        -headers => {},
        -body    => ''
    );

    return $frame;

}

# -----------------------------------------------------------
# Private Methods
# -----------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    unless (defined($self->{target})) {

        $self->{target} = $self->env->mqlevel;

    }

    return $self;

}

sub _match {
    my $buffer = shift;

    foreach my $item (split(',', $buffer)) {

        return 0 if ($item !~ m/\d\.\d/);

    }

    return 1;

}

1;

__END__

=head1 NAME 

XAS::Lib::Stomp::Utils - STOMP protocol utilities for clients

=head1 SYNOPSIS

This module uses XAS::Lib::Stomp::Frame to create STOMP frames.

 use XAS::Lib::Stomp::Utils;

 my $stomp = XAS::Lib::Stomp::Utils->new();
 my $frame = $stomp->connect(
     -login    => 'test', 
     -passcode => 'test'
 );

 put($frame->to_string);

=head1 DESCRIPTION

This module is an easy way to create STOMP frames without worrying about
the various differences between the protocol versions.

=head1 METHODS

=head2 new

This method initializes the base object. It takes the following parameters:

=head2 connect

This method creates a "CONNECT" frame. This frame is used to initiate a
session with a STOMP server. On STOMP v1.1 and later targets the following 
headers are automatically set: 

  host
  heart-beat
  accept-version

Unless otherwise specified, they will be the defaults. This method takes the 
following parameters:

=over 4 

=item B<-login>

An optional login name to be used on the STOMP server.

=item B<-passcode>

An optional password for the login name on the STOMP server.

=item B<-host>

An optional virtual host name to connect to on STOMP v1.1 and later servers.
Defaults to 'localhost'.

=item B<-heart_beat>

An optional heart beat request for STOMP v1.1 and later servers. The default
is to turn them off.

=item B<-acceptable>

An optional list of protocol versions that are acceptable to this client for
STOMP v1.1 and later clients. The default is '1.0,1.1,1.2'.

=item B<-prefetch>

This sets the optional header 'prefetch-size' for RabbitMQ or other servers
that support this extension.

=back

=head2 stomp

This method creates a "STOMP" frame, this works the same as connect(), but 
only works for STOMP v1.1 and later targets. Please see the documentation for 
connect().

=head2 disconnect

This method creates a "DISCONNECT" frame. This frame is used to signal the
server that you no longer wish to communicate with it. This method takes the
following parameters:

=over 4

=item B<-receipt>

An optional receipt that will be returned by the server.

=back

=head2 subscribe

This method create a "SUBSCRIBE" frame. This frame is used to notify 
the server which queues you want to listen too. The naming of queues is 
left up to the server implementation. This method takes the following
parameters:

=over 4

=item B<-destination>

The name of the queue you wish to subscribe too. Naming convention is
server dependent.

=item B<-subscription>

A mandatory subscription id for usage on STOMP v1.1 and later targets. It 
has no meaning for STOMP v1.0 servers.

=item B<-ack>

The type of acknowledgement you would like to receive when messages are sent
to a queue. It defaults to 'auto'. It understands 'auto', 'client' and 
'client-individual'. Please refer to the STOMP protocol reference for 
what this means.

=item B<-receipt>

An optional receipt that will be returned by the server.

=back

=head2 unsubscribe

This method creates an "UNSUBSCRIBE" frame. This frame is used to notify the
server that you don't want to subscribe to a queue anymore. Subsequently
any messages left on that queue will no longer be sent to your client.

=over 4

=item B<-destination>

The optional name of the queue that you subscribed too. STOMP v1.0 targets
need a queue name and/or a subscription id to unsubscribe. This is optional 
on v1.1 and later targets.

=item B<-subscription>

The id of the subscription, this should be the same as the one used 
with subscribe(). This is optional on STOMP v1.0 servers and mandatory
on v1.1 and later targets.

=item B<-receipt>

An optional receipt that will be returned by the server.

=back

=head2 begin

This method creates a "BEGIN" frame. This frame signals the server that a 
transaction is beginning. A transaction is either ended by a "COMMIT" frame 
or an "ABORT" frame. Any other frame that is sent must have a transaction id
associated with them. This method takes the following parameters:

=over 4

=item B<-transaction>

The mandatory id for the transaction.

=item B<-receipt>

An optional receipt that will be returned by the server.

=back

=head2 commit

This method creates a "COMMIT" frame. This frame signals the end of a 
transaction. This method takes the following parameters:

=over 4

=item B<-transaction>

The mandatory transaction id from begin().

=item B<-receipt>

An optional receipt that will be returned by the server.

=back

=head2 abort

This method creates an "ABORT" frame. This frame is used to signal the server
that the current transaction is to be aborted.

This method takes the following parameters:

=over 4

=item B<-transaction>

The mandatory transaction id from begin().

=item B<-receipt>

An optional receipt that will be returned by the server.

=back

=head2 send

This method creates a "SEND" frame. This frame is the basis of communication
over your queues to the server. This method takes the following parameters:

=over 4

=item B<-destination>

The name of the queue to send the message too.

=item B<-message>

The message to be sent. No attempt is made to serializes the message.

=item B<-transaction>

An optional transaction number. This should be the same as for begin().

=item B<-length>

An optional length for the message. If one is not specified a 
'content-length' header will be auto generated.

=item B<-type>

An optional MIME type for the message. If one is not specified, 'text/plain'
will be used. This only has meaning for STOMP v1.1 and later targets.

=item B<-persistent>

An optional header for indicating that this frame should be 'persisted' by
the server. What this means, is highly server specific.

=item B<-receipt>

An optional receipt that will be returned by the server.

=back

=head2 ack

This method creates an "ACK" frame. This frame is used to tell the server that 
the message was successfully received. This method takes the following 
parameters:

=over 4

=item B<-message_id>

The id of the message that is being acked.

=item B<-subscription>

This should match the id from the subscribe() method. This has meaning for
STOMP v1.1 and later targets.

=item B<-transaction>

The transaction id if this ack is part of a transaction.

=item B<-receipt>

An optional receipt that will be returned by the server.

=back

=head2 nack

This method creates a "NACK" frame. It notifies the server that the message 
was rejected. It has meaning on STOMP v1.1 and later targets. This method
takes the following parameters:

=over 4

=item B<-message_id>

The id of the message that is being nacked.

=item B<-subscription>

This should match the id from the subscribe() method. This has meaning for
STOMP v1.1 and later targets.

=item B<-transaction>

The transaction id if this nack is part of a transaction.

=item B<-receipt>

An optional receipt that will be returned by the server.

=back

=head2 noop

This method creates a "NOOP" frame. It has meaning on STOMP v1.1 and 
later targets. 

=head1 SEE ALSO

=over 4

=item L<Net::Stomp|https://metacpan.org/pod/Net::Stomp>

=item L<Net::Stomp::Frame|https://metacpan.org/pod/Net::Stomp::Frame>

=item L<XAS|XAS>

=back

For more information on the STOMP protocol, please refer to: L<http://stomp.github.io/> .

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut

package Zabbix::Sender;
# ABSTRACT: A pure-perl implementation of zabbix-sender.
$Zabbix::Sender::VERSION = '0.07';
use Moo;
use namespace::autoclean;

use Carp;
use JSON;
use IO::Socket;
use IO::Select;
use Net::Domain;
use Types::Standard -types;


has 'server' => (
    'is'       => 'rw',
    'isa'      => Str,
    'required' => 1,
);

has 'port' => (
    'is'      => 'rw',
    'isa'     => Int,
    'default' => 10051,
);

has 'timeout' => (
    'is'      => 'rw',
    'isa'     => Int,
    'default' => 30,
);

has 'hostname' => (
    'is'      => 'rw',
    'isa'     => Str,
    'lazy'    => 1,
    'builder' => '_init_hostname',
);

has 'interval' => (
    'is'      => 'rw',
    'isa'     => Int,
    'default' => 1,
);

has 'retries' => (
    'is'      => 'rw',
    'isa'     => Int,
    'default' => 3,
);

has 'keepalive' => (
    'is'    => 'rw',
    'isa'   => Bool,
    'default' => 0,
);

has '_json' => (
    'is'      => 'rw',
    'isa'     => InstanceOf['JSON'],
    'lazy'    => 1,
    'builder' => '_init_json',
);

has '_last_sent' => (
    'is'      => 'rw',
    'isa'     => Int,
    'default' => 0,
);

has '_socket' => (
    'is'    => 'rw',
    'isa'   => Maybe[ InstanceOf['IO::Socket'] ],
);

has 'response' => (
    'is'    => 'rw',
    'isa'   => HashRef,
    'default'   => sub { {} },
);

has 'bulk_buf' => (
    'is'    => 'rw',
    'isa'   => ArrayRef,
    'default'   => sub { [] },
);

has '_info' => (
    'is'    => 'rw',
    'isa'      => Str,
);

has 'strict' => (
    'is'    => 'rw',
    'isa'   => Bool,
    'default' => 0,
);



sub _init_json {
    my $self = shift;

    my $JSON = JSON::->new->utf8();

    return $JSON;
}


sub _init_hostname {
    my $self = shift;

    return Net::Domain::hostname() . '.' . Net::Domain::hostdomain();
}


has 'zabbix_template_1_8' => (
    'is'      => 'ro',
    'isa'     => Str,
    'default' => "a4 b V V a*",
);


sub _encode_request {
    my $self  = shift;
    my $values = shift;

    my @data;
    for my $ref (@{$values}) {
        my %data = (
            'host'  => $ref->[0],
            'key'   => $ref->[1],
            'value' => $ref->[2],
        );
        $data{'clock'} = $ref->[3]
            if $ref->[3];
        push @data, \%data;
    }

    my $data = {
        'request' => 'sender data',
        'data'    => \@data,
    };

    my $output = '';
    my $json   = $self->_json()->encode($data);

    # turn on byte semantics to get the real length of the string
    use bytes;
    my $length = length($json);
    no bytes;

    ## no critic (ProhibitBitwiseOperators)
    $output = pack(
        $self->zabbix_template_1_8(),
        "ZBXD", 0x01,
        $length, 0x00,
        $json
    );
    ## use critic

    return $output;
}


sub _check_info {
    my $self = shift;
    if($self->_info() !~ /^Processed:?\s+(\d+);?\s+Failed:?\s+(\d+);?\s+Total:?\s+(\d+);?\s+Seconds\s+spent:?\s+\d+.\d+$/i )
    {
        return "Failed to parse info from zabbix server: ", $self->_info();
    }
    my($processed, $failed, $total) = (int($1), int($2), int($3));
    return if $processed eq $total and $failed eq 0;
    return "(Processed, failed, total) != (x, 0, x) in info from zabbix server: ", $self->_info()
}


sub _decode_answer {
    my $self = shift;
    my $data = shift;

    $self->_info('');
    my ( $ident, $answer );
    $ident = substr( $data, 0, 4 ) if length($data) > 3;
    if ($ident and $ident eq 'ZBXD') {
        # Headers are optional since Zabbix 2.0.8 and 2.1.7
        if (length($data) > 12) {
            $answer = substr( $data, 13 );
        } else {
            carp "Invalid response header received: '$data' (length: ", length($data), ")";
            return;
        }
    } else {
        $answer = $data;
    }

    if ( $answer ) {
        my $ref = $self->_json()->decode($answer);
        if ($ref) {
            $self->response($ref);
            if ( $ref->{'response'} eq 'success' ) {
                $self->_info($ref->{'info'});
                if($self->strict())
                {
                    my $msg = $self->_check_info();
                    carp $msg if $msg;
                    return 0 if $msg;
                }
                return 1;
            }
            return $ref->{'response'} eq 'success' ? 1 : '';
        } else {
            $self->response(undef);
        }
    }
    return;
}


# DGR: Anything but send just doesn't makes sense here. And since this is a pure-OO module
# and if the implementor avoids indirect object notation you should be fine.
## no critic (ProhibitBuiltinHomonyms)
sub send {
## use critic
    my $self  = shift;
    my $item  = shift;
    my $value = shift;
    my $clock = shift || time;

    my $data = $self->_encode_request( [ [ $self->hostname(), $item, $value, $clock ] ] );
    my $status = 0;
    foreach my $i ( 1 .. $self->retries() ) {
        if ( $self->_send( $data ) ) {
            $status = 1;
            last;
        }
    }

    if ($status) {
        return $self->response;
    }
    else { ## Should this die/croak/warn? Is this for timeout?
        return;
    }

}

sub _send {
    my $self  = shift;
    my $data  = shift;

    if ( time() - $self->_last_sent() < $self->interval() ) {
        my $sleep = $self->interval() - ( time() - $self->_last_sent() );
        $sleep ||= 0;
        sleep $sleep;
    }

    unless ($self->_socket()) {
        return
            unless $self->_connect();
    }
    $self->_socket()->send( $data );
    my $Select  = IO::Select::->new($self->_socket());
    my $status = 0;
    my $recvstarttime = time;
    my $reply = '';
    while($recvstarttime + $self->timeout() > time)
    {
      my @Handles = $Select->can_read( $self->timeout() );

      if ( scalar(@Handles) > 0 ) {
        my $result;
        $self->_socket()->recv( $result, 1024 );
        $reply .= $result;
        next if length($reply) < 13;
        # we need to recv until we have read either as much data as indicated
        # in the header or there is an error.  so we have to decode the header
        # here, before calling _decode_answer.
        my($ZBXD, $one, $len1, $len2, $json) = unpack 'A4 C V2 A*', $reply;
        my $expected_length = 13 + $len1 + ($len2 << 32);
        next if length($reply) < $expected_length;
        if ( $self->_decode_answer($reply) ) {
            $status = 1;
        }
        last;
      }
    }
    $self->_disconnect() unless $self->keepalive();
    if ($status) {
        return $status;
    }
    else {
        return;
    }
}

sub _connect {
    my $self = shift;

    my $Socket = IO::Socket::INET::->new(
        PeerAddr => $self->server(),
        PeerPort => $self->port(),
        Proto    => 'tcp',
        Timeout  => $self->timeout(),
    ) or return;

    $self->_socket($Socket);

    return 1;
}

sub _disconnect {
    my $self = shift;

    if(!$self->_socket()) {
        return;
    }

    $self->_socket()->close();
    $self->_socket(undef);

    return 1;
}


sub bulk_buf_add {
    my $self = shift;

    my @values;
    while (@_) {
        my $arg = shift;
        if ($arg) {
            if (ref $arg) {
                if (ref $arg eq 'ARRAY' and (@{$arg} == 2 or @{$arg} == 3)) {
                    # Array of (key, value[, clock])
                    push @values, [ $self->hostname(),
                        $arg->[0], $arg->[1], $arg->[2] || time ];
                } else {
                    carp "Invalid argument: Expected ARRAY with 2 or 3 elements";
                    return;
                }
            } else {
                my $arg2 = shift;
                if ($arg2) {
                    if (ref $arg2) {
                        unless (ref $arg2 eq 'ARRAY') {
                            carp "Invalid argument: Expected ARRAY";
                            return;
                        }
                        my $hostname = $arg;
                        for my $ref (@{$arg2}) {
                            if (ref $ref and ref $ref eq 'ARRAY'
                                    and (@{$ref} == 2 or @{$ref} == 3)) {
                                # (key, value[, clock])
                                $ref->[2] = time
                                    unless $ref->[2];
                                push @values, [ $hostname, $ref->[0],
                                    $ref->[1], $ref->[2] || time ];
                            } else {
                                carp "Invalid argument: ARRAY had not 2 or 3 elements";
                                return;
                            }
                        }
                    } else {
                        # (key, value[, clock])
                        my $key = $arg;
                        my $value = $arg2;
                        my $clock = shift || time;
                        push @values, [ $self->hostname(), $key, $value, $clock ];
                    }
                } else {
                    carp "Insufficient number of arguments";
                    return;
                }
            }
        } else {
            carp "Insufficient number of arguments";
            return;
        }
    }

    push @{$self->bulk_buf()}, @values;
    return 1;
}


sub bulk_buf_clear {
    my $self = shift;

    $self->bulk_buf([]);
}


sub bulk_send {
    my $self  = shift;

    if (@_) {
        $self->bulk_buf_add(@_)
            or return;
    }

    my $data = $self->_encode_request( $self->bulk_buf() );
    my $status = 0;
    foreach my $i ( 1 .. $self->retries() ) {
        if ( $self->_send( $data ) ) {
            $status = 1;
            last;
        }
    }

    if ($status) {
        $self->bulk_buf_clear();
        return 1;
    }
    else {
        return;
    }

}


sub DEMOLISH {
    my $self = shift;

    $self->_disconnect();

    return 1;
}

no Moose;
__PACKAGE__->meta->make_immutable;


1;    # End of Zabbix::Sender

__END__

=pod

=encoding UTF-8

=head1 NAME

Zabbix::Sender - A pure-perl implementation of zabbix-sender.

=head1 VERSION

version 0.07

=head1 SYNOPSIS

This code snippet shows how to send the value "OK" for the item "my.zabbix.item"
to the zabbix server/proxy at "my.zabbix.server.example" on port "10055".

    use Zabbix::Sender;

    my $Sender = Zabbix::Sender->new({
       'server' => 'my.zabbix.server.example',
       'port' => 10055,
    });
    $Sender->send('my.zabbix.item','OK');

=head1 NAME

Zabbix::Sender - A pure-perl implementation of zabbix-sender.

=head1 SUBROUTINES/METHODS

=head2 hostname

Name of the host for which to submit items to Zabbix.  Initialized by _init_hostname. You can set it either using

   $Sender->hostname('another.hostname');

or during creation time of Zabbix::Sender

    my $Sender = Zabbix::Sender->new({
        'server' => 'my.zabbix.server.example',
        'hostname' => 'another.hostname',
    });

You can also query the current setting using

    my $current_hostname = $Sender->hostname();

=head2 strict

Use the strict setting to make Zabbix::Sender check the return values from
Zabbix:

    $Sender->strict(1);

You can also query the current setting using

    my $is_strict = $Sender->strict();

=head2 _init_json

Zabbix 1.8 uses a JSON encoded payload after a custom Zabbix header.
So this initializes the JSON object.

=head2 _init_hostname

The hostname of the sending instance may be given in the constructor.

If not it is detected here.

=head2 zabbix_template_1_8

ZABBIX 1.8 TEMPLATE

a4 - ZBXD
b  - 0x01
V - Length of Request in Bytes (64-bit integer), aligned left, padded with 0x00, low 32 bits
V - High 32 bits of length (always 0 in Zabbix::Sender)
a* - JSON encoded request

This may be changed to a HashRef if future version of zabbix change the header template.

=head2 _encode_request

This method encodes values as a json string and creates
the required header according to the template defined above.

=head2 _check_info

Checks the return value from the Zabbix server (or Zabbix proxy),
which states the number of processed, failed and total values.
Returns undef if everything is alright, a message otherwise.

This method is called when the strict setting of Zabbix::Sender
is active:

    my $Sender = Zabbix::Sender->new({
        'server' => 'my.zabbix.server.example',
        'strict' => 1,
    });

=head2 _decode_answer

This method tries to decode the answer received from the server.

Returns true if response indicates success, false if response indicates
failure, undefined value if response was empty or cannot be decoded.

Method "response" may be used to return decoded response.

=head2 send

Send the given item with the given value to the server.

Takes two or three scalar arguments: item key, value and clock (clock is
optional).

=head2 bulk_buf_add

Adds values to the stack of values to bulk_send.

It accepts arguments in forms:

$sender->bulk_buf_add($key, $value, $clock, ...);
$sender->bulk_buf_add([$key, $value, $clock], ...);
$sender->bulk_buf_add($hostname, [ [$key, $value, $clock], ...], ...);

Last form allows to add values for several hosts at once.

$clock is optional and may be undef, empty or omitted.

Returns true if successful or undef if invalid arguments are specified.

=head2 bulk_buf_clear

Clear bulk_send buffer.

=head2 bulk_send

Send accumulated values to the server.

It accepts the same arguments as bulk_buf_add. If arguments are specified,
they are added to the buffer before sending.

=head2 DEMOLISH

Disconnects any open sockets on destruction.

=head1 AUTHOR

"Dominik Schulz", C<< <"lkml at ds.gauner.org"> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-zabbix-sender at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Zabbix-Sender>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Zabbix::Sender

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Zabbix-Sender>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Zabbix-Sender>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Zabbix-Sender>

=item * Search CPAN

L<http://search.cpan.org/dist/Zabbix-Sender/>

=back

=head1 ACKNOWLEDGEMENTS

This code is based on the documentation and sample code found at:

=over 4

=item http://www.zabbix.com/documentation/1.8/protocols

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Dominik Schulz.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

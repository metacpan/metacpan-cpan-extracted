package XAS::Lib::SSH::Client;

our $VERSION = '0.01';

use IO::Select;
use Errno 'EAGAIN';
use Net::SSH2 ':all';

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Base',
  mixin     => 'XAS::Lib::Mixins::Bufops',
  accessors => 'ssh chan sock select exit_code exit_signal',
  mutators  => 'attempts', 
  utils     => ':validation dotid trim',
  import    => 'class',
  vars => {
    PARAMS => {
      -port      => { optional => 1, default => 22 },
      -timeout   => { optional => 1, default => 0.2 },
      -username  => { optional => 1, default => undef},
      -host      => { optional => 1, default => 'localhost' },
      -eol       => { optional => 1, default => "\015\012" },
      -password  => { optional => 1, default => undef, depends => [ 'username' ] },
      -priv_key  => { optional => 1, default => undef, depends => [ 'pub_key', 'username' ] },
      -pub_key   => { optional => 1, default => undef, depends => [ 'priv_key', 'username' ] },
    },
    ERRNO  => 0,
    ERRSTR => '',
  }
;

#use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub connect {
    my $self = shift;

    my ($errno, $name, $errstr);

    $self->class->var('ERRNO', 0);
    $self->class->var('ERRSTR', '');

    if ($self->ssh->connect($self->host, $self->port)) {

        if ($self->pub_key) {

            unless ($self->ssh->auth_publickey($self->username,
                    $self->pub_key, $self->priv_key)) {

                ($errno, $name, $errstr) = $self->ssh->error();

                $self->class->var('ERRNO', $errno);
                $self->class->var('ERRSTR', $errstr);

                $self->throw_msg(
                    dotid($self->class) . '.autherr',
                    'ssh_client_autherr',
                    $name, $errstr
                );

            }

        } else {

            unless ($self->ssh->auth_password($self->username, $self->password)) {

                ($errno, $name, $errstr) = $self->ssh->error();

                $self->class->var('ERRNO', $errno);
                $self->class->var('ERRSTR', $errstr);

                $self->throw_msg(
                    dotid($self->class) . '.autherr',
                    'ssh_client_autherr',
                    $name, $errstr
                );

            }

        }

        $self->{'sock'}   = $self->ssh->sock();
        $self->{'chan'}   = $self->ssh->channel();
        $self->{'select'} = IO::Select->new($self->sock);

        $self->setup();

    } else {

        ($errno, $name, $errstr) = $self->ssh->error();

        $self->class->var('ERRNO', $errno);
        $self->class->var('ERRSTR', $errstr);

        $self->throw_msg(
            dotid($self->class) . '.conerr',
            'ssh_client_conerr',
            $name, $errstr
        );

    }

}

sub setup {
    my $self = shift;

}

sub pending {
    my $self = shift;

    return length($self->{'buffer'});

}

sub disconnect {
    my $self = shift;

    if (my $chan = $self->chan) {

        $chan->send_eof();
        $chan->close();

    }

    if (my $ssh = $self->ssh) {

        $ssh->disconnect();

    }

}

sub get {
    my $self = shift;
    my ($length) = validate_params(\@_, [
        { optional => 1, default => 512 }
    ]);

    my $output = '';

    # extract $length from buffer. if the buffer size is > $length then
    # try to refill buffer. If there is nothing to read, then return
    # the remainder of the buffer.
    #
    # Patterned after some libssh2 examples and C network programming
    # "best practices".

    if ($self->pending > $length) {

        $output = $self->buf_slurp(\$self->{'buffer'}, $length);

    } else {

        $self->_fill_buffer();

        my $l = ($self->pending > $length) ? $length : $self->pending;
        $output = $self->buf_slurp(\$self->{'buffer'}, $l);

    }

    return $output;

}

sub gets {
    my $self = shift;

    my $buffer;
    my $output = '';

    while (my $buf = $self->get()) {

        $buffer .= $buf;

        if ($output = $self->buf_get_line(\$buffer, $self->eol)) {

            $self->{'buffer'} = $buffer . $self->{'buffer'};
            last;

        }

    }

    return trim($output);

}

sub put {
    my $self = shift;
    my ($buffer) = validate_params(\@_, [1]);

    my $counter = 0;
    my $working = 1;
    my $written = 0;
    my $bufsize = length($buffer);

    $self->class->var('ERRNO', 0);
    $self->class->var('ERRSTR', '');

    # Setup non-blocking writes. Keep writting until nothing is left.
    # Returns the number of bytes written, if any.
    #
    # Patterned after some libssh2 examples and C network programming
    # "best practices".

    $self->chan->blocking(0);

    do {

        if (my $bytes = $self->chan->write($buffer)) {

            $written += $bytes;
            $buffer  = substr($buffer, $bytes);
            $working = 0 if ($written >= $bufsize);

        } else {

            my ($errno, $name, $errstr) = $self->ssh->error();
            if ($errno == LIBSSH2_ERROR_EAGAIN) {

                $counter++;

                $working = 0         if ($counter > $self->attempts);
                $self->_waitsocket() if ($counter <= $self->attempts);

            } else {

                $self->chan->blocking(1);

                $self->class->var('ERRNO', $errno);
                $self->class->var('ERRSTR', $errstr);

                $self->throw_msg(
                    dotid($self->class) . '.protoerr',
                    'ssh_client_protoerr',
                    $name, $errstr
                );

            }

        }

    } while ($working);

    $self->chan->blocking(1);

    return $written;

}

sub puts {
    my $self = shift;
    my ($buffer) = validate_params(\@_, [1]);

    my $output  = sprintf("%s%s", trim($buffer), $self->eol);
    my $written = $self->put($output);

    return $written;

}

sub errno {
    my $class = shift;
    my ($value) = validate_params(\@_, [
        { optional => 1, default => undef }
    ]);

    class->var('ERRNO', $value) if (defined($value));

    return class->var('ERRNO');

}

sub errstr {
    my $class = shift;
    my ($value) = validate_params(\@_, [
        { optional => 1, default => undef }
    ]);

    class->var('ERRSTR', $value) if (defined($value));

    return class->var('ERRSTR');

}

sub DESTROY {
    my $self = shift;

    $self->disconnect();

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->{'ssh'} = Net::SSH2->new();
    $self->{'buffer'} = '';

    $self->attempts(5);       # number of EAGAIN attempts

    return $self;

}

sub _fill_buffer {
    my $self = shift;

    my $read     = 0;
    my $counter  = 0;
    my $working  = 1;

    # Setup non-blocking read. Keep reading until nothing is left.
    # i.e. the reads timeout.

    $self->chan->blocking(0);

    while ($working) {

        my $buf;

        if (my $bytes = $self->chan->read($buf, 512)) {

            $self->{'buffer'} .= $buf;
            $read += $bytes;

        } else {

            my $syserr = $! + 0;
            my ($errno, $name, $errstr) = $self->ssh->error();

            if (($errno == LIBSSH2_ERROR_EAGAIN) || ($syserr == EAGAIN)) {

                $counter++;
 
                $working = 0         if ($counter >  $self->attempts);
                $self->_waitsocket() if ($counter <= $self->attempts);

            } else {

                $self->chan->blocking(1);

                $self->class->var('ERRNO', $errno);
                $self->class->var('ERRSTR', $errstr);

                $self->throw_msg(
                    dotid($self->class) . '.protoerr',
                    'ssh_client_protoerr',
                    $name, $errstr
                );

            }

        }

    }

    $self->chan->blocking(1);

    return $read;

}
    
sub _waitsocket {
    my $self = shift;

    my $to  = $self->timeout;
    my $dir = $self->ssh->block_directions();

    # If $dir is 1, then input  is blocking.
    # If $dir is 2, then output is blocking.
    #
    # Patterned after some libssh2 examples.

    if ($dir == 1) {

        $self->select->can_read($to);

    } else {

        $self->select->can_write($to);

    }

    return $! + 0;

}

1;

__END__

=head1 NAME

XAS::Lib::SSH::Client - A SSH based client

=head1 SYNOPSIS

 use XAS::Lib::SSH::Client;

 my $client = XAS::Lib::SSH::Client->new(
    -host    => 'auburn-xen-01',
    -username => 'root',
    -password => 'secret',
 );

 $client->connect();
 
 $client->put($data);
 $data = $client->get();

 $client->disconnect();

=head1 DESCRIPTION

The module provides basic network connectivity along with input/output methods
using the SSH protocol. It can authenticate using username/password or
username/public key/private key/password. 

=head1 METHODS

=head2 new

This initializes the object. It takes the following parameters:

=over 4

=item B<-username>

An optional username to use when connecting to the server.

=item B<-password>

An optional password to use for authentication.

=item B<-pub_key>

An optional public ssh key file to use.

=item B<-priv_key>

An optional private ssh key to use.

=item B<-host>

The server to connect too. Defaults to 'localhost'.

=item B<-port>

The port to use on the server. It defaults to 22.

=item B<-timeout>

The number of seconds to timeout writes. It must be compatible with IO::Select.
Defaults to 0.2.

=item B<-eol>

The EOL to use, defaults to "\015\012".

=back

=head2 connect

This method makes a connection to the server.

=head2 setup

This method sets up the channel to be used. It needs to be overridden
to be useful.

=head2 get($length)

This block reads data from the channel. A buffer is returned when it reaches
$length or timeout, whichever is first.

=over 4

=item B<$length>

An optional length for the buffer. Defaults to 512 bytes.

=back

=head2 gets

This reads a buffer delimited by the eol from the channel.

=head2 errno

A class method to return the SSH error number.

=head2 errstr

A class method to return the SSH error string.

=head2 put($buffer)

This method will write a buffer to the channel. Returns the number of
bytes written.

=over 4

=item B<$buffer>

The buffer to be written.

=back

=head2 puts($buffer)

This writes a buffer that is terminated with eol to the channel. Returns the
number of bytes written.

=over 4

=item B<$buffer>

The buffer to send over the socket.

=back

=head2 disconnect

This method closes the connection.

=head1 MUTATORS

=head2 attempts

This is used when reading data from the channel. It triggers how many
times to attempt reading from the channel when a LIBSSH2_ERROR_EAGAIN
error occurs. The default is 5 times.

=head1 SEE ALSO

=over 4

=item L<XAS::Lib::SSH::Server|XAS::Lib::SSH::Server>

=item L<XAS::Lib::SSH::Client::Exec|XAS::Lib::SSH::Client::Exec>

=item L<XAS::Lib::SSH::Client::Shell|XAS::Lib::SSH::Client::Shell>

=item L<XAS::Lib::SSH::Client::Subsystem|XAS::Lib::SSH::Client::Subsystem>

=item L<Net::SSH2|https://metacpan.org/pod/Net::SSH2>

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2015 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut

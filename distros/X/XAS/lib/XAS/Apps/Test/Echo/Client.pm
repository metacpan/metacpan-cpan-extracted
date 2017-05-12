package XAS::Apps::Test::Echo::Client;

our $VERSION = '0.02';

use Try::Tiny;
use XAS::Lib::Net::Client;

use XAS::Class
  version   => $VERSION,
  base      => 'XAS::Lib::App',
  accessors => 'handle port host send'
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub setup {
    my $self = shift;

    $self->{handle} = XAS::Lib::Net::Client->new(
        -port => $self->port,
        -host => $self->host,
    );

}

sub do_echo {
    my $self = shift;

    my $message;

    $self->handle->connect();
    $self->handle->puts($self->send);

    $message = $self->handle->gets();
    $self->handle->disconnect();

    $self->log->info(sprintf("echo = %s", $message));

}

sub main {
    my $self = shift;

    $self->setup();

    $self->log->debug('Starting main section');

    $self->do_echo();

    $self->log->debug('Ending main section');

}

sub options {
    my $self = shift;

    $self->{send} = '';
    $self->{port} = '9505';
    $self->{host} = 'localhost';

    return {
        'port=s' => \$self->{port},
        'host=s' => \$self->{host},
        'send=s' => \$self->{send},
    };

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Apps::Test::Echo::Client - This module will send data to the echo server

=head1 SYNOPSIS

 use XAS::Apps::Test::Echo::Client;

 my $app = XAS::Apps::Test::Echo::Client->new(;
    -throws  => 'echo-client',
 );

 exit $app->run();

=head1 DESCRIPTION

This module will send a message to the echo server. This message should be
'echoed' back.

=head1 CONFIGURATION

There is no additional configuration.

=head1 OPTIONS

This module provides these additonal cli options.

=head2 --host

The host the echo server resides on. Defaults to 'localhost'.

=head2 --port

The port it is listening on. Defaults to '9505'.

=head2 --send

The text to be "echoed" back.

=head1 SEE ALSO

=over 4

=item bin/echo-client.pl

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut

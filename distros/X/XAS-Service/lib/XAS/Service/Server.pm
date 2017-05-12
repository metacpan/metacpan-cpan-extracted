package XAS::Service::Server;

our $VERSION = '0.01';

use POE;
use Try::Tiny;
use Plack::Util;
use Data::Dumper;
use Socket ':all';
use HTTP::Message::PSGI;
use XAS::Constants 'CODEREF';
use POE::Filter::HTTP::Parser;

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'XAS::Lib::Net::Server',
  utils   => ':validation',
  vars => {
    PARAMS => {
      -app => { type => CODEREF },
    }
  }
;

# ---------------------------------------------------------------------
# Public Events
# ---------------------------------------------------------------------

sub process_request {
    my $self = shift;
    my ($request, $ctx) = validate_params(\@_, [1,1]);

    my $app      = $self->app;
    my $alias    = $self->alias;
    my $version  = $request->header('X-HTTP-Verstion') || '0.9';
    my $protocol = "HTTP/$version";

    my $env = req_to_psgi($request,
       SERVER_NAME        => $self->address,
       SERVER_PORT        => $self->port,
       SERVER_PROTOCOL    => $protocol,
       'psgi.streaming'   => Plack::Util::TRUE,
       'psgi.nonblocking' => Plack::Util::TRUE,
       'psgi.runonce'     => Plack::Util::FALSE,
    );

    $self->log->debug(Dumper($env));

    my $r        = Plack::Util::run_app($app, $env);
    my $response = res_from_psgi($r);

    $self->log->debug(Dumper($response));

    $self->process_response($response, $ctx);

}

sub process_response {
    my $self = shift;
    my ($output, $ctx) = validate_params(\@_, [1,1]);

    my $alias = $self->alias;

    $poe_kernel->call($alias, 'client_output', $output, $ctx);

}

# ---------------------------------------------------------------------
# Public Methods
# ---------------------------------------------------------------------

# ---------------------------------------------------------------------
# Private Events
# ---------------------------------------------------------------------

sub _client_flushed {
    my ($self, $wheel) = @_[OBJECT, ARG0];

    my $alias = $self->alias;
    my $host  = $self->peerhost($wheel);
    my $port  = $self->peerport($wheel);

    $self->log->debug(sprintf('%s: _client_flushed() - wheel: %s, host: %s, port: %s', $alias, $wheel, $host, $port));
    $self->log->info_msg('service_client_flushed', $alias, $host, $port, $wheel);

    delete $self->{'clients'}->{$wheel};

}

# ---------------------------------------------------------------------
# Private Methods
# ---------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->{'filter'} = POE::Filter::HTTP::Parser->new(type => 'server');

    return $self;

}

1;

__END__

=head1 NAME

XAS::Service::Server - Perl extension for the XAS environment

=head1 SYNOPSIS

 use XAS::Service::Server;

 my $interface = XAS::Service::Server->new(
     -alias   => 'server',
     -port    => 9507,
     -address => 'localhost,
     -app     => $self->build_app($schema),
 );

 $interface->run();

=head1 DESCRIPTION

This module provides a basic web server based on POE. It binds the POE
environment to the Plack environment. It's primary mission is to run
L<Web::Machine|https://metacpan.org/pod/Web::Machine>. This allows for the
building of REST based web services quickly and easily. Which also allows the
same code base to run as a daemon on UNIX/Linux and a service on Windows.

=head1 METHODS

=head2 new

This module inherits from L<XAS::Lib::Net::Server|XAS::Lib::Net::Server> and
takes these additional parameters:

=over 4

=item B<-app>

This should be a complied Plack application.

=back

=head2 process_request($input, $ctx)

This event will process the input from the client. This method will
take the L<HTTP::Request|https://metacpan.org/pod/HTTP::Request> and
format it so the L<Plack|https://metacpan.org/pod/Plack> application can use
the request. The response from the application is then reformated into a
L<HTTP::Response|https://metacpan.org/pod/HTTP::Response> which is sent back
to the client. It also sets up a synchronous pipeline to handle this response.

It takes the following parameters:

=over 4

=item B<$input>

The input received from the socket.

=item B<$ctx>

A hash variable to maintain context. This will be initialized with a "wheel"
field. Others fields may be added as needed.

=back

=head2 process_response($output, $ctx)

This event will process the output for the client. It continues the
synchronous pipeline to handle this response.

It takes the following parameters:

=over 4

=item B<$output>

The output to be sent to the socket.

=item B<$ctx>

A hash variable to maintain context. This uses the "wheel" field to direct output
to the correct socket. Others fields may have been added as needed.

=back

=head1 SEE ALSO

=over 4

=item L<Web::Machine|https://metacpan.org/pod/Web::Machine>

=item L<XAS::Lib::Net::Server|XAS::Lib::Net::Server>

=item L<XAS::Service|XAS::Service>

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2016 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut

package XAS::Apps::Test::Echo::Server;

our $VERSION = '0.03';

use XAS::Lib::Net::Server;
use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Lib::App::Service',
  accessors => 'port address',
  vars => {
    SERVICE_NAME         => 'XAS_Echo_Server',
    SERVICE_DISPLAY_NAME => 'XAS Echo Server',
    SERVICE_DESCRIPTION  => 'This is a test Perl service',
  }
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub main {
    my $self = shift;

    my $server = XAS::Lib::Net::Server->new(
        -alias   => 'echo',
        -port    => $self->port,
        -address => $self->address,
    );

    $self->log->info('Starting up');

    $self->service->register('echo');
    $self->service->run();

    $self->log->info('Shutting down');

}

sub options {
    my $self = shift;

    $self->{port}    = '9505';
    $self->{address} = '127.0.0.1';

    return {
        'port=s'    => \$self->{port},
        'address=s' => \$self->{address},
     };

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Apps::Test::Echo::Server - This module is an 'echo' server

=head1 SYNOPSIS

 use XAS::Apps::Test::Echo::Server;

 my $app = XAS::Apps::Test::Echo::Server->new(
     -throws => 'something',
 );

 exit $app->run();

=head1 DESCRIPTION

This module will 'echo' received messages back to the sender.

=head1 CONFIGURATION

There is no additional configuration.

=head1 OPTIONS

This module provides these additonal cli options.

=head2 --port

The port the server will listen on. Defaults to '9505'.

=head2 --address

The address the server will attache too. Defaults to '127.0.0.1';

=head1 SEE ALSO

=over 4

=item sbin/echo-server.pl

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

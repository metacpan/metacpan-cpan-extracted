package XAS::Apps::Test::RPC::Server;

our $VERSION = '0.01';

use XAS::Apps::Test::RPC::Processor;
use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Lib::App::Service',
  accessors => 'port address keepalive',
  vars => {
    SERVICE_NAME         => 'XAS_RPC_ECHO',
    SERVICE_DISPLAY_NAME => 'XAS RPC ECHO Server',
    SERVICE_DESCRIPTION  => 'This is a test rpc echo service',
  }
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub setup {
    my $self = shift;

}

sub main {
    my $self = shift;

    $self->setup();

    $self->log->info('starting up');

    my $server = XAS::Apps::Test::RPC::Processor->new(
        -alias         => 'rpc-server',
        -port          => $self->port,
        -address       => $self->address,
        -tcp_keepalive => $self->keepalive,
    );

    $self->service->register('rpc-server');
    $self->service->run();

    $self->log->info('shutting down');

}

sub options {
    my $self = shift;

    $self->{port}      = 9500;
    $self->{address}   = 'localhost';
    $self->{keepalive} = 0;
    
    return {
        'port=s'    => \$self->{port},
        'address=s' => \$self->{address},
        'keepalive' => \$self->{keepalive},
    };

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Apps:: - A class for the XAS environment

=head1 SYNOPSIS

 use XAS::Apps:: ;

 my $app = XAS::Apps:: ->new(
     -throws => 'changeme',
 );

 exit $app->run();

=head1 DESCRIPTION

=head1 METHODS

=head2 setup

=head2 main

=head2 options

=head1 SEE ALSO

=over 4

=item L<XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut

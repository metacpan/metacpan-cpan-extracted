package XAS::Apps::Supervisor::Client;

use XAS::Supervisor::Client;

use XAS::Class
  version   => '0.03',
  base      => 'XAS::Lib::App',
  accessors => 'port host start stop pause resume status list kill',
  constants => ':jsonrpc',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub main {
    my $self = shift;

    my $result;
    my $message;
    my $rpc = XAS::Supervisor::Client->new(
        -port    => $self->port,
        -host    => $self->host,
        -timeout => 60,
    );

    $rpc->connect();

    if (defined($self->start)) {

        $result = $rpc->start($self->start);
        $message = $self->message('supervisor_status', $self->start, $result);

    } elsif (defined($self->stop)) {

        $result = $rpc->stop($self->stop);
        $message = $self->message('supervisor_status', $self->stop, $result);

    } elsif (defined($self->pause)) {

        $result = $rpc->pause($self->pause);
        $message = $self->message('supervsior_status', $self->pause, $result);

    } elsif (defined($self->resume)) {

        $result = $rpc->resume($self->resume);
        $message = $self->message('supervsior_status', $self->resume, $result);

    } elsif (defined($self->list)) {

        $result = $rpc->list($self->list);
        $message = $self->message('supervisor_list', join(',', @$result));

    } elsif (defined($self->kill)) {

        $result = $rpc->kill($self->kill);
        $message = $self->message('supervisor_status', $self->kill, $result);

    } elsif (defined($self->status)) {

        $result = $rpc->status($self->status);
        $message = $self->message('supervisor_status', $self->status, $result);

    }

    $rpc->disconnect();

    $self->log->info($message);

}

sub options {
    my $self = shift;

    $self->{'host'}   = RPC_DEFAULT_ADDRESS;
    $self->{'port'}   = RPC_DEFAULT_PORT;
    $self->{'start'}  = undef;
    $self->{'stop'}   = undef;
    $self->{'status'} = undef;
    $self->{'resume'} = undef;
    $self->{'pause'}  = undef;
    $self->{'list'}   = undef;
    $self->{'kill'}   = undef;

    return {
        'host=s'   => \$self->{'host'},
        'port=s'   => \$self->{'port'},
        'start=s'  => \$self->{'start'},
        'stop=s'   => \$self->{'stop'},
        'status=s' => \$self->{'status'},
        'pause=s'  => \$self->{'pause'},
        'resume=s' => \$self->{'resume'},
        'kill=s'   => \$self->{'kill'},
        'list'     => \$self->{'list'},
    };

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Apps::Supervisor::Client - control program for the XAS Supervisor

=head1 SYNOPSIS

 use XAS::Apps::Supervisor::Cleint;

 my $app = XAS::Apps::Supervisor::Client->new( );

 exit $app->run();

=head1 DESCRIPTION

This module provides a simple control interface to the XAS Supervisor. This
module inherits from L<XAS::Lib::App|XAS::Lib::App>.

=head1 OPTIONS

This modules provides these additonal cli options.

=head2 --host

This is the host that the supervisor resides on.

=head2 --port

This is the port that it listens too.

=head2 --start

Request that a process be started.

=head2 --stop

Request that a process be stopped.

=head2 --pause

Request that a process be paused.

=head2 --resume

Request that a process be resumed.

=head2 --kill

Request that a process be killed.

=head2 --status

Request the status of a process.

=head2 --list

List the known processes on the supervisor

=head1 SEE ALSO

=over 4

=item L<XAS::Supervisor::Client|XAS::Supervisor::Client>

=item L<XAS::Supervisor|XAS::Supervisor>

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

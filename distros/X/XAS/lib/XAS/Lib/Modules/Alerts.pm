package XAS::Lib::Modules::Alerts;

our $VERSION = '0.06';

use DateTime;
use Try::Tiny;
use XAS::Factory;

use XAS::Class
  debug      => 0,
  version    => $VERSION,
  base       => 'XAS::Singleton',
  accessors  => 'spooler',
  codec      => 'JSON',
  utils      => ':validation',
  filesystem => 'Dir'
;

# ------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------

sub send {
    my $self = shift;
    my ($message) = validate_params(\@_, [1]);

    my $dt = DateTime->now(time_zone => 'local');

    my $data = {
        hostname => $self->env->host,
        datetime => $dt->strftime('%Y-%m-%dT%H:%M:%S.%3N%z'),
        process  => $self->env->script,
        pid      => $$,
        tid      => 0,
        msgnum   => 0,
        priority => $self->env->priority,
        facility => $self->env->facility,
        message  => $message,
    };

    my $json = encode($data);

    $self->spooler->write($json);

}

# ------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->{'spooler'} = XAS::Factory->module('spooler', {
        -directory => Dir($self->env->spool, 'alerts'),
        -lock      => Dir($self->env->spool, 'alerts', 'locked')->path,
        -mask      => 0777,
    });

    return $self;

}

1;

__END__

=head1 NAME

XAS::Lib::Modules::Alerts - The alert module for the XAS environment

=head1 SYNOPSIS

Your program can use this module in the following fashion:

 use XAS::Lib::Modules::Alerts;

 my $alert = XAS::Lib::Modules::Alerts->new();

 $alert->send('There is a problem');

=head1 DESCRIPTION

This is the module for sending alerts within the XAS environment. It will write
an "alert" to the alerts spool directory. It is implemented as a singleton 
and will auto-load when invoked.

=head1 METHODS

=head2 new

This method initializes the module.

=head2 send($message)

This method will send an alert. It takes the following named parameters:

=over 4

=item B<$message>

The message to send.

=back

=head1 SEE ALSO

=over 4

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

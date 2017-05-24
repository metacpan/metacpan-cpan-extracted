package URI::amqp;
use strict;
use warnings;

our $VERSION = '0.1.1';

use URI::QueryParam;
use URI::Escape qw(uri_unescape);

use parent qw(URI::_server URI::_userpass);

sub default_port { 5672 }

=head1 NAME

URI::amqp - AMQP (RabbitMQ) URI

=head1 SYNOPSIS

    my $uri = URI->new('amqp://user:pass@host.domain:1234/');
    my $ar = AnyEvent::RabbitMQ->new->load_xml_spec()->connect(
        host      => $uri->host,
        port      => $uri->port,
        user      => $uri->user,
        pass      => $uri->password,
        vhost     => $uri->vhost,
        tls       => $uri->secure,
        heartbeat => scalar $uri->query_param('heartbeat'),
        ...
    );

=head1 DESCRIPTION

URI extension for AMQP protocol (L<https://www.rabbitmq.com/uri-spec.html>)

=head1 EXTENDED METHODS

=head2 vhost

vhost is path part of URI

slash C</> on start is removed (this is different with C<path> method)

return C<undef> if vhost not defined (should be used default of module which use this URI module)

=cut

sub vhost {
    my ($self) = @_;

    my $vhost = $self->path;
    $vhost =~ s/^\///;

    return if !length $vhost;

    return uri_unescape($vhost);
}

=head2 query_param

return query parameters (L<https://www.rabbitmq.com/uri-query-parameters.html>)

implement by L<URI::QueryParam> module

=head2 as_net_amqp_rabbitmq

return tuplet of C<($host, $options)> which works with L<Net::AMQP::RabbitMQ> C<connect> method

    use URI;
    use Net::AMQP::RabbitMQ;

    my $uri = URI->new('amqp://guest:guest@localhost');
    my $mq = Net::AMQP::RabbitMQ->new();
    $mq->connect($uri->as_net_amqp_rabbitmq_options);

=cut

sub as_net_amqp_rabbitmq {
    my ($self) = @_;

    return (
        $self->host,
        {
            user            => $self->user,
            password        => $self->password,
            port            => $self->port,
            vhost           => $self->vhost,
            channel_max     => scalar $self->query_param('channel_max'),
            frame_max       => scalar $self->query_param('frame_max'),
            heartbeat       => scalar $self->query_param('heartbeat'),
            timeout         => scalar $self->query_param('connection_timeout'),
            ssl             => $self->secure,
            ssl_verify_host => scalar $self->query_param('verify'),
            ssl_cacert      => scalar $self->query_param('cacertfile'),
        }
    );
}

=head2 as_anyevent_rabbitmq

return options which works with L<AnyEvent::RabbitMQ> C<connect> method

    use URI;
    use AnyEvent::RabbitMQ;
     
    my $cv = AnyEvent->condvar;
    my $uri = URI->new('amqp://user:pass@host.domain:1234/');
    my $ar = AnyEvent::RabbitMQ->new->load_xml_spec()->connect(
        $uri->as_anyevent_rabbitmq(),
        on_success => sub {
            ...
        },
        ...
    );

=cut

sub as_anyevent_rabbitmq {
    my ($self) = @_;

    return {
        host    => $self->host,
        port    => $self->port,
        user    => $self->user,
        pass    => $self->password,
        vhost   => $self->vhost,
        timeout => scalar $self->query_param('connection_timeout'),
        tls     => $self->secure,
        tune    => {
            heartbeat   => scalar $self->query_param('heartbeat'),
            channel_max => scalar $self->query_param('channel_max'),
            frame_max   => scalar $self->query_param('frame_max'),
        },
    };
}

=head1 LIMITATIONS

module doesn't support correct C<canonpath> (reverse) method (yet)

=head1 LICENSE

Copyright (C) Avast Software.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Jan Seidl E<lt>seidl@avast.comE<gt>

=cut

1;

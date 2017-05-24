package URI::amqps;
use strict;
use warnings;

use parent qw(URI::amqp);

=head1 NAME

URI::amqps - secure AMQP (RabbitMQ) URI

=head1 SYNOPSIS

    my $uri = URI->new('amqps://user:pass@host.domain:1234/');
    my $ar = AnyEvent::RabbitMQ->new->load_xml_spec()->connect(
        host  => $uri->host,
        port  => $uri->port,
        user  => $uri->user,
        pass  => $uri->password,
        vhost => $uri->vhost,
        tls   => $uri->secure,
        ...
    );
=head1 DESCRIPTION

URI extension for secure AMQP protocol (https://www.rabbitmq.com/uri-spec.html)

same as L<URI::amqp>

=cut

sub secure { 1 }

sub default_port { 5671 }


=head1 LICENSE

Copyright (C) Avast Software.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Jan Seidl E<lt>seidl@avast.comE<gt>

=cut

1;

[![Build Status](https://travis-ci.org/avast/URI-amqp.svg?branch=master)](https://travis-ci.org/avast/URI-amqp)
# NAME

URI::amqp - AMQP (RabbitMQ) URI

# SYNOPSIS

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

# DESCRIPTION

URI extension for AMQP protocol ([https://www.rabbitmq.com/uri-spec.html](https://www.rabbitmq.com/uri-spec.html))

# EXTENDED METHODS

## vhost

vhost is path part of URI

slash `/` on start is removed (this is different with `path` method)

return `undef` if vhost not defined (should be used default of module which use this URI module)

## query\_param

return query parameters ([https://www.rabbitmq.com/uri-query-parameters.html](https://www.rabbitmq.com/uri-query-parameters.html))

implement by [URI::QueryParam](https://metacpan.org/pod/URI::QueryParam) module

## as\_net\_amqp\_rabbitmq

return tuplet of `($host, $options)` which works with [Net::AMQP::RabbitMQ](https://metacpan.org/pod/Net::AMQP::RabbitMQ) `connect` method

    use URI;
    use Net::AMQP::RabbitMQ;

    my $uri = URI->new('amqp://guest:guest@localhost');
    my $mq = Net::AMQP::RabbitMQ->new();
    $mq->connect($uri->as_net_amqp_rabbitmq_options);

## as\_anyevent\_rabbitmq

return options which works with [AnyEvent::RabbitMQ](https://metacpan.org/pod/AnyEvent::RabbitMQ) `connect` method

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

# LIMITATIONS

module doesn't support correct `canonpath` (reverse) method (yet)

# LICENSE

Copyright (C) Avast Software.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Jan Seidl <seidl@avast.com>

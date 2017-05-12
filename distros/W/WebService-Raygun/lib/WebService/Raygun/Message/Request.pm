package WebService::Raygun::Message::Request;
$WebService::Raygun::Message::Request::VERSION = '0.030';
use Mouse;
use WebService::Raygun::Message::Request::QueryString;


=head1 NAME

WebService::Raygun::Message::Request - Encapsulate the data in a typical HTTP request.


=head1 SYNOPSIS

    sub request_handler {
        my $c = shift;     

        try {
                # error code
            } 
            catch {
    
                my $raygun = WebService::Raygun::Messenger->new(
                    api_key => '<your raygun.io api key>',
                    message => {
                        ...
                        request => $c->request, # HTTP::Request object
                        ... 
                    }
                );
                $raygun->fire_raygun;
        };
    }

=head1 DESCRIPTION

You should not need to instantiate this class directly. When creating an instance of L<WebService::Raygun::Messenger|WebService::Raygun::Messenger>, just pass in the I<request> object for your framework. See below for a list of types.


=head1 INTERFACE

=cut

use Mouse::Util::TypeConstraints;
subtype 'RawData' => as 'Str';    # => where {};

subtype 'Request' => as 'Object' => where {
    $_->isa('WebService::Raygun::Message::Request');
};

subtype 'HttpRequest' => as 'Object' => where {
    $_->isa('HTTP::Request');
};

subtype 'MojoliciousRequest' => as 'Object' => where {
    $_->isa('Mojo::Message::Request');
};

subtype 'DancerRequest' => as 'Object' => where {
    $_->isa('Dancer::Request');
};

subtype 'Dancer2Request' => as 'Object' => where {
    $_->isa('Dancer2::Core::Request');
};

subtype 'PlackRequest' => as 'Object' => where {
    $_->isa('Plack::Request');
};

subtype 'HttpEngineRequest' => as 'Object' => where {
    $_->isa('HTTP::Engine::Request');
};

subtype 'CatalystRequest' => as 'Object' => where {
    $_->isa('Catalyst::Request');
};

coerce 'Request' => from 'HttpRequest' => via {
    my @header_names = $_->headers->header_field_names;
    my $headers;
    foreach my $header (@header_names) {
        my $value = $_->header($header);
        $headers->{$header} = $value;
    }
    my $query_string = $_->uri->query || '';

    my $ws = WebService::Raygun::Message::Request->new(
        url          => $_->uri->as_string,
        raw_data     => $_->as_string,
        headers      => $headers,
        http_method  => $_->method,
        query_string => $query_string,
    );
    return $ws;
} => from 'MojoliciousRequest' => via {
    my $headers      = $_->headers->to_hash;
    my $query_params = $_->query_params;
    my $query_string = '';
    if (defined $query_params and $query_params->isa('Mojo::Parameters')) {
        $query_string = $query_params->to_string;
    }
    my $ws = WebService::Raygun::Message::Request->new(
        url          => $_->url->to_abs->path,
        http_method  => $_->method,
        raw_data     => $_->get_body_chunk,
        headers      => $headers,
        query_string => $query_string,
    );
    return $ws;
} => from 'PlackRequest' => via {
    my $headers      = $_->headers->to_hash;
    my $ws = WebService::Raygun::Message::Request->new(
        url          => $_->request_uri,
        http_method  => $_->method,
        raw_data     => $_->raw_body,
        headers      => $headers,
        query_string => $_->query_string,
    );
    return $ws;

} => from 'DancerRequest' => via {
    my $headers      = $_->headers->to_hash;
    my $ws = WebService::Raygun::Message::Request->new(
        url          => $_->request_uri,
        http_method  => $_->method,
        raw_data     => $_->body(),
        headers      => $headers,
        query_string => $_->params,
    );
    return $ws;
} => from 'Dancer2Request' => via {
    my $headers      = $_->headers->to_hash;
    my $ws = WebService::Raygun::Message::Request->new(
        url          => $_->uri_base,
        http_method  => $_->method,
        raw_data     => $_->raw_body,
        headers      => $headers,
        query_string => $_->query_string,
    );
    return $ws;
} => from 'HttpEngineRequest' => via {
    my $headers      = $_->headers->to_hash;
    my $ws = WebService::Raygun::Message::Request->new(
        url          => $_->base,
        http_method  => $_->method,
        raw_data     => $_->raw_body,
        headers      => $headers,
        query_string => $_->query_parameters,
    );
    return $ws;
} => from 'PlackRequest' => via {
    my $header_array      = $_->headers->flatten;
    my $headers = {@{$header_array}};
    my $ws = WebService::Raygun::Message::Request->new(
        url          => $_->request_uri,
        http_method  => $_->method,
        raw_data     => $_->raw_body,
        headers      => $headers,
        query_string => $_->query_parameters,
    );
    return $ws;
} => from 'CatalystRequest' => via {

    my @header_names = $_->headers->header_field_names;
    my $headers;
    foreach my $header (@header_names) {
        my $value = $_->header($header);
        $headers->{$header} = $value;
    }
    my $chunk;
    $_->read_chunk(\$chunk, 4096);
    my $query_string = $_->uri->query || '';
    my $ws = WebService::Raygun::Message::Request->new(
        ip_address   => $_->address,
        headers      => $headers,
        http_method  => $_->method,
        host_name    => $_->hostname,
        raw_data     => $chunk,
        query_string => $query_string,
    );
    return $ws;
} => from 'HashRef' => via {
    return WebService::Raygun::Message::Request->new(%{$_});
};

coerce 'RawData' => from 'Str' => via {
    my $rawData = $_;
    open my $fh, '<:bytes', \$rawData;
    read $fh, my $truncated, 4096;
    return $truncated;
};

no Mouse::Util::TypeConstraints;

has host_name => (
    is  => 'rw',
    isa => 'Str',
);

has url => (
    is  => 'rw',
    isa => 'Str',
);

has http_method => (
    is      => 'rw',
    isa     => 'Str',
    default => sub {
        return 'GET';
    }
);

has ip_address => (
    is      => 'rw',
    isa     => 'Str',
    default => sub {
        return '127.0.0.1';
    }
);

has query_string => (
    is      => 'rw',
    isa     => 'RaygunQueryString',
    coerce => 1,
    default => sub {
        return {};
    }
);

has raw_data => (
    is     => 'rw',
    isa    => 'RawData|Undef',
    coerce => 1
);

has headers => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub {
        return {};
    },
);

=head2 prepare_raygun

Return the data structure that will be sent to raygun.io.

=cut

sub prepare_raygun {
    my $self = shift;
    return {
        ipAddress   => $self->ip_address,
        hostName    => $self->host_name,
        url         => $self->url,
        httpMethod  => $self->http_method,
        queryString => $self->query_string->prepare_raygun,
        headers     => $self->headers,
        rawData     => $self->raw_data,
    };
}

=head1 DEPENDENCIES


=head1 SEE ALSO


Here is the list of supported request types. I haven't experimented with all of them yet, but most of them have similar interfaces and thus I<should> work.

=over 2


=item L<HTTP::Request|HTTP::Request>


=item L<Catalyst::Request|Catalyst::Request>


=item L<Mojo::Message::Request|Mojo::Message::Request>


=item L<Dancer::Request|Dancer::Request>


=item L<Dancer2::Core::Request|Dancer2::Core::Request>


=item L<Plack::Request|Plack::Request>


=item L<HTTP::Engine::Request|HTTP::Engine::Request>


=back

=cut

__PACKAGE__->meta->make_immutable();

1;

__END__

package WWW::Foreman::API;
$WWW::Foreman::API::VERSION = '0.001';
use strict;
use warnings;
use Carp 'croak';
use Encode;
use Exporter 'import';
my @EXPORT = ();
my @EXPORT_OK = qw(get post put delete);
use JSON;
use MIME::Base64;
use REST::Client;

# ABSTRACT: Perl client to the Foreman API

sub new {
    my ($class, %params) = @_;
    my $self = {
        user       => $params{user},
        password   => $params{password},
        url        => $params{url},
        verify_ssl => $params{verify_ssl}
    };
    bless($self, $class);

    return $self;
}

sub get {
    my ($self, $path) = @_;
    croak 'get() must be called with 1 argument' if @_ != 2;
    croak 'The #1 argument to get() must be a scalar' if ref($_[1]);
    my $client = $self->create_client();
    my $headers = $self->set_headers();
    $client->GET($path, $headers);
    my $response = decode_json(decode_utf8($client->responseContent()));

    return $response;
}

sub post {
    my ($self, $path, $params) = @_;
    croak 'post() must be called with 2 argument' if @_ != 3;
    croak 'The #2 argument to post() must be a hash' if ref($_[2]) ne 'HASH';
    $params = JSON::encode_json($params);
    my $client = $self->create_client();
    my $headers = $self->set_headers();
    $client->POST($path, $params, $headers);
    my $response = decode_utf8($client->responseContent());

    return $response;
}

sub put {
    my ($self, $path, $params) = @_;
    croak 'put() must be called with 2 argument' if @_ != 3;
    croak 'The #2 argument to put() must be a hash' if ref($_[2]) ne 'HASH';
    $params = JSON::encode_json($params);
    my $client = $self->create_client();
    my $headers = $self->set_headers();
    $client->PUT($path, $params, $headers);
    my $response = decode_utf8($client->responseContent());

    return $response;
}

sub delete {
    my ($self, $path) = @_;
    croak 'delete() must be called with 1 argument' if @_ != 2;
    croak 'The #1 argument to delete() must be a scalar' if ref($_[1]);
    my $client = $self->create_client();
    my $headers = $self->set_headers();
    $client->DELETE($path, $headers);
    my $response = decode_json(decode_utf8($client->responseContent()));

    return $response;
}

sub create_client {
    my $self = shift;
    my $client = REST::Client->new();
    if($self->{verify_ssl} == 0) {
        $client->getUseragent()->ssl_opts(verify_hostname => 0);
        $client->getUseragent()->ssl_opts(SSL_verify_mode => 0);
    }
    $client->setHost($self->{url});

    return $client;
}

sub set_headers {
    my $self = shift;
    my $headers = {
        Content_Type  => 'application/json;charset=utf8',
        Accept        => 'application/json',
        Authorization => 'Basic ' . encode_base64($self->{user} . ':' . $self->{password})
    };

    return $headers;
}

=head1 NAME

WWW::Foreman::API - Perl client to the Foreman API

=head1 SYNOPSIS

    use WWW::Foreman::API;
    use Data::Dumper;

    my $api = WWW::Foreman::API->new(
        user       => $user,
        password   => $password,
        url        => $foreman_api_url,
        verify_ssl => 1
    );

    print Dumper $api->get('hosts');



=head1 DESCRIPTION

This module is a generic client to the Foreman API. To use this module, you should use the C<post()>, C<get()>, C<put()> and C<delete()> methods.

=head3 Methods:

=head4 C<new()>

Create a Foreman API object.


    my $api = WWW::Foreman::API->new(
        user       => $user,
        password   => $password,
        url        => $foreman_api_url,
        verify_ssl => 1
    );

=head4 Parameters:

=over

=item user

The user who will be used for the API requests.

=item password

The password of the user.

=item url

The url of the Foreman API. For example, L<https://foreman/api>.

=item verify_ssl

If this parameter is set to 0, this disables certificate chain checking, as well as host name checking.

=back

=head4 C<get()>:

The C<get()> method sends a GET request to the Foreman API, using the API end point supplied as an argument.
For example, this code:

    $api->get('hosts/2');

will send a GET request to L<https://foreman_url/api/hosts/2>

=head4 C<post()>:

The C<post()> method sends a POST request to the Foreman API, using the API end point and the parameters supplied as arguments.
For example, this code:

    $api->post('architectures', \%params);

will send a POST request to L<https://foreman_url/api/architecures>. C<\%params> is a hash ref which contains the parameters being send within the request.

=head4 C<put()>:

The C<put()> method sends a PUT request to the Foreman API, using the API end point and the parameters supplied as arguments.
For example, this code:

    $api->put('architectures/2', \%params);

will send a PUT request to L<https://foreman_url/api/architecures/2>. C<\%params> is a hash ref which contains the parameters being send within the request.

=head4 C<delete()>:

The C<delete()> method sends a DELETE request to the Foreman API, using the API end point supplied as argument.
For example, this code:

    $api->delete('hosts/2');

will send a DELETE request to L<https://<url_foreman/api/hosts/2>

=head4 Getting more help

For more information about the api endpoints and the parameters for each request, please refer to the official documentation: L<https://theforeman.org/api/1.12/index.html>.

=head3 Return values

The return value is an hash reference which is the deserialised json returned by the API. For example:


    $VAR1 = {
              'page' => 1,
              'per_page' => 20,
              'results' => [
                             {
                               'created_at' => '2015-04-03T13:59:04.398Z',
                               'id' => 1,
                               'updated_at' => '2015-05-14T13:59:04.398Z',
                               'name' => 'x86_64'
                             }
                           ],
              'total' => 1,
              'subtotal' => 1,
              'search' => undef,
              'sort' => {
                          'by' => undef,
                          'order' => undef
                        }
            };

=head1 AUTHOR

Vincent Lequertier <vi.le@autistici.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

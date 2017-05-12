# NAME

WWW::Foreman::API - Perl client to the Foreman API

# SYNOPSIS

    use WWW::Foreman::API;
    use Data::Dumper;

    my $api = WWW::Foreman::API->new(
        user       => $user,
        password   => $password,
        url        => $foreman_api_url,
        verify_ssl => 1
    );

    print Dumper $api->get('hosts');

# DESCRIPTION

This module is a generic client to the Foreman API. To use this module, you should use the `post()`, `get()`, `put()` and `delete()` methods.

### Methods:

#### `new()`

Create a Foreman API object.

    my $api = WWW::Foreman::API->new(
        user       => $user,
        password   => $password,
        url        => $foreman_api_url,
        verify_ssl => 1
    );

#### Parameters:

- user

    The user who will be used for the API requests.

- password

    The password of the user.

- url

    The url of the Foreman API. For example, [https://foreman/api](https://foreman/api).

- verify\_ssl

    If this parameter is set to 0, this disables certificate chain checking, as well as host name checking.

#### `get()`:

The `get()` method sends a GET request to the Foreman API, using the API end point supplied as an argument.
For example, this code:

    $api->get('hosts/2');

will send a GET request to [https://foreman\_url/api/hosts/2](https://foreman_url/api/hosts/2)

#### `post()`:

The `post()` method sends a POST request to the Foreman API, using the API end point and the parameters supplied as arguments.
For example, this code:

    $api->post('architectures', \%params);

will send a POST request to [https://foreman\_url/api/architecures](https://foreman_url/api/architecures). `\%params` is a hash ref which contains the parameters being send within the request.

#### `put()`:

The `put()` method sends a PUT request to the Foreman API, using the API end point and the parameters supplied as arguments.
For example, this code:

    $api->put('architectures/2', \%params);

will send a PUT request to [https://foreman\_url/api/architecures/2](https://foreman_url/api/architecures/2). `\%params` is a hash ref which contains the parameters being send within the request.

#### `delete()`:

The `delete()` method sends a DELETE request to the Foreman API, using the API end point supplied as argument.
For example, this code:

    $api->delete('hosts/2');

will send a DELETE request to [https://&lt;url\_foreman/api/hosts/2](https://<url_foreman/api/hosts/2)

#### Getting more help

For more information about the api endpoints and the parameters for each request, please refer to the official documentation: [https://theforeman.org/api/1.12/index.html](https://theforeman.org/api/1.12/index.html).

### Return values

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

# AUTHOR

Vincent Lequertier <vi.le@autistici.org>

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

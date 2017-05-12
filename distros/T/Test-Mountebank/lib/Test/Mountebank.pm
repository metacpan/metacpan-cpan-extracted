use 5.014;
package Test::Mountebank;
our $VERSION = '0.001';

use Test::Mountebank::Client;

=encoding utf8

=head1 NAME

Test::Mountebank - Perl client library for mountebank

=head1 SYNOPSIS

    use Test::Mountebank;

    # Create mountebank client with default port 2525
    my $mb = Test::Mountebank::Client->new(
        base_url => 'http://127.0.0.1'
    );

    # Create an imposter that answers on port 4546
    my $imposter = $mb->create_imposter( port => 4546 );

    # Adds a stub to the imposter with a predicate and a response
    # (Responds to URL /foobar.json, returns JSON content '{"foo":"bar"}')
    $imposter->stub->predicate(
        path   => "/foobar.json",
        method => "GET",
    )->response(
        status_code  => 200,
        content_type => "application/json",
        # Equivalent:
        # headers    => { Content_Type => "application/json" },
        body         => { foo => "bar" },
        # Equivalent:
        # body       => '{ "foo":"bar" }',
    );

    # Adds a stub for a non-existent resource
    $imposter->stub->predicate(
        path   => "/qux/999/json",
        method => "GET",
    )->response(
        status_code  => 404,
        content_type => "application/json",
        body         => '{ "error": "No such qux: 999" }',
    );

    # Add a stub to return HTML content read from a file
    $imposter->stub->predicate(
        path   => "/foobar.html",
        method => "GET",
    )->response(
        status_code    => 200,
        content_type   => "text/html",
        body_from_file => './foobar.html',
    );

    # Clear existing imposter on port 4546
    $mb->delete_imposters(4546); # Takes more than one port number, if desired

    # Send the new imposter to mountebank
    $mb->save_imposter($imposter);

=head1 DESCRIPTION

The example in the synopsis builds an object structure that generates JSON code like
the following, which can be sent to the running mountebank instance in a POST request.

    {
        "port": 4546,
        "protocol": "http",
        "stubs": [
            {
                "predicates": [
                    {
                        "equals": {
                            "method": "GET",
                            "path": "/foobar.json"
                        }
                    }
                ],
                "responses": [
                    {
                        "is": {
                            "body": {
                                "foo": "bar"
                            },
                            "headers": {
                                "Content-Type": "application/json"
                            },
                            "statusCode": 200
                        }
                    }
                ]
            },
            {
                "predicates": [
                    {
                        "equals": {
                            "method": "GET",
                            "path": "/qux/999/json"
                        }
                    }
                ],
                "responses": [
                    {
                        "is": {
                            "body": "{ \"error\": \"No such qux: 999\" }",
                            "headers": {
                                "Content-Type": "application/json"
                            },
                            "statusCode": 404
                        }
                    }
                ]
            },
            {
                "predicates": [
                    {
                        "equals": {
                            "method": "GET",
                            "path": "/foobar.html"
                        }
                    }
                ],
                "responses": [
                    {
                        "is": {
                            "body": "<html>\n  <head>\n    <title>foobar</title>\n  </head>\n  <body>\n    foobar\n  </body>\n</html>\n\n",
                            "headers": {
                                "Content-Type": "text/html"
                            },
                            "statusCode": 200
                        }
                    }
                ]
            }
        ]
    }

Compare the mountebank documentation at L<http://www.mbtest.org/docs/api/stubs>
and L<http://www.mbtest.org/docs/api/predicates>.  Currently at least,
Test::Mountebank implements only the features of mountebank stubs that are most
useful for simulating a REST API. There is only one type of predicate (C<equals>)
and only one type of response (C<is>).


=cut



=head1 AUTHOR

Dagfinn Reiersøl dagfinn@reiersol.com

=head1 COPYRIGHT

Copyright (C) 2016, Dagfinn Reiersøl.

=cut

1;

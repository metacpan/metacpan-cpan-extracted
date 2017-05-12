[![Build Status](https://travis-ci.org/yusukebe/Test-JSON-RPC-Autodoc.svg?branch=master)](https://travis-ci.org/yusukebe/Test-JSON-RPC-Autodoc)
# NAME

Test::JSON::RPC::Autodoc - Testing tools for auto generating documents of JSON-RPC applications

# SYNOPSIS

    use Test::More;
    use Plack::Request;
    use JSON qw/to_json from_json/;
    use Test::JSON::RPC::Autodoc;

    # Making a PSGI-based JSON-RPC application
    my $app = sub {
        my $env  = shift;
        my $req  = Plack::Request->new($env);
        my $ref  = from_json( $req->content );
        my $data = {
            jsonrpc => '2.0',
            id      => 1,
            result  => $ref->{params},
        };
        my $json = to_json($data);
        return [ 200, [ 'Content-Type' => 'application/json' ], [$json] ];
    };

    # Let's test
    my $test = Test::JSON::RPC::Autodoc->new(
        document_root => './docs',
        app           => $app,
        path          => '/rpc'
    );

    my $rpc_req = $test->new_request();
    $rpc_req->params(
        language => { isa => 'Str', default => 'English', required => 1 },
        country  => { isa => 'Str', documentation => 'Your country' }
    );
    $rpc_req->post_ok( 'echo', { language => 'Perl', country => 'Japan' } );
    my $res  = $rpc_req->response();
    my $data = $res->from_json();
    is_deeply $data->{result}, { language => 'Perl', country => 'Japan' };

    $test->write('echo.md');
    done_testing();

# DESCRIPTION

**Test::JSON::RPC::Autodoc** is a software for testing JSON-RPC Web applications. These modules generate the Markdown formatted documentations about RPC parameters, requests, and responses. Using **Test::JSON::RPC::Autodoc**, we just write and run the integrated tests, then documents will be generated. So it will be useful to share the JSON-RPC parameter rules with other developers.

# METHODS

## Test::JSON::RPC::Autodoc

### **new(%options)**

    my $test = Test::JSON::RPC::Autodoc->new(
        app => $app,
        document_root => './documents',
        path => '/rpc'
    );

Create a new Test::JSON::RPC::Autodoc instance. Possible options are:

- `app => $app`

    PSGI application, required.

- `document_root => './documents'`

    Output directory for documents, optional, default is './docs'.

- `path => '/rpc'`

    JSON-RPC endpoint path, optional, default is '/'.

### **new\_request()**

Return a new Test::JSON::RPC::Autodoc::Request instance.

### **write('echo.md')**

Save the document named as a given parameter filename.

## Test::JSON::RPC::Autodoc::Request

Test::JSON::RPC::Autodoc::Request is a sub-class of [HTTP::Request](https://metacpan.org/pod/HTTP::Request). Extended with these methods.

### **$request->params(%options)**

    $request->params(
        language => { isa => 'Str', default => 'English', required => 1, documentation => 'Your language' },
        country => { isa => 'Str', documentation => 'Your country' }
    );

Take parameters with the rules for calling JSON-RPC a method.
To validate parameters this module use [Data::Validator](https://metacpan.org/pod/Data::Validator) module internal.
Attributes of rules are below:

- `isa => $type: Str`

    The type of the property, which can be `Mouse` Type constraint name.

- `required => $value: Bool`

    If true, the parameter must be set.

- `default => $value: Str`

    The default value for the parameter. If the argument is blank, this value will be used.

- `documentation => $doc: Str`

    Description of the parameter. This will be used when the Markdown documents are generated.

### **$request->post\_ok($method, $params)**

    $request->post_ok('echo', { language => 'Perl', country => 'Japan' });

Post parameters to the specified method on your JSON-RPC application and check the parameters as tests.
If the response code is 200, it will return `OK`.

### **$request->post\_not\_ok($method, $params)**

If the parameters are not valid or the response code is not `200`, it will be passed.

### **$request->response()**

Return the last response as a Test::JSON::RPC::Autodoc::Response instance.

## Test::JSON::RPC::Autodoc::Response

This module extends [HTTP::Response](https://metacpan.org/pod/HTTP::Response) with the methods below:

### **$response->from\_json()**

Return a Perl-Object of the JSON response content. That is parsed by JSON parser.

# SEE ALSO

- [Test::JsonAPI::Autodoc](https://metacpan.org/pod/Test::JsonAPI::Autodoc)
- [https://github.com/r7kamura/autodoc](https://github.com/r7kamura/autodoc)
- [Shodo](https://metacpan.org/pod/Shodo)
- [Data::Validator](https://metacpan.org/pod/Data::Validator)

# LICENSE

Copyright (C) Yusuke Wada.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Yusuke Wada <yusuke@kamawada.com>

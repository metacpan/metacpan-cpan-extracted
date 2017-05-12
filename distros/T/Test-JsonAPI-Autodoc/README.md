[![Build Status](https://travis-ci.org/moznion/Test-JsonAPI-Autodoc.svg?branch=master)](https://travis-ci.org/moznion/Test-JsonAPI-Autodoc) [![Coverage Status](https://img.shields.io/coveralls/moznion/Test-JsonAPI-Autodoc/master.svg)](https://coveralls.io/r/moznion/Test-JsonAPI-Autodoc?branch=master)
# NAME

Test::JsonAPI::Autodoc - Test JSON API response and auto generate API documents

# SYNOPSIS

    use HTTP::Request::Common;
    use Test::More;
    use Test::JsonAPI::Autodoc;

    # JSON request
    describe 'POST /foo' => sub {
        my $req = POST 'http://localhost:5000/foo';
        $req->header('Content-Type' => 'application/json');
        $req->content(q{
            {
                "id": 1,
                "message": "blah blah"
            }
        });
        my $res = http_ok($req, 200, "returns response"); # <= Check status whether 200, and generate documents.
                                                          #    And this test method returns the response as hash reference.
    };

    # Can also request application/x-www-form-urlencoded
    describe 'POST /bar' => sub {
        my $req = POST 'http://localhost:3000/bar', [ id => 42, message => 'hello' ];
        http_ok($req, 200, "returns response");
    }

    # And you can use Plack::Test
    use Plack::Test;
    use Plack::Request;
    my $app = sub {
        my $env = shift;
        my $req = Plack::Request->new($env);
        if ($req->path eq '/') {
            return [ 200, [ 'Content-Type' => 'application/json' ], ['{ "message" : "success" }'] ];
        }
        return [ 404, [ 'Content-Type' => 'text/plain' ], [ "Not found" ] ];
    };

    my $test_app = Plack::Test->create($app);
    describe 'POST /' => sub {
        my $req = POST '/';
        $req->header('Content-Type' => 'application/json');
        $req->content(q{
            {
                "id": 1,
                "message": "blah blah"
            }
        });
        plack_ok($test_app, $req, 200, "get message ok");
    };

    # Of course you can use `test_psgi`
    test_psgi $app, sub {
        my $cb = shift;

        describe 'POST /not-exist' => sub {
            my $req = POST '/not-exist';
            $req->header('Content-Type' => 'application/json');
            $req->content(q{
                {
                    "id": 1,
                    "message": "blah blah"
                }
            });
            plack_ok($cb, $req, 404, "not found");
        };
    };

# DESCRIPTION

Test::JsonAPI::Autodoc tests JSON API response (only check status code).
And it generates API documents according to the response automatically.
Please refer to ["USAGE"](#usage) for details.

# USAGE

A document will be generated if `describe` is used instead of `Test::More::subtest`.
And call `http_ok` or `plack_ok` at inside of `describe`, then it tests API response
and convert the response to markdown document.

Run test as follows.

    $ TEST_JSONAPI_AUTODOC=1 prove t/test.t

If `TEST_JSONAPI_AUTODOC` doesn't have true value, **documents will not generate**.

The example of `test.t` is as follows.

    use HTTP::Request::Common;
    use Test::More;
    use Test::JsonAPI::Autodoc;

    # JSON request
    describe 'POST /foo' => sub {
        my $req = POST 'http://localhost:5000/foo';
        $req->header('Content-Type' => 'application/json');
        $req->content(q{
            {
                "id": 1,
                "message": "blah blah"
            }
        });
        http_ok($req, 200, "get message ok");
    };

The following markdown document are outputted after execution of a test.
Document will output to `$project_root/docs/test.md` on default setting.

    generated at: 2013-11-04 22:41:10

    ## POST /foo

    get message ok

    ### Target Server

    http://localhost:5000

    ### Parameters

    __application/json__

    - `id`: Number (e.g. 1)
    - `message`: String (e.g. "blah blah")

    ### Request

    POST /foo

    ### Response

    - Status:       200
    - Content-Type: application/json

    ```json
    {
       "message" : "success"
    }

    ```

Please also refer to example ([https://github.com/moznion/Test-JsonAPI-Autodoc/tree/master/eg](https://github.com/moznion/Test-JsonAPI-Autodoc/tree/master/eg)).

# METHODS

- describe ($description, \\&coderef)

    `describe` method can be used like `Test::More::subtest`.
    If this method is called, a document will be outputted with a test.

    `$description` will be headline of markdown documents.

    **\*\*\* DO NOT USE THIS METHOD AS NESTING \*\*\***

- http\_ok ($request, $expected\_status\_code, $note)

    `http_ok` method tests API response (only status code).
    and convert the response to markdown document.

    `$note` will be note of markdown documents.

    When this method is not called at inside of `describe`, documents is not generated.

    And this method returns the response as hash reference.

    Example of response structure;

        $response = {
            status       => <% status code %>,
            content_type => <% content type %>,
            body         => <% response body %>,
        }

    Moreover if `$note` is hash reference like below, you can describe each request parameters.

        {
            description => 'get message ok',
            param_description => {
                param1 => 'This is param1'
                param2 => 'This is param2',
            },
        }

    `description` is the same as the time of using as <$note> as scalar.
    `param_description` contains descriptions about request parameters.
    Now, this faculty only can describe request parameters are belonging to top level.
    Please refer [https://github.com/moznion/Test-JsonAPI-Autodoc/tree/master/eg/http\_with\_req\_params\_description.t](https://github.com/moznion/Test-JsonAPI-Autodoc/tree/master/eg/http_with_req_params_description.t) and
    [https://github.com/moznion/Test-JsonAPI-Autodoc/tree/master/eg/doc/http\_with\_req\_params\_description.md](https://github.com/moznion/Test-JsonAPI-Autodoc/tree/master/eg/doc/http_with_req_params_description.md).

- plack\_ok ($plack\_app, $request, $expected\_status\_code, $note)

    `plack_ok` method carries out almost the same operation as `http_ok`.
    This method is for [Plack](https://metacpan.org/pod/Plack) application.
    This method requires plack application as the first argument.

    This method also returns the response as hash reference.

- set\_documents\_path

    Set the output place of a document.
    An absolute path and a relative path can be used.

- set\_template

    Set the original template. This method require the string.
    Please refer to ["CUSTOM TEMPLATE"](#custom-template) for details.

# REQUIREMENTS

Generated document will output to `$project_root/docs/` on default setting.
$project\_root means the directory on which `cpanfile` discovered while going
back to a root directory from a test script is put.
Therefore, **it is necessary to put `cpanfile` on a project root**.

# CONFIGURATION AND ENVIRONMENT

- TEST\_JSONAPI\_AUTODOC

    Documents are generated when true value is set to this environment variable.

# CUSTOM TEMPLATE

You can customize template of markdown documents.

Available variables are the followings.

- description
- generated\_at
- results
    - result.note
    - result.path
    - result.server
    - result.method
    - result.query
    - result.request\_content\_type
    - result.request\_parameters
    - result.is\_plack\_app
    - result.status
    - result.response\_body
    - result.response\_content\_type

### Example

    : if $generated_at {
    generated at: <: $generated_at :>

    : }
    ## <: $description :>

    : for $results -> $result {
    <: $result.note :>

    : if $result.server {
    ### Target Server

    <: $result.server :>
    : if $result.is_plack_app {

    (Plack application)
    : }

    :}
    ### Parameters

    : if $result.request_parameters {
        : if $result.request_content_type {
    __<: $result.request_content_type :>__

        : }
    : for $result.request_parameters -> $parameter {
    <: $parameter :>
    : }
    : }
    : else {
    Not required
    : }

    ### Request

    <: $result.method:> <: $result.path :>
    : if $result.query {

        <: $result.query :>
    : }

    ### Response

    - Status:       <: $result.status :>
    - Content-Type: <: $result.response_content_type :>

    ```json
    <: $result.response_body :>
    ```
    : }

Template needs to be written by [Text::Xslate::Syntax::Kolon](https://metacpan.org/pod/Text::Xslate::Syntax::Kolon) as looking.

# FAQ

#### Does this module correspond to JSON-RPC?

Yes. It can use as [https://github.com/moznion/Test-JsonAPI-Autodoc/tree/master/eg/json\_rpc.t](https://github.com/moznion/Test-JsonAPI-Autodoc/tree/master/eg/json_rpc.t).

#### Can methods of [Test::More](https://metacpan.org/pod/Test::More) (e.g. `subtest()`) be called in `describe()`?

Yes, of course!

# INSPIRED

This module is inspired by “autodoc”, which is written by Ruby. That is very nice RSpec extension.

See also [https://github.com/r7kamura/autodoc](https://github.com/r7kamura/autodoc)

# CONTRIBUTORS

- Yuuki Tsubouchi (y-uuki)

# LICENSE

Copyright (C) moznion.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

moznion <moznion@gmail.com>

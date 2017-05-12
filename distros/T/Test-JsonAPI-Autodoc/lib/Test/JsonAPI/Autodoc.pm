package Test::JsonAPI::Autodoc;
use 5.008005;
use strict;
use warnings;
use parent qw/Exporter/;
use Carp;
use Test::More ();
use Scope::Guard;
use LWP::UserAgent;
use Test::JsonAPI::Autodoc::Markdown;
use Test::JsonAPI::Autodoc::Request;
use Test::JsonAPI::Autodoc::Response;

our @EXPORT = qw/
    describe
    http_ok
    plack_ok
    set_documents_path
    set_template
/;

our $VERSION = "0.22";

my $in_describe;
my $results;
my $first_time;

my $output_path;
my $template;

BEGIN {
    $first_time = 1;
}

sub set_documents_path {
    $output_path = shift;
}

sub set_template {
    $template = shift;
}

sub describe {
    if ($in_describe) {
        croak '`describe` must not call as nesting';
    }

    my $guard = sub {
        return Scope::Guard->new(sub {
            undef $in_describe;
            undef $results;
            undef $first_time;
        });
    }->();

    $in_describe = 1;

    my ($description, $coderef) = @_;

    # change location of test failure to be included Test::More's output
    # to be more helpful to user.
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $result = Test::More::subtest($description => $coderef);

    if ($result && $results && $ENV{TEST_JSONAPI_AUTODOC}) {
        my $markdown = Test::JsonAPI::Autodoc::Markdown->new($output_path, $template);
        $markdown->generate($description, $results, $first_time);
    }
}

sub http_ok {
    my ($req, $expected_code, $note) = @_;
    return _api_ok($req, $expected_code, $note);
}

sub plack_ok {
    my ($plack_app, $req, $expected_code, $note) = @_;
    return _api_ok($req, $expected_code, $note, $plack_app);
}

sub _api_ok {
    my ($req, $expected_code, $note, $plack_app) = @_;

    my $description       = $note;
    my $param_description = {};
    if (ref $note eq 'HASH') {
        $description       = $note->{description};
        $param_description = $note->{param_description};
    }

    my $res;
    my $is_plack_app = 0;
    if ($plack_app) { # for Plack::Test
        $res = ref $plack_app eq 'CODE' ? $plack_app->($req)         # use `test_psgi`
                                        : $plack_app->request($req); # not use `test_psgi`
        $is_plack_app = 1;
    }
    else {
        $res = LWP::UserAgent->new->request($req);
    }

    # change location of test failure to be included Test::More's output
    # to be more helpful to user.
    local $Test::Builder::Level = $Test::Builder::Level + 2;

    my $result = Test::More::is $res->code, $expected_code;
    return unless $result;
    return unless $in_describe;

    my $parsed_request  = Test::JsonAPI::Autodoc::Request->new->parse($req, $param_description);
    my $parsed_response = Test::JsonAPI::Autodoc::Response->new->parse($res);

    my $response_body         = $parsed_response->{body};
    my $response_content_type = $parsed_response->{content_type};

    push @$results, {
        note                  => $description,

        path                  => $parsed_request->{path},
        server                => $parsed_request->{server},
        method                => $parsed_request->{method},
        query                 => $parsed_request->{query},
        request_content_type  => $parsed_request->{content_type},
        request_parameters    => $parsed_request->{parameters},
        is_plack_app          => $is_plack_app,

        status                => $expected_code,
        response_body         => $response_body,
        response_content_type => $response_content_type,
    };

    return +{
        status       => $expected_code,
        body         => $response_body,
        content_type => $response_content_type,
    };
}
1;
__END__

=encoding utf-8

=for stopwords autodoc coderef y-uuki

=head1 NAME

Test::JsonAPI::Autodoc - Test JSON API response and auto generate API documents


=head1 SYNOPSIS

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

=head1 DESCRIPTION

Test::JsonAPI::Autodoc tests JSON API response (only check status code).
And it generates API documents according to the response automatically.
Please refer to L<"USAGE"> for details.

=head1 USAGE

A document will be generated if C<describe> is used instead of C<Test::More::subtest>.
And call C<http_ok> or C<plack_ok> at inside of C<describe>, then it tests API response
and convert the response to markdown document.

Run test as follows.

    $ TEST_JSONAPI_AUTODOC=1 prove t/test.t

If C<TEST_JSONAPI_AUTODOC> doesn't have true value, B<documents will not generate>.

The example of F<test.t> is as follows.

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
Document will output to F<$project_root/docs/test.md> on default setting.

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

Please also refer to example (L<https://github.com/moznion/Test-JsonAPI-Autodoc/tree/master/eg>).


=head1 METHODS

=over 4

=item * describe ($description, \&coderef)

C<describe> method can be used like C<Test::More::subtest>.
If this method is called, a document will be outputted with a test.

C<$description> will be headline of markdown documents.

B<*** DO NOT USE THIS METHOD AS NESTING ***>

=item * http_ok ($request, $expected_status_code, $note)

C<http_ok> method tests API response (only status code).
and convert the response to markdown document.

C<$note> will be note of markdown documents.

When this method is not called at inside of C<describe>, documents is not generated.

And this method returns the response as hash reference.

Example of response structure;

    $response = {
        status       => <% status code %>,
        content_type => <% content type %>,
        body         => <% response body %>,
    }

Moreover if C<$note> is hash reference like below, you can describe each request parameters.

    {
        description => 'get message ok',
        param_description => {
            param1 => 'This is param1'
            param2 => 'This is param2',
        },
    }

C<description> is the same as the time of using as <$note> as scalar.
C<param_description> contains descriptions about request parameters.
Now, this faculty only can describe request parameters are belonging to top level.
Please refer L<https://github.com/moznion/Test-JsonAPI-Autodoc/tree/master/eg/http_with_req_params_description.t> and
L<https://github.com/moznion/Test-JsonAPI-Autodoc/tree/master/eg/doc/http_with_req_params_description.md>.

=item * plack_ok ($plack_app, $request, $expected_status_code, $note)

C<plack_ok> method carries out almost the same operation as C<http_ok>.
This method is for L<Plack> application.
This method requires plack application as the first argument.

This method also returns the response as hash reference.

=item * set_documents_path

Set the output place of a document.
An absolute path and a relative path can be used.

=item * set_template

Set the original template. This method require the string.
Please refer to L<CUSTOM TEMPLATE> for details.

=back


=head1 REQUIREMENTS

Generated document will output to F<$project_root/docs/> on default setting.
$project_root means the directory on which F<cpanfile> discovered while going
back to a root directory from a test script is put.
Therefore, B<it is necessary to put F<cpanfile> on a project root>.


=head1 CONFIGURATION AND ENVIRONMENT

=over 4

=item * TEST_JSONAPI_AUTODOC

Documents are generated when true value is set to this environment variable.

=back


=head1 CUSTOM TEMPLATE

You can customize template of markdown documents.

Available variables are the followings.

=over 4

=item * description

=item * generated_at

=item * results

=over 4

=item * result.note

=item * result.path

=item * result.server

=item * result.method

=item * result.query

=item * result.request_content_type

=item * result.request_parameters

=item * result.is_plack_app

=item * result.status

=item * result.response_body

=item * result.response_content_type

=back

=back

=head3 Example

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

Template needs to be written by L<Text::Xslate::Syntax::Kolon> as looking.


=head1 FAQ

=head4 Does this module correspond to JSON-RPC?

Yes. It can use as L<https://github.com/moznion/Test-JsonAPI-Autodoc/tree/master/eg/json_rpc.t>.

=head4 Can methods of L<Test::More> (e.g. C<subtest()>) be called in C<describe()>?

Yes, of course!


=head1 INSPIRED

This module is inspired by “autodoc”, which is written by Ruby. That is very nice RSpec extension.

See also L<https://github.com/r7kamura/autodoc>

=head1 CONTRIBUTORS

=over 4

=item * Yuuki Tsubouchi (y-uuki)

=back

=head1 LICENSE

Copyright (C) moznion.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=head1 AUTHOR

moznion E<lt>moznion@gmail.comE<gt>

=cut

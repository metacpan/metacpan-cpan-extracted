use strict;
use warnings;
package Test::Mojo::Role::OpenAPI::Modern; # git description: v0.009-3-g2de4222
# vim: set ts=8 sts=2 sw=2 tw=100 et :
# ABSTRACT: Test::Mojo role providing access to an OpenAPI document and parser
# KEYWORDS: validation evaluation JSON Schema OpenAPI Swagger HTTP request response

our $VERSION = '0.010';

use 5.020;  # for fc, unicode_strings features
use strictures 2;
use utf8;
use if "$]" >= 5.022, experimental => 're_strict';
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';
no if "$]" >= 5.041009, feature => 'smartmatch';
no feature 'switch';
use JSON::Schema::Modern 0.577;
use OpenAPI::Modern 0.054;
use List::Util 'any';
use namespace::clean;

use Mojo::Base -role, -signatures;

has openapi => sub ($self) {
  # use the plugin's object, if the plugin is being used
  # FIXME: we should be calling $self->app->$_call_if_can, but can() isn't behaving
  my $openapi = eval { $self->app->openapi };
  return $openapi if $openapi;

  # otherwise try to construct our own using provided configs
  if (my $config = $self->app->config->{openapi}) {
    return $config->{openapi_obj} if $config->{openapi_obj};

    if (my $args = eval {
        +require Mojolicious::Plugin::OpenAPI::Modern;
        Mojolicious::Plugin::OpenAPI::Modern->VERSION('0.007');
        Mojolicious::Plugin::OpenAPI::Modern::_process_configs($config);
      }) {
      return OpenAPI::Modern->new($args);
    }
  }

  die 'openapi object or configs required';
};

has test_openapi_verbose => 0;

# keys being tracked here:
# - request_result
# - response_result
# - validation_options
sub _openapi_stash ($self, @data) { Mojo::Util::_stash(_openapi_stash => $self, @data) }

after _request_ok => sub ($self, @args) {
  $self->{_openapi_stash} = {};
};

sub request_valid ($self, $desc = 'request is valid') {
  $self->test('ok', $self->request_validation_result->valid, $desc);
  $self->dump_request_validation_result if not $self->success and $self->test_openapi_verbose;
  return $self;
}

sub response_valid ($self, $desc = 'response is valid') {
  $self->test('ok', $self->response_validation_result->valid, $desc);
  $self->dump_response_validation_result if not $self->success and $self->test_openapi_verbose;
  return $self;
}

# expected_error can either be the 'recommended_response' or any error string in the result.
sub request_not_valid ($self, $expected_error = undef, $desc = undef) {
  my $result = $self->request_validation_result;
  if ($expected_error and not $result->valid) {
    $desc //= 'request validation error matches';
    if ($expected_error eq $result->recommended_response->[1]) {
      $self->test('pass', $desc);
    }
    else {
      $self->test('ok', (any { $expected_error eq $_ } $result->errors), $desc);
    }
  }
  else {
    $self->test('ok', !$self->request_validation_result->valid, $desc // 'request is not valid');
  }

  $self->dump_request_validation_result if not $self->success and $self->test_openapi_verbose;
  return $self;
}

# expected_error must match an error string in the result.
sub response_not_valid ($self, $expected_error = undef, $desc = undef) {
  my $result = $self->response_validation_result;
  if ($expected_error and not $result->valid) {
    $self->test('ok', (any { $expected_error eq $_ } $result->errors),
      $desc // 'response validation error matches');
  }
  else {
    $self->test('ok', !$self->response_validation_result->valid, $desc // 'response is not valid');
  }

  $self->dump_response_validation_result if not $self->success and $self->test_openapi_verbose;
  return $self;
}

# I'm not sure yet which names are best, why not go for both?
sub request_invalid { goto \&request_not_valid }
sub response_invalid { goto \&response_not_valid }

sub request_validation_result ($self) {
  my $result = $self->_openapi_stash('request_result');
  return $result if defined $result;

  $result = $self->openapi->validate_request($self->tx->req, my $options = {});
  $self->_openapi_stash(request_result => $result, validation_options => $options);
  return $result;
}

sub response_validation_result ($self) {
  my $result = $self->_openapi_stash('response_result');
  return $result if defined $result;

  my $options = $self->_openapi_stash('validation_options');
  $self->_openapi_stash(validation_options => $options = {}) if not $options;
  $options->{request} = $self->tx->req;

  $result = $self->openapi->validate_response($self->tx->res, $options);
  $self->_openapi_stash(response_result => $result);
  return $result;
}

sub operation_id_is ($self, $operation_id, $desc = undef) {
  my $validation_options = $self->_openapi_stash('validation_options');
  return $self->test('fail', 'operation_id was captured during the last validation')
    if not $validation_options->{operation_id};

  $self->test('is', $validation_options->{operation_id}, $operation_id, $desc // 'operation_id is '.$operation_id);
}

my $encoder = JSON::Schema::Modern::_JSON_BACKEND()->new
  ->allow_nonref(1)
  ->utf8(0)
  ->canonical(1)
  ->pretty(1)
  ->indent_length(2);

sub dump_request_validation_result ($self, $style = 'data_only') {
  my $result = $self->request_validation_result;
  my $method = $ENV{AUTOMATED_TESTING} ? 'diag' : 'note';
  $self->handler->($method, "got request validation result:\n".$encoder->encode($result->format($style)));
}

sub dump_response_validation_result ($self, $style = 'data_only') {
  my $result = $self->response_validation_result;
  my $method = $ENV{AUTOMATED_TESTING} ? 'diag' : 'note';
  $self->handler->($method, "got response validation result:\n".$encoder->encode($result->format($style)));
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Mojo::Role::OpenAPI::Modern - Test::Mojo role providing access to an OpenAPI document and parser

=head1 VERSION

version 0.010

=head1 SYNOPSIS

  my $openapi = OpenAPI::Modern->new(
    openapi_uri => '/api',
    openapi_schema => YAML::PP->new(boolean => 'JSON::PP')->load_string(<<'YAML'));
---
  openapi: 3.1.0
  info:
    title: Test API
    version: 1.2.3
  paths:
    /foo/{foo_id}:
      parameters:
      - name: foo_id
        in: path
        required: true
        schema:
          type: integer
      post:
        operationId: my_foo_request
        requestBody:
          required: true
          content:
            application/json:
              schema: {}
        responses:
          200:
            description: success
            content:
              application/json:
                schema:
                  type: object
                  required: [ status ]
                  properties:
                    status:
                      const: ok
  YAML

  my $t = Test::Mojo
    ->with_roles('+OpenAPI::Modern')
    ->new('MyApp', { ... })
    ->openapi($openapi);

  $t->post_ok('/foo/123')
    ->status_is(200)
    ->json_is('/status', 'ok')
    ->request_valid
    ->or->dump_validation_request_result('basic')
    ->response_valid
    ->or->dump_validation_response_result('basic')
    ->operation_id_is('my_foo_request');

  $t->test_openapi_verbose(1);  # automatically dump validation errors on test failure

  $t->post_ok('/foo/123', form => { salutation => 'hi' })
    ->status_is(400)
    ->request_not_valid('Unsupported Media Type')
    ->response_not_valid(q{'/response': no response object found for code 400});

  $t->post('/foo/hello')
    ->status_is(400)
    ->request_not_valid(q{/request/path: 'wrong type: expected integer, got string'}, 'detected bad path parameter');

=head1 DESCRIPTION

Provides methods on a L<Test::Mojo> object suitable for using L<OpenAPI::Modern> to validate the
request and response.

=for stopwords OpenAPI openapi

=head1 ACCESSORS/METHODS

=head2 openapi

The L<OpenAPI::Modern> object to use for validation. This object stores the OpenAPI schema used to
describe requests and responses in your application, as well as the underlying
L<JSON::Schema::Modern> object used for the validation itself. See that documentation for
information on how to customize your validation and provide the specification document.

If not provided, the object is constructed using configuration values passed to the application
under the C<openapi> key (see L<Test::Mojo/new>), as for L<Mojolicious::Plugin::OpenAPI::Modern>,
or re-uses the object from the application itself if that plugin is applied.

Note that for testing purposes, you should use a relative URI for C<openapi_uri>, otherwise request
URIs will not match. This is because L<Test::Mojo> uses a randomly-generated port for test requests,
which cannot be predicted in advance to be included in C<openapi_uri>.

=head2 test_openapi_verbose

When true, failing request and response validation tests will dump the actual validation result via
L</dump_request_validation_result> or L</dump_response_validation_result>.

Defaults to false.

=head2 request_valid

Passes C<< $t->tx->req >> to L<OpenAPI::Modern/validate_request>, as in
L<Mojolicious::Plugin::OpenAPI::Modern/validate_request>, producing a boolean test result.

=head2 request_not_valid, request_invalid

The inverse of L</request_valid>. May optionally take an error string, which is matched against
the L<JSON::Schema::Modern::Result/recommended_response>, and all error strings in the result.

=head2 response_valid

Passes C<< $t->tx->res >> to L<OpenAPI::Modern/validate_response> as in
L<Mojolicious::Plugin::OpenAPI::Modern/validate_response>, producing a boolean test result.

=head2 response_not_valid, response_invalid

The inverse of L</response_valid>. May optionally take an error string, which is matched against all
error strings in the result.

Note that normally you shouldn't be testing for an invalid response, as all responses from your
application should be valid according to the specification, but this method is provided for
completeness. Instead, check for invalid responses right in your application (see
L<Mojolicious::Plugin::OpenAPI::Modern>) and log an error when this occurs.

=head2 operation_id_is

Test the C<operationId> corresponding to the last validated request or response (the unique string
used to identify the operation). See L<https://spec.openapis.org/oas/v3.1.0#operation-object>.

=head2 request_validation_result

Returns the L<JSON::Schema::Modern::Result> object for the validation result for the last request,
or calculates it if not already available.

Does not emit a test result.

=head2 dump_request_validation_result

Prints the L<JSON::Schema::Modern::Result> object for the validation result for the last request
(calculates it if not already available) to the test output stream.

Takes an optional argument indicating the result format, see
L<JSON::Schema::Modern::Result/output_format>. Defaults to C<data_only>, which is the format used
for comparing error responses in L</request_not_valid>.

Does not emit a test result.

=head2 response_validation_result

Returns the L<JSON::Schema::Modern::Result> object for the validation result for the last response,
or calculates it if not already available.

Does not emit a test result.

=head2 dump_response_validation_result

Prints the L<JSON::Schema::Modern::Result> object for the validation result for the last response
(calculates it if not already available) to the test output stream.

Takes an optional argument indicating the result format, see
L<JSON::Schema::Modern::Result/output_format>. Defaults to C<data_only>, which is the format used
for comparing error responses in L</response_not_valid>.

Does not emit a test result.

=head1 FUTURE FEATURES

Lots of features are still to come, including:

=over 4

=item *

stashing the validation results on the test object for reuse or diagnostic printing

=item *

integration with L<Mojolicious::Plugin::OpenAPI::Modern>, including sharing the openapi object and customization options that are set in the application

=back

=head1 SEE ALSO

=over 4

=item *

L<Mojolicious::Plugin::OpenAPI::Modern>

=item *

L<Test::Mojo>

=item *

L<Test::Mojo::WithRoles>

=item *

L<OpenAPI::Modern>

=item *

L<JSON::Schema::Modern::Document::OpenAPI>

=item *

L<JSON::Schema::Modern>

=item *

L<https://json-schema.org>

=item *

L<https://www.openapis.org/>

=item *

L<https://learn.openapis.org/>

=item *

L<https://spec.openapis.org/oas/latest.html>

=back

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/karenetheridge/Test-Mojo-Role-OpenAPI-Modern/issues>.

There is also an irc channel available for users of this distribution, at
L<C<#mojo> on C<irc.libera.chat>|irc://irc.libera.chat/#mojo>.

I am also usually active on irc, as 'ether' at C<irc.perl.org> and C<irc.libera.chat>.

=head1 AUTHOR

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2023 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

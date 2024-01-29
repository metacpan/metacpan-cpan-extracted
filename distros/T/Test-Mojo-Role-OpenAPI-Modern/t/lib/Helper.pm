# vim: set ts=8 sts=2 sw=2 tw=100 et :
use strictures 2;
# no package, so things defined here appear in the namespace of the parent.
use 5.020;
use stable 0.031 'postderef';
use experimental 'signatures';
use if "$]" >= 5.022, experimental => 're_strict';
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';

use Test::More 0.96;
use Test::Mojo;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use YAML::PP 0.005;
use Mojo::URL;
use OpenAPI::Modern;
use Mojolicious;
use Storable 'dclone';

our $openapi_preamble = <<'YAML';
---
openapi: 3.1.0
info:
  title: Test API
  version: 1.2.3
YAML

our $yamlpp = YAML::PP->new(boolean => 'JSON::PP');
our $schema = $yamlpp->load_string($openapi_preamble . <<'YAML');
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
            schema:
              type: object
              properties:
                kaboom:
                  $ref: '#/$defs/i_do_not_exist'
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
                  kaboom:
                    $ref: '#/$defs/i_do_not_exist'
YAML

our $doc_uri = Mojo::URL->new('https://example.com/api');

our $openapi = OpenAPI::Modern->new(
  openapi_uri => $doc_uri,
  openapi_schema => $schema,
);

our $app = Mojolicious->new;
$app->routes->post('/foo/:foo_id' => sub ($c) {
  if ($c->req->json) {
    if ($c->req->json->{kaboom}) {
      $c->render(json => { kaboom => $c->req->json->{kaboom} });
    }
    else {
      $c->render(json => { status => 'ok' });
    }
  }
  else {
    $c->render(text => 'kaboom', status => 400);
  }
});

1;

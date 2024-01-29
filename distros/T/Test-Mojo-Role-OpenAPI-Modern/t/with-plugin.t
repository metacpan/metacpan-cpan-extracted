# vim: set ts=8 sts=2 sw=2 tw=100 et :
use strictures 2;
use 5.020;
use stable 0.031 'postderef';
use experimental 'signatures';
use if "$]" >= 5.022, experimental => 're_strict';
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';
use utf8;
use open ':std', ':encoding(UTF-8)'; # force stdin, stdout, stderr into utf8

use lib 't/lib';
use Helper;

use Test::Needs 'Mojolicious::Plugin::OpenAPI::Modern';

my $schema = dclone($::schema);
$schema->{info}{title} = 'Test API using config from the plugin';

$::app->config({
  openapi => {
    schema => $schema,
  },
});

$::app->plugin('OpenAPI::Modern', $::app->config->{openapi});

subtest 'openapi object from the Mojo plugin' => sub {
  my $t = Test::Mojo
    ->with_roles('+OpenAPI::Modern')
    ->new($::app);

  is($t->app->openapi->document_get('/info/title'), 'Test API using config from the plugin',
    'openapi object on the application is constructed correctly');
  is($t->openapi, $t->app->openapi, 'the test openapi object is the same as in the application');

  $t->post_ok('/foo/123', json => {})
    ->status_is(200)
    ->json_is('/status', 'ok')
    ->request_valid
    ->response_valid;
};

done_testing;

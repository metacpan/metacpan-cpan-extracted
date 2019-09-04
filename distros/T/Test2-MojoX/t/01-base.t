#!/usr/bin/env perl
use Mojo::Base -strict;
use Test2::API qw(intercept);
use Test2::V0 -target => 'Test2::MojoX';
use Test2::Tools::Tester qw(facets);

ok $CLASS, 'Test2::MojoX';

use Mojolicious::Lite;

get '/' => sub {
  my $c = shift;
  $c->render(text => 'Bender');
};

my $t = Test2::MojoX->new;
my $assert_facets;

isa_ok $t, 'Test2::MojoX';
isa_ok $t->app, 'Mojolicious';

my $moniker = $t->app->moniker;
$t->app(__PACKAGE__->new->moniker('Test'));
is $t->app->moniker, 'Test';
isnt $moniker, 'Test';

my @methods = qw(delete get head options patch post put);
my $events  = intercept {
  for my $method (@methods) {
    my $sub_name = "${method}_ok";
    $t->$sub_name('/');
  }
};
$assert_facets = facets assert => $events;
is @$assert_facets, 7;
for my $i (0 .. 6) {
  my $method = $methods[$i];
  my $facet  = $assert_facets->[$i];


  is $facet->details, uc $method . ' /';
  is $facet->pass,    1;
}
is $t->success, 1;

isa_ok $t->ua, 'Mojo::UserAgent';
ok $t->ua->insecure;

# Request with custom method
my $tx = $t->ua->build_tx(FOO => '/test.json' => json => {foo => 1});
$assert_facets = facets assert => intercept {
  $t->request_ok($tx);
};
is $assert_facets->[0]->details, 'FOO /test.json';
is $assert_facets->[0]->pass,    1;

done_testing;

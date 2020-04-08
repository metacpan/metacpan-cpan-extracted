#!/usr/bin/env perl

use strict;
use warnings;

use Test::LWP::UserAgent;
use Test::More;

{
  package WebService::Foo;
  use Moo;
  with 'WebService::Client';

  has '+base_url' => ( default => 'https://example.com' );

  sub get_widgets() {
    my $self = shift;
    return $self->get("/widgets");
  }

  sub get_widget() {
    my ($self, $id) = @_;
    return $self->get("/widgets/$id");
  }

  sub create_widget() {
    my ($self, $widget_data) = @_;
    return $self->post("/widgets", $widget_data);
  }
}

my $useragent = Test::LWP::UserAgent->new;
$useragent->map_response(
  qr{example.com/widgets},
  HTTP::Response->new(
    '200', 'OK', ['Content-Type' => 'application/json'], '[{"name": "widget1"}]'
  )
);

my $webservice = WebService::Foo->new(
  ua          => $useragent,
  log_method  => 'warn',
);

subtest 'GET' => sub {
  my $widgets = $webservice->get_widgets();
  ok $widgets, "can get success";
  ok @$widgets, "deserialized get into a list";
  is scalar @$widgets, 1, "correct amount of values in returned list";
};

done_testing();

1;

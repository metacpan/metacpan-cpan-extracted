package Internal::Fixture::Simple;
use 5.010001;
use strict;
use warnings;
use parent 'Test::FITesque::Fixture';
use Test::More ;

sub string_found : Test : Plan(2) {
  my ($self, $args) = @_;
  note($args->{'-special'}->{description});
  ok(defined($args->{all}), 'String exists');
  like($args->{all}, qr/dahut/, 'Has a certain keyword');
}

sub string_found_long : Test : Plan(2) {
  my ($self, $args) = @_;
  note($args->{'-special'}->{description});
  ok(defined($args->{'http://example.org/my-parameters#all'}), 'String exists');
  like($args->{'http://example.org/my-parameters#all'}, qr/dahut/, 'Has a certain keyword');
}

sub relative_uri : Test : Plan(3) {
  my ($self, $args) = @_;
  note($args->{'-special'}->{description});
  ok(defined($args->{url}), 'Url comes through');
  isa_ok(defined($args->{url}), 'URI');
  is($args->{url}->as_string, 'http://example.org/foo/', 'Url is resolved');
}

1;


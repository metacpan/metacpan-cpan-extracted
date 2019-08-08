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

sub relative_uri : Test : Plan(2) {
  my ($self, $args) = @_;
  note($args->{'-special'}->{description});
  ok(defined($args->{url}), 'Url comes through');
  is($args->{url}, 'http://example.org/foo/', 'Url is resolved');
}

1;


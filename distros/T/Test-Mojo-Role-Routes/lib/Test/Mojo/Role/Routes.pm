package Test::Mojo::Role::Routes;

use strict;
use 5.008_005;
our $VERSION = '0.03';

use Mojo::Base -role;
use Mojo::Util qw(encode);

## make requests for named routes

sub delete_route_ok {
  my $self = shift;
  my $route = shift;
  return $self->delete_ok($self->app->url_for($route), @_);
}

sub get_route_ok  {
  my $self = shift;
  my $route = shift;
  return $self->get_ok($self->app->url_for($route), @_);
}

sub head_route_ok {
  my $self = shift;
  my $route = shift;
  return $self->head_ok($self->app->url_for($route), @_);
}

sub options_route_ok {
  my $self = shift;
  my $route = shift;
  return $self->options_ok($self->app->url_for($route), @_);
}

sub patch_route_ok {
  my $self = shift;
  my $route = shift;
  return $self->patch_ok($self->app->url_for($route), @_);
}

sub post_route_ok {
  my $self = shift;
  my $route = shift;
  return $self->post_ok($self->app->url_for($route), @_);
}

sub put_route_ok {
  my $self = shift;
  my $route = shift;
  return $self->put_ok($self->app->url_for($route), @_);
}

## testing current url path and named route

sub path_is {
  my ($self, $path, $desc) = @_;
  $desc = _desc($desc, 'url path '. $self->tx->req->url->path ." is $path");
  return $self->test('is', $self->tx->req->url->path => $path, $desc);
}

sub path_isnt {
  my ($self, $path, $desc) = @_;
  $desc = _desc($desc, 'url path '. $self->tx->req->url->path ." isn't $path");
  return $self->test('ok', !($self->tx->req->url->path eq $path), $desc);
}

sub path_like {
  my ($self, $path, $desc) = @_;
  $desc = _desc($desc, 'url path '. $self->tx->req->url->path ." like $path");
  return $self->test('like', $self->tx->req->url->path => $path, $desc);
}

sub path_unlike {
  my ($self, $path, $desc) = @_;
  $desc = _desc($desc, 'url path '. $self->tx->req->url->path ." unlike $path");
  return $self->test('unlike', $self->tx->req->url->path => $path, $desc);
}

sub path_starts_with {
  my ($self, $path, $desc) = @_;
  $desc = _desc($desc, 'url path '. $self->tx->req->url->path ." starts with $path");
  my $length = length($path);
  return $self->test('is', substr($self->tx->req->url->path, 0, $length) => $path, $desc);
}

sub route_is {
  my ($self, $route, $desc) = @_;
  my $path = $self->app->url_for($route);
  $desc = _desc($desc, 'url path '. $self->tx->req->url->path ." is route $route -> $path");
  return $self->test('is', $self->tx->req->url->path => $path, $desc);
}

sub route_isnt {
  my ($self, $route, $desc) = @_;
  my $path = $self->app->url_for($route);
  $desc = _desc($desc, 'url path '. $self->tx->req->url->path ." isn't route $route -> $path");
  return $self->test('ok', !($self->tx->req->url->path eq $path), $desc);
}

# if no $desc is provided to test then use the default that each method defines
sub _desc { encode 'UTF-8', shift || shift }

1;
__END__

=encoding utf-8

=head1 NAME

Test::Mojo::Role::Routes - Write Mojo tests using named routes.

=head1 SYNOPSIS

  use Test::Mojo;
  my $t = Test::Mojo->with_roles('+Routes')->new('MyApp');

  $t->get_route_ok('dashboard')->status_is(200)->route_is('dashboard');

=head1 DESCRIPTION

Test::Mojo::Role::Routes allows you to use your named routes in tests.

=head1 AUTHOR

Brian Davis, BD3i LLC E<lt>bdiii@cpan.orgE<gt>

=head1 COPYRIGHT

This software is copyright (c) 2021 by Brian Davis and BD3i LLC.

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 SEE ALSO

=cut

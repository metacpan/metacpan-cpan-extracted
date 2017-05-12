package t::lib::Plugin;

use Mojo::Base 'Mojolicious::Plugin';

sub register {
  my($self, $app, $config) = @_;

  $app->routes->get('/info')->to(cb => sub { $_[0]->render(json => $config) });
}

1;

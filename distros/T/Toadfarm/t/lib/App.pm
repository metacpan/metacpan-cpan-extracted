package
  t::lib::App;
use Mojo::Base 'Mojolicious';

sub startup {
  my $self = shift;

  $self->routes->get('/dummy')->to(text => "Dummy\n");
}

1;

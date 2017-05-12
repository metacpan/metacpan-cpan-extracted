package
  t::App;

use Mojo::Base 'Mojolicious';

sub startup {
  my $self = shift;

  $self->routes->route('/')->to(cb => sub { shift->render(text => "yay\n") });
}

1;

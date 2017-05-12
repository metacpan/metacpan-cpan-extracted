package Wcpancover::Author;
use Mojo::Base 'Mojolicious::Controller';

# This action will render a template
sub index {
  my $self = shift;

  # Render template "front/index.html.ep"
  $self->render();
}

sub show {
  my $self = shift;

  # Render $page
  $self->render_not_found
    unless $self->render();
}

1;

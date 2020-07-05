package
  MyApp::Once;

use parent 'Zing::Process';

sub perform {
  my ($self) = @_;

  $self->log->fatal('shutting down');

  $self->winddown;

  sleep 1;

  return $self;
}

1;

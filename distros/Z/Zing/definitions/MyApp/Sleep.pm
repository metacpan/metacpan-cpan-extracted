package
  MyApp::Sleep;

use parent 'Zing::Process';

sub perform {
  my ($self) = @_;

  $self->log->warn('sleeping for 1 sec');

  sleep 1;

  return $self;
}

1;

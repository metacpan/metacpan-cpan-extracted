package
  MyApp::Version;

use parent 'Zing::Process';

our $VERSION = time;

sub install {
  [__PACKAGE__, [], 1]
}

sub perform {
  my ($self) = @_;

  $self->log->warn(version => $VERSION);

  sleep 1;

  return $self;
}

1;

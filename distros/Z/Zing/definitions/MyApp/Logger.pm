package
  MyApp::Logger;

use parent 'Zing::Process';

sub perform {
  my ($self) = @_;

  my $type = (qw(debug info warn fatal))[rand(4)];

  $self->log->$type($$, time, 'something happened');

  return $self;
}

1;

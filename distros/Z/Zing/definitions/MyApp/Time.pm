package
  MyApp::Time;

use parent 'Zing::Process';

my $i = 0;
my $time = time;

sub perform {
  my ($self) = @_;

  my $tick = ($i = (time == $time ? $i+1 : do{$time=time; 0}));

  $self->log->warn(tick => $tick);

  return $self;
}

1;

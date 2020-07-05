package
  MyApp::Timer;

use parent 'Zing::Timer';

use Zing::Queue;

sub perform {
  my ($self) = @_;

  my $queue = Zing::Queue->new(name => 'tasks');

  return $self unless my $data = $queue->recv;

  my $type = $data->{type};
  my $time = time;

  $self->log->warn("received $type from tasks queue at $time");

  return $self;
}

sub schedules {
  [
    # every hour
    ['@hourly', ['tasks'], { type => 'EA_HOUR' }],

    # every minute
    ['@minute', ['tasks'], { type => 'EA_MINUTE' }],

    # every ten minutes
    ['*/10 * * * *', ['tasks'], { type => 'EA_TEN_MINUTE' }],
  ]
}

1;

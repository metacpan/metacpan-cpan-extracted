package Test::Zing;

BEGIN {
  $ENV{ZING_HANDLE}  = 'main';
  $ENV{ZING_HOST}    = '0.0.0.0';
  $ENV{ZING_STORE}   = 'Zing::Store::Hash';
  $ENV{ZING_ENCODER} = 'Zing::Encoder::Dump';
  $ENV{ZING_TARGET}  = 'global';
}

use Zing::Daemon;
use Zing::Fork;
use Zing::Logic;
use Zing::Loop;
use Zing::Process;
use Zing::Timer;

use Data::Object::Space;

our $PIDS = $$ + 1;

# Zing::Daemon
{
  my $space = Data::Object::Space->new(
    'Zing::Daemon'
  );
  $space->inject(fork => sub {
    $ENV{ZING_TEST_FORK} || $PIDS++;
  });
  my $_start = $space->cop(
    'start'
  );
  $space->inject(start => sub {
    my ($self, @args) = @_;
    my $result = $_start->($self, @args);
    unlink $self->cartridge->pidfile;
    $result
  });
}

# Zing::Fork
{
  my $space = Data::Object::Space->new(
    'Zing::Fork'
  );
  $space->inject(_waitpid => sub {
    $ENV{ZING_TEST_WAIT_ONE}
    ? ($ENV{ZING_TEST_WAIT_ONE}++ == 1 ? 1 : -1)
    : ($ENV{ZING_TEST_WAIT} || -1);
  });
  $space->inject(execute => sub {
    my ($self) = @_;
    my $pid = $ENV{ZING_TEST_FORK} || $PIDS++;
    $self->space->load;
    my $process = $self->processes->{$pid} = $self->space->build(
      @{$self->scheme->[1]},
      parent => $self->parent,
      pid => $pid,
    );
    $process->execute;
    $process
  });
}

# Zing::Loop
{
  my $space = Data::Object::Space->new(
    'Zing::Loop'
  );
  $space->inject(execute => sub {
    my ($self, @args) = @_;
    $self->exercise(@args); # always run once
  });
}

# Zing::Process
{
  my $space = Data::Object::Space->new(
    'Zing::Process'
  );
  $space->inject(_kill => sub {
    $ENV{ZING_TEST_KILL} || 0;
  });
}

# Zing::Timer
{
  my $space = Data::Object::Space->new(
    'Zing::Timer'
  );
  $space->inject(_time => sub {
    $ENV{ZING_TEST_TIME} || time;
  });
  $space->inject(execute => sub {
    my ($self, @args) = @_;
    $self->exercise(@args); # always run once
  });
}

1;

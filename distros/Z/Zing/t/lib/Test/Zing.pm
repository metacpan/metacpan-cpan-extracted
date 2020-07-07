package Redis;

# safety measure
unless ($ENV{TEST_REDIS}) {
  *{"Redis::new"} = $INC{'Redis.pm'} = sub {
    require Carp;
    Carp::croak "Redis disabaled while testing"; undef
  };
}

package Test::Zing;

BEGIN {
  $ENV{ZING_HOST} = '0.0.0.0';
  $ENV{ZING_STORE} = 'Test::Zing::Store';
}

use Zing::Daemon;
use Zing::Fork;
use Zing::Logic;
use Zing::Loop;
use Zing::Process;
use Zing::Redis;
use Zing::Timer;

use Data::Object::Space;

our $PIDS = $$ + 1;

# Zing/Daemon
{
  my $space = Data::Object::Space->new(
    'Zing/Daemon'
  );
  $space->inject(fork => sub {
    $ENV{ZING_TEST_FORK} || $PIDS++;
  });
  my $_execute = $space->cop(
    'execute'
  );
  $space->inject(execute => sub {
    my ($self, @args) = @_;
    my $result = $_execute->($self, @args);
    unlink $self->pid_path;
    $result
  });
  $space->inject(start => sub {
    my ($self, @args) = @_;
    my $result = $self->execute(@args);
    unlink $self->pid_path;
    $result
  });
}

# Zing/Fork
{
  my $space = Data::Object::Space->new(
    'Zing/Fork'
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
      node => Zing::Node->new(pid => $pid),
      parent => $self->parent,
    );
    $process->execute;
    $process
  });
}

# Zing/Loop
{
  my $space = Data::Object::Space->new(
    'Zing/Loop'
  );
  $space->inject(execute => sub {
    my ($self, @args) = @_;
    $self->exercise(@args); # always run once
  });
}

# Zing/Process
{
  my $space = Data::Object::Space->new(
    'Zing/Process'
  );
  $space->inject(_kill => sub {
    $ENV{ZING_TEST_KILL} || 0;
  });
}

# Zing/Redis
{
  my $space = Data::Object::Space->new(
    'Zing/Redis'
  );
  my $other = Data::Object::Space->new(
    'Test/Zing/Store'
  );
  unless ($ENV{TEST_REDIS}) {
    $space->load;
    $other->load;
    for my $routine (@{$other->routines}) {
      next if $routine eq 'dump';
      next if $routine eq 'load';
      $space->inject($routine, $other->package->can($routine));
    }
  }
}

# Zing/Timer
{
  my $space = Data::Object::Space->new(
    'Zing/Timer'
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

use Zing::Store;

package Redis;

unless ($ENV{TEST_REDIS}) {
  *{"Redis::new"} = $INC{'Redis.pm'} = sub {
    require Carp;
    Carp::croak "Redis disabaled while testing"; undef
  };
}

package Zing::Store;

our $DATA = {};

unless ($ENV{TEST_REDIS}) {
  *{"Zing::Store::drop"} = sub {
    my ($self, $key) = @_;
    return int(!!delete $DATA->{$key});
  };
}

unless ($ENV{TEST_REDIS}) {
  *{"Zing::Store::keys"} = sub {
    my ($self, @key) = @_;
    my $re = join('|', $self->term(@key), $self->term(@key, '.*'));
    return [grep /$re/, keys %$DATA];
  };
}

unless ($ENV{TEST_REDIS}) {
  *{"Zing::Store::pop"} = sub {
    my ($self, $key) = @_;
    my $get = pop @{$DATA->{$key}} if $DATA->{$key};
    return $get ? $self->load($get) : $get;
  };
}

unless ($ENV{TEST_REDIS}) {
  *{"Zing::Store::pull"} = sub {
    my ($self, $key) = @_;
    my $get = shift @{$DATA->{$key}} if $DATA->{$key};
    return $get ? $self->load($get) : $get;
  };
}

unless ($ENV{TEST_REDIS}) {
  *{"Zing::Store::push"} = sub {
    my ($self, $key, $val) = @_;
    my $set = $self->dump($val);
    return push @{$DATA->{$key}}, $set;
  };
}

unless ($ENV{TEST_REDIS}) {
  *{"Zing::Store::recv"} = sub {
    my ($self, $key) = @_;
    my $get = $DATA->{$key};
    return $get ? $self->load($get) : $get;
  };
}

unless ($ENV{TEST_REDIS}) {
  *{"Zing::Store::send"} = sub {
    my ($self, $key, $val) = @_;
    my $set = $self->dump($val);
    $DATA->{$key} = $set;
    return 'OK';
  };
}

unless ($ENV{TEST_REDIS}) {
  *{"Zing::Store::size"} = sub {
    my ($self, $key) = @_;
    return $DATA->{$key} ? scalar(@{$DATA->{$key}}) : 0;
  };
}

unless ($ENV{TEST_REDIS}) {
  *{"Zing::Store::slot"} = sub {
    my ($self, $key, $pos) = @_;
    my $get = $DATA->{$key}->[$pos];
    return $get ? $self->load($get) : $get;
  };
}

unless ($ENV{TEST_REDIS}) {
  *{"Zing::Store::test"} = sub {
    my ($self, $key) = @_;
    return int exists $DATA->{$key};
  };
}

package Test::Zing;

BEGIN {
  $ENV{ZING_HOST} = '0.0.0.0';
}

use Zing::Daemon;
use Zing::Fork;
use Zing::Logic;
use Zing::Loop;
use Zing::Process;
use Zing::Timer;

use Data::Object::Space;

our $PIDS = $$ + 1;

# Zing/Daemon
{
  my $space = Data::Object::Space->new(
    'Zing/Daemon'
  );
  $space->inject(debug => sub {
    0 # noop
  });
  $space->inject(fatal => sub {
    0 # noop
  });
  $space->inject(info => sub {
    0 # noop
  });
  $space->inject(warn => sub {
    0 # noop
  });
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

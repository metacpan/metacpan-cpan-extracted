package Thrust::Window;

use common::sense;

our $AUTOLOAD;


sub AUTOLOAD {
  my ($self, @rest) = @_;

  my $type = ref($self) or die "$self is not an object";

  my $method = $AUTOLOAD;
  $method =~ s/.*://;

  return $self->_call($method, @rest);
}

sub _add_event {
  my ($self, $event, $cb) = @_;

  push @{ $self->{events}->{$event} }, $cb;
}

sub _trigger_event {
  my ($self, $event) = @_;

  foreach my $cb (@{ $self->{events}->{$event} }) {
    $cb->();
  }

  delete $self->{events}->{$event};
}

sub _call {
  my ($self, $method, $args, $cb) = @_;

  if (!defined $cb && ref $args eq 'CODE') {
    ## Allow you to omit the args parameter
    $cb = $args;
    $args = {};
  }

  die "arguments param is not a hashref" if defined $args && ref $args ne 'HASH';

  $cb ||= sub {};

  $self->_pre(sub {
    $self->{thrust}->do_action({ '_action' => 'call', '_target' => $self->{target}, '_method' => $method, '_args' => $args, }, $cb);
  });

  return $self;
}

sub _pre {
  my ($self, $cb) = @_;

  if (exists $self->{target}) {
    $cb->();
  } else {
    $self->_add_event('ready', $cb);
  }
}


sub _trigger {
  my ($self, $event, $args) = @_;

  foreach my $cb (@{ $self->{events}->{$event} }) {
    $cb->($args);
  }
}



sub on {
  my ($self, $event, $cb) = @_;

  push @{ $self->{events}->{$event} }, $cb;

  return $self;
}

sub clear {
  my ($self, $event) = @_;

  delete $self->{events}->{$event};

  return $self;
}

sub run {
  my ($self) = @_;

  $self->{thrust}->run;

  return $self;
}


1;

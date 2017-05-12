# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat::Core::Service;

use fields qw(connectors container name started);
use strict;
use warnings;

use Servlet::Util::Exception ();

sub new {
    my $self = shift;

    $self = fields::new($self) unless ref $self;
    $self->{connectors} = [];
    $self->{container} = undef;
    $self->{name} = undef;
    $self->{started} = undef;

    return $self;
}

# accessors

sub getContainer {
    my $self = shift;

    return $self->{container};
}

sub setContainer {
    my $self = shift;
    my $container = shift;

    my $oldContainer = $self->{container};
    $self->{container} = $container;

    if ($self->{started} && $self->{container}) {
        $container->start();
    }

    for my $connector (@{ $self->{connectors} }) {
        $connector->setContainer($self->{container});
    }

    if ($self->{started} && $oldContainer) {
        $oldContainer->stop();
    }

    return 1;
}

sub getName {
    my $self = shift;

    return $self->{name};
}

sub setName {
    my $self = shift;
    my $name = shift;

    $self->{name} = $name;

    return 1;
}

# public methods

sub await {
    my $self = shift;

    for my $connector (@{ $self->{connectors} }) {
        $connector->await();
    }

    return 1;
}


sub addConnector {
    my $self = shift;
    my $connector = shift;

    $connector->setContainer($self->getContainer());
    push @{ $self->{connectors} }, $connector;

    if ($self->{started} && $connector) {
        $connector->start();
    }

    return 1;
}

sub getConnectors {
    my $self = shift;

    return wantarray ? @{ $self->{connectors} } : $self->{connectors};
}

sub removeConnector
  {
    my $self = shift;
    my $connector = shift;

    my $j;
    for (my $i = 0; $i < @{ $self->{connectors} }; $i++)
      {
        if (ref $self->{connectors}->[$i] eq ref $connector)
          {
            $j = $i;
            last;
          }
      }

    return 1 unless defined $j;

    if ($self->{started} && $connector)
      {
        $connector->stop();
      }

    splice @{ $self->{connectors} }, $j, 1;

    return 1;
  }

# lifecycle methods

sub start {
    my $self = shift;

    if ($self->{started}) {
        my $msg = "start: service already started";
        Servlet::Util::Exception->throw($msg);
    }

    $self->{started} = 1;

    $self->getContainer()->start();

    for my $connector ($self->getConnectors()) {
        $connector->start();
    }

    return 1;
}

sub stop {
    my $self = shift;

    unless ($self->{started}) {
        my $msg = "stop: service not started";
        Servlet::Util::Exception->throw($msg);
    }

    undef $self->{started};

    for my $connector ($self->getConnectors()) {
        $connector->stop();
    }

    $self->getContainer()->stop();

    return 1;
}

1;
__END__

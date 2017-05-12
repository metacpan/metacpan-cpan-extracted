# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat::Core::Pipeline;

use base qw(Wombat::ValveContext);
use fields qw(basic container started state valves);
use strict;
use warnings;

use Servlet::ServletException ();
use Wombat::Exception ();

sub new {
    my $self = shift;
    my $container = shift;

    $self = fields::new($self) unless ref $self;

    $self->{basic} = undef;
    $self->{container} = undef;
    $self->{started} = undef;
    $self->{state} = undef;
    $self->{valves} = [];

    $self->setContainer($container) if $container;

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

    $self->{container} = $container;

    return 1;
}

# public methods

sub getBasic {
    my $self = shift;

    return $self->{basic};
}

sub setBasic {
    my $self = shift;
    my $valve = shift;

    my $oldBasic = $self->{basic};
    return 1 if ref $valve eq ref $oldBasic;

    $oldBasic->setContainer(undef) if $oldBasic;

    return 1 unless $valve;

    $valve->setContainer($self->{container});
    $self->{basic} = $valve;
    $self->{state} = undef;

    return 1;
}

sub addValve {
    my $self = shift;
    my $valve = shift;

    $valve->setContainer($self->{container});
    push @{ $self->{valves} }, $valve;

    $valve->start() if $self->{started};

    return 1;
}

sub getValves {
    my $self = shift;

    return $self->{basic} ?
        (@{ $self->{valves} }, $self->{basic}) :
            @{ $self->{valves} };
}

sub invoke {
    my $self = shift;

    $self->{state} = 0;
    $self->invokeNext(@_);

    return 1;
}

sub removeValve {
    my $self = shift;
    my $valve = shift;

    my $j = 0;
    for (my $i=0; $i < @{ $self->{valves} }; $i++) {
        if (ref $valve eq ref $self->{valves}->[$i]) {
            $j = $i;
            last;
        }
    }

    return 1 unless $j;

    splice @{ $self->{valves} }, $j, 1;
    $valve->setContainer(undef);

    $valve->stop() if $self->{started};

    return 1;
}

sub invokeNext {
    my $self = shift;

    my $subscript = $self->{state}++;
    my $numValves = @{ $self->{valves} };

    if ($subscript < $numValves) {
        $self->{valves}->[$subscript]->invoke(@_, $self);
    }
    elsif ($subscript == $numValves && $self->{basic}) {
        $self->{basic}->invoke(@_, $self);
    }
    else {
        my $msg = "invokeNext: no further valves configured";
        Servlet::ServletException->throw($msg);
    }

    return 1;
}

=pod

=head1 LIFECYCLE METHODS

=over

=item start()

Prepare for active use of this component. This method should be called
before any of the public methods of the component are utilized.

B<Throws:>

=over

=item B<Wombat::LifecycleException>

if the component has already been started

=back

=cut

sub start {
    my $self = shift;

    if ($self->{started}) {
        my $msg = "start: pipeline already started";
        Wombat::LifecycleException->throw($msg);
    }

    for my $valve (@{ $self->{valves} }) {
        $valve->start();
    }

    $self->{basic}->start() if $self->{basic};

    $self->{started} = 1;

    return 1;
}

=pod

=item stop()

Gracefully terminate active use of this component. Once this method
has been called, no public methods of the component should be
utilized.

B<Throws:>

=over

=item B<Wombat::LifecycleException>

if the component is not started

=back

=cut

sub stop {
    my $self = shift;

    unless ($self->{started}) {
        my $msg = "stop: pipeline not started";
        Wombat::LifecycleException->throw($msg);
    }

    undef $self->{started};

    $self->{basic}->stop() if $self->{basic};

    for my $valve (@{ $self->{valves} }) {
        $valve->stop();
    }

    return 1;
}

=pod

=back

=cut

# private methods

sub log {
    my $self = shift;

    $self->{container}->log(@_) if $self->{container};

    return 1;
}

1;
__END__

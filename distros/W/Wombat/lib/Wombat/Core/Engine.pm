# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat::Core::Engine;

use base qw(Wombat::Core::ContainerBase);
use fields qw(defaultHost);
use strict;
use warnings;

use Servlet::Util::Exception ();
use Wombat::Core::EngineValve ();

sub new {
    my $class = shift;

    my $self = fields::new($class);
    $self->SUPER::new();

    $self->{defaultHost} = undef;

    $self->{mapperClass} = 'Wombat::Core::EngineMapper';
    $self->{pipeline}->setBasic(Wombat::Core::EngineValve->new());

    return $self;
}

# accessors

sub getDefaultHost {
    my $self = shift;

    return $self->{defaultHost};
}

sub setDefaultHost {
    my $self = shift;
    my $defaultHost = shift;

    $self->{defaultHost} = lc $defaultHost;

    return 1;
}

# public methods

sub addChild {
    my $self = shift;
    my $child = shift;

    unless ($child->isa('Wombat::Core::Host')) {
        my $msg = "addChild: child container must be Host";
        Servlet::Util::IllegalArgumentException->throw($msg);
    }

    $self->SUPER::addChild($child);

    return 1;
}

sub setParent {
    my $msg = "setParent: Engine may not have a parent";
    Servlet::Util::IllegalArgumentException->throw($msg);
}

sub toString {
    my $self = shift;

    return sprintf "Engine[%s]", $self->getName();
}

1;
__END__

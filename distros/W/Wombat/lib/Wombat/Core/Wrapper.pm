# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat::Core::Wrapper;

use base qw(Servlet::ServletConfig Wombat::Core::ContainerBase);
use fields qw(available class facade instance loadOnStartup references runAs);
use fields qw(params);
use strict;
use warnings;

use Servlet::ServletException ();
use Servlet::Util::Exception ();
use Wombat::Core::WrapperFacade ();
use Wombat::Core::WrapperValve ();

sub new {
    my $self = shift;

    $self = fields::new($self) unless ref $self;
    $self->SUPER::new();

    # internal wrapper fields
    $self->{available} = 0;
    $self->{class} = undef;
    $self->{facade} = Wombat::Core::WrapperFacade->new($self);
    $self->{instance} = undef;
    $self->{loadOnStartup} = -1;
    $self->{references} = {};
    $self->{runAs} = undef;

    # Servlet::ServletConfig fields
    $self->{params} = {};

    $self->{pipeline}->setBasic(Wombat::Core::WrapperValve->new());

    return $self;
}

# accessors

sub getAvailable {
    my $self = shift;

    return $self->{available};
}

sub setAvailable {
    my $self = shift;
    my $secs = shift;

    # default to available now
    defined $secs || ($secs = 0);

    if ($secs && $secs > time) {
        # unavailable until this future time
        $self->{available} = $secs;
    } elsif ($secs) {
        # was unavailable at one time, but that time has now passed
        $self->{available} = 0;
    } else {
        # catches 0 (available now), -1 (permanently unavailable)
        $self->{available} = $secs;
    }

    $self->{available} = ($secs > time) ? $secs : 0;

    return 1;
}

sub isUnavailable {
    my $self = shift;

    # -1 means permanently unavailable
    # 0 means available now
    # > 0 is the unix time at which becomes available

    my $rv = 1;
    if ($self->{available} && $self->{available} <= time) {
        # was unavailable once, but no more
        $self->setAvailable(0);
        undef $rv;
    } elsif ($self->{available} == 0) {
        # available now
        undef $rv;
    } else {
        # unavailable, either temporarily (some time greater than now)
        # or permanently (-1)
    }

    return $rv;
}

sub addChild {
    my $self = shift;
    my $child = shift;

    my $msg = "addChild: child container not allowed";
    Servlet::Util::IllegalArgumentException->throw($msg);

    return 1;
}

sub getLoadOnStartup {
    my $self = shift;

    return $self->{loadOnStartup};
}

sub setLoadOnStartup {
    my $self = shift;
    my $order = shift;

    $self->{loadOnStartup} = $order;

    return 1;
}

sub addInitParameter {
    my $self = shift;
    my $name = shift;
    my $value = shift;

    $self->{params}->{$name} = $value;

    return 1;
}

sub getInitParameter {
    my $self = shift;
    my $name = shift;

    return $self->{params}->{$name};
}

sub getInitParameterNames {
    my $self = shift;

    my @params = keys %{ $self->{params} };

    return wantarray ? @params : \@params;
}

sub removeInitParameter {
    my $self = shift;
    my $name = shift;

    delete $self->{params}->{$name};

    return 1;
}

sub setParent {
    my $self = shift;
    my $container = shift;

    unless ($container && $container->isa('Wombat::Core::Application')) {
        my $msg = "setParent: parent container must be Application";
        Servlet::Util::IllegalArgumentException->throw($msg);
    }

    $self->SUPER::setParent($container);

    return 1;
}

sub getRunAs {
    my $self = shift;

    return $self->{runAs};
}

sub setRunAs {
    my $self = shift;
    my $runAs = shift;

    $self->{runAs} = $runAs;

    return 1;
}

sub addSecurityReference {
    my $self = shift;
    my $name = shift;
    my $link = shift;

    $self->{references}->{$name} = $link;

    return 1;
}

sub getSecurityReference {
    my $self = shift;
    my $name = shift;

    return $self->{references}->{$name};
}

sub getSecurityReferences {
    my $self = shift;

    my @references = keys %{ $self->{params} };

    return wantarray ? @references : \@references;
}

sub removeSecurityReference {
    my $self = shift;
    my $name = shift;

    delete $self->{references}->{$name};

    return 1;
}

sub getServletClass {
    my $self = shift;

    return $self->{class};
}

sub setServletClass {
    my $self = shift;
    my $class = shift;

    $self->{class} = $class;

    return 1;
}

# complements getServletName in the ServletConfig methods
sub setServletName {
    my $self = shift;
    my $name = shift;

    return $self->setName($name);
}

# public methods

sub allocate {
    my $self = shift;

    # XXXTHR

    $self->load() unless $self->{instance};

    return $self->{instance};
}

sub deallocate {
    my $self = shift;

    # XXXTHR

    return 1;
}

sub load {
    my $self = shift;

    return 1 if $self->{instance};

    unless ($self->{class}) {
        Servlet::ServletException->throw("servlet class unspecified");
    }

    # load the servlet class
    eval "require $self->{class}";
    if ($@) {
        $self->unavailable();
        my $msg = "servlet class load error [$self->{class}]";
        Servlet::ServletException->throw($msg, $@);
    }

    # instantiate the servlet class
    my $servlet;
    eval {
        $servlet = $self->{class}->new();
    };
    if ($@) {
        $self->unavailable();
        Servlet::ServletException->throw("servlet instantiation error", $@);
    }

    # special handling for ContainerServlet instances
    $servlet->setWrapper($self) if $servlet->isa('Wombat::ContainerServlet');

    # initialize the servlet
    eval {
        $servlet->init($self->{facade});
    };
    if ($@) {
        if ($@->isa('Servlet::UnavailableException')) {
            $self->unavailable($@);
            $@->rethrow();
        } elsif ($@->isa('Servlet::ServletException')) {
            $@->rethrow();
        } else {
            Servlet::ServletException->throw("servlet init error", $@);
        }
    }

    $self->{instance} = $servlet;
    $self->setAvailable();

    return 1;
}

sub toString {
    my $self = shift;

    my $parent = $self->getParent();
    my $str = sprintf "Wrapper[%s]", $self->getName();
    $str = sprintf "%s.%s", $parent->toString(), $str if $parent;

    return $str;
}

sub unavailable {
    my $self = shift;
    my $e = shift;

    $self->log("servlet unavailable");

    if (!$e || $e->isPermanent()) {
        $self->setAvailable(-1);
    } else {
        my $secs = $e->getUnavailableSeconds() || 60;
        $self->setAvailable(time + $secs);
    }

    return 1;
}

sub unload {
    my $self = shift;

    return 1 unless $self->{instance};

    eval {
        $self->{instance}->destroy();
    };

    undef $self->{instance};

    if ($@) {
        Servlet::ServletException->throw("destroy exception", $@);
    }

    return 1;
}

# ServletConfig methods

sub getServletContext {
    my $self = shift;

    my $parent = $self->getParent();

    return undef unless $parent && $parent->isa('Wombat::Core::Application');
    return $parent->getServletContext();
}

sub getServletName {
    my $self = shift;

    return $self->getName();
}

# lifecycle methods

sub stop {
    my $self = shift;

    eval {
        $self->unload();
    };
    if ($@) {
        $self->log("unload exception", $@);
    }

    return $self->SUPER::stop();
}

1;
__END__

package perfSONAR_PS::Collectors::LinkStatus::Agent::TL1;

use strict;
use warnings;
use Params::Validate qw(:all);
use Log::Log4perl qw(get_logger);
use perfSONAR_PS::ParameterValidation;

our $VERSION = 0.09;

use fields 'AGENT', 'PHYSPORT', 'TYPE', 'LOGGER';

my %signalMappings = (
        "normal" => 'up',
        "ok" => 'up',
        "los" => 'down',
        "lof" => 'down',
        "ais-l" => 'down',
        "rdi-l" => 'down',
        "sf-ber" => 'down',
        "sd-ber" => 'down',
        );

my %stateMappings = (
        "is-nr" => 'normaloperation',
        "is-anr" => 'unknown',
        "oos-au" => 'troubleshooting',
        "oos-auma" => 'troubleshooting',
        "oos-ma" => 'maintenance',
        );

sub new {
    my ($class, @params) = @_;

    my $parameters = validateParams(@params,
            {
            type => 1,
            hostType => 0,
            address => 0,
            port => 0,
            username => 0,
            password => 0,
            agent => 0,
            check_sonet => 0,
            check_optical => 0,
            check_ethernet => 0,
            physPort => 1,
            });

    my $self = fields::new($class);

    $self->{LOGGER} = get_logger("perfSONAR_PS::Collectors::LinkStatus::Agent::TL1");

    if (not $parameters->{agent} and
            (not $parameters->{hostType} or
             not $parameters->{address} or
             not $parameters->{port} or
             not $parameters->{username} or
             not $parameters->{password})
       ) {
        return;
    }

    if (not defined $parameters->{agent}) {
        $self->{AGENT} = perfSONAR_PS::Collectors::LinkStatus::Agent::TL1::Caching->new({
                username => $parameters->{username},
                password => $parameters->{password},
                type => $parameters->{hostType},
                address => $parameters->{address},
                port => $parameters->{port},
                cache_time => 5,
                check_sonet => $parameters->{check_sonet},
                check_optical => $parameters->{check_optical},
                check_ethernet => $parameters->{check_ethernet},
                logger => $self->{LOGGER},
                });
    } else {
        $self->{AGENT} = $parameters->{agent};
    }

    $self->{PHYSPORT} = $parameters->{physPort};
    $self->{TYPE} = $parameters->{type};

    if ($self->{TYPE} ne "admin" and $self->{TYPE} ne "oper") {
        return;
    }

    return $self;
}

sub run {
    my ($self) = @_;

    my ($signalState, $portState) = $self->{AGENT}->getPortStatus($self->{PHYSPORT});
    my $time = time;
    my ($operState, $adminState);

    if ($self->{TYPE} eq "oper") {
        my $signal = lc($signalState);
        my $operState;
        if (not defined $signalMappings{$signal}) {
            $operState = "unknown";
        } else  {
            $operState = $signalMappings{$signal};
        }
        return (0, $time, $operState);
    } else {
        my $state = lc($portState);
        my $adminState;
        if (not defined $stateMappings{$state}) {
            $adminState = "unknown";
        } else  {
            $adminState = $stateMappings{$state};
        }
        return (0, $time, $adminState);
    }
}

sub getType {
    my ($self) = @_;

    return $self->{TYPE};
}

sub setType {
    my ($self, $type) = @_;

    $self->{TYPE} = $type;

    return;
}

sub setPhysPort {
    my ($self, $physPort) = @_;

    $self->{PHYSPORT} = $physPort;

    return;
}

sub getPhysPort {
    my ($self) = @_;

    return $self->{PHYSPORT};
}

sub setAgent {
    my ($self, $agent) = @_;

    $self->{AGENT} = $agent;

    return;
}

sub getAgent {
    my ($self) = @_;

    return $self->{AGENT};
}

package perfSONAR_PS::Collectors::LinkStatus::Agent::TL1::Caching;

use strict;
use Params::Validate qw(:all);

use TL1;

use fields 'USERNAME', 'PASSWORD', 'TYPE', 'ADDRESS', 'PORT', 'TL1AGENT',
    'OPTICAL', 'SONET', 'ETHERNET', 'CACHE_TIME', 'CHECK_OPTICAL',
    'CHECK_SONET', 'CHECK_ETHERNET', 'TIME', 'LOGGER';

sub new {
    my ($class, @params) = @_;

    my $parameters = validateParams(@params,
            {
            type => 1,
            address => 1,
            port => 1,
            username => 1,
            password => 1,
            cache_time => 1,
            check_sonet => 0,
            check_optical => 0,
            check_ethernet => 0,
            logger => 1,
            });

    if (not defined $parameters->{type} and not defined $parameters->{address} and
            not defined $parameters->{port} and not defined $parameters->{username} and
            not defined $parameters->{password}) {
        return;
    }

    my $self = fields::new($class);


    $self->{TL1AGENT} = TL1->new(
            username => $parameters->{username},
            password => $parameters->{password},
            type => $parameters->{type},
            host => $parameters->{address},
            port => $parameters->{port}
            );

    $self->{USERNAME} = $parameters->{username};
    $self->{PASSWORD} = $parameters->{passwd};
    $self->{TYPE} = $parameters->{type};
    $self->{ADDRESS} = $parameters->{address};
    $self->{PORT} = $parameters->{port};

    $self->{CACHE_TIME} = $parameters->{cache_time};

    $self->{CHECK_OPTICAL} = 0;
    $self->{CHECK_SONET} = 1;
    $self->{CHECK_ETHERNET} = 0;

#	$self->{CHECK_OPTICAL} = $parameters->{check_optical} if (defined $parameters->{check_optical});
#	$self->{CHECK_SONET} = $parameters->{check_sonet} if (defined $parameters->{check_sonet});
#	$self->{CHECK_ETHERNET} = $parameters->{check_ethernet} if (defined $parameters->{check_ethernet});

    $self->{OPTICAL} = undef;
    $self->{SONET} = undef;
    $self->{ETHERNET} = undef;

    $self->{LOGGER} = $parameters->{logger};

    return $self;
}

sub getType {
    my ($self) = @_;

    return $self->{TYPE};
}

sub setType {
    my ($self, $type) = @_;

    $self->{TYPE} = $type;

    return;
}

sub setUsername {
    my ($self, $username) = @_;

    $self->{USERNAME} = $username;

    return;
}

sub getUsername {
    my ($self) = @_;

    return $self->{USERNAME};
}

sub setPassword {
    my ($self, $password) = @_;

    $self->{PASSWORD} = $password;

    return;
}

sub getPassword {
    my ($self) = @_;

    return $self->{PASSWORD};
}

sub setAddress {
    my ($self, $address) = @_;

    $self->{ADDRESS} = $address;

    return;
}

sub getAddress {
    my ($self) = @_;

    return $self->{ADDRESS};
}

sub setAgent {
    my ($self, $agent) = @_;

    $self->{TL1AGENT} = $agent;

    return;
}

sub getAgent {
    my ($self) = @_;

    return $self->{TL1AGENT};
}


sub getPortStatus {
    my ($self, $physPort) = @_;

    my $time = time;

    if (not defined $self->{TIME} or $time - $self->{TIME} > $self->{CACHE_TIME}) {
        $self->getCurrentData();
    }

    if ($self->{SONET}) {
        foreach my $port ( @{ $self->{SONET} } ) {
            if ($port->{'port'} eq $physPort) {
                return ($port->{'signal'}, $port->{'state'});
            }
        }
    }

    return ("unknown", "unknown");
}

sub getCurrentData {
    my ($self) = @_;

    print("getCurrentData\n");

    if (not $self->{CHECK_OPTICAL} and not $self->{CHECK_SONET} and not $self->{CHECK_ETHERNET}) {
        $self->{LOGGER}->debug("Nothing to check");
        return;
    }

    $self->{TL1AGENT}->connect();
    $self->{TL1AGENT}->login();

    if ($self->{CHECK_OPTICAL}) {
        my @res = $self->{TL1AGENT}->getOpticals();
        $self->{OPTICAL} = \@res;
    }

    if ($self->{CHECK_SONET}) {
        my @res = $self->{TL1AGENT}->getSonet();
        $self->{SONET} = \@res;
    }

    if ($self->{CHECK_ETHERNET}) {
        my @res = $self->{TL1AGENT}->getEthernet();
        $self->{ETHERNET} = \@res;
    }

    $self->{TL1AGENT}->disconnect();

    $self->{TIME} = time;

    return;
}

1;

# vim: expandtab shiftwidth=4 tabstop=4

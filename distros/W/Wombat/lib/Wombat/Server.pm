# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat::Server;

=pod

=head1 NAME

Wombat::Server - server class

=head1 SYNOPSIS

  my $wombat = Wombat::Server();
  $wombat->setHome('/usr/local/wombat');
  $wombat->setConfigFile('conf/server.xml');

  $wombat->start();
  $wombat->await();
  $wombat->stop();

=head1 DESCRIPTION

This class implements a Wombat server. It uses I<server.xml> to
configure a container hierarchy and provides methods for starting and
stopping the server. It is meant to be used in both standalone and
embedded mode, so it does not take care of standard daemon things,
like processing command line arguments or setting up signal
handlers. Those are the responsibilities of the surrounding
environment (eg a control script or mod_perl <Perl> section).

=cut

use fields qw(configFile home mapper services started);
use strict;
use warnings;

use Cwd ();
use Servlet::Util::Exception ();
use Wombat::Exception ();
use Wombat::Globals ();
use Wombat::Util::XmlMapper ();

=pod

=head1 CONSTRUCTOR

=over

=item new()

Create and return an instance, initializing fields to default values.

=back

=cut

sub new {
    my $self = shift;

    $self = fields::new($self) unless ref $self;

    $self->{home} = undef;
    $self->{mapper} = Wombat::Util::XmlMapper->new();
    $self->{services} = [];
    $self->{started} = undef;

    return $self;
}

=pod

=head1 ACCESSOR METHODS

=over

=item getConfigFile()

Return the location of the configuration file for this
Server. Defaults to I<server.xml> in the I<conf> subdirectory of
C<getHome()>.

=cut

sub getConfigFile {
    my $self = shift;

    return $self->{configFile} ||
        File::Spec->catfile($self->getHome(), 'conf', 'server.xml');
}

=pod

=item setConfigFile($configFile)

Set the location of the configuration file for this Server. If the
specified location is relative, then it will be absolutized using
C<getHome()>.

=over

=item B<Parameters:>

=over

=item $configFile

the location of the configuration file relative to the server's home
directory

=back

=back

=cut

sub setConfigFile {
    my $self = shift;
    my $configFile = shift;

    return 1 unless $configFile;

    $configFile = File::Spec->rel2abs($configFile, $self->getHome()) unless
        File::Spec->file_name_is_absolute($configFile);
    $self->{configFile} = $configFile;

    return 1;
}

=pod

=item getHome()

Return the home directory for this Server.

=cut

sub getHome {
    my $self = shift;

    return $self->{home};
}

=pod

=item setHome($home)

Set the home directory for this Server.

B<Parameters:>

=over

=item $home

the server home directory, specified absolutely

=back

B<Throws:>

=over

=item B<Servlet::Util::IllegalArgumentException>

if the specified directory is not specified absolutely

=back

=cut

sub setHome {
    my $self = shift;
    my $home = shift;

    return 1 unless $home;

    unless (File::Spec->file_name_is_absolute($home)) {
        my $msg = "setHome: home directory must be absolute [$home]";
        Servlet::Util::IllegalArgumentException($msg);
    }

    $self->{home} = $home;
    $ENV{WOMBAT_HOME} = $home;

    return 1;
}

=pod

=back

=head1 PUBLIC METHODS

=over

=item await()

Direct all defined Services to begin listening for requests. Depending
on Connector implementations, this method may return immediately (for
Connectors that execute asynchrously, eg Apache) or may block (eg Http
Connector).

=cut

sub await {
    my $self = shift;

    for my $service (@{ $self->{services} }) {
        $service->await();
    }

    return 1;
}

=pod

=item addService($service)

Add a new Service to the set of defined Services.

B<Parameters:>

=over

=item $service

the B<Wombat::Core::Service> to add

=back

=cut

sub addService {
    my $self = shift;
    my $service = shift;

    push @{ $self->{services} }, $service;

    return 1;
}

=pod

=item getServices()

Return an array containing all defined Services.

=cut

sub getServices {
    my $self = shift;

    my @services = @{ $self->{services} };

    return wantarray ? @services : \@services;
}

=pod

=item removeService($service)

Remove a Service from the set of defined Services.

B<Parameters:>

=over

=item $service

the B<Wombat::Core::Service> to remove

=back

=cut

sub removeService {
    my $self = shift;
    my $service = shift;

    my $j;
    for (my $i=0; $i < @{ $self->{services} }; $i++) {
        if ($service->getName() eq $self->{services}->[$i]->getName()) {
            $j = $i;
            last;
        }
    }

    splice @{ $self->{services} }, $j, 1 if defined $j;

    return 1;
}

=pod

=back

=head1 LIFECYCLE METHODS

=over

=item start()

Prepare for active use of this component. This method should be called
before any of the public methods of the component are utilized.

B<Throws:>

=over

=item B<Wombat::LifecycleException>

if the component has already been started

=item B<Wombat::XmlException>

if a problem occurs while parsing a config file

=item B<Wombat::ConfigException>

if a validity error is detected in a config file

=item B<Servlet::Util::IOException>

if an input or output error occurs

=back

=cut

sub start {
    my $self = shift;

    if ($self->{started}) {
        my $msg = "start: server already started";
        Wombat::LifecycleException->throw($msg);
    }

    $self->addServiceRules('Server');

    my $fh = Symbol::gensym;
    my $configFile = $self->getConfigFile();
    unless (open $fh, $configFile) {
        my $msg = "can't open config file [$configFile]: $!";
        Servlet::Util::IOException->throw($msg);
    }

    $self->{mapper}->readXml($fh, $self);
    close $fh;

    $self->{started} = 1;

    my $msg = sprintf("%s configured -- resuming normal operations",
                      Wombat::Globals::SERVER_INFO);

    for my $service (@{ $self->{services} }) {
        $service->start();
        $service->getContainer()->log($msg);
    }

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
        my $msg = "stop: server not started";
        Wombat::LifecycleException->throw($msg);
    }

    undef $self->{started};

    for my $service (@{ $self->{services} }) {
        $service->stop();
    }

    return 1;
}

# private methods

sub addServiceRules {
    my $self = shift;
    my $xpath = shift;

    $xpath .= '/Service';
    my $class = 'Wombat::Core::Service';

    $self->{mapper}->addRule($xpath,
                             $self->{mapper}->objectCreate($class));
    $self->{mapper}->addRule($xpath,
                             $self->{mapper}->setProperties());
    $self->{mapper}->addRule($xpath,
                             $self->{mapper}->addChild('addService'));

    $self->addConnectorRules($xpath);
    $self->addEngineRules($xpath);

    return 1;
}

sub addEngineRules {
    my $self = shift;
    my $xpath = shift;

    $xpath .= '/Engine';
    my $class = 'Wombat::Core::Engine';

    $self->{mapper}->addRule($xpath,
                             $self->{mapper}->objectCreate($class));
    $self->{mapper}->addRule($xpath,
                             $self->{mapper}->setProperties());
    $self->{mapper}->addRule($xpath,
                             $self->{mapper}->addChild('setContainer'));

    $self->addLoggerRules($xpath);
    $self->addRealmRules($xpath);
    $self->addSessionManagerRules($xpath);
    $self->addValveRules($xpath);

    # default host applications
    $self->addApplicationRules($xpath);

    $self->addHostRules($xpath);

    return 1;
}

sub addHostRules {
    my $self = shift;
    my $xpath = shift;

    $xpath .= '/Host';
    my $class = 'Wombat::Core::Host';

    $self->{mapper}->addRule($xpath,
                             $self->{mapper}->objectCreate($class));
    $self->{mapper}->addRule($xpath,
                             $self->{mapper}->setProperties());
    $self->{mapper}->addRule($xpath,
                             $self->{mapper}->addChild('addChild'));

    # aliases
    $self->{mapper}->addRule("$xpath/Alias",
                             $self->{mapper}->methodSetter('addAlias', 0));

    $self->addLoggerRules($xpath);
    $self->addRealmRules($xpath);
    $self->addSessionManagerRules($xpath);
    $self->addValveRules($xpath);

    $self->addApplicationRules($xpath);

    return 1;
}

sub addApplicationRules {
    my $self = shift;
    my $xpath = shift;

    $xpath .= '/Application';
    my $class = 'Wombat::Core::Application';

    $self->{mapper}->addRule($xpath,
                             $self->{mapper}->objectCreate($class));
    $self->{mapper}->addRule($xpath,
                             $self->{mapper}->setProperties());
    # XXX: application config
    $self->{mapper}->addRule($xpath,
                             $self->{mapper}->addChild('addChild'));

    $self->addLoggerRules($xpath);
    $self->addRealmRules($xpath);
    $self->addSessionManagerRules($xpath);
    $self->addValveRules($xpath);

    return 1;
}

sub addConnectorRules {
    my $self = shift;
    my $xpath = shift;

    $xpath .= '/Connector';

    $self->{mapper}->addRule($xpath,
                             $self->{mapper}->objectCreate(undef,
                                                           'className'));
    $self->{mapper}->addRule($xpath,
                             $self->{mapper}->setProperties());
    $self->{mapper}->addRule($xpath,
                             $self->{mapper}->addChild('addConnector'));

    $self->addEngineRules($xpath);

    return 1;
}

sub addLoggerRules {
    my $self = shift;
    my $xpath = shift;

    $xpath .= '/Logger';

    $self->{mapper}->addRule($xpath,
                             $self->{mapper}->objectCreate(undef,
                                                           'className'));
    $self->{mapper}->addRule($xpath,
                             $self->{mapper}->setProperties());
    $self->{mapper}->addRule($xpath,
                             $self->{mapper}->addChild('setLogger'));

    return 1;
}

sub addRealmRules {
    my $self = shift;
    my $xpath = shift;

    $xpath .= '/Realm';

    $self->{mapper}->addRule($xpath,
                             $self->{mapper}->objectCreate(undef,
                                                           'className'));
    $self->{mapper}->addRule($xpath,
                             $self->{mapper}->setProperties());
    $self->{mapper}->addRule($xpath,
                             $self->{mapper}->addChild('setRealm'));

    return 1;
}

sub addSessionManagerRules {
    my $self = shift;
    my $xpath = shift;

    $xpath .= '/SessionManager';

    $self->{mapper}->addRule($xpath,
                             $self->{mapper}->objectCreate(undef,
                                                           'className'));
    $self->{mapper}->addRule($xpath,
                             $self->{mapper}->setProperties());
    $self->{mapper}->addRule($xpath,
                             $self->{mapper}->addChild('setSessionManager'));

    return 1;
}

sub addValveRules {
    my $self = shift;
    my $xpath = shift;

    $xpath .= '/Valve';

    $self->{mapper}->addRule($xpath,
                             $self->{mapper}->objectCreate(undef,
                                                           'className'));
    $self->{mapper}->addRule($xpath,
                             $self->{mapper}->setProperties());
    $self->{mapper}->addRule($xpath,
                             $self->{mapper}->addChild('addValve'));

    return 1;
}

1;
__END__

=back

=head1 SEE ALSO

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut



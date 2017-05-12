# $Id: Server.pm,v 1.3 2003/04/08 00:27:30 cwest Exp $
package POEST::Server;

=pod

=head1 NAME

POEST::Server - The Poest Master General

=head1 SYNOPSIS

 my $server = POEST::Server->new(
   Config     => 'POEST::Config::Genearl',
   ConfigFile => '/etc/poest.conf',
 );
 
 $server->start;

=head1 ABSTRACT

This module controls the server itself.

=head1 DESCRIPTION

All high-level server interaction happens here.

=cut

use strict;
$^W = 1;
$0  = 'poest';

use vars qw[$VERSION];
$VERSION = (qw$Revision: 1.3 $)[1];

use POE qw[Component::Server::SMTP];
use Carp;
use POSIX ();

sub CONFIG () { [ qw[plugin hostname port pidfile] ] }

=head2 new()

Create a new server instance.  This will not make the server run, but
it will configure it, load the modules and configure them, and spawn
the proper POE sessions.  All the parameters passed to new will be
passed directly to the configurator of your choice, as defined by the
C<Config> parameter (L<POEST::Config|POEST::Config> by default).

=cut

sub new {
	my ($class, %args) = @_;

	my $self = bless \%args, $class;

	$self->{Config} ||= 'POEST::Config';

	eval qq[use $self->{Config}];
	croak $@ if $@;
	croak "$self->{Config} is broken, please fix it or use another"
		unless $self->{Config}->can( 'new' ) &&
			$self->{Config}->can( 'config' ) &&
			$self->{Config}->can( 'set' ) &&
			$self->{Config}->can( 'get' );

	$self->{config} = $self->{Config}->new( %args );

	my %config = %{ $self->{config}->get( @{$self->CONFIG} ) };

	$self->{conf} = \%config;

	croak "No plugins configured, server would be useless"
	  unless exists $config{plugin};

	my (@plugins) = ref $config{plugin} ?
		@{ $config{plugin} } : $config{plugin};

	my @pobjects = ();
	foreach my $plugin ( @plugins ) {
		eval qq[use $plugin];
		croak $@ if $@;
		croak "$plugin is broken, it doesn't conform to POEST::Plugin specs"
			unless $plugin->can( 'new' ) &&
				$plugin->can( 'EVENTS' ) &&
				$plugin->can( 'CONFIG' );

		my $pobject = $plugin->new(
			%{ $self->{config}->get( @{ $plugin->CONFIG } ) }
		);
		push @pobjects, $pobject, $plugin->EVENTS;
	}
	
	$self->{pobjects} = \@pobjects;

	return $self;
}

=head2 run()

Make the server run.  This will block execution when called directly.

=cut

sub run {
	my ($self) = @_;

	POE::Component::Server::SMTP->spawn(
		Hostname     => $self->{conf}->{hostname},
		Port         => $self->{conf}->{port},
		ObjectStates => $self->{pobjects},
	);

	$poe_kernel->run;
	exit(0);
}

=head2 start()

Fork and start the server.  This method will return the pid of the
server.  If the C<pidfile> configuration parameter is found in the
configuration class, an attempt is made to write that pid file.  If
that attempt fails, or if the pid file already exists, and exception
is thrown and the attempt to start the server is stalled.

=cut

sub start {
	my ($self) = shift;
	
	my $pid = fork;
	if ( ! defined $pid ) {
		croak "Couldn't start poest: $!";
	} elsif ($pid) {
		$self->{pid} = $pid;
		if ( $self->{conf}->{pidfile} ) {
			croak "PID file already exists, delete it and start again."
				if -e $self->{conf}->{pidfile};

			open PID, "> $self->{conf}->{pidfile}"
				or die "Can't write $self->{conf}->{pidfile}: $!\n";
			flock PID, 2;
			print PID "$self->{pid}\n";
			flock PID, 8;
			close PID or die "Can't close $self->{conf}->{pidfile}: $!\n";
		}

		POSIX::setsid();
		umask(0);

		open(STDIN,  '</dev/null');
		open(STDOUT, '>/dev/null');
		open(STDERR, '>&STDOUT'  );

		exit 0;
	}

	$self->run;
}

=head2 stop()

Stop the server.  If a pidfile was specified, the pid will be read
from it.  Otherwise, an attempt to find a process name with the value
of C<$0> is tried, by default that is set to 'poest'.

B<NOTE>: As of right this minute, the process table magic isn't written
as L<Proc::ProcessTable|Proc::ProcessTable> isn't ported to Darwin.

=cut

sub stop {
	my ($self) = @_;
	
	if ( $self->{conf}->{pidfile} ) {
		croak "PID file doesn't exist, manual kill is required."
			unless -e $self->{conf}->{pidfile};
		open PID, "< $self->{conf}->{pidfile}"
			or die "Can't read $self->{conf}->{pidfile}: $!\n";
		chomp( $self->{pid} = <PID> );
		close PID or die "Can't close $self->{conf}->{pidfile}: $!\n";
		unlink $self->{conf}->{pidfile}
			or die "Can't unlink $self->{conf}->{pidfile}: $!\n";
	} elsif ( $self->{pid} ) {
		# Cool.
	} else {
		croak "PID file was not specified in the configuration."
	}
	
	if ( kill 0, $self->{pid} ) {
		kill 15, $self->{pid};
	} else {
		croak "Server is not running.";
	}
}

1;

__END__

=pod

=head2 Configuration

Thses are the configuration parameters that the server itself needs
from the configuration mechanism.

=head3 hostname

The main host that this smtp server runs for.

=head3 port

The port this server will run on.

=head3 plugin

This is a multi-value parameter.  Each value is the full name of the
module that contains the plugin class.

=head1 AUTHOR

Casey West, <F<casey@dyndns.org>>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 DynDNS.org

You may distribute this package under the terms of either the GNU
General Public License or the Artistic License, as specified in the Perl
README file, with the exception that it may not be placed on physical
media for distribution without the prior written approval of the author.

THIS PACKAGE IS PROVIDED WITH USEFULNESS IN MIND, BUT WITHOUT GUARANTEE
OF MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE. USE IT AT YOUR
OWN RISK.

For more information, please visit http://opensource.dyndns.org

=head1 SEE ALSO

L<perl>, L<POEST::Plugin>, L<POEST::Config>, L<POEST::Server::Commands>.

=cut

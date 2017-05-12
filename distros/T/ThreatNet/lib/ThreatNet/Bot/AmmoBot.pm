package ThreatNet::Bot::AmmoBot;

=pod

=head1 NAME

ThreatNet::Bot::AmmoBot - Tail threat messages from a file to ThreatNet

=head1 DESCRIPTION

C<ThreatNet::Bot::AmmoBot> is the basic foot soldier of the ThreatNet
bot ecosystem, fetching ammunition and bringing it to the channel.

It connects to a single ThreatNet channel, and then tails one or more
files scanning for threat messages while following the basic channel
rules.

When it sees a L<ThreatNet::Message::IPv4>-compatible message appear
at the end of the file, it will report it to the channel (subject to
the appropriate channel rules).

Its main purpose is to make it as easy as possible to connect any system
capable of writing a log file to ThreatNet. If an application can be
configured or coded to spit out the appropriately formatted messages to
a file, then C<ammobot> will patiently watch for them and then haul them
off to the channel for you (so you don't have to).

It the data can be extracted from an existing file format, then a
C<Filter> property can be set which will specify a class to be used
as a customer L<POE::Filter> for the event stream.

=head1 METHODS

=cut

use strict;
use Params::Util '_INSTANCE';
use POE 'Wheel::FollowTail',
        'Component::IRC',
        'Component::IRC::Plugin::Connector';
use ThreatNet::Message::IPv4       ();
use ThreatNet::Filter::Chain       ();
use ThreatNet::Filter::Network     ();
use ThreatNet::Filter::ThreatCache ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.20';
}





#####################################################################
# Constructor and Accessors

=pod

=head2 new %args

The isn't really any big reason that you would be wanting to instantiate
a C<ThreatNet::Bot::AmmoBot> yourself, but if it comes to that you do
it by simply passing a list of the appropriate arguments to the C<new>
method.

  # Create the ammobot
  my $Bot = ThreatNet::Bot::AmmoBot->new( %args );
  
  # Run the ammobot
  $Bot->run;

=cut

sub new {
	my ($class, %args) = @_;

	# Check the args
	$args{Nick}     or die "Did not specify a nickname";
	$args{Channel}  or die "Did not specify a channel";
	$args{Channel} =~ /^\#\w+$/
			or die "Invalid channel specification";
	$args{Server}   or die "Did not specify a server";
	$args{Port}     ||= 6667;
	$args{Username} ||= $args{Nick};
	$args{Ircname}  ||= $args{Nick};
	$args{Tails}    = {};

	# Create the IRC client
	unless ( _INSTANCE($args{IRC}, 'POE::Component::IRC') ) {
		$args{IRC} = POE::Component::IRC->spawn
			or die "Failed to create new IRC server: $!";
	}

	# Create the empty object
	my $self = bless {
		running => '',
		args    => \%args,
		}, $class;

	$self;
}

=pod

=head2 args

The C<args> accessor returns the argument hash.

=cut

sub args { $_[0]->{args} }

=pod

=head2 tails

The C<tails> accessor returns the C<HASH> of C<FollowTail> objects
indexed by file name.

=cut

sub tails { $_[0]->{args}->{Tails} }

=pod

=head2 running

The C<running> accessor returns true if the bot is currently
running, or false if the bot has not yet started.

=cut

sub running { $_[0]->{running} }

=pod

=head2 Session

Once the bot has started, the C<Session> accessor provides direct access
to the L<POE::Session> object for the bot.

=cut

sub Session { $_[0]->{Session}       }

=pod

=head2 files

The C<files> accessor returns a list of the files the bot is tailing
(or will be tailing), or in scalar context returns the number of files.

=cut

sub files {
	my $self = shift;
	wantarray
		? (sort keys %{$self->tails})
		: scalar(keys %{$self->tails});
}

=pod

=head2 add_file $file [, Filter => $POEFilter ]

Once you have created the Bot object, the C<add_file> method is used to
add the list of files that the bot will be tailing.

It takes as argument a file name, followed by a number of key/value
parameters.

For the time being, the only available param is C<"Filter">. The filter
param provides a class name. The class will be loaded if needed, and
then a new default object of it created and used as a custom
L<POE::Filter> for the file.

=cut

sub add_file {
	my $self = shift;
	$self->running and die "Cannot add files once the bot is running";
	my $file = ($_[0] and ( -p $_[0] or -f $_[0] ) and -r $_[0]) ? shift
		: die "Invalid file '$_[0]'";
	if ( $self->tails->{$file} ) {
		die "File '$file' already attached to bot";
	}

	# Create the basic FollowTail params
	my %args = @_;
	my %Params = (
		Filename     => $file,
		PollInterval => 1,
		InputEvent   => 'tail_input',
		ErrorEvent   => 'tail_error',
		);

	# Add the optional params if needed
	if ( _INSTANCE($args{Driver}, 'POE::Driver') ) {
		$Params{Driver} = $args{Driver};
	} elsif ( $args{Driver} ) {
		die "Driver param was not a valid POE::Driver";
	}
	if ( _INSTANCE($args{Filter}, 'POE::Filter') ) {
		$Params{Filter} = $args{Filter};
	} elsif ( $args{Filter} ) {
		die "Filter param was not a valid POE::Filter";
	}

	# Save the FollowTail params
	$self->tails->{$file} = \%Params;

	1;
}

=pod

=head2 run

Once the bot has been created, and all of the files have been added, the
C<run> method is used to start the bot, and connect to the files and the
IRC server.

The method dies if the bot has not had any files added.

=cut

sub run {
	my $self = shift;
	unless ( $self->files ) {
		die "Refusing to start, no files added";
	}

	# Create the Session
	$self->{Session} = POE::Session->create(
		inline_states => {
			_start           => \&_start,
			stop             => \&_stop,

			tail_input       => \&_tail_input,
			tail_error       => \&_tail_error,

			irc_001          => \&_irc_001,
			irc_socketerr    => \&_irc_socketerr,
			irc_disconnected => \&_irc_disconnected,
			irc_public       => \&_irc_public,

			threat_receive   => \&_threat_receive,
			threat_send      => \&_threat_send,
			},
		args => [ $self->args ],
		);

	$self->{running} = 1;
	POE::Kernel->run;
}





#####################################################################
# POE Event Handlers

# Add a file
# Called when the Kernel fires up
sub _start {
	%{$_[HEAP]} = %{$_[ARG0]};

	# Create the main message i/o filter
	$_[HEAP]->{ThreatCache} = ThreatNet::Filter::ThreatCache->new
		or die "Failed to create ThreatCache Filter";
	$_[HEAP]->{Filter} = ThreatNet::Filter::Chain->new(
		ThreatNet::Filter::Network->new( discard => 'rfc3330' ),
		$_[HEAP]->{ThreatCache},
		) or die "Failed to create Message I/O Filter";

	# Register for events and connect to the server
	$_[HEAP]->{IRC}->yield( register => 'all' );
	$_[HEAP]->{IRC}->plugin_add(
		'Connector' => POE::Component::IRC::Plugin::Connector->new( delay => 60 )
		);
	$_[HEAP]->{IRC}->yield( connect  => {
		Nick     => $_[HEAP]->{Nick},
		Server   => $_[HEAP]->{Server},
		Port     => $_[HEAP]->{Port},
		$_[HEAP]->{Flood}
			? (Flood => 1)
			: (),
		$_[HEAP]->{ServerPassword}
			? (Password => $_[HEAP]->{ServerPassword})
			: (),
		Username => $_[HEAP]->{Username},
		Ircname  => $_[HEAP]->{Ircname},
		} );

	# Initialize the tails
	my $Tails = $_[HEAP]->{Tails};
	foreach my $key ( sort keys %$Tails ) {
		$Tails->{$key} = POE::Wheel::FollowTail->new( %{$Tails->{$key}} )
			or die "Failed to create FollowTail for $key";
	}
}

sub _stop {
	# Stop tailing the files
	delete $_[HEAP]->{Tails};

	# Disconnect from IRC
	if ( $_[HEAP]->{IRC} ) {
		if ( $_[HEAP]->{IRC}->connected ) {
			$_[HEAP]->{IRC}->yield( quit => 'Controlled shutdown' );
		}
		delete $_[HEAP]->{IRC};
	}

	1;
}





#####################################################################
# The Tailing of the File

sub _tail_input {
	my $input = $_[ARG0];
	chomp $input;

	# Does the input line form a valid message?
	my $Message = ThreatNet::Message::IPv4->new( $input ) or return;

	# Send the Message to the channel (or not, for now)
	$_[KERNEL]->yield( threat_send => $Message );
}

sub _tail_error {
	$_[KERNEL]->yield( stop => 1 );
}





#####################################################################
# IRC Events

# Connected
sub _irc_001 {
	$_[HEAP]->{IRC}->yield( join => $_[HEAP]->{Channel} );
}

# Failed to connect
sub _irc_socketerr {
	$_[KERNEL]->yield( stop => 1 );
}

# We were disconnected
### FIXME - Make this reconnect
sub _irc_disconnected {
	if ( $_[HEAP]->{IRC} ) {
		$_[KERNEL]->yield( stop => 1 );
	} else {
		# Already shutting down, do nothing
	}
}

# Normal channel message
sub _irc_public {
	my ($who, $where, $msg) = @_[ARG0, ARG1, ARG2];

	# Is this a ThreatNet message?
	my $Message = ThreatNet::Message::IPv4->new($msg);
	if ( $Message ) {
		# Pass the message through the channel i/o filter
		$_[HEAP]->{Filter}->keep($Message) or return;

		# Hand off to the threat_receive message
		return $_[KERNEL]->yield( threat_receive => $Message );
	}

	# Is this an addressed message?
	my $Nick = $_[HEAP]->{Nick};
	return unless $msg =~ /^$Nick(?::|,)?\s+(\w+)\b/;
	my $command = lc $1;
	return unless lc($1) eq 'status';

	# Generate stats
	my $stats = $_[HEAP]->{ThreatCache}->stats;
	my $message = "Online $stats->{time_running} seconds. $stats->{seen} events at $stats->{rate_seen}/s with $stats->{kept} kept and $stats->{size} currently in the ThreatCache. $stats->{percent_discard} synced with the channel";
	$_[HEAP]->{IRC}->yield( privmsg => $_[HEAP]->{Channel}, $message );
}





#####################################################################
# ThreatNet Events

# We just do nothing normally
sub _threat_receive {
	1;
}

sub _threat_send {
	my $Message = $_[ARG0];

	# Pass it through the filter
	$_[HEAP]->{Filter}->keep($Message) or return;

	# Occasionally the IRC object is missing.
	# I'm not entirely sure why this is the case, but it
	# isn't very expensive to just check, and drop any
	# messages if it's not there.
	return unless $_[HEAP]->{IRC};

	# Send the message immediately
	$_[HEAP]->{IRC}->yield( privmsg => $_[HEAP]->{Channel}, $Message->message );
}

1;

=pod

=head1 TO DO

- Add support for additional outbound filters

=head1 SUPPORT

All bugs should be filed via the bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ThreatNet-Bot-AmmoBot>

For other issues, or commercial enhancement and support, contact the author

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<http://ali.as/devel/threatnetwork.html>, L<POE>

=head1 COPYRIGHT

Copyright (c) 2005 Adam Kennedy. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

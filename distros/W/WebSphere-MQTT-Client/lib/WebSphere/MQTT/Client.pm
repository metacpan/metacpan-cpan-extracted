package WebSphere::MQTT::Client;

################
#
# MQTT: WebSphere MQ Telemetry Transport
#

use strict;
use Sys::Hostname;
use Time::HiRes;
use XSLoader;
use Carp;

use vars qw/$VERSION/;

$VERSION="0.03";

XSLoader::load('WebSphere::MQTT::Client', $VERSION);



sub new {
    my $class = shift;
    my (%args) = @_;
    
 	# Store parameters
    my $self = {
    	'host'		=> '127.0.0.1',	# broker's hostname (localhost)
    	'port'		=> 1883,		# broker's port
    	'clientid'	=> undef,		# our client ID
    	'debug'		=> 0,			# debugging disabled
  	
 
    	# Advanced options (with sensible defaults)
    	'clean_start'	=> 1,			# set CleanStart flag ?
    	'keep_alive'	=> 10,			# timeout (in seconds) for receiving data
    	'retry_count'	=> 10,
    	'retry_interval' => 10,
    	'async'			=> 0,
    	'persist'		=> undef,

		# Used internally only    	
  		'handle'		=> undef,	# Connection Handle
		'txqueue'		=> [],		# TX messages in transit
 		'send_task_info'	=> undef,	# Send Thread Parameters
 		'recv_task_info'	=> undef,	# Receive Thread Parameters
		'api_task_info'		=> undef,	# API Thread Parameters

		# TODO: LWT stuff
		#'lwt_enabled'	=> 0,
		#'lwt_message'	=> undef,
		#'lwt_qos'		=> 0,
		#'lwt_topic'	=> undef,
		#'lwt_retain'	=> 0,

    };
    
    # Bless the hash into an object
    bless $self, $class;

    # Arguments specified ?
		foreach (keys %args) {
			my $key = $_;
			$key =~ tr/A-Z/a-z/;
			$key =~ s/\W/_/g;
			$key = 'host' if ($key eq 'hostname');
			$self->{$key} = $args{$_};
		}
    
    # Generate a Client ID if we don't have one 
    if (defined $self->{'clientid'}) {
    	$self->{'clientid'} = substr($self->{'clientid'}, 0, 23);
  	} else {
		my $hostname = hostname();
		my ($host, $domain) = ($hostname =~ /^([^\.]+)\.?(.*)$/);
    	$self->{'clientid'} = substr($host, 0, 22-length($$)).'-'.$$;
    }

	# Start threads (if enabled)
	$self->xs_start_tasks() or die("xs_start_tasks() failed");

	# Dump configuration if Debug is enabled
	$self->dump_config() if ($self->{'debug'});

	return $self;
}


sub dump_config {
	my $self = shift;
	
	print "\n";
	print "WebSphere::MQTT::Client config\n";
	print "==============================\n";
	foreach( sort keys %$self ) {
		printf(" %15s: %s\n", $_, $self->{$_});
	}
	print "\n";

}


sub debug {
	my $self = shift;
	my ($debug) = @_;
	
	if (defined $debug) {
		if ($debug) { $self->{'debug'} = 1; }
		else		{ $self->{'debug'} = 0; }
	}
	
	return $self->{'debug'};
}



sub connect {
	my $self = shift;	
	
	# Connect
	my $result = $self->xs_connect( $self->{'api_task_info'} );

	# Print the result if debugging enabled
	print "xs_connect: $result\n" if ($self->{'debug'});

	return $result unless($result eq 'OK');

	# New feature in 0.02: an asynchronous connect returns immediately.
	# The state will sit in CONNECTING for as long as retries take place.
	# This allows outbound messages to be published (and queued locally
	# if QOS>0), even if the remote server is currently down.
	#
	# Note: when all the retries are used up, the state changes to
	# CONNECTION_BROKEN and no publishing can take place until you call
	# connect() again
	#
	return 0 if ($self->{'async'});
	
	# Wait until we are connected
	# FIXME: *with timeout*
	while (1) {
		$result = $self->status();
		last unless $result eq 'CONNECTING';
		select(undef, undef, undef, 0.5);  # short sleep
	}
	
	# Failed to connect ?
	if ($result ne 'CONNECTED') {
		$self->disconnect();
		# backwards compatibility
		return 'FAILED' if ($result eq 'CONNECTION_BROKEN');
		return $result;
	}
	
	# Success
	return 0;
}

sub disconnect {
	my $self = shift;

	# Allow 10 seconds for any messages in transit to be delivered
	for (my $tries=0; $self->txQueueSize > 0 && $tries < 10; $tries++) {
		sleep 1;
	}
	$self->{'txqueue'} = [];

	# Disconnect
	my $result = $self->xs_disconnect();
	
	# Print the result if debugging enabled
	print "xs_disconnect: $result\n" if ($self->{'debug'});
				
	# Return 0 if result is OK
	return 0 if ($result eq 'OK');
	return $result;
}

sub publish {
	my $self = shift;
	my ($data, $topic, $qos, $retain, $cbfunc, $cbarg) = @_;

	croak("Usage: publish(data, topic, [qos, [retain]]") unless ((defined $data) && (defined $topic));
	$qos = 0 unless (defined $qos);
	$retain = 0 unless (defined $retain);

	# Keep the queue of TX message IDs tidy, because publishing a message
	# may allocate a new message ID (possibly re-using an old one).
	# Also gives an opportunity to invoke callbacks.
	$self->txQueueSize;

	# Publish
	my ($result,$hmsg) = $self->xs_publish( $data, $topic, $qos, $retain );

	# Print the result if debugging enabled
	print "xs_publish[$data][$topic]: $result, $hmsg\n" if ($self->{'debug'});

	return $result if $result ne 'OK';

	# New feature in 0.03: caller can provide callback function
	# and argument, which will be invoked when message has had
	# its delivery ACK'd.
	# This allows QOS 1 publishers to use their existing queue
	# without copying into the MQISDP persistence layer.
	if ($cbfunc && $qos) {
		push @{$self->{'txqueue'}}, [$hmsg, $cbfunc, $cbarg];
	}
	return 0;
}

sub subscribe {
	my $self = shift;
	my ($topic, $qos) = @_;
	
	croak("Usage: subscribe(topic, [qos])") unless (defined $topic);
	$qos = 0 unless (defined $qos);

	# Subscribe
	my $result = $self->xs_subscribe( $topic, $qos );
	
	# Print the result if debugging enabled
	print "xs_subscribe[$topic]: $result\n" if ($self->{'debug'});
				
	# Return 0 if result is OK
	return 0 if ($result eq 'OK');
	return $result;
}


sub receivePub {
	my $self = shift;
	# my(%args) = @_;
	# FIXME: only receive messages which look like match=>'patt'

	$self->txQueueSize;
	my $result = $self->xs_receivePub();

	# Print the result if debugging enabled
	if ($self->{'debug'}) {
		print "xs_receivePub[".$result->{'topic'}."]: ";
		print $result->{'data'}."\n";
	}

	# Note: if an error occurs (e.g. connection lost), we will get
	# $result->{'status'} but nothing else. For API compatibility, we
	# will treat this as a fatal error. If the application cares, it can
	# use eval to catch this.
	croak("receivePub status: $result->{'status'}") if
	  ($result->{'status'} ne 'OK' && $result->{'status'} ne 'PUBS_AVAILABLE');
	
	return ( $result->{'topic'}, $result->{'data'}, $result->{'options'} );
}

sub unsubscribe {
	my $self = shift;
	my ($topic) = @_;
	
	croak("Usage: unsubscribe(topic)") unless (defined $topic);

	# Subscribe
	my $result = $self->xs_unsubscribe( $topic );
	
	# Print the result if debugging enabled
	print "xs_unsubscribe[$topic]: $result\n" if ($self->{'debug'});
				
	# Return 0 if result is OK
	return 0 if ($result eq 'OK');
	return $result;
}


sub status {
	my $self = shift;
	$self->txQueueSize;
	return $self->xs_status();
}

# 
# Check the status of any messages 'in transit', perform callbacks for
# those which have been delivered or dropped, and return the number of
# messages still left
# 
sub txQueueSize {
	my $self = shift;
	my $q = $self->{'txqueue'};
	return 0 unless @$q;
	my $i = 0;
	#print "--- txQueue ---\n";
	while ($i < @$q) {
		my ($hmsg, $cbfunc, $cbarg) = @{$q->[$i]};
		my $s = $self->xs_getMsgStatus($hmsg);
		#print "Message $hmsg status $s\n";
		if ($s eq 'DELIVERED') {
			$cbfunc->(0, $cbarg);	# success
			splice @$q, $i, 1;
		}
		elsif ($s =~ /ERROR/) {
			$cbfunc->($s, $cbarg);	# fail
			splice @$q, $i, 1;
		}
		else {
			$i++;			# still in transit
		}
	}
	return scalar(@$q);
}

sub terminate {
	my $self = shift;

	# Disconnect first (if connected)
	if (exists $self->{'handle'} and defined $self->{'handle'}) {
		$self->disconnect();
	}

	# Terminate threads and free memory
	my $result = $self->xs_terminate();	
	
	# Return 0 if result is OK
	return 0 if ($result eq 'OK');
	return $result;
}

sub libversion {
	return eval { xs_version(); };
}


sub DESTROY {
    my $self=shift;
    
    $self->terminate();
}


1;

__END__

=pod

=head1 NAME

WebSphere::MQTT::Client - WebSphere MQ Telemetry Transport Client

=head1 SYNOPSIS

  use WebSphere::MQTT::Client;

  my $mqtt = WebSphere::MQTT::Client->new( Hostname => 'localhost' );

  $mqtt->disconnect();


=head1 DESCRIPTION

WebSphere::MQTT::Client

Publish and Subscribe to broker.

=head1 TODO

=over

=item add full POD documentation

=item LWT (Last Will and Testament)

=item support threaded version of C code

=item interface to set internal log level ( pHconn->comParms.mspLogOptions )

=back

=head1 BUGS

Please report any bugs or feature requests to
C<bug-websphere-mqtt-client@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you will automatically
be notified of progress on your bug as I make changes.

=head1 AUTHORS

Nicholas Humfrey, njh@ecs.soton.ac.uk
Brian Candler, B.Candler@pobox.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 University of Southampton

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.005 or,
at your option, any later version of Perl 5 you may have available.

=cut

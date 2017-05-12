package WWW::RabbitMQ::Broker::Shovel;

use strict;
use warnings;

our $VERSION = '0.03';

sub new
{
	my $class  = shift;
	my $broker = shift;

	my $self = {
		_config => ref($_[0]) ? $_[0] : {@_},
	};

	unless ($broker && ref($broker) eq 'WWW::RabbitMQ::Broker') {
		die "ERROR: Did not receive a proper broker object.\n";
	}

	$self->{_config}{vhost} ||= '/';
	$self->{_broker} = $broker;
	return bless($self, $class);
}

sub delete
{
	my $self = shift;
	$self->{_broker}->httpMethod('DELETE')->apiCall("parameters/shovel/$self->{_config}{vhost}/$self->{_config}{name}");
	return {deleted => 1};
}

sub get
{
	my $self = shift;
	my $res  = $self->{_broker}->httpMethod('GET')->apiCall("parameters/shovel/$self->{_config}{vhost}/$self->{_config}{name}");
	return $self->{_config} = $res;
}

sub getConfig
{
	my $self = shift;
	my $get  = shift;
	$self->get;
	if ($get eq 'all') {
		return $self->{_config};
	}
	else {
		return $self->{_config}{$get};
	}
}

sub getOrPut
{
	my $self = shift;

	my $res;
	eval {
		$res = $self->{_broker}->httpMethod('GET')->apiCall("parameters/shovel/$self->{_config}{vhost}/$self->{_config}{name}");
	};

	if ($!) {
		unless ($! =~ /Invalid/) {
			die "ERROR[404]: Invalid Method\n";
		}
		my $res = $self->{_broker}->httpMethod('PUT')->apiCall(
			"parameters/shovel/$self->{_config}{vhost}/$self->{_config}{name}",
			$self->{_config},
		);
		return $self->{_config} = $res;
	}
	else {
		return $self->{_config} = $res;
	}
}

sub put
{
	my $self = shift;
	my $res = $self->{_broker}->httpMethod('PUT')->apiCall(
		"parameters/shovel/$self->{_config}{vhost}/$self->{_config}{name}",
		$self->{_config},
	);
	return $self->{_config} = $res;
}

1;

__END__

=head1 NAME

WWW::RabbitMQ::Broker::Shovel

=head1 SYNOPSIS

	# You need to have a broker object first
	my $broker = WWW::RabbitMQ::Broker->new(
		username => 'guest',
		password => 'guest,
		host     => 'localhost',
	);

	# Pass the broker object to the shovel with your shovel's config
	my $shovel = WWW::RabbitMQ::Broker::Shovel->new(
		$broker,
		config => {
			component => 'shovel',
			name      => 'example_shovel',
			vhost     => 'example_vhost',
			value     => {
			        'ack-mode'          => 'on-confirm',
			        'delete-after'      => 'never',
			        'src-uri'           => 'amqp://',
			        'src-exchange'      => 'amq.direct',
			        'src-exchange-key'  => 'example_queue',
			        'dest-uri'          => 'amqp://guest:guest@remotehost.com/example_vhost',
			        'dest-exchange'     => 'amq.direct',
			        'dest-exchange-key' => 'example_queue',
			},
		},
	);

	# Get or Create the shovel. This is probably the best method to use in general for setting shovels
	# up, unless you are specifically looking for failures.
	$shovel->getOrPut;

	# Get all the configuration details for the shovel
	my $shovel_details = $shovel->getConfig;

=head1 DESCRIPTION

A simple wrapper around the RabbitMQ Shovel plugin

=head1 METHODS

=head2 new

Create a new WWW::RabbitMQ::Broker Object

	Takes a $broker as its first argument, needs to be a valid WWW::RabbitMQ::Broker object.

	Additional arguments will be used as part of the shovel configuration.

=head2 delete

Removes the shovel from the given broker.

=head2 get

Retrieves the shovel based on the configuration given

=head2 getConfig

Retrieves the current configuration for the shovel object, which can be updated with ->get or getOrPut

=head2 getOrPut

Safely lets you create or retrieve a shovel to minimize failing

=head2 put

Creates the shovel based on given configuration

=cut

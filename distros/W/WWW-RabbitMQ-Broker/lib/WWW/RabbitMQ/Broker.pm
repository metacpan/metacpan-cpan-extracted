package WWW::RabbitMQ::Broker;

use strict;
use warnings;

our $VERSION = '0.03';

use LWP::UserAgent;
use HTTP::Request;
use JSON;
use Want;
use URI;

use WWW::RabbitMQ::Broker::Shovel;

sub new
{
	my $class  = shift;
	my $self   = ref($_[0]) ? $_[0] : {@_};

	unless ($self->{username} and $self->{password} and $self->{host}) {
		my @missing_arguments;
		for my $key (qw/username password host/) {
			push(@missing_arguments, $key) unless $self->{$key};
		}
		die "Missing arguments: " . join(', ', @missing_arguments) . "\n";
	}

	$self->{base}   ||= 'api';   # url will look like http://localhost:15672/api/
	$self->{mode}   ||= 'GET';
	$self->{port}   ||= '15672'; # default port for rabbitmq api
	$self->{scheme} ||= 'http';  # by default https is not enabled

	$self->{uri} = URI->new("$self->{scheme}://$self->{host}:$self->{port}/");
	return bless($self, $class);
}

sub AUTOLOAD
{
	my $self = shift;
	our $AUTOLOAD;

	my ($key) = $AUTOLOAD =~ /.*::([\w_]+)/o;
	return if ($key eq 'DESTROY');
	push @{$self->{chain}}, $key;

	if (want('OBJECT') || want('VOID')) {
		return $self;
	}

	my $args = ref($_[0]) ? $_[0] : {@_};

	unshift(@{$self->{chain}}, $self->{base});
	my $url = join('/', @{$self->{chain}});
	$self->{chain} = [];
	$self->{uri}->path($url);

	return $self->_apiCall($args);
}

sub apiCall
{
	my $self   = shift;
	my $method = "$self->{base}/" . shift;
	my $args   = shift || {};
	$self->{uri}->path($method);
	return $self->_apiCall($args);
}

sub httpMethod
{
	my ($self, $method) = @_;
	$self->{mode} = $method;
	return $self;
}

sub getShovel
{
	my $self = shift;
	my $args = shift;
	return WWW::RabbitMQ::Broker::Shovel->new($self, $args);
}

sub _apiCall
{
	my $self = shift;
	my $args = shift;

	my $ua = LWP::UserAgent->new;
	$ua->timeout(($self->{timeout} || 30));

	my $url = $self->{uri}->as_string;

	my $req = HTTP::Request->new($self->{mode} => $url);
	$req->header('Content-Type' => 'application/json; charset=UTF-8');
	$req->authorization_basic($self->{username}, $self->{password});

	my $parser = JSON->new->utf8(1);
	my $json   = $parser->encode($args);
	$req->content($json);

	my $response = $ua->request($req);
	$self->{mode} = 'GET';

	my $code    = $response->code;
	my $content = $response->content;

	if ($code == 200) {
		my $results = $parser->decode($content);
		return $results;
	}

	if ($code == 204) {
		return {success => 1};
	}

	if ($code == 401) {
		die "ERROR[401]: [username = $self->{username}, message => $content]\n";
	}

	if ($code == 404) {
		die "ERROR[404]: Not Found\n";
	}

	if ($code == 500 && ($content =~ /timeout/)){
		die "Error[500 - Timeout]: $content\n";
	}
	else {
		die "Error[$code]: [url = $url, message = $content]\n";
	}
}

1;

__END__

=head1 NAME

WWW::RabbitMQ::Broker

=head1 SYNOPSIS

	# Make a call to a RabbitMQ API on a broker...
	my $broker = WWW::RabbitMQ::Broker->new(
		username => 'guest',
		password => 'guest,
		host     => 'localhost',
	);

	# get an overview of the system
	my $overview = $broker->overview;

	# get all nodes in the cluster
	my $nodes = $broker->nodes;

	# get all open connections
	my $connections = $broker->connections;

	# publish a message to an exchange
	my $res = $broker->uriRequestMethod('POST')->exchanges->$vhost->$name->publish({
		payload          => "mymessage",
		payload_encoding => "string",
		properties       => {},
		routing_key      => "mykey",
	});

	# configure a shovel
	my $res = $broker->uriRequestMethod('PUT')->parameters->shovel->$vhost->$myshovel({
		value => {
			src-uri    => "amqp://",
			src-queue  => "my-queue",
			dest-uri   => "amqp://remote-server",
			dest-queue => "another-queue",
		},
	});

=head1 DESCRIPTION

A simple module that generically interacts with the RabbitMQ API

=cut

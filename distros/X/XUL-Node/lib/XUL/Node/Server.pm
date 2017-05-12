package XUL::Node::Server;

use strict;
use warnings;
use Carp qw(verbose croak);
use File::Path;
use XML::Parser;
use HTTP::Status;
use POE qw(
	Component::Server::HTTPServer
	Component::Server::HTTPServer::Handler
);
use XUL::Node::Server::SessionManager;
use XUL::Node::Server::SessionTimer;
use XUL::Node::Server::ViewSourceHandler;

use base qw(POE::Component::Server::HTTPServer::Handler Exporter);

our @EXPORT = qw(start);

use constant HTTP_SERVER_ID => 'XUL-Node POE server';

sub start {
	my ($port, $server_root) = @_;

	my $self  = bless
		{ session_manager => XUL::Node::Server::SessionManager->new },
		__PACKAGE__;

	$self->create_http_server_component($port, $server_root);
	$self->{session_timer} = XUL::Node::Server::SessionTimer->new
		(sub { $self->timeout_session(pop) });

	$poe_kernel->run;
	exit 0;
}

# private ---------------------------------------------------------------------

sub create_http_server_component {
	my ($self, $port, $server_root) = @_;
	croak "no port given" unless $port;
	croak "no server_root given" unless $server_root;

	my $document_root = "$server_root/xul";
	my $logs_dir      = "$server_root/logs";
	my $log_file      = "$logs_dir/xul-node-server.log";
	mkpath($logs_dir);
	
	POE::Component::Server::HTTPServer->new(
		port     => $port,
		log_file => $log_file,
		handlers => [
			'/_view_source' => XUL::Node::Server::ViewSourceHandler->new,
			'/xul'          => $self,
			'/'             => new_handler
				(StaticHandler => $document_root, auto_index => 1),
		],
	)->create_server;

	print << "HEADING";

Starting server on ${\( scalar localtime )}...
   port: $port
   root: $document_root
    log: $log_file
Server started. 

HEADING

}

sub handle {
	my ($self, $context) = @_;
	my $request  = $context->{request};
	my $response = $context->{response};
	my ($content, $code, %request);
	eval {
		%request = $self->get_request_as_hash($request);
#use Data::Dumper;print Dumper {%request};
		$content = $self->{session_manager}->handle_request(\%request);
		$code    = RC_OK;
		$self->{session_timer}->user_session_keep_alive($request{session});
#print "\n............................\nRESPONSE\n$content\n-------------------------------\n";
	};
	if ($@) {
		$content = $self->get_error_message($@, %request);
		$code    = RC_INTERNAL_SERVER_ERROR;
print STDERR "# Server error:\n". $content;
	}
	$self->config_response($response, $content, $code);
	return H_FINAL;
}

sub timeout_session { shift->{session_manager}->timeout_session(pop) }

sub config_response {
	my ($self, $response, $content, $code) = @_;
	for ($response) {
		$_->code($code);
		$_->content_type('text/html');
		$_->content_encoding('UTF-8');
		$_->server(HTTP_SERVER_ID);
		$_->content($content);
	}
}	

sub get_request_as_hash {
	my ($self, $request) = @_;
	return $request->method eq 'GET'?
		$request->uri->query_form:
		$self->xml_as_hash($request->content);
}

sub xml_as_hash {
	my ($self, $xml) = @_;
	$xml =~ s/\r\n/\n/g; # newlines could come in wrong
	my %request = (_xml => $xml);
	my $parser = XML::Parser->new(Style => 'Tree');
	my @parsed = @{$parser->parse($xml)->[1]};
	shift @parsed;
	my %parsed = @parsed;
	while (my ($key, $value) = each %parsed) {
		next if $key eq '0';
		$request{$key} = $value->[2];
	}
	return %request;
}

sub get_error_message {
	my ($self, $error, %request) = @_;
	local $_;
	return << "ERROR_MESSAGE";
ERROR. Cannot handle request:
   {
${\( keys %request?
	join ",\n", map {
		$request{$_} ||= 0;
		"      '$_' => '$request{$_}'";
	} sort keys %request:
	"\t\t*no parameters in request*"
)}
   }

Caused by:
	$error
ERROR_MESSAGE
}

1;


=encoding utf8

=head1 NAME

WWW::Splunk::API - Splunk REST client

=head1 DESCRIPTION

L<WWW::Splunk::API> is a low-level interface to Splunk
log search engine. It deals with HTTP communication as well as
working around certain interface glitches.

See L<http://www.splunk.com/base/Documentation/latest/Developer/RESTSearch>
for API definition.

This module is designed to be Splunk API version agnostic.

=cut

package WWW::Splunk::API;

use LWP::UserAgent;
use HTTP::Request::Common;
use WWW::Splunk::XMLParser;
use Carp;

use strict;
use warnings;

our $VERSION = '2.09';

=head2 B<new> (F<params>)

A constructor.

  my $splunk = WWW::Splunk::API->new({
          host => $host,
          port => $port,
          login => $login,
          password => $password,
          unsafe_ssl => 0,
          verbose => 0,
  });

Default values are:
 - port - 8089
 - host - localhost
 - url - https://$host:$port
 - verbose - 0
 - unsafe_ssl - 0
 - service_prefix - /services
 - search - 1

=cut

sub new {
	my ($class, $self) = @_;

	$self->{port} ||= 8089;
	$self->{host} ||= 'localhost';
	$self->{url} ||= 'https://'.$self->{host}.':'.$self->{port};
	$self->{verbose} ||= 0;
	$self->{service_prefix} ||= '/services';
	$self->{search} ||= 1;

	# Set up user agent unless an existing one was passed
	unless ($self->{agent}) {
		$self->{agent} = LWP::UserAgent->new(
			ssl_opts =>  {verify_hostname => (not $self->{unsafe_ssl})},
		);
		$self->{agent}->cookie_jar ({});
		$self->{agent}->credentials(
			delete ($self->{host}).':'.(delete $self->{port}),
			'/splunk',
			delete $self->{login},
			delete $self->{password},
		) if exists $self->{login};
		$self->{agent}->agent("$class/$VERSION ");
	}

	return bless $self, $class;
}

=head2 B<delete> (F<parameters>)

Wrapper around HTTP::Request::Common::DELETE().

=cut

sub delete {
	my ($self, @args) = @_;

	print "DELETE" if $self->{verbose};
	$self->request(\&DELETE, @args);
}

=head2 B<post> (F<parameters>)

Wrapper around HTTP::Request::Common::POST().

=cut

sub post {
	my ($self, @args) = @_;

	print "POST" if $self->{verbose};
	$self->request(\&POST, @args);
}

=head2 B<get> (F<parameters>)

Wrapper around HTTP::Request::Common::GET().

=cut

sub get {
	my ($self, @args) = @_;

	print "GET" if $self->{verbose};
	$self->request(\&GET, @args);
}

=head2 B<head> (F<parameters>)

Wrapper around HTTP::Request::Common::HEAD().
Not used anywhere in splunk API

=cut

sub head {
	my ($self, @args) = @_;

	print "HEAD" if $self->{verbose};
	$self->request(\&HEAD, @args);
}

=head2 B<put> (F<parameters>)

Wrapper around HTTP::Request::Common::PUT().
Not used anywhere in splunk API

=cut

sub put {
	my ($self, @args) = @_;

	print "PUT" if $self->{verbose};
	$self->request(\&PUT, @args);
}

=head2 B<request> (F<method>, F<location>, [F<data>], [F<callback>])

Request a Splunk api and deal with the results.

Method can be either a L<HTTP::Request> instance (see L<HTTP::Request::Common>
for useful ones), or a plain string, such as "GET" or "DELETE."

Optional F<data> is has reference gets serialized into a request body for POST
request. Use I<undef> in case you don't have any data to send, but need to
specify a callback function in subsequent argument.

Call-back function can be specified for a single special case, where a XML stream
of <results> elements is expected.

=cut

sub request {
	my ($self, $method, $location, $data, $callback) = @_;

	my $url = $self->{url}.$self->{service_prefix}.$location;
	if ($self->{verbose}) {
		print " $url\n";
		if (defined $data) {
			foreach my $key (sort keys %$data) {
				my $value = $data->{$key};
				$value =~ s/\n/ /msg;
				print "- $key => $value\n";
			}
		}
	}

	# Construct the request
	my $request;
	if (ref $method and ref $method eq 'CODE') {
		# Most likely a HTTP::Request::Common
		if (! defined $data) {
			$request = $method->($url);
		} else {
			$request = $method->($url, $data);
		}
	} else {
		# A method string
		$request = HTTP::Request->($method, $url);
	}

	my $content_type = '';
	my $buffer;

	$self->{agent}->remove_handler('response_header');
	$self->{agent}->add_handler(response_header => sub {
		my ($response, $ua, $h) = @_;

		# Do not think of async processing of error responses
		return 0 unless $response->is_success;

		my $content_type_header = $response->header('Content-Type') // '';
		if ($content_type_header =~ /^([^\s;]+)/) {
			$content_type = $1;
		} elsif ($response->code ne 204) {
			# Sometimes splunk return HTTP 204 NO CONTENT during poll_search() call,
			# Content-Type header is empty in this case. We must not croak in this case.
			croak "Missing or invalid Content-Type: $content_type_header";
		}

		if ($callback) {
			$response->{default_add_content} = 0;
			$buffer = "";
		}
	});

	$self->{agent}->remove_handler('response_data');
	$self->{agent}->add_handler(response_data => sub {
		my ($response, $ua, $h, $data) = @_;

		return 1 unless defined $buffer;
		$buffer .= $data;
		foreach (split /<\/results>\K/, $buffer) {
			unless (/<\/results>$/) {
				$buffer = $_;
				last;
			}

			my $xml = XML::LibXML->load_xml(string => $_);
			$callback->(WWW::Splunk::XMLParser::parse($xml));
		}

		return 1;
	}) if $callback;

	# Run it
	my $response = $self->{agent}->request($request);
	croak $response->header ('X-Died') if $response->header ('X-Died');

	# Deal with HTTP errors
	unless ($response->is_success) {
		my $content = WWW::Splunk::XMLParser::parse ($response->content)
			if $response->header ('Content-Type') =~ /xml/;
		my $error = "HTTP Error: ".$response->status_line;
		$error .= sprintf "\n%s: %s",
			$content->findvalue ('/response/messages/msg/@type'),
			$content->findvalue ('/response/messages/msg')
			if eval { $content->isa ('XML::LibXML::Document') }
				and $content->documentElement->nodeName eq 'response';
		croak $error;
	}

	# We've gotten the response already
	return if $callback;

	# Parse content from synchronous responses
	# TODO: use callback and m_media_type matchspecs
	if ($content_type eq 'text/xml') {
		my $xml = XML::LibXML->load_xml (string => $response->content);
		my @ret = WWW::Splunk::XMLParser::parse ($xml);
		return $#ret ? @ret : $ret[0];
	} elsif ($response->code eq 204) {
		# "No content"
		# Happens when events are requested immediately
		# after the job is enqueued. With a text/plain content type
		# Empty array is the least disturbing thing to return here
		return ();
	} elsif ($content_type eq 'text/plain') {
		# Sometimes an empty text/plain body is sent
		# even without 204 return code.
		return ();
	} else {
		# TODO: We probably can't do much about RAW
		# format, yet we could parse at least JSON
		croak "Unknown content type: $content_type";
	}
}

=head1 SEE ALSO

L<WWW::Splunk>, L<sc>

=head1 AUTHORS

Lubomir Rintel, L<< <lkundrak@v3.sk> >>,
Michal Josef Špaček L<< <skim@cpan.org> >>

The code is hosted on GitHub L<http://github.com/michal-josef-spacek/perl-WWW-Splunk>.
Bug fixes and feature enhancements are always welcome.

=head1 LICENSE

 This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

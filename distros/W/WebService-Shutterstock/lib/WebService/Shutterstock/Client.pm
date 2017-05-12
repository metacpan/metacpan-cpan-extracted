package WebService::Shutterstock::Client;
{
  $WebService::Shutterstock::Client::VERSION = '0.006';
}

# ABSTRACT: Provides easy REST interactions with the Shutterstock API

use strict;
use warnings;
use Moo;
use JSON qw(decode_json);
use WebService::Shutterstock::Exception;

use REST::Client;
extends 'REST::Client';


sub response {
	my $self = shift;
	if(@_){
		$self->{_res} = $_[0];
	}
	return $self->{_res};
}

sub GET {
	my($self, $url, $query, $headers) = @_;
	if(ref($query) eq 'HASH'){
		$url .= $self->buildQuery(%$query);
	}
	$self->SUPER::GET($url, $headers);
	return $self->response;
}

sub DELETE {
	my($self, $url, $query, $headers) = @_;
	if(ref($query) eq 'HASH'){
		$url .= $self->buildQuery(%$query);
	}
	$self->SUPER::DELETE($url, $headers);
	return $self->response;
}

sub PUT {
	my($self, $url, $content, $headers) = @_;
	if(ref($content) eq 'HASH'){
		my $uri = URI->new();
		$uri->query_form(%$content);
		$content = $uri->query;
		$headers ||= {};
		$headers->{'Content-Type'} = 'application/x-www-form-urlencoded';
	}
	$self->SUPER::PUT($url, $content, $headers);
	return $self->response;
}

sub POST {
	my($self, $url, $content, $headers) = @_;
	if(ref($content) eq 'HASH'){
		my $uri = URI->new();
		$uri->query_form(%$content);
		$content = $uri->query;
		$headers ||= {};
		$headers->{'Content-Type'} = 'application/x-www-form-urlencoded';
	}
	$self->SUPER::POST($url, $content, $headers);
	return $self->response;
}


sub process_response {
	my $self = shift;
	my %handlers = (
		204 => sub { 1 }, # empty response, but success
		401 => sub { die WebService::Shutterstock::Exception->new(response => shift, error => "invalid api_username or api_key"); },
		@_
	);

	my $code = $self->responseCode;
	my $content_type = $self->responseHeader('Content-Type') || '';

	my $response = $self->{_res}; # blech, why isn't this public?
	my $request = $response->request;

	if(my $error = $response->header('X-Died')){
		die WebService::Shutterstock::Exception->new(
			response => $response,
			error    => sprintf( 'Transport error: %s', $error )
		);
	}

	if(my $h = $handlers{$code}){
		$h->($response);
	} elsif($code <= 299){ # a success
		return $content_type =~ m{^application/json} && $self->responseContent ? decode_json($self->responseContent) : $response->decoded_content;
	} elsif($code <= 399){ # a redirect of some sort
		return $self->responseHeader('Location');
	} elsif($code <= 499){ # client-side error
		die WebService::Shutterstock::Exception->new( response => $response, error => sprintf('%s: %s', $response->status_line, $response->decoded_content) );
	} elsif($code >= 500){ # server-side error
		die WebService::Shutterstock::Exception->new( response => $response, error => sprintf('%s: %s', $response->status_line, $response->decoded_content) );
	}
}


sub BUILD {
	my $self = shift;
	if($ENV{SS_API_DEBUG}){
		$self->getUseragent->add_handler("request_send",  sub { shift->dump(prefix => '> '); return });
		$self->getUseragent->add_handler("response_done", sub { shift->dump(prefix => '< '); return });
	}
}

1;

__END__

=pod

=head1 NAME

WebService::Shutterstock::Client - Provides easy REST interactions with the Shutterstock API

=head1 VERSION

version 0.006

=head1 DESCRIPTION

This class extends the L<REST::Client> class and provides some additional
convenience functions.

You should not need to use this class to use L<WebService::Shutterstock>

=head1 METHODS

=head2 response

Returns most recent response object.

=head2 process_response(201 => \&created_handler, 404 => \&notfound_handler)

Processes the most recent response object based on the HTTP status code,
the content type and response body.  Additional handlers may be passed in
(keyed on HTTP status codes).

=for Pod::Coverage BUILD

=head1 AUTHOR

Brian Phillips <bphillips@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Brian Phillips and Shutterstock, Inc. (http://shutterstock.com).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

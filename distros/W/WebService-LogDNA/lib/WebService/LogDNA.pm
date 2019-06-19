use strict;
use warnings;

package WebService::LogDNA;

# ABSTRACT: Implements the ingest API call for L<https://www.logdna.com>

use Moo;
use LWP::UserAgent;
use URI;
use Time::HiRes;
use MIME::Base64 qw/encode_base64/;
use WebService::LogDNA::Body;

use namespace::clean;

has key => ( is => 'ro', required => 1 );

has hostname => ( 
	is => 'ro', 
	default => sub {  
		require POSIX;

		return( (POSIX::uname())[1] ); #nodename
	}
);

has mac => ( is => 'ro' );
has ip => ( is => 'ro' );

# Private!
has agent => (
	is => 'ro',
	default => sub {
		return LWP::UserAgent->new;
	}
);

# Mostly overrideable for testing
has url => (
	is => 'ro',
	default => sub {
		URI->new("https://logs.logdna.com/logs/ingest");
	},
	coerce => sub {
		unless( ref $_[0] ) { return URI->new($_[0]) }

		return $_[0];
	},
);

sub ingest {
	my( $self, $body ) = @_;

	unless( defined $body and ref $body ) {
		die 'Ingest requires a $body argument';
	}

	# Attempt to upgrade a hashref to a proper object
	if( ref $body eq 'HASH' ) {
		$body = WebService::LogDNA::Body->new( %$body );
	}

	unless( UNIVERSAL::isa( $body, 'WebService::LogDNA::Body' ) ) {
		die "Ingest requires WebService::LogDNA::Body argument, got: $body";
	}

	my $now = int( Time::HiRes::time() * 1000 );
	my $url = $self->url->clone;
	$url->query_form(
		hostname => $self->hostname,
		mac => $self->mac,
		ip => $self->ip,
		now => $now,
	);

	my $headers = HTTP::Headers->new;
	$headers->authorization_basic($self->key, "");
	$headers->content_type('application/json; charset=UTF-8');

	my $content = '{"lines":[' . $body->to_json . ']}';

	my $request = HTTP::Request->new( "POST", $url, $headers, $content );

	my $resp = $self->agent->request($request);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::LogDNA - Implements the ingest API call for L<https://www.logdna.com>

=head1 VERSION

version 0.001

=head1 SYNOPSIS

Implements the ingest API call for L<https://www.logdna.com>

=head1 AUTHOR

Robert Grimes <rmzgrimes@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Robert Grimes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

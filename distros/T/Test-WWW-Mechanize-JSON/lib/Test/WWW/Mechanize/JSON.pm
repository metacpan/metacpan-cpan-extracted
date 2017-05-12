use strict;
use warnings;

package Test::WWW::Mechanize::JSON;

our $VERSION = 0.73;

use base "Test::WWW::Mechanize";
use Test::More;
use JSON::Any;


=head1 NAME

Test::WWW::Mechanize::JSON - Add a JSON and AJAXy methods to the super-class

=head1 SYNOPSIS

	use Test::More 'no_plan';
	use_ok("Test::WWW::Mechanize::JSON") or BAIL_OUT;
	my $MECH = Test::WWW::Mechanize::JSON->new(
		noproxy => 1,
		etc     => 'other-params-for-Test::WWW::Mechanize',
	);
	$MECH->get('http://example.com/json');
	my $json_as_perl = $MECH->json_ok or BAIL_OUT Dumper $MECH->response;
	$MECH->diag_json;

=head1 DESCRIPTION

Extends L<Test::WWW::Mechanize|Test::WWW::Mechanize>
to test JSON content in response bodies and C<x-json> headers.

It adds a few HTTP verbs to Mechanize, for convenience.

=head2 METHODS: HTTP VERBS

=cut

=head3 $mech->put

An HTTP 'put' request, extending L<HTTP::Request::Common|HTTP::Request::Common>.

At the time of wriring, modules that rely on L<HTTP::Request::Common|HTTP::Request::Common>
treat C<PUT> as a type of C<GET>, when the spec says it is really a type of C<POST>:

	The fundamental difference between the POST and PUT
	requests is reflected in the different meaning of
	the Request-URI.
	                HTTP specification

=cut

sub put {
    my ($self, @parameters) = @_;
    my @suff = $self->_process_colonic_headers(\@parameters,1);

	require HTTP::Request::Common;
	my $r = HTTP::Request::Common::POST(@parameters);
	$r->{_method} = 'PUT';
    return $self->request( $r, @suff );
}


=head3 $mech->delete

An HTTP 'delete' request, extending L<HTTP::Request::Common|HTTP::Request::Common>.

=cut

sub delete {
    require HTTP::Request::Common;
    my ($self, @parameters) = @_;
    my @suff = $self->_process_colonic_headers(\@parameters,1);
    return $self->request( HTTP::Request::Common::DELETE( @parameters ), @suff );
}


=head3 $mech->options

An HTTP 'options' request, extending L<HTTP::Request::Common|HTTP::Request::Common>.

=cut

sub options {
    require HTTP::Request::Common;
    my ($self, @parameters) = @_;
    my @suff = $self->_process_colonic_headers(\@parameters,1);
    return $self->request( HTTP::Request::Common::_simple_req( 'OPTIONS', @parameters ), @suff );
}


=head3 $mech->head

An HTTP 'head' request, using L<HTTP::Request::Common|HTTP::Request::Common>.

=cut

sub head {
    require HTTP::Request::Common;
    my ($self, @parameters) = @_;
    my @suff = $self->_process_colonic_headers(\@parameters,1);
    return $self->request( HTTP::Request::Common::_simple_req( 'HEAD', @parameters ), @suff );
}

=head2 METHODS: ASSERTIONS

=head3 $mech->json_ok($desc)

Tests that the last received resopnse body is valid JSON.

A default description of "Got JSON from $url"
or "Not JSON from $url"
is used if none if provided.

Returns the L<JSON|JSON> object, that you may perform
further tests upon it.

=cut

sub json_ok {
	my ($self, $desc) = @_;
	return $self->_json_ok( $desc, $self->content );
}


=head3 $mech->x_json_ok($desc)

As C<$mech->json_ok($desc)> but examines the C<x-json> header.

=cut

sub x_json_ok {
	my ($self, $desc) = @_;
	return $self->_json_ok(
		$desc,
		$self->response->headers->{'x-json'}
	);
}

sub json {
	my ($self, $text) = @_;
	$text ||= exists $self->response->headers->{'x-json'}?
		$self->response->headers->{'x-json'}
	:	$self->content;
	my $json = eval {
		JSON::Any->jsonToObj($text);
	};
	return $json;
}

=head2 any_json_ok( $desc )

Like the other JSON methods, but passes if the response
contained JSON in the content or C<x-json> header.

=cut

sub any_json_ok {
	my ($self, $desc) = @_;
	return $self->_json_ok(
		$desc,
		$self->json
	);
}


sub _json_ok {
	my ($self, $desc, $text) = @_;
	my $json = $self->json( $text );

	if (not $desc){
		if (defined $json and ref $json eq 'HASH' and not $@){
			$desc = sprintf 'Got JSON from %s', $self->uri;
		}
		else {
			$desc = sprintf 'Not JSON from %s (%s)', $self->uri, $@;
		}
	}

	Test::Builder->new->ok( $json, $desc );

	return $json || undef;
}


=head3 $mech->diag_json

Like L<diag|Test::More/diag>, but renders the JSON of body the last request
with indentation.

=cut

sub diag_json {
	my $self = shift;
	return $self->_diag_json( $self->content );
}

=head3 $mech->diag_x_json

Like L<diag|Test::More/diag>, but renders the JSON
from the C<x-json> header of the last request with indentation.

=cut

sub diag_x_json {
	my $self = shift;
	return $self->_diag_json(
		$self->response->headers->{'x-json'}
	);
}

sub _diag_json {
	my ($self, $text) = @_;
	eval {
		my $json = $self->json( $text );
		if (not defined $json){
			warn "Not a $json objet";
		}
		elsif (not ref $json or ref $json ne 'HASH'){
			warn "Not an JSON object";
		}
		else {
			warn "Not a JSON object?";
		}
	};
	warn $@ if $@;
}


sub utf8 {
	return $_[0]->response->headers('content-type') =~ m{charset=\s*utf-8}? 1 : 0;
}

=head3 $mech->utf8_ok( $desc )

Passes if the last response contained a C<charset=utf-8> definition in its content-type header.

=cut

sub utf8_ok {
	my $self = shift;
	my $desc = shift || 'Has a utf-8 heaer';
	Test::Builder->new->ok( $self->utf8, $desc );
}





1;

=head1 AUTHOR AND COPYRIGHT

Copyright (C) Lee Goddard, 2009/2011.

Available under the same terms as Perl itself.

=cut

1;

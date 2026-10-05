package WWW::Authentik::Role::HTTP;

# ABSTRACT: Sending requests to authentik and turning failures into exceptions

use HTTP::Request;
use JSON::MaybeXS;
use MIME::Base64 qw( encode_base64 );
use URI;
use WWW::Authentik::Error::API;
use WWW::Authentik::Error::Network;
use WWW::Authentik::Error::Validation;
use Moo::Role;

our $VERSION = '0.001';


sub json_codec { JSON::MaybeXS->new( utf8 => 1, canonical => 1, convert_blessed => 1 ) }


sub api_error_class        { 'WWW::Authentik::Error::API' }
sub network_error_class    { 'WWW::Authentik::Error::Network' }
sub validation_error_class { 'WWW::Authentik::Error::Validation' }


sub build_request {
  my ( $self, $method, $url, %arg ) = @_;
  my $request = HTTP::Request->new( $method => $url );
  $request->header( Accept => 'application/json' );
  $request->header( Authorization => 'Bearer '.$arg{bearer} ) if defined $arg{bearer};
  $request->header( Authorization => 'Basic '.encode_base64( $arg{basic}[0].':'.$arg{basic}[1], '' ) ) if $arg{basic};
  if ( exists $arg{json} ) {
    $request->header( 'Content-Type' => 'application/json' );
    $request->content( $self->json_codec->encode( $arg{json} ) );
  }
  elsif ( $arg{form} ) {
    my $uri = URI->new('http:');
    $uri->query_form( map { $_ => $arg{form}{$_} } grep { defined $arg{form}{$_} } sort keys %{ $arg{form} } );
    $request->header( 'Content-Type' => 'application/x-www-form-urlencoded' );
    $request->content( $uri->query // '' );
  }
  return $request;
}


sub read_response {
  my ( $self, $response, $method, $url, %arg ) = @_;
  # decoded_content undoes a Content-Encoding; the raw content does not. With
  # charset => 'none' it stops short of decoding the character set, which is
  # what the JSON codec wants, because it decodes UTF-8 itself. Reading the
  # raw content here would lose the whole body to any user agent that asked
  # for gzip.
  my $bytes   = $response->decoded_content( charset => 'none' ) // '';
  my $content = $response->decoded_content // '';
  my $data    = length $bytes ? eval { $self->json_codec->decode($bytes) } : undef;
  # authentik answers 302 at the authorize endpoint and between the stages of
  # a flow; that is an answer, not a failure
  return { status => $response->code, data => $data, location => scalar $response->header('Location'), content => $content }
    if $response->code < 400;
  my ( $message, $oauth, $request_id, %fields );
  my $body = $content;
  $body = substr( $body, 0, 500 ).'...' if length $body > 500;
  if ( ref $data eq 'HASH' ) {
    $request_id = $data->{request_id};
    if ( defined $data->{detail} && !ref $data->{detail} ) {
      $message = $data->{detail};
    }
    elsif ( defined $data->{error} && !ref $data->{error} ) {
      $oauth   = $data->{error};
      $message = $data->{error}.( defined $data->{error_description} ? ': '.$data->{error_description} : '' );
    }
    else {
      %fields  = %{ $self->flatten_field_errors($data) };
      $message = join '; ', map { $_.': '.join ', ', @{ $fields{$_} } } sort keys %fields;
    }
  }
  if ( ( !defined $message || !length $message ) && ( my $challenge = $response->header('WWW-Authenticate') ) ) {
    ( $oauth )   = $challenge =~ /error="([^"]+)"/;
    ( $message ) = $challenge =~ /error_description="([^"]+)"/;
    $message = $oauth if !defined $message && defined $oauth;
  }
  # Not every error on the way to authentik comes from authentik: a proxy, or
  # a base_url that points somewhere else, answers HTML or plain text. Saying
  # only "404 Not Found" would leave the reader with nothing to go on, so a
  # squeezed snippet of whatever came back stands in.
  if ( ( !defined $message || !length $message ) && length $body ) {
    my $snippet = $body =~ s/\s+/ /gr =~ s/\A\s+|\s+\z//gr;
    $snippet = substr( $snippet, 0, 200 ).'...' if length $snippet > 200;
    $message = $snippet if length $snippet;
  }
  $self->api_error_class->throw(
    message      => $method.' '.$url.' failed: '.$response->status_line
      .( defined $message && length $message ? ' - '.$message : '' ),
    http_status  => $response->code,
    api_message  => ( defined $message && length $message ? $message : undef ),
    field_errors => \%fields,
    oauth_error  => $oauth,
    request_id   => $request_id,
    body         => ( length $body ? $body : undef )
  );
}


sub flatten_field_errors {
  my ( $self, $data, $prefix ) = @_;
  my %flat;
  for my $key ( keys %$data ) {
    my $name  = defined $prefix ? $prefix.'.'.$key : $key;
    my $value = $data->{$key};
    if    ( ref $value eq 'HASH' )  { %flat = ( %flat, %{ $self->flatten_field_errors( $value, $name ) } ) }
    elsif ( ref $value eq 'ARRAY' ) { $flat{$name} = [ map { ref $_ ? $self->json_codec->encode($_) : $_ } @$value ] }
    else                            { $flat{$name} = [ defined $value ? $value : '' ] }
  }
  return \%flat;
}


sub send_request {
  my ( $self, $method, $url, %arg ) = @_;
  my $response = $self->ua->request( $self->build_request( $method, $url, %arg ) );
  $self->network_error_class->throw( message => $method.' '.$url.': '.$response->status_line )
    if $response->code == 500 && ( $response->header('Client-Warning') // '' ) eq 'Internal response';
  return $self->read_response( $response, $method, $url, %arg );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Authentik::Role::HTTP - Sending requests to authentik and turning failures into exceptions

=head1 VERSION

version 0.001

=head1 DESCRIPTION

What L<WWW::Authentik::API> and L<WWW::Authentik::OIDC> share: one
L<LWP::UserAgent>, JSON in and out, and the mapping of authentik's four error
shapes onto L<WWW::Authentik::Error::API>.

Building the request and reading the response are separate from sending it,
so that L<Net::Async::Authentik> can reuse L</build_request> and
L</read_response> and only replace the sending.

=head2 json_codec

The JSON codec every part uses: UTF-8, canonical, honouring C<TO_JSON>.

=head2 api_error_class

=head2 network_error_class

=head2 validation_error_class

The classes the errors are thrown as. L<Net::Async::Authentik> overrides them
with its own subclasses.

=head2 build_request

    my $request = $self->build_request( POST => $url, json => \%body, bearer => $token );
    my $request = $self->build_request( POST => $url, form => \%fields );
    my $request = $self->build_request( POST => $url, form => \%fields, basic => [ $id, $secret ] );

The L<HTTP::Request> for one call: JSON accepted, a bearer token or a basic
login when given, the body as JSON or as a form. Form values are sorted, so
the same arguments always produce the same request.

=head2 read_response

    my $result = $self->read_response( $response, $method, $url, %arg );

Turns an L<HTTP::Response> into C<status>, the decoded C<data>, the
C<location> header and the decoded C<content>, or throws L</api_error_class>
for any status of 400 and above. Anything below 400 is an answer, because
authentik redirects where it wants a browser. C<%arg> are the arguments the
request was built with.

The body is read through L<HTTP::Response/decoded_content>, so a user agent
that asked for a compressed answer still gets its JSON.

When the body is neither of authentik's error shapes — a proxy's HTML, plain
text, a JSON array — a squeezed snippet of it becomes the message, and the
whole of it (up to 500 characters) is on the exception as
L<WWW::Authentik::Error::API/body>.

The thrown error names the method and the URL, never the token or the
secret.

=head2 flatten_field_errors

    my $fields = $self->flatten_field_errors( \%body );

authentik's field errors as a flat hash of field name to a list of messages.
A nested shape such as C<< {"grant_types": {"0": [...]}} >> or
C<< {"app": {"slug": [...]}} >> becomes C<grant_types.0> and C<app.slug>.

=head2 send_request

    my $result = $self->send_request( GET => $url, bearer => $token );
    my $result = $self->send_request( POST => $url, json => \%body, bearer => $token );
    my $result = $self->send_request( POST => $url, form => \%fields );

Sends one request and returns what L</read_response> returns. Throws
L<WWW::Authentik::Error::Network> when no answer came back and
L<WWW::Authentik::Error::API> for any status of 400 and above.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-www-authentik/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

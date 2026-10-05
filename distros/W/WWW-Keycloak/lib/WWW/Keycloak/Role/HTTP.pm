package WWW::Keycloak::Role::HTTP;

# ABSTRACT: Sending requests to Keycloak and turning failures into exceptions

use HTTP::Request;
use JSON::MaybeXS;
use URI;
use WWW::Keycloak::Error::API;
use WWW::Keycloak::Error::Network;
use Moo::Role;

our $VERSION = '0.001';


sub json_codec { JSON::MaybeXS->new( utf8 => 1, canonical => 1, convert_blessed => 1 ) }

sub api_error_class     { 'WWW::Keycloak::Error::API' }
sub network_error_class { 'WWW::Keycloak::Error::Network' }


sub build_request {
  my ( $self, $method, $url, %arg ) = @_;
  my $request = HTTP::Request->new( $method => $url );
  $request->header( Accept => 'application/json' );
  $request->header( Authorization => 'Bearer '.$arg{bearer} ) if defined $arg{bearer};
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
  # decoded_content undoes a Content-Encoding, the raw content does not; with
  # charset => 'none' the bytes stay bytes, which the JSON codec decodes itself
  my $content = $response->decoded_content( charset => 'none' ) // '';
  my $data    = length $content ? eval { $self->json_codec->decode($content) } : undef;
  return { status => $response->code, data => $data, location => scalar $response->header('Location') }
    if $response->is_success;
  my ( $message, $oauth );
  if ( ref $data eq 'HASH' ) {
    $message = $data->{errorMessage} // $data->{error};
    if ( defined $data->{error} && defined $data->{error_description} || $arg{form} ) {
      $oauth = $data->{error};
      $message = $data->{error}.( defined $data->{error_description} ? ': '.$data->{error_description} : '' )
        if defined $data->{error};
    }
  }
  $self->api_error_class->throw(
    message     => $method.' '.$url.' failed: '.$response->status_line.( defined $message ? ' - '.$message : '' ),
    http_status => $response->code,
    api_message => $message,
    oauth_error => $oauth
  );
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

WWW::Keycloak::Role::HTTP - Sending requests to Keycloak and turning failures into exceptions

=head1 VERSION

version 0.001

=head1 DESCRIPTION

What L<WWW::Keycloak::Admin>, L<WWW::Keycloak::OIDC> and
L<WWW::Keycloak::Auth> share: one L<LWP::UserAgent>, JSON in and out, and the
mapping of Keycloak's three error shapes onto L<WWW::Keycloak::Error::API>.

=head2 api_error_class

=head2 network_error_class

The classes the errors are thrown as. L<Net::Async::Keycloak> overrides them
with its own subclasses.

=head2 build_request

    my $request = $self->build_request( POST => $url, json => \%body, bearer => $token );
    my $request = $self->build_request( POST => $url, form => \%fields );

The L<HTTP::Request> for one call: JSON accepted, a bearer token when given,
the body as JSON or as a form.

=head2 read_response

    my $result = $self->read_response( $response, $method, $url, %arg );

Turns an L<HTTP::Response> into C<status>, the decoded C<data> and the
C<location> header, or throws L</api_error_class> for any status of 400 and
above. C<%arg> are the arguments the request was built with.

=head2 send_request

    my $result = $self->send_request( POST => $url, json => \%body, bearer => $token );
    my $result = $self->send_request( POST => $url, form => \%fields );

Sends one request. Returns C<status>, the decoded C<data> and the C<location>
header. Throws L<WWW::Keycloak::Error::Network> when no answer came back and
L<WWW::Keycloak::Error::API> for any status of 400 and above.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-www-keycloak/issues>.

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

package WebService::Auth0::Authentication;

use Moo;
extends 'WebService::Auth0::HTTPClient';

has 'client_id' => (
  is=>'ro',
  required=>1);

has 'client_secret' => (
  is=>'ro',
  predicate=>'has_client_secret',
  required=>0);

# I Hate to mix POD with code like this but this way I don't miss
# something (and it makes it easier on me to keep all these numerous
# methods correct

=head1 NAME

WebService::Auth0::Authentication::Login - Authentication API

=head1 SYNOPSIS

    my $ua = WebService::Auth0::UA->create;
    my $auth = WebService::Auth0::Authentication->new(
      ua => $ua,
      domain => $ENV{AUTH0_DOMAIN},
      client_id => $ENV{AUTH0_CLIENT_ID} );


=head1 DESCRIPTION

Auth0 Authentication Login Module

=head1 METHODS

This class defines the following methods.  Unless otherwise noted
all methods below will add in the client_id and/or client_secret as
needed.

=head2 authorize

    GET $DOMAIN/authorize

L<https://auth0.com/docs/api/authentication#social>,
L<https://auth0.com/docs/api/authentication#database-ad-ldap-passive->,
L<https://auth0.com/docs/api/authentication#enterprise-saml-and-others->,
L<https://auth0.com/docs/api/authentication?http#authorization-code-grant>.

=cut 

sub authorize {
  my ($self, $params) = @_;
  $params->{client_id} = $self->client_id;
  return $self->GET($self->uri_for('authorize', $params));
}

=head2 oauth_access_token

    POST $DOMAIN/oauth/access_token
    
L<https://auth0.com/docs/api/authentication#social-with-provider-s-access-token>

=cut

sub oauth_access_token {
  my ($self, $params) = @_;
  $params->{client_id} = $self->client_id;
  return $self->POST_JSON($self->uri_for('oauth','access_token'), $params);
}

=head2 oauth_ro

    POST $DOMAIN/oauth/ro

L<https://auth0.com/docs/api/authentication#database-ad-ldap-active->
L<https://auth0.com/docs/api/authentication?http#resource-owner>
L<https://auth0.com/docs/api/authentication#authenticate-user>

=cut

sub oauth_ro {
  my ($self, $params) = @_;
  $params->{client_id} = $self->client_id;
  return $self->POST_JSON($self->uri_for('oauth','ro'), $params);
}

=head2 logout

    GET $DOMAIN/v2/logout

L<https://auth0.com/docs/api/authentication#logout>

=cut

sub logout {
  my ($self, $params) = @_;
  $params->{client_id} = $self->client_id;
  return $self->GET($self->uri_for('v2','logout', $params));

}

=head2 signup

    POST $DOMAIN/dbconnections/signup

L<https://auth0.com/docs/api/authentication#signup>

=cut

sub signup {
  my ($self, $params) = @_;
  $params->{client_id} = $self->client_id;
  return $self->POST_JSON($self->uri_for('dbconnections','signup'), $params);
}

=head2 change_db_password

    POST $DOMAIN/dbconnections/change_password

L<https://auth0.com/docs/api/authentication?http#change-password>

=cut

sub change_db_password {
  my ($self, $params) = @_;
  $params->{client_id} = $self->client_id;
  return $self->POST_JSON($self->uri_for('dbconnections','change_password'), $params);
}

=head2 impersonation

    POST $DOMAIN/users/:user_id/impersonate

L<https://auth0.com/docs/api/authentication#impersonation>

=cut

sub impersonation {
  my ($self, $user_id, $params) = @_;
  $params->{client_id} = $self->client_id;
  return $self->POST_JSON($self->uri_for('users', $user_id, 'impersonate'), $params);
}

=head2 impersonate

    POST $DOMAIN/users/:user_id/impersonate

L<https://auth0.com/docs/api/authentication#delegation>

=cut

sub impersonate {
  my ($self, $params) = @_;
  $params->{client_id} = $self->client_id;
  return $self->POST_JSON($self->uri_for('delegation'), $params);
}

=head2 get_token

    POST $DOMAIN/oauth/token

L<https://auth0.com/docs/api/authentication?http#get-token>

=cut

sub get_token {
  my ($self, $params) = @_;
  die "method requires 'client_secret'" unless $self->has_client_secret;
  $params->{client_id} = $self->client_id;
  $params->{client_secret} = $self->client_secret;
  return $self->POST_JSON($self->uri_for('oauth','token'), $params);
}

=head2 ws_fed_accept_request

    GET $DOMAIN/wsfed/:client_id/

L<https://auth0.com/docs/api/authentication#accept-request22>

=cut

sub ws_fed_accept_request {
  my ($self, $params) = @_;
  return $self->GET($self->uri_for('wsfed', $self->client_id), $params);
}

=head2 ws_fed_metadata

    GET $DOMAIN/wsfed/:client_id/FederationMetadata/2007-06/FederationMetadata.xml

L<https://auth0.com/docs/api/authentication#get-metadata23>

=cut

sub ws_fed_metadata {
  my ($self) = @_;
  return $self->GET(
    $self->uri_for('wsfed', $self->client_id, 'FederationMetadata', '2007-06', 'FederationMetadata.xml'));
}

=head2 saml_accept_request

    GET $DOMAIN/samlp/:client_id

L<https://auth0.com/docs/api/authentication#accept-request>

=cut

sub saml_accept_request {
  my ($self, $params) = @_;
  return $self->GET($self->uri_for('samlp', $self->client_id), $params);
}

=head2 saml_metadata

    GET $DOMAIN/samlp/metadata/:client_id

L<https://auth0.com/docs/api/authentication#get-metadata>

=cut

sub saml_metadata {
  my ($self) = @_;
  return $self->GET($self->uri_for('samlp', 'metadata', $self->client_id));
}

=head2 initiated_sso_flow

    POST $DOMAIN/login/callback

L<https://auth0.com/docs/api/authentication#idp-initiated-sso-flow>

=cut

sub initiated_sso_flow {
  my ($self, $params) = @_;
  return $self->POST_JSON($self->uri_for('login', 'callback'), $params);
}

=head2 passwordless_start

    POST $DOMAIN/passwordless/start

L<https://auth0.com/docs/api/authentication#get-code-or-link>

=cut

sub passwordless_start {
  my ($self, $params) = @_;
  $params->{client_id} = $self->client_id;
  return $self->POST_JSON($self->uri_for('passwordless','start'), $params);
}

=head2 userinfo

    GET $DOMAIN/userinfo

L<https://auth0.com/docs/api/authentication#get-user-info>

=cut

sub userinfo {
  my ($self, $params) = @_;
  die "'access_token' is a required parameter" unless $params->{access_token};
  return $self->GET(
    $self->uri_for('userinfo'),
    Authorization => "Bearer ${\$params->{access_token}}",
  );
}

=head2 tokeninfo

    POST $DOMAIN/tokeninfo

L<https://auth0.com/docs/api/authentication#get-token-info>

=cut

sub tokeninfo {
  my ($self, $params) = @_;
  return $self->POST_JSON($self->uri_for('tokeninfo'), $params);
}

=head1 SEE ALSO
 
L<WebService::Auth0>, L<https://auth0.com>.

=head1 AUTHOR
 
    See L<WebService::Auth0>
  
=head1 COPYRIGHT & LICENSE
 
    See L<WebService::Auth0>

=cut

1;

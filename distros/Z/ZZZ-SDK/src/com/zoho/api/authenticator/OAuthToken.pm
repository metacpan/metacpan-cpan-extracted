package TokenType;
sub GRANT{
  return 'grant';
}
sub REFRESH{
  return 'refresh';
}

package OAuthToken;
use src::com::zoho::crm::api::Initializer;
use src::com::zoho::api::exception::SDKException;
use src::com::zoho::api::authenticator::Token;
use src::com::zoho::crm::api::util::Constants;
use JSON;
use Moose;
use Try::Catch;
use Log::Handler;
use REST::Client;
use Scalar::Util::Numeric qw(isint isfloat);
use LWP::UserAgent;
use HTTP::Request;

require Mozilla::CA;

extends 'Token';

my $client = REST::Client->new();

$client->setCa(Mozilla::CA::SSL_ca_file());

our $logger = Log::Handler->get_logger("SDKLogger");

sub new
{
  my ($class, $client_id, $client_secret, $redirect_url, $token, $token_type) = @_;

  my $self={
      client_id => $client_id,
      client_secret => $client_secret,
      redirect_url => $redirect_url,
      token => $token,
      type => $token_type,
      grant_token => undef,
      refresh_token => undef,
      access_token => undef,
      expires_in => undef
  };

  my %error=();
  try{
  unless (defined($self->{client_id}))
  {
    $error{$Constants::FIELD}=$Constants::CLIENT_ID;
    $error{$Constants::EXPECTED_TYPE}=$Constants::STRING;
    $error{$Constants::CLASS}=$Constants::OAUTH_TOKEN;
    die SDKException->new($Constants::TOKEN_ERROR, undef, \%error, undef);
  }
  unless (defined($self->{client_secret}))
 {
    $error{$Constants::FIELD}=$Constants::CLIENT_SECRET;
    $error{$Constants::EXPECTED_TYPE}=$Constants::STRING;
    $error{$Constants::CLASS}=$Constants::OAUTH_TOKEN;
    die SDKException->new($Constants::TOKEN_ERROR, undef, \%error, undef);
  }
  unless (defined($self->{redirect_url}))
  {
    $error{$Constants::FIELD}=$Constants::REDIRECT_URI;
    $error{$Constants::EXPECTED_TYPE}=$Constants::STRING;
    $error{$Constants::CLASS}=$Constants::OAUTH_TOKEN;
    die SDKException->new($Constants::TOKEN_ERROR, undef, \%error, undef);
  }
  unless (defined($self->{token}))
  {
    $error{$Constants::FIELD}=$Constants::TOKEN;
    $error{$Constants::EXPECTED_TYPE}=$Constants::STRING;
    $error{$Constants::CLASS}=$Constants::OAUTH_TOKEN;
    die SDKException->new($Constants::TOKEN_ERROR, undef, \%error, undef);
  }
  if (!($self->{type} eq 'refresh'))
  {
    if (!($self->{type} eq 'grant'))
    {
    $error{$Constants::FIELD}=$Constants::TOKEN_TYPE;
    $error{$Constants::EXPECTED_TYPE}=$Constants::GRANT;
    $error{$Constants::CLASS}=$Constants::OAUTH_TOKEN;
    die SDKException->new($Constants::TOKEN_ERROR, undef, \%error, undef);
    }
  }

  if($self->{type} eq TokenType::GRANT())
  {
    $self->{grant_token}=$self->{token};
  }
  else{
    $self->{refresh_token}=$self->{token};

    $self->{grant_token} = undef;
  }

  bless $self,$class;
  return $self;
  }
catch{
        my $e=shift;
        my $log=Log::Handler->get_logger("SDKLogger");
        $log->error($e->to_string());
        die;
}
finally{};
}

sub get_client_id{
  my $self = shift;

  return $self->{client_id};
}

sub get_client_secret{
  my $self = shift;

  return $self->{client_secret};
}

sub get_redirect_url{
  my $self = shift;

  return $self->{redirect_url};
}

sub get_grant_token{
  my $self = shift;

  return $self->{grant_token};
}

sub get_refresh_token{
  my $self = shift;

  return $self->{refresh_token};
}

sub get_access_token{
  my $self = shift;

  return $self->{access_token};
}

sub get_expires_in{
  my $self = shift;

  return $self->{expires_in};
}

sub set_refresh_token{
  my ($self, $value) = @_;

  $self->{refresh_token} = $value;
}

sub set_access_token{
  my ($self, $value) = @_;

  $self->{access_token} = $value;
}

sub set_expires_in{

  my ($self, $value) = @_;

  $self->{expires_in} = $value;
}

sub set_grant_token{
  my ($self, $value) = @_;

  $self->{grant_token} = $value;
}

sub authenticate
{

    my ($self, $url_connection) = @_;

    my $token = undef;

    my $store = Initializer::get_store();

    my $user = Initializer::get_user();

    my $oauth_token = Initializer::get_store()->get_token($user, $self);

    if (!(defined($oauth_token)))
    {
        $token = (defined($self->{access_token})) ? ($self->generate_access_token($user, $store)->get_access_token()) : ($self->refresh_access_token($user, $store)->get_access_token());
    }
    elsif($oauth_token->get_expires_in()-(time()*1000) < 5000)
    {
        $token = $self->refresh_access_token($user, $store)->get_access_token();
    }
    else
    {
        $token = $self->get_access_token();
    }

  $url_connection->add_header($Constants::AUTHORIZATION, $Constants::OAUTH_HEADER_PREFIX.$token);
}


sub refresh_access_token
{
    my ($self, $user, $store) = @_;
    try
    {
        my $url = Initializer::get_environment()->get_accounts_url();

        my %request_body = (
            $Constants::GRANT_TYPE => $Constants::REFRESH_TOKEN,
            $Constants::CLIENT_ID => $self->get_client_id(),
            $Constants::CLIENT_SECRET => $self->get_client_secret(),
            $Constants::REDIRECT_URI => $self->get_redirect_url(),
            $Constants::REFRESH_TOKEN => $self->get_refresh_token()
        );

        my $res = LWP::UserAgent->new()->post($url, \%request_body);

        my $decoded_json = JSON->new->utf8->decode($res->decoded_content());

        $store->save_token($user, $self->parse_response($decoded_json));

        return $self;
    }
    catch
    {
        my $e=shift;
        my $log=Log::Handler->get_logger("SDKLogger");
        $log->error($e->to_string());
        die;
    }
    finally{};
}

sub generate_access_token
{
    my($self, $user, $store) = @_;
    try
    {
        my $url = Initializer::get_environment()->get_accounts_url();

        my %request_body = (
            $Constants::GRANT_TYPE => $Constants::GRANT_TYPE_AUTH_CODE,
            $Constants::CLIENT_ID => $self->get_client_id(),
            $Constants::CLIENT_SECRET => $self->get_client_secret(),
            $Constants::REDIRECT_URI => $self->get_redirect_url(),
            $Constants::CODE => $self->get_grant_token()
        );

        my $res = LWP::UserAgent->new()->post($url, \%request_body);

        my $decoded_json = JSON->new->utf8->decode($res->decoded_content());

        $store->save_token($user, $self->parse_response($decoded_json));

        return $self;
    }
    catch
    {
        my $e=shift;
        my $log=Log::Handler->get_logger("SDKLogger");
        $log->error($e->to_string());
        die;
    }
finally{};
}


sub parse_response
{

    my ($self, $response_json) = @_;

    my %response_json = %{$response_json};

    unless(exists($response_json{$Constants::ACCESS_TOKEN}))
    {
        $OAuthToken::logger->error($Constants::GET_TOKEN_ERROR);

        die SDKException->new($Constants::INVALID_CLIENT_ERROR, $response_json{$Constants::ERROR_KEY});
    }

    $self->set_access_token($response_json{$Constants::ACCESS_TOKEN});

    if(exists($response_json{$Constants::REFRESH_TOKEN}))
    {
        $self->set_refresh_token($response_json{$Constants::REFRESH_TOKEN});
    }

    $self->set_expires_in((time() * 1000) + $self->get_token_expires_in($response_json));

    return $self;
}


sub get_token_expires_in{
  my ($self, $response_json)=@_;

  return ($response_json->{$Constants::EXPIRES_IN_SEC})? $response_json->{$Constants::EXPIRES_IN} : ($response_json->{$Constants::EXPIRES_IN} * 1000);
}

=head1 NAME

com::zoho::api::athenticator::OAuthToken - This class gets token and checks expiry time

=head1 DESCRIPTION

=head2 METHODS

=over 4

=item C<new>

Returns an OAuthToken class instance with the specified parameters

Param client_id : A String containing the OAuth client id

Param client_secret : A String containing the OAuth Client secret

Param redirect_url : A String containing the OAuth redirect Url

Param token : A String containing the REFRESH/GRANT token

Param token_type : A method containing the given token type.

=item C<get_client_id>

Returns A String representing the OAuth client id

=item C<get_client_secret>

Returns A String representing the OAuth client secret

=item C<get_redirect_url>

Returns A String representing the OAuth redirect URL

=item C<get_grant_token>

Returns A String representing the grant token

=item C<get_refresh_token>

Returns A String representing the refresh token

=item C<get_access_token>

Returns A String representing access token

=item C<get_expires_in>

Returns A String representing token expire time

=item C<set_refresh_token>

This is a setter method to set refresh token.

Param refresh_token :  A String containing the refresh token

=item C<set_access_token>

This is a setter method to set access token.

Param access_token : A String containing the access token

=item C<set_expires_in>

This is a setter method to set Expires in.

Param expires_in : A String containing the token expire time

=item C<set_grant_token>

This is a setter method to set grant token.

Param grant_token :  A String containing the grant token

=back

=cut

1;

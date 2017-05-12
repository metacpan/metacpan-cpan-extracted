package WebService::Spotify::OAuth2;
use Moo;
use Method::Signatures;
use IO::File;
use LWP::UserAgent;
use URI::QueryParam;
use JSON;
use MIME::Base64;
use Data::Dumper;

our $VERSION = '1.002';

has 'client_id'     => ( is => 'rw', required => 1 );
has 'client_secret' => ( is => 'rw', required => 1 );
has 'redirect_uri'  => ( is => 'rw', required => 1 );
has 'state'         => ( is => 'rw' );
has 'scope'         => ( is => 'rw' );
has 'cache_path'    => ( is => 'rw' );
has 'trace'         => ( is => 'rw', default => 0 );

has 'oauth_authorize_url' => ( is => 'rw', default => 'https://accounts.spotify.com/authorize' );
has 'oauth_token_url'     => ( is => 'rw', default => 'https://accounts.spotify.com/api/token' );

has 'user_agent' => (
  is => 'rw',
  default => sub { 
    my $ua = LWP::UserAgent->new;
    $ua->agent("WebService::Spotify::OAuth2/$VERSION");
    return $ua;
  }
);

method get_cached_token {
  my $token_info;
  if ($self->cache_path) {
    
    if (my $fh = IO::File->new('< ' . $self->cache_path)) {
      local $/;
      $token_info = from_json( <$fh> );
      $fh->close;
    }

    $token_info = $self->refresh_access_token($token_info->{refresh_token}) if $self->is_token_expired($token_info);
  }
  return $token_info;
}

method save_token_info ($token_info) {
  if ($self->cache_path) {
    my $fh = IO::File->new('> ' . $self->cache_path) || die "Could not create cache file $@";
    print $fh to_json($token_info);
    $fh->close;
  }
}

method is_token_expired ($token_info) {
  return ($token_info and $token_info->{expires_at} ? ($token_info->{expires_at} < time) : 0);
}

method get_authorize_url {
  my %payload = (
    client_id     => $self->client_id,
    response_type => 'code',
    redirect_uri  => $self->redirect_uri
  );
  $payload{scope} = $self->scope if $self->scope;
  $payload{state} = $self->state if $self->state;

  my $uri = URI->new( $self->oauth_authorize_url );
  $uri->query_param( $_, $payload{$_} ) for keys %payload;

  return $uri->as_string;
}

method parse_response_code ($response) {
  my $code = [split /&/, [split /\?code=/, $response]->[1]]->[0];
  chomp($code);
  return $code;
}

method get_access_token ($code) {
  my $payload = {
    grant_type    => 'authorization_code',
    code          => $code,
    redirect_uri  => $self->redirect_uri
  };
  $payload->{scope} = $self->scope if $self->scope;
  $payload->{state} = $self->state if $self->state;
 
  my $token_info = $self->_post( $self->oauth_token_url, $payload );

  if ($token_info) {
    die("Token error: $token_info->{error}" . ($token_info->{error_description} ? " ($token_info->{error_description})" : '') ) if $token_info->{error};
    $self->save_token_info($token_info);
  }

  return $token_info;
}

method refresh_access_token ($refresh_token) {
  my $payload = {
    grant_type    => 'refresh_token',
    refresh_token => $refresh_token
  };

  my $token_info = $self->_post( $self->oauth_token_url, $payload );

  if ($token_info) {
    die("Token error: $token_info->{error}" . ($token_info->{error_description} ? " ($token_info->{error_description})" : '') ) if $token_info->{error};
    $token_info->{expires_at} = time + $token_info->{expires_in};
    $token_info->{refresh_token} ||= $refresh_token;
    $self->save_token_info($token_info);
  }

  return $token_info;
}

method _post ($uri, $payload) {
  my $headers  = $self->_auth_headers;
  my $response = $self->user_agent->post( $uri, $payload, %$headers );
  
  $self->_log("POST", $uri);
  $self->_log("HEAD", Dumper $headers);
  $self->_log("DATA", Dumper $payload);
  $self->_log("RESP", $response->content);

  #die $response->status_line unless $response->is_success;
  
  return from_json( $response->content );
}

method _auth_headers {
  my $auth_header = encode_base64( $self->client_id . ':' . $self->client_secret, '' );
  return { 'Authorization' => 'Basic ' . $auth_header };
}

method _log (@strings) {
  print join(' ', @strings) . "\n" if $self->trace;
}

1;

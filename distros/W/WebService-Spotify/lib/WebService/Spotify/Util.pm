package WebService::Spotify::Util;
use WebService::Spotify::OAuth2;
use strict;
use warnings;

sub prompt_for_user_token {
  my ($username, $scope) = @_;

  my $sp_oauth = WebService::Spotify::OAuth2->new(
    client_id     => $ENV{SPOTIFY_CLIENT_ID}     || die('Expected env var SPOTIFY_CLIENT_ID'), 
    client_secret => $ENV{SPOTIFY_CLIENT_SECRET} || die('Expected env var SPOTIFY_CLIENT_SECRET'), 
    redirect_uri  => $ENV{SPOTIFY_REDIRECT_URI}  || die('Expected env var SPOTIFY_REDIRECT_URI'),
    cache_path    => $username,
    trace         => 0,
  );
  $sp_oauth->scope($scope) if $scope;
  
  my $token_info = $sp_oauth->get_cached_token;

  if (!$token_info) {
    my $auth_url = $sp_oauth->get_authorize_url;  
    
    printf "\nPlease navigate here:\n%s\n", $auth_url;
    
    print "\nEnter the URL you were redirected to: ";
    my $response = <STDIN>;
    
    my $code = $sp_oauth->parse_response_code($response);
    $token_info = $sp_oauth->get_access_token($code);
  }

  return $token_info ? $token_info->{access_token} : undef;
}

1;
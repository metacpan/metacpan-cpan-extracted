package WebService::Akeneo::Auth;
$WebService::Akeneo::Auth::VERSION = '0.001';
use v5.38;

use Object::Pad;
use Mojo::URL;
use Time::HiRes 'time';
use MIME::Base64 ();

use WebService::Akeneo::HTTPError;

class WebService::Akeneo::Auth 0.001;

field $config   :param;   # WebService::Akeneo::Config
field $ua       :param;   # Mojo::UserAgent
field $token;
field $refresh;
field $expires_at = 0;

method token_info { { access_token => $token, refresh_token => $refresh, expires_at => $expires_at } }
method bearer { $token }

method _basic_auth ($id,$secret) { MIME::Base64::encode_base64("$id:$secret", '') }

method authenticate () {
  my $url = Mojo::URL->new($config->base_url . '/api/oauth/v1/token');
  my $tx  = $ua->post($url => { Authorization => 'Basic ' . $self->_basic_auth($config->client_id, $config->client_secret) }
                          => form => { grant_type => 'password', username => $config->username, password => $config->password, scope => $config->scope });
  my $res = $tx->result;
  WebService::Akeneo::HTTPError->new(code=>$res->code,message=>$res->message,body=>($res->body//''))->throw if $res->is_error;
  my $j = $res->json; $token = $j->{access_token}; $refresh = $j->{refresh_token}//$refresh; $expires_at = time + ($j->{expires_in}//3600);
  1;
}

method refresh_if_needed () {
  return 1 if $token && time < $expires_at - 30;
  return $self->refresh_token if $refresh;
  return $self->authenticate;
}

method refresh_token () {
  die 'No refresh_token' unless $refresh;
  my $url = Mojo::URL->new($config->base_url . '/api/oauth/v1/token');
  my $tx  = $ua->post($url => { Authorization => 'Basic ' . $self->_basic_auth($config->client_id, $config->client_secret) }
                          => form => { grant_type => 'refresh_token', refresh_token => $refresh, scope => $config->scope });
  my $res = $tx->result;
  WebService::Akeneo::HTTPError->new(code=>$res->code,message=>$res->message,body=>($res->body//''))->throw if $res->is_error;
  my $j = $res->json; $token = $j->{access_token}; $refresh = $j->{refresh_token}//$refresh; $expires_at = time + ($j->{expires_in}//3600);
  1;
}

1;

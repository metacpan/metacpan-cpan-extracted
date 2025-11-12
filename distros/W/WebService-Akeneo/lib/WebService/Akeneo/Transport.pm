package WebService::Akeneo::Transport;
$WebService::Akeneo::Transport::VERSION = '0.001';
use v5.38;

use Object::Pad;

use Mojo::UserAgent;
use Mojo::URL;
use Mojo::JSON qw(encode_json decode_json);

use Time::HiRes 'sleep';

use WebService::Akeneo::HTTPError;

class WebService::Akeneo::Transport 0.001;

field $config   :param;       # WebService::Akeneo::Config
field $auth     :param;       # WebService::Akeneo::Auth
field $ua       = Mojo::UserAgent->new;
field $rate_guard = 1;
field $on_request;
field $on_response;

method set_ua ($new) { $ua = $new; $self }
method on_request ($cb) { $on_request = $cb; $self }
method on_response ($cb){ $on_response = $cb; $self }
method set_rate_guard ($b){ $rate_guard = $b ? 1 : 0; $self }

method request ($method, $path, %opt) {
  $auth->refresh_if_needed;
  my $url = Mojo::URL->new($config->base_url . $config->api_prefix . $path);
  $url->query($opt{query}) if $opt{query};

  my $headers = { Accept=>'application/json', Authorization => 'Bearer ' . $auth->bearer };
  my $tx;

  if (exists $opt{ndjson}) {
    my $records = $opt{ndjson} // [];
    die 'ndjson must be arrayref' unless ref($records) eq 'ARRAY';
    die 'ndjson array empty' unless @$records;
    my $ndjson = join("", map { encode_json($_)."\n" } @$records);
    $headers->{'Content-Type'} = 'application/vnd.akeneo.collection+json';
    $tx = $ua->build_tx($method => $url => $headers => $ndjson);
  }
  elsif (exists $opt{json}) {
    $headers->{'Content-Type'} = 'application/json';
    $tx = $ua->build_tx($method => $url => $headers => encode_json($opt{json}));
  }
  else {
    $tx = $ua->build_tx($method => $url => $headers);
  }

  $on_request->({ method => $method, url => "$url", headers=>{ %$headers }, body=>($tx->req->body//'') })
    if $on_request;

  $tx = $ua->start($tx);
  my $res = $tx->result;

  if ($rate_guard) {
    my $h = $res->headers;
    if ( ($h->header('X-Rate-Limit-Remaining') // '') eq '0') {
      my $reset = $h->header('X-Rate-Limit-Reset') // 1;
      sleep($reset+0.05)
    }
  }

  if ($res->is_error && ($res->code//0) == 401) {
    $auth->refresh_token; $headers->{Authorization} = 'Bearer ' . $auth->bearer;
    $tx = $ua->start($ua->build_tx($method => $url => $headers => $tx->req->body));
    $res = $tx->result;
  }

  if ($res->is_error) {
    WebService::Akeneo::HTTPError->new(code=>$res->code, message=>$res->message, body=>($res->body//''))->throw
  }

  my $decoded = _decode($res);

  $on_response->({ code=>$res->code, headers=>{ %{$res->headers->to_hash} }, decoded=>$decoded })
    if $on_response;

  return $decoded;
}

sub _decode ($res) {
  my $ct = $res->headers->content_type // '';
  my $body = $res->body // '';

  if ($ct =~ m{application/vnd\.akeneo\.collection\+json}i) {
    my @items = map { eval { decode_json($_) } // { raw => $_ } } grep { length } split /\r?\n/, $body; return \@items;
  }

  return $res->json if $ct =~ m{application/json}i;

  return $body;
}

1;

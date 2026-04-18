package WWW::Firecrawl;
# ABSTRACT: Firecrawl v2 API bindings (self-host first, cloud compatible)
use Moo;
use Carp qw( croak );
use HTTP::Request ();
use JSON::MaybeXS ();
use URI ();
use Safe::Isa;
use WWW::Firecrawl::Error ();

our $VERSION = '0.001';

has base_url => (
  is => 'ro',
  default => sub { $ENV{FIRECRAWL_BASE_URL} || 'https://api.firecrawl.dev' },
);

has api_key => (
  is => 'ro',
  default => sub { $ENV{FIRECRAWL_API_KEY} },
);

has api_version => (
  is => 'ro',
  default => sub { 'v2' },
);

has json => (
  is => 'lazy',
  default => sub { JSON::MaybeXS->new( utf8 => 1, convert_blessed => 1 ) },
);

has user_agent_string => (
  is => 'ro',
  default => sub { "WWW-Firecrawl/$VERSION" },
);

has ua => (
  is => 'lazy',
);

has is_failure => (
  is => 'ro',
  default => sub { \&_default_is_failure },
);

has strict => ( is => 'ro', default => sub { 0 } );

has max_attempts   => ( is => 'ro', default => sub { 3 } );
has retry_backoff  => ( is => 'ro', default => sub { [ 1, 2, 4 ] } );
has retry_statuses => ( is => 'ro', default => sub { [ 429, 502, 503, 504 ] } );
has on_retry       => ( is => 'ro' );

has sleep_sub => (
  is => 'ro',
  default => sub {
    require Time::HiRes;
    return sub { Time::HiRes::sleep($_[0]) };
  },
);

has _retry_status_set => ( is => 'lazy' );
sub _build__retry_status_set {
  return { map { $_ => 1 } @{ $_[0]->retry_statuses } };
}

sub _default_is_failure {
  my ( $page ) = @_;
  return 0 unless ref $page eq 'HASH';
  my $meta = $page->{metadata} || {};
  return 1 if defined $meta->{error} && length $meta->{error};
  my $sc = $meta->{statusCode} // 0;
  return $sc >= 500;
}

sub BUILDARGS {
  my ( $class, @args ) = @_;
  my %args = @args == 1 && ref $args[0] eq 'HASH' ? %{ $args[0] } : @args;
  if ( exists $args{failure_codes} ) {
    die "WWW::Firecrawl: pass either 'is_failure' or 'failure_codes', not both\n"
      if exists $args{is_failure};
    my $spec = delete $args{failure_codes};
    $args{is_failure} = $class->_compile_failure_codes($spec);
  }
  return \%args;
}

sub _compile_failure_codes {
  my ( $class, $spec ) = @_;
  if ( !ref $spec && defined $spec && $spec eq 'any-non-2xx' ) {
    return sub {
      my ($p) = @_;
      return 0 unless ref $p eq 'HASH';
      my $meta = $p->{metadata} || {};
      return 1 if defined $meta->{error} && length $meta->{error};
      my $sc = $meta->{statusCode} // 200;
      return $sc < 200 || $sc >= 300;
    };
  }
  if ( ref $spec eq 'ARRAY' ) {
    my %codes = map { $_ => 1 } @$spec;
    return sub {
      my ($p) = @_;
      return 0 unless ref $p eq 'HASH';
      my $meta = $p->{metadata} || {};
      return 1 if defined $meta->{error} && length $meta->{error};
      my $sc = $meta->{statusCode} // 0;
      return !!$codes{$sc};
    };
  }
  die "WWW::Firecrawl: failure_codes must be arrayref or the string 'any-non-2xx'\n";
}

sub _build_ua {
  my ( $self ) = @_;
  require LWP::UserAgent;
  my $ua = LWP::UserAgent->new(
    agent => $self->user_agent_string,
    timeout => 300,
  );
  return $ua;
}

#----------------------------------------------------------------------
# URL + header helpers
#----------------------------------------------------------------------

sub endpoint_url {
  my ( $self, @path ) = @_;
  my $base = $self->base_url;
  $base =~ s{/+\z}{};
  return join('/', $base, $self->api_version, @path);
}

sub _default_headers {
  my ( $self ) = @_;
  my @h = ( 'Content-Type' => 'application/json', 'Accept' => 'application/json' );
  push @h, 'Authorization' => 'Bearer '.$self->api_key if defined $self->api_key;
  return @h;
}

sub _json_post {
  my ( $self, $url, $body ) = @_;
  my $content = defined $body ? $self->json->encode($body) : '{}';
  return HTTP::Request->new( POST => $url, [ $self->_default_headers ], $content );
}

sub _get {
  my ( $self, $url ) = @_;
  return HTTP::Request->new( GET => $url, [ $self->_default_headers ] );
}

sub _delete {
  my ( $self, $url ) = @_;
  return HTTP::Request->new( DELETE => $url, [ $self->_default_headers ] );
}

#----------------------------------------------------------------------
# Retry wrapper
#----------------------------------------------------------------------

sub _classify_response {
  my ( $self, $response, $attempt ) = @_;
  my $cw = $response->header('Client-Warning');
  if ( defined $cw && $cw eq 'Internal response' ) {
    return (
      WWW::Firecrawl::Error->new(
        type => 'transport',
        message => 'Firecrawl transport error: ' . ($response->decoded_content // $response->message // 'unknown'),
        response => $response,
        status_code => 0,
        attempt => $attempt,
      ),
      1,
    );
  }
  return (undef, 0) if $response->is_success;
  my $code = $response->code;
  my $retryable = $self->_retry_status_set->{$code} ? 1 : 0;
  my $err = WWW::Firecrawl::Error->new(
    type => 'api',
    message => "Firecrawl: HTTP $code " . $response->message,
    response => $response,
    status_code => $code,
    attempt => $attempt,
  );
  return ($err, $retryable);
}

sub _retry_delay {
  my ( $self, $response, $attempt ) = @_;
  my $ra = $response->header('Retry-After');
  if ( defined $ra && $ra =~ /\A\d+\z/ ) {
    return 0 + $ra;
  }
  my $backoff = $self->retry_backoff;
  my $idx = $attempt - 1;
  $idx = $#$backoff if $idx > $#$backoff;
  return $backoff->[ $idx ] // 1;
}

sub _do_with_retry {
  my ( $self, $request ) = @_;
  my $max = $self->max_attempts;
  my $last_error;
  for my $attempt ( 1 .. $max ) {
    my $response = $self->ua->request($request);
    my ( $err, $retryable ) = $self->_classify_response($response, $attempt);
    return $response unless $err;
    $last_error = $err;
    if ( $retryable && $attempt < $max ) {
      my $delay = $self->_retry_delay($response, $attempt);
      if ( my $cb = $self->on_retry ) {
        $cb->( $attempt, $delay, $err );
      }
      $self->sleep_sub->($delay);
      next;
    }
    die $err;
  }
  die $last_error;
}

#----------------------------------------------------------------------
# Response parser: unified JSON decode + error handling
#----------------------------------------------------------------------

sub is_response { $_[1]->$_isa('HTTP::Response') }
sub is_request  { $_[1]->$_isa('HTTP::Request')  }

sub parse_response {
  my ( $self, $response ) = @_;
  croak "parse_response requires an HTTP::Response" unless $self->is_response($response);
  my $body = $response->decoded_content;
  my $data;
  if ( defined $body && length $body ) {
    local $@;
    $data = eval { $self->json->decode($body) };
    if ($@) {
      if ( !$response->is_success ) {
        die WWW::Firecrawl::Error->new(
          type => 'api',
          message => "Firecrawl: HTTP ".$response->code.": ".$response->message,
          response => $response,
          status_code => $response->code,
        );
      }
      die WWW::Firecrawl::Error->new(
        type => 'api',
        message => "Firecrawl: invalid JSON response (HTTP ".$response->code."): $@",
        response => $response,
        status_code => $response->code,
      );
    }
  }
  if ( !$response->is_success ) {
    my $msg = (ref $data eq 'HASH' && ($data->{error} || $data->{message}))
      || $response->message || 'unknown error';
    die WWW::Firecrawl::Error->new(
      type => 'api',
      message => "Firecrawl: HTTP ".$response->code.": $msg",
      response => $response,
      data => $data,
      status_code => $response->code,
    );
  }
  if ( ref $data eq 'HASH' && exists $data->{success} && !$data->{success} ) {
    my $msg = $data->{error} || $data->{message} || 'request failed';
    die WWW::Firecrawl::Error->new(
      type => 'api',
      message => "Firecrawl: $msg",
      response => $response,
      data => $data,
      status_code => $response->code,
    );
  }
  return $data;
}

#----------------------------------------------------------------------
# Inspection helpers (classification)
#----------------------------------------------------------------------

sub is_scrape_ok {
  my ( $self, $page ) = @_;
  return !$self->is_failure->($page);
}

sub scrape_status {
  my ( $self, $page ) = @_;
  return 0 unless ref $page eq 'HASH';
  return $page->{metadata}{statusCode} // 0;
}

sub scrape_error {
  my ( $self, $page ) = @_;
  return undef unless ref $page eq 'HASH';
  my $err = $page->{metadata}{error};
  my $sc  = $page->{metadata}{statusCode};
  my $bad_sc = defined $sc && ( $sc < 200 || $sc >= 300 );
  if ( defined $err && length $err && $bad_sc ) {
    return "$err (HTTP $sc)";
  }
  return $err if defined $err && length $err;
  return "HTTP $sc" if $bad_sc;
  return undef;
}

#----------------------------------------------------------------------
# Endpoint: /scrape
#----------------------------------------------------------------------

sub scrape_request {
  my ( $self, %args ) = @_;
  delete $args{strict};   # client-side option, not an API param
  croak "scrape_request requires 'url'" unless defined $args{url};
  return $self->_json_post($self->endpoint_url('scrape'), \%args);
}

sub parse_scrape_response {
  my ( $self, $response, %opts ) = @_;
  my $full = $self->parse_response($response);
  my $data = $full->{data};
  my $strict = exists $opts{strict} ? $opts{strict} : $self->strict;
  if ( $strict && $self->is_failure->($data) ) {
    die WWW::Firecrawl::Error->new(
      type => 'scrape',
      message => 'Firecrawl scrape failed: ' . ($self->scrape_error($data) // 'unknown'),
      data => $data,
      status_code => $self->scrape_status($data),
      url => $data->{metadata}{sourceURL} // $data->{metadata}{url},
      response => $response,
    );
  }
  return $data;
}

sub scrape {
  my ( $self, %args ) = @_;
  my %parse_opts;
  $parse_opts{strict} = delete $args{strict} if exists $args{strict};
  return $self->parse_scrape_response(
    $self->_do_with_retry($self->scrape_request(%args)),
    %parse_opts,
  );
}

#----------------------------------------------------------------------
# Endpoint: /crawl
#----------------------------------------------------------------------

sub crawl_request {
  my ( $self, %args ) = @_;
  croak "crawl_request requires 'url'" unless defined $args{url};
  return $self->_json_post($self->endpoint_url('crawl'), \%args);
}

sub parse_crawl_response {
  my ( $self, $response ) = @_;
  return $self->parse_response($response);
}

sub crawl {
  my ( $self, %args ) = @_;
  return $self->parse_crawl_response(
    $self->_do_with_retry($self->crawl_request(%args))
  );
}

sub crawl_status_request {
  my ( $self, $id ) = @_;
  croak "crawl_status_request requires id" unless defined $id && length $id;
  return $self->_get($self->endpoint_url('crawl', $id));
}

sub parse_crawl_status_response {
  my ( $self, $response ) = @_;
  return $self->parse_response($response);
}

sub crawl_status {
  my ( $self, $id ) = @_;
  return $self->parse_crawl_status_response(
    $self->_do_with_retry($self->crawl_status_request($id))
  );
}

sub crawl_cancel_request {
  my ( $self, $id ) = @_;
  croak "crawl_cancel_request requires id" unless defined $id && length $id;
  return $self->_delete($self->endpoint_url('crawl', $id));
}

sub parse_crawl_cancel_response { $_[0]->parse_response($_[1]) }

sub crawl_cancel {
  my ( $self, $id ) = @_;
  return $self->parse_crawl_cancel_response(
    $self->_do_with_retry($self->crawl_cancel_request($id))
  );
}

sub crawl_errors_request {
  my ( $self, $id ) = @_;
  croak "crawl_errors_request requires id" unless defined $id && length $id;
  return $self->_get($self->endpoint_url('crawl', $id, 'errors'));
}

sub parse_crawl_errors_response { $_[0]->parse_response($_[1]) }

sub crawl_errors {
  my ( $self, $id ) = @_;
  return $self->parse_crawl_errors_response(
    $self->_do_with_retry($self->crawl_errors_request($id))
  );
}

sub crawl_active_request {
  my ( $self ) = @_;
  return $self->_get($self->endpoint_url('crawl', 'active'));
}

sub parse_crawl_active_response { $_[0]->parse_response($_[1]) }

sub crawl_active {
  my ( $self ) = @_;
  return $self->parse_crawl_active_response(
    $self->_do_with_retry($self->crawl_active_request)
  );
}

sub crawl_params_preview_request {
  my ( $self, %args ) = @_;
  return $self->_json_post($self->endpoint_url('crawl', 'params', 'preview'), \%args);
}

sub parse_crawl_params_preview_response { $_[0]->parse_response($_[1]) }

sub crawl_params_preview {
  my ( $self, %args ) = @_;
  return $self->parse_crawl_params_preview_response(
    $self->_do_with_retry($self->crawl_params_preview_request(%args))
  );
}

# Follow the "next" pagination URL verbatim (crawl_status chunks > 10MB)
sub crawl_status_next_request {
  my ( $self, $next_url ) = @_;
  croak "crawl_status_next_request requires next URL" unless defined $next_url && length $next_url;
  return HTTP::Request->new( GET => $next_url, [ $self->_default_headers ] );
}

sub crawl_status_next {
  my ( $self, $next_url ) = @_;
  return $self->parse_crawl_status_response(
    $self->_do_with_retry($self->crawl_status_next_request($next_url))
  );
}

#----------------------------------------------------------------------
# Endpoint: /map
#----------------------------------------------------------------------

sub map_request {
  my ( $self, %args ) = @_;
  croak "map_request requires 'url'" unless defined $args{url};
  return $self->_json_post($self->endpoint_url('map'), \%args);
}

sub parse_map_response {
  my ( $self, $response ) = @_;
  my $data = $self->parse_response($response);
  return $data->{links} if exists $data->{links};
  return $data;
}

sub map {
  my ( $self, %args ) = @_;
  return $self->parse_map_response(
    $self->_do_with_retry($self->map_request(%args))
  );
}

#----------------------------------------------------------------------
# Endpoint: /search
#----------------------------------------------------------------------

sub search_request {
  my ( $self, %args ) = @_;
  croak "search_request requires 'query'" unless defined $args{query};
  return $self->_json_post($self->endpoint_url('search'), \%args);
}

sub parse_search_response {
  my ( $self, $response ) = @_;
  return $self->parse_response($response);
}

sub search {
  my ( $self, %args ) = @_;
  return $self->parse_search_response(
    $self->_do_with_retry($self->search_request(%args))
  );
}

#----------------------------------------------------------------------
# Endpoint: /batch/scrape
#----------------------------------------------------------------------

sub batch_scrape_request {
  my ( $self, %args ) = @_;
  croak "batch_scrape_request requires 'urls' arrayref"
    unless ref $args{urls} eq 'ARRAY';
  return $self->_json_post($self->endpoint_url('batch', 'scrape'), \%args);
}

sub parse_batch_scrape_response { $_[0]->parse_response($_[1]) }

sub batch_scrape {
  my ( $self, %args ) = @_;
  return $self->parse_batch_scrape_response(
    $self->_do_with_retry($self->batch_scrape_request(%args))
  );
}

sub batch_scrape_status_request {
  my ( $self, $id ) = @_;
  croak "batch_scrape_status_request requires id" unless defined $id && length $id;
  return $self->_get($self->endpoint_url('batch', 'scrape', $id));
}

sub parse_batch_scrape_status_response { $_[0]->parse_response($_[1]) }

sub batch_scrape_status {
  my ( $self, $id ) = @_;
  return $self->parse_batch_scrape_status_response(
    $self->_do_with_retry($self->batch_scrape_status_request($id))
  );
}

sub batch_scrape_cancel_request {
  my ( $self, $id ) = @_;
  croak "batch_scrape_cancel_request requires id" unless defined $id && length $id;
  return $self->_delete($self->endpoint_url('batch', 'scrape', $id));
}

sub parse_batch_scrape_cancel_response { $_[0]->parse_response($_[1]) }

sub batch_scrape_cancel {
  my ( $self, $id ) = @_;
  return $self->parse_batch_scrape_cancel_response(
    $self->_do_with_retry($self->batch_scrape_cancel_request($id))
  );
}

sub batch_scrape_errors_request {
  my ( $self, $id ) = @_;
  croak "batch_scrape_errors_request requires id" unless defined $id && length $id;
  return $self->_get($self->endpoint_url('batch', 'scrape', $id, 'errors'));
}

sub parse_batch_scrape_errors_response { $_[0]->parse_response($_[1]) }

sub batch_scrape_errors {
  my ( $self, $id ) = @_;
  return $self->parse_batch_scrape_errors_response(
    $self->_do_with_retry($self->batch_scrape_errors_request($id))
  );
}

sub batch_scrape_status_next_request {
  my ( $self, $next_url ) = @_;
  croak "batch_scrape_status_next_request requires next URL"
    unless defined $next_url && length $next_url;
  return HTTP::Request->new( GET => $next_url, [ $self->_default_headers ] );
}

sub batch_scrape_status_next {
  my ( $self, $next_url ) = @_;
  return $self->parse_batch_scrape_status_response(
    $self->_do_with_retry($self->batch_scrape_status_next_request($next_url))
  );
}

#----------------------------------------------------------------------
# Endpoint: /extract
#----------------------------------------------------------------------

sub extract_request {
  my ( $self, %args ) = @_;
  croak "extract_request requires 'urls' arrayref"
    unless ref $args{urls} eq 'ARRAY';
  return $self->_json_post($self->endpoint_url('extract'), \%args);
}

sub parse_extract_response { $_[0]->parse_response($_[1]) }

sub extract {
  my ( $self, %args ) = @_;
  return $self->parse_extract_response(
    $self->_do_with_retry($self->extract_request(%args))
  );
}

sub extract_status_request {
  my ( $self, $id ) = @_;
  croak "extract_status_request requires id" unless defined $id && length $id;
  return $self->_get($self->endpoint_url('extract', $id));
}

sub parse_extract_status_response { $_[0]->parse_response($_[1]) }

sub extract_status {
  my ( $self, $id ) = @_;
  return $self->parse_extract_status_response(
    $self->_do_with_retry($self->extract_status_request($id))
  );
}

#----------------------------------------------------------------------
# Endpoint: /agent + /agent/{id}
#----------------------------------------------------------------------

sub agent_request {
  my ( $self, %args ) = @_;
  return $self->_json_post($self->endpoint_url('agent'), \%args);
}

sub parse_agent_response { $_[0]->parse_response($_[1]) }

sub agent {
  my ( $self, %args ) = @_;
  return $self->parse_agent_response(
    $self->_do_with_retry($self->agent_request(%args))
  );
}

sub agent_status_request {
  my ( $self, $id ) = @_;
  croak "agent_status_request requires id" unless defined $id && length $id;
  return $self->_get($self->endpoint_url('agent', $id));
}

sub parse_agent_status_response { $_[0]->parse_response($_[1]) }

sub agent_status {
  my ( $self, $id ) = @_;
  return $self->parse_agent_status_response(
    $self->_do_with_retry($self->agent_status_request($id))
  );
}

sub agent_cancel_request {
  my ( $self, $id ) = @_;
  croak "agent_cancel_request requires id" unless defined $id && length $id;
  return $self->_delete($self->endpoint_url('agent', $id));
}

sub parse_agent_cancel_response { $_[0]->parse_response($_[1]) }

sub agent_cancel {
  my ( $self, $id ) = @_;
  return $self->parse_agent_cancel_response(
    $self->_do_with_retry($self->agent_cancel_request($id))
  );
}

#----------------------------------------------------------------------
# Endpoint: /browser
#----------------------------------------------------------------------

sub browser_create_request {
  my ( $self, %args ) = @_;
  return $self->_json_post($self->endpoint_url('browser', 'create'), \%args);
}

sub parse_browser_create_response { $_[0]->parse_response($_[1]) }

sub browser_create {
  my ( $self, %args ) = @_;
  return $self->parse_browser_create_response(
    $self->_do_with_retry($self->browser_create_request(%args))
  );
}

sub browser_list_request {
  my ( $self ) = @_;
  return $self->_get($self->endpoint_url('browser', 'list'));
}

sub parse_browser_list_response { $_[0]->parse_response($_[1]) }

sub browser_list {
  my ( $self ) = @_;
  return $self->parse_browser_list_response(
    $self->_do_with_retry($self->browser_list_request)
  );
}

sub browser_delete_request {
  my ( $self, $id ) = @_;
  croak "browser_delete_request requires id" unless defined $id && length $id;
  return $self->_delete($self->endpoint_url('browser', $id));
}

sub parse_browser_delete_response { $_[0]->parse_response($_[1]) }

sub browser_delete {
  my ( $self, $id ) = @_;
  return $self->parse_browser_delete_response(
    $self->_do_with_retry($self->browser_delete_request($id))
  );
}

sub browser_execute_request {
  my ( $self, %args ) = @_;
  return $self->_json_post($self->endpoint_url('browser', 'execute'), \%args);
}

sub parse_browser_execute_response { $_[0]->parse_response($_[1]) }

sub browser_execute {
  my ( $self, %args ) = @_;
  return $self->parse_browser_execute_response(
    $self->_do_with_retry($self->browser_execute_request(%args))
  );
}

#----------------------------------------------------------------------
# Endpoint: /scrape/execute + /scrape/{id}/browser
#----------------------------------------------------------------------

sub scrape_execute_request {
  my ( $self, %args ) = @_;
  return $self->_json_post($self->endpoint_url('scrape', 'execute'), \%args);
}

sub parse_scrape_execute_response { $_[0]->parse_response($_[1]) }

sub scrape_execute {
  my ( $self, %args ) = @_;
  return $self->parse_scrape_execute_response(
    $self->_do_with_retry($self->scrape_execute_request(%args))
  );
}

sub scrape_browser_stop_request {
  my ( $self, $id ) = @_;
  croak "scrape_browser_stop_request requires id" unless defined $id && length $id;
  return $self->_delete($self->endpoint_url('scrape', $id, 'browser'));
}

sub parse_scrape_browser_stop_response { $_[0]->parse_response($_[1]) }

sub scrape_browser_stop {
  my ( $self, $id ) = @_;
  return $self->parse_scrape_browser_stop_response(
    $self->_do_with_retry($self->scrape_browser_stop_request($id))
  );
}

#----------------------------------------------------------------------
# Usage + monitoring endpoints
#----------------------------------------------------------------------

sub credit_usage_request  { $_[0]->_get($_[0]->endpoint_url('credit-usage')) }
sub parse_credit_usage_response { $_[0]->parse_response($_[1]) }
sub credit_usage {
  my ( $self ) = @_;
  return $self->parse_credit_usage_response($self->_do_with_retry($self->credit_usage_request));
}

sub credit_usage_historical_request { $_[0]->_get($_[0]->endpoint_url('credit-usage', 'historical')) }
sub parse_credit_usage_historical_response { $_[0]->parse_response($_[1]) }
sub credit_usage_historical {
  my ( $self ) = @_;
  return $self->parse_credit_usage_historical_response($self->_do_with_retry($self->credit_usage_historical_request));
}

sub token_usage_request { $_[0]->_get($_[0]->endpoint_url('token-usage')) }
sub parse_token_usage_response { $_[0]->parse_response($_[1]) }
sub token_usage {
  my ( $self ) = @_;
  return $self->parse_token_usage_response($self->_do_with_retry($self->token_usage_request));
}

sub token_usage_historical_request { $_[0]->_get($_[0]->endpoint_url('token-usage', 'historical')) }
sub parse_token_usage_historical_response { $_[0]->parse_response($_[1]) }
sub token_usage_historical {
  my ( $self ) = @_;
  return $self->parse_token_usage_historical_response($self->_do_with_retry($self->token_usage_historical_request));
}

sub queue_status_request { $_[0]->_get($_[0]->endpoint_url('queue-status')) }
sub parse_queue_status_response { $_[0]->parse_response($_[1]) }
sub queue_status {
  my ( $self ) = @_;
  return $self->parse_queue_status_response($self->_do_with_retry($self->queue_status_request));
}

sub activity_request { $_[0]->_get($_[0]->endpoint_url('activity')) }
sub parse_activity_response { $_[0]->parse_response($_[1]) }
sub activity {
  my ( $self ) = @_;
  return $self->parse_activity_response($self->_do_with_retry($self->activity_request));
}

#----------------------------------------------------------------------
# Bulk scrape + retry helpers
#----------------------------------------------------------------------

sub scrape_many {
  my ( $self, $urls, %common ) = @_;
  croak "scrape_many: first arg must be arrayref of URLs"
    unless ref $urls eq 'ARRAY';
  my @ok;
  my @failed;
  for my $url ( @$urls ) {
    my $res = eval { $self->scrape( url => $url, %common ) };
    if ( my $e = $@ ) {
      my $err = ref $e && $e->isa('WWW::Firecrawl::Error')
        ? $e
        : WWW::Firecrawl::Error->new( type => 'api', message => "$e", url => $url );
      push @failed, { url => $url, error => $err };
      next;
    }
    if ( $self->is_scrape_ok($res) ) {
      push @ok, { url => $url, data => $res };
    }
    else {
      push @failed, {
        url => $url,
        error => WWW::Firecrawl::Error->new(
          type => 'page',
          message => 'Firecrawl scrape failed: ' . ($self->scrape_error($res) // 'unknown'),
          data => $res,
          status_code => $self->scrape_status($res),
          url => $url,
        ),
      };
    }
  }
  return {
    ok => \@ok,
    failed => \@failed,
    stats => { ok => scalar @ok, failed => scalar @failed, total => scalar @$urls },
  };
}

sub retry_failed_pages {
  my ( $self, $result, %scrape_opts ) = @_;
  my @urls = map { $_->{url} } @{ $result->{failed} || [] };
  return $self->scrape_many( \@urls, %scrape_opts );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Firecrawl - Firecrawl v2 API bindings (self-host first, cloud compatible)

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use WWW::Firecrawl;

  # Self-hosted
  my $fc = WWW::Firecrawl->new(
    base_url => 'http://localhost:3002',
  );

  # Cloud
  my $fc = WWW::Firecrawl->new(
    api_key => 'fc-...',
  );

  # Synchronous calls (uses LWP::UserAgent)
  my $doc     = $fc->scrape( url => 'https://example.com', formats => ['markdown'] );
  my $links   = $fc->map( url => 'https://example.com' );
  my $results = $fc->search( query => 'perl firecrawl', limit => 5 );

  my $job = $fc->crawl( url => 'https://example.com', limit => 50 );
  my $status = $fc->crawl_status( $job->{id} );

  # Request builders (bring your own UA / async framework)
  my $req = $fc->scrape_request( url => 'https://example.com' );
  my $res = $my_ua->request($req);
  my $data = $fc->parse_scrape_response($res);

=head1 DESCRIPTION

Firecrawl (L<https://firecrawl.dev>, L<https://github.com/firecrawl/firecrawl>)
is an open-source web scraping and crawling API. This module provides Perl
bindings for the v2 API, with a focus on self-hosted deployments (cloud works
too).

Every endpoint is exposed in three flavours:

=over 4

=item * C<< $fc->foo_request(%args) >> — returns an L<HTTP::Request>, no network I/O

=item * C<< $fc->parse_foo_response($http_response) >> — decodes JSON, dies on error, returns the payload

=item * C<< $fc->foo(%args) >> — convenience: builds, fires via L<LWP::UserAgent>, parses

=back

The split makes the module trivial to use with any async framework; see
L<Net::Async::Firecrawl> for the L<IO::Async> integration.

=head1 ERROR HANDLING

All failures throw a L<WWW::Firecrawl::Error> object (stringifies to its
message — so existing C<< die "..." >> / C<$@>-matching code keeps working).

Five error types:

=over 4

=item * C<transport> — Could not reach Firecrawl (DNS / connect / TLS / socket).

=item * C<api> — Firecrawl returned a non-2xx HTTP response, invalid JSON, or C<< {success: false} >>.

=item * C<job> — For flows using C<*_status>: the Firecrawl job ended with
status C<failed> or C<cancelled>.

=item * C<scrape> — Single scrape: the target URL was classified as failed
by L</is_failure>. Only thrown when L</strict> is on.

=item * C<page> — Surfaced in the C<failed[]> arrayref of
L</scrape_many> / L</retry_failed_pages>: an individual URL's scrape
was classified as failed but the overall operation continued.

=back

Retries are automatic for C<transport> and retryable C<api> statuses (see
L</retry_statuses>). Never for C<job>, C<scrape>, or C<page> — Firecrawl
already retries target-level failures server-side, and re-running a failed
job is a caller decision. See L</retry_failed_pages> for the manual
re-scrape helper.

Usage:

  use Try::Tiny;
  try {
    my $data = $fc->scrape( url => $u, strict => 1 );
    ...
  }
  catch {
    my $e = $_;
    if (ref $e && $e->isa('WWW::Firecrawl::Error')) {
      if ($e->is_transport) { ... }
      elsif ($e->is_scrape) { warn "target dead: ", $e->url }
      else                  { warn "firecrawl: $e" }
    }
  };

=head2 base_url

Base URL of the Firecrawl server. Defaults to C<$ENV{FIRECRAWL_BASE_URL}> or
C<https://api.firecrawl.dev>.

=head2 api_key

Bearer token for authentication. Defaults to C<$ENV{FIRECRAWL_API_KEY}>.
Optional — self-hosted instances can run without auth.

=head2 api_version

Defaults to C<v2>.

=head2 ua

L<LWP::UserAgent> instance used by the synchronous convenience methods. Lazily
built.

=head2 strict

When true, C<parse_scrape_response> (and therefore C<scrape>) throws a
L<WWW::Firecrawl::Error> with C<type=scrape> if the target URL is classified
as failed by L</is_failure>. Default is false — partial results are returned
and the caller inspects via L</is_scrape_ok> / L</scrape_error>.

Can be overridden per call: C<< $fc->scrape( url => ..., strict => 1 ) >>.

C<strict> affects only single-URL scrape. Flow helpers (crawl, batch-scrape,
scrape_many) always return partial-success results regardless.

=head2 max_attempts

Number of attempts for each request (default C<3>). Set to C<1> to disable
retries. Retries apply only to transport errors and retryable API statuses
(see L</retry_statuses>). Never retries target-level (C<scrape>/C<page>) or
job-level (C<job>) failures — Firecrawl already retries targets server-side,
and re-running a failed job is a caller decision.

=head2 retry_backoff

Arrayref of delays in seconds between attempts (default C<[1, 2, 4]>). If
fewer entries than C<max_attempts - 1>, the last value is reused. Overridden
by a numeric C<Retry-After> response header.

=head2 retry_statuses

Arrayref of HTTP status codes that trigger a retry (default
C<[429, 502, 503, 504]>).

=head2 on_retry

Optional CodeRef called before each retry, with C<($attempt, $delay, $error)>.
Useful for logging.

=head2 sleep_sub

CodeRef that performs the inter-attempt sleep. Defaults to
C<Time::HiRes::sleep>. Override in tests to avoid wall-clock delays.

=head2 is_failure

Code reference that classifies a scrape result hash as a failure. Defaults to:
C<metadata.error> non-empty OR C<metadata.statusCode> >= 500. Mutually
exclusive with L</failure_codes>.

=head2 failure_codes

Constructor sugar for common L</is_failure> variants. Pass an arrayref of HTTP
status codes (e.g. C<[ 404, 500..599 ]>) or the string C<'any-non-2xx'>.
Compiled into an C<is_failure> predicate at construction time.

Passing both C<is_failure> and C<failure_codes> raises at construction.

=head2 endpoint_url(@path_parts)

Builds C<< <base_url>/<api_version>/<path_parts> >>.

=head2 parse_response($http_response)

Generic JSON decoder used by all C<parse_*> helpers. On failure, throws a
L<WWW::Firecrawl::Error> object (type C<api> or C<transport>). Throws on
HTTP errors and on C<< {success: false} >> payloads.

=head2 is_response / is_request

Boolean helpers to check if a value is an L<HTTP::Response> or L<HTTP::Request>.

=head2 is_scrape_ok($page)

Returns true if the given scrape result hash is not classified as a failure
by L</is_failure>.

=head2 scrape_status($page)

Returns the target URL's HTTP status code (C<metadata.statusCode>), or C<0>
if absent.

=head2 scrape_error($page)

Returns a combined error string for a failed scrape (C<metadata.error>
and/or non-2xx C<statusCode>), or C<undef> if nothing looks wrong.

=head2 scrape / scrape_request / parse_scrape_response

POST C</v2/scrape>. Returns the C<data> hash on success.

=head2 crawl / crawl_request / parse_crawl_response

POST C</v2/crawl>. Returns C<< { success, id, url } >>.

=head2 crawl_status / crawl_status_request / parse_crawl_status_response

GET C</v2/crawl/{id}>. Returns the full status object including
C<status>, C<total>, C<completed>, C<data>, and C<next> (pagination URL).

=head2 crawl_status_next($next_url)

Follow the C<next> URL verbatim for subsequent pages of a large crawl result.

=head2 crawl_cancel / crawl_cancel_request

DELETE C</v2/crawl/{id}>.

=head2 crawl_errors / crawl_errors_request

GET C</v2/crawl/{id}/errors>.

=head2 crawl_active / crawl_active_request

GET C</v2/crawl/active>.

=head2 crawl_params_preview / crawl_params_preview_request

POST C</v2/crawl/params/preview>.

=head2 map / map_request / parse_map_response

POST C</v2/map>. Returns the C<links> array.

=head2 search / search_request / parse_search_response

POST C</v2/search>.

=head2 batch_scrape / batch_scrape_request

POST C</v2/batch/scrape>. Returns C<< { id, url, invalidURLs } >>.

=head2 batch_scrape_status / batch_scrape_status_request

GET C</v2/batch/scrape/{id}>.

=head2 batch_scrape_status_next($next_url)

Follow pagination for batch-scrape results.

=head2 batch_scrape_cancel / batch_scrape_cancel_request

DELETE C</v2/batch/scrape/{id}>.

=head2 batch_scrape_errors / batch_scrape_errors_request

GET C</v2/batch/scrape/{id}/errors>.

=head2 extract / extract_request

POST C</v2/extract>.

=head2 extract_status / extract_status_request

GET C</v2/extract/{id}>.

=head2 agent / agent_status / agent_cancel

POST C</v2/agent>, GET/DELETE C</v2/agent/{id}>.

=head2 browser_create / browser_list / browser_delete / browser_execute

POST/GET/DELETE C</v2/browser/...>.

=head2 scrape_execute / scrape_browser_stop

Interactive scrape session endpoints.

=head2 credit_usage / credit_usage_historical / token_usage / token_usage_historical / queue_status / activity

GET monitoring endpoints.

=head2 scrape_many(\@urls, %scrape_opts)

Sequential per-URL scrape with partial-success semantics. Returns a hashref:

  {
    ok     => [ { url => ..., data => $scrape_data }, ... ],
    failed => [ { url => ..., error => $WWW_Firecrawl_Error }, ... ],
    stats  => { ok => N, failed => M, total => N+M },
  }

Transport/API errors and target-level failures (per L</is_failure>) all land
in C<failed[]>. The outer call never throws for per-URL failures.

=head2 retry_failed_pages(\%crawl_or_batch_result, %scrape_opts)

Pulls URLs out of a crawl/batch result's C<failed[]> array and re-scrapes them
via L</scrape_many>. Returns the standard
C<< { ok, failed, stats } >> hashref. The scrape options you pass here are
applied to the retry round — caller is responsible for matching them to the
original crawl's scrape options if needed.

=head1 SEE ALSO

L<Net::Async::Firecrawl>, L<https://firecrawl.dev>, L<https://docs.firecrawl.dev/api-reference/v2-introduction>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-www-firecrawl/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudss.us/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

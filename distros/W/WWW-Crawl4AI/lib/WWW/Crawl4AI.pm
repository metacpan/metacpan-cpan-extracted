package WWW::Crawl4AI;
# ABSTRACT: Perl client and fallback orchestrator for Crawl4AI
use Moo;
use Carp qw( croak );
use Time::HiRes ();
use URI ();
use WWW::Crawl4AI::Client ();
use WWW::Crawl4AI::Result ();
use WWW::Crawl4AI::Attempt ();
use WWW::Crawl4AI::Error ();
use WWW::Crawl4AI::Detect ();
use WWW::Crawl4AI::StrategyChain ();
use WWW::Crawl4AI::DeepCrawlIterator ();

our $VERSION = '0.004';


has strategy_chain => (
  is      => 'lazy',
);


sub _build_strategy_chain {
  my ( $self ) = @_;
  return WWW::Crawl4AI::StrategyChain->new;
}

# Deprecated: kept for backward compat. Returns the applicable strategy list
# the same way the old _build_strategies did.
sub _strategies_for {
  my ( $self ) = @_;
  my $fb = $self->fallback;
  my @all = @{ $self->strategy_chain->strategies };

  if ( ref $fb eq 'ARRAY' ) {
    my %by_name = map { $_->name => $_ } @all;
    return [ grep { $_ && $_->applicable($self) } map { $by_name{$_} } @$fb ];
  }
  if ( !$fb || $fb eq 'none' || $fb eq 'plain' ) {
    return [ grep { $_->name eq 'crawl4ai_plain' } @all ];
  }
  return $self->strategy_chain->applicable($self);
}

has strategies => ( is => 'lazy' );


sub _build_strategies { $_[0]->_strategies_for }

has base_url => (
  is      => 'ro',
  default => sub { $ENV{CRAWL4AI_URL} || $ENV{CRAWL4AI_BASE_URL} || 'http://localhost:11235' },
);


has api_token => (
  is      => 'ro',
  default => sub { $ENV{CRAWL4AI_API_TOKEN} },
);


has cloakbrowser_url => (
  is      => 'ro',
  default => sub { $ENV{CLOAKBROWSER_CDP_URL} },
);


has proxy_url => (
  is      => 'ro',
  default => sub { $ENV{CRAWL4AI_PROXY_URL} },
);


has callback => ( is => 'ro' );


# 'auto' (full applicable chain), 'plain'/'none' (Plain only), or an arrayref
# of backend names to run in that explicit order.
has fallback => ( is => 'ro', default => sub { 'auto' } );


has timeout      => ( is => 'ro', default => sub { 120 } );


has min_markdown => ( is => 'ro' );


has client => ( is => 'lazy' );


sub _build_client {
  my ( $self ) = @_;
  return WWW::Crawl4AI::Client->new(
    base_url  => $self->base_url,
    api_token => $self->api_token,
    timeout   => $self->timeout,
  );
}

sub _normalize_args {
  my ( $self, @args ) = @_;
  return () unless @args;
  # a single hashref: { url => ..., %opts }
  if ( @args == 1 && ref $args[0] eq 'HASH' ) {
    my %a   = %{ $args[0] };
    my $url = delete $a{url};
    return ( $url, %a );
  }
  # a leading positional URL, optionally followed by named options
  if ( @args % 2 == 1 && !ref $args[0] ) {
    my ( $url, %a ) = @args;
    return ( $url, %a );
  }
  # all named: ( url => ..., %opts )
  my %a   = @args;
  my $url = delete $a{url};
  return ( $url, %a );
}

# Build the detect option hash (just min_markdown for now) from a per-call
# %opts plus the instance default. Shared with Net::Async::Crawl4AI.
sub _detect_opts {
  my ( $self, %opts ) = @_;
  my $min = defined $opts{min_markdown} ? $opts{min_markdown} : $self->min_markdown;
  return defined $min ? { min_markdown => $min } : {};
}

# Turn one strategy run — its page, error, and timing — into an Attempt,
# classifying the page via Detect. Shared with Net::Async::Crawl4AI so the sync
# and async chains build identical attempt history.
#
# Classification is performed by overridable methods. To swap in a different
# classifier (e.g. Crawl4AI's own quality score), subclass and override
# classify_signals and classify_why_failed.
sub _attempt_for {
  my ( $self, $strategy, $page, $err, $elapsed, $detect ) = @_;
  $detect ||= {};
  return WWW::Crawl4AI::Attempt->new(
    backend    => $strategy->name,
    cost_class => $strategy->cost_class,
    ok         => 0,
    error      => $err,
    why_failed => 'error',
    elapsed    => $elapsed,
  ) if $err;
  return WWW::Crawl4AI::Attempt->new(
    backend    => $strategy->name,
    cost_class => $strategy->cost_class,
    ok         => 0,
    why_failed => 'empty',
    elapsed    => $elapsed,
  ) unless defined $page;

  my $signals = $self->classify_signals( $page, %$detect );
  my $good    = WWW::Crawl4AI::Detect::is_good( $page, %$detect );
  return WWW::Crawl4AI::Attempt->new(
    backend    => $strategy->name,
    cost_class => $strategy->cost_class,
    ok         => $good,
    page       => $page,
    signals    => $signals,
    why_failed => ( $good ? undef : $self->classify_why_failed( $page, %$detect ) ),
    elapsed    => $elapsed,
  );
}


sub classify_signals {
  my ( $self, $page, %opts ) = @_;
  return WWW::Crawl4AI::Detect::signals( $page, %opts );
}


sub classify_why_failed {
  my ( $self, $page, %opts ) = @_;
  return WWW::Crawl4AI::Detect::why_failed( $page, %opts );
}

sub crawl {
  my ( $self, @args ) = @_;
  my ( $url, %opts ) = $self->_normalize_args(@args);
  croak "crawl needs a url" unless defined $url && length $url;
  my $detect = $self->_detect_opts(%opts);

  my @attempts;
  for my $strategy ( @{ $self->strategies } ) {
    my $t0   = Time::HiRes::time();
    my $page = eval { $strategy->crawl( $self, $url, %opts ) };
    my $err  = $@;
    my $elapsed = sprintf( '%.3f', Time::HiRes::time() - $t0 ) + 0;

    my $attempt = $self->_attempt_for( $strategy, $page, $err, $elapsed, $detect );
    push @attempts, $attempt;
    return WWW::Crawl4AI::Result->from_attempt( $attempt, attempts => \@attempts ) if $attempt->ok;
  }

  return $self->_failed_result( $url, \@attempts );
}


sub markdown { my ( $self, @args ) = @_; return $self->crawl(@args) }

# Drop the fragment so map apps (#5/lat/lon/...) and trailing-anchor links don't
# look like distinct pages during dedup.
sub _canon_url {
  my ( $self, $url ) = @_;
  my $u = eval { URI->new($url) } or return $url;
  $u->fragment(undef);
  return $u->as_string;
}

sub deep_crawl {
  my ( $self, @args ) = @_;
  my ( $start, %opts ) = $self->_normalize_args(@args);
  croak "deep_crawl needs a url" unless defined $start && length $start;

  my $iter = WWW::Crawl4AI::DeepCrawlIterator->new(
    crawler    => $self,
    start_url  => $start,
    max_pages  => ( exists $opts{max_pages}  ? delete $opts{max_pages}  : 25 ),
    max_depth  => ( exists $opts{max_depth}  ? delete $opts{max_depth}  : 2 ),
    same_host  => ( exists $opts{same_host}  ? delete $opts{same_host}  : 1 ),
    url_filter => ( delete $opts{url_filter} ),
    on_page    => ( delete $opts{on_page} ),
  );

  my @results;
  while ( my $page = $iter->next ) {
    push @results, $page->[0];
  }
  return \@results;
}


sub _failed_result {
  my ( $self, $url, $attempts ) = @_;
  my $last = $attempts->[-1];
  return WWW::Crawl4AI::Result->new(
    ok       => 0,
    url      => $url,
    attempts => $attempts,
    error    => WWW::Crawl4AI::Error->new(
      type    => 'content',
      message => 'all crawl strategies failed',
      url     => $url,
    ),
    why_failed => 'no_strategies',
  ) unless $last;

  return WWW::Crawl4AI::Result->new(
    ok         => 0,
    url        => $url,
    final_url  => ( $last->page ? $last->page->{final_url} : undef ),
    status     => ( $last->page ? $last->page->{status_code} : undef ),
    backend    => $last->backend,
    cost_class => $last->cost_class,
    signals    => $last->signals,
    why_failed => $last->why_failed,
    attempts   => $attempts,
    error      => (
      $last->error || WWW::Crawl4AI::Error->new(
        type    => 'content',
        message => 'all crawl strategies failed (last: ' . ( $last->why_failed // 'unknown' ) . ')',
        url     => $url,
        backend => $last->backend,
      )
    ),
  );
}

sub health { $_[0]->client->health }


sub screenshot { my $self = shift; $self->client->screenshot(@_) }
sub pdf        { my $self = shift; $self->client->pdf(@_) }
sub html       { my $self = shift; $self->client->html(@_) }
sub execute_js { my $self = shift; $self->client->execute_js(@_) }
sub llm        { my $self = shift; $self->client->llm(@_) }
sub token      { my $self = shift; $self->client->token(@_) }


sub available_backends { [ map { $_->name } @{ $_[0]->strategies } ] }


sub detect {
  my ( $self ) = @_;
  return {
    crawl4ai         => $self->health,
    crawl4ai_url     => $self->base_url,
    cloakbrowser     => ( $self->cloakbrowser_url ? WWW::Crawl4AI::Detect::probe_cloakbrowser( $self->cloakbrowser_url ) : 0 ),
    cloakbrowser_url => $self->cloakbrowser_url,
    proxy            => ( $self->proxy_url ? 1 : 0 ),
    proxy_url        => $self->proxy_url,
    callback         => ( $self->callback ? 1 : 0 ),
    backends         => $self->available_backends,
  };
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Crawl4AI - Perl client and fallback orchestrator for Crawl4AI

=head1 VERSION

version 0.004

=head1 SYNOPSIS

  use WWW::Crawl4AI;

  my $crawler = WWW::Crawl4AI->new(
    base_url         => 'http://localhost:11235',
    cloakbrowser_url => $ENV{CLOAKBROWSER_CDP_URL},  # optional
    proxy_url        => $ENV{CRAWL4AI_PROXY_URL},    # optional
    fallback         => 'auto',
  );

  my $result = $crawler->markdown('https://example.com');

  say $result->markdown;
  say $result->backend;       # crawl4ai_plain / crawl4ai_stealth / crawl4ai_cloakbrowser
  say $result->final_url;
  say $result->cost_class;    # cheap / browser / stealth / paid
  say $result->attempts_json;

=head1 DESCRIPTION

A Perl interface to a self-hosted L<Crawl4AI|https://github.com/unclecode/crawl4ai>
service that escalates crawling through a B<visible strategy chain> and returns
a normalized, agent-friendly L<WWW::Crawl4AI::Result>.

Crawl4AI does the fetch and Markdown extraction; C<WWW::Crawl4AI> decides
policy. Rather than hiding fallback inside Crawl4AI, every attempt is modelled
on the Perl side as a L<WWW::Crawl4AI::Attempt>, so a caller can see which
backend won, what it cost, and — on failure — exactly why.

=head2 The chain

C<markdown>/C<crawl> walk strategies in cost order and stop at the first result
that L<WWW::Crawl4AI::Detect> rates good:

  crawl4ai_plain        cheap     headless text mode
  crawl4ai_browser      browser   full JS render, wait for networkidle
  crawl4ai_stealth      stealth   enable_stealth + random user agent
  crawl4ai_cloakbrowser stealth   attach to CloakBrowser via cdp_url   (if configured)
  crawl4ai_proxy        paid      stealth via proxy_config             (if configured)
  external_callback     paid      user coderef                         (if configured)

For raw, single-shot REST access without the chain, use
L<WWW::Crawl4AI::Client> directly.

=head2 strategy_chain

A L<WWW::Crawl4AI::StrategyChain> object. Holds the strategy registry.
Override L</_build_strategy_chain> in a subclass to change defaults or
pre-build a specific chain.

=head2 strategies

Arrayref of instantiated, applicable L<WWW::Crawl4AI::Strategy> objects in
execution order. Lazily built via L</_strategies_for>.

=head2 base_url

Crawl4AI server URL. Default C<$ENV{CRAWL4AI_URL}>, then
C<$ENV{CRAWL4AI_BASE_URL}>, then C<http://localhost:11235>.

=head2 api_token

Optional bearer token (C<$ENV{CRAWL4AI_API_TOKEN}>).

=head2 cloakbrowser_url

CloakBrowser CDP endpoint (C<$ENV{CLOAKBROWSER_CDP_URL}>). When set, the
C<crawl4ai_cloakbrowser> strategy joins the chain.

=head2 proxy_url

Proxy URL (C<$ENV{CRAWL4AI_PROXY_URL}>). When set, the C<crawl4ai_proxy>
strategy joins the chain.

=head2 callback

Optional coderef, called as C<< ->($url, %opts) >> as the last resort; should
return a page-shaped hashref or C<undef>. When set, the C<external_callback>
strategy joins the chain.

=head2 fallback

Chain selection: C<'auto'> (default; all applicable strategies),
C<'plain'>/C<'none'> (Plain only), or an arrayref of backend names to run in
that explicit order, e.g. C<['crawl4ai_plain', 'crawl4ai_stealth']>.

=head2 timeout

Per-request timeout in seconds (default 120), passed to the client.

=head2 min_markdown

Override the thin-content threshold (characters) for classification. Can also be
given per call as C<< markdown($url, min_markdown => N) >>.

=head2 client

The underlying L<WWW::Crawl4AI::Client>. Lazily built from C<base_url> /
C<api_token> / C<timeout>; inject your own to share a UA or change transport.

=head2 classify_signals

Returns the signals hashref for a normalized page. Default calls
L<WWW::Crawl4AI::Detect/signals>. Override in a subclass to substitute an
alternative classifier.

=head2 classify_why_failed

Returns the most-specific failure token for a page. Default calls
L<WWW::Crawl4AI::Detect/why_failed>. Override in a subclass to substitute an
alternative classifier.

=head2 crawl

=head2 markdown

  my $result = $crawler->markdown('https://example.com');
  my $result = $crawler->crawl( url => 'https://example.com' );

Run the strategy chain against one URL and return a L<WWW::Crawl4AI::Result>.
Both are the same chain; the result always carries both C<markdown> and C<html>.
Accepts a single positional URL or named arguments with a C<url> key.

The returned C<Result> is never C<undef> — on total failure C<< $r->ok >> is
false, C<< $r->why_failed >> explains the last attempt, and C<< $r->attempts >>
holds the full history.

=head2 deep_crawl

  my $results = $crawler->deep_crawl('https://example.com');
  my $results = $crawler->deep_crawl(
    'https://example.com',
    max_pages  => 50,
    max_depth  => 3,
    same_host  => 1,
    url_filter => sub { $_[0] !~ m{/login} },
    on_page    => sub { my ( $result, $depth ) = @_; ... },
    min_markdown => 200,            # any crawl() option is forwarded
  );

Breadth-first crawl that follows the L<WWW::Crawl4AI::Result/urls> of each good
page. Each page goes through the full strategy chain, so C<deep_crawl> is just
L</crawl> applied across a frontier — the per-page escalation and attempt
history are unchanged.

Returns an arrayref of L<WWW::Crawl4AI::Result> in visit order (the first is the
start URL). URLs are deduplicated with the fragment stripped, so map-style
C<#lat/lon> anchors don't count as separate pages. Options:

=over

=item C<max_pages> (default C<25>) — hard cap on pages crawled.

=item C<max_depth> (default C<2>) — link-following depth; the start URL is depth C<0>.

=item C<same_host> (default true) — only follow links on the start URL's host.

=item C<url_filter> — coderef C<< ($url) -> bool >>; return false to skip a URL.

=item C<on_page> — coderef C<< ($result, $depth) >> called as each page completes (for streaming or progress).

=back

Any remaining options (such as C<min_markdown>) are forwarded to each
L</crawl>. Note that the strategy chain is fixed per crawler instance — a
per-call C<fallback> is B<not> honoured here; set it on the constructor.

=head2 health

True if the Crawl4AI server answers C<GET /health>.

=head2 screenshot

=head2 pdf

=head2 html

=head2 execute_js

=head2 llm

=head2 token

Single-URL action endpoints, delegated straight to the underlying
L<WWW::Crawl4AI::Client> (they do B<not> run the strategy chain). C<screenshot>
and C<pdf> return raw bytes; C<html> the preprocessed HTML; C<execute_js> a
normalized page with C<js_result>; C<llm> an answer string (needs a server-side
LLM provider); C<token> a JWT hash. See L<WWW::Crawl4AI::Client> for arguments.

=head2 available_backends

Arrayref of backend names currently in the chain.

=head2 detect

Hashref describing what the orchestrator can reach: C<crawl4ai>,
C<cloakbrowser>, C<proxy>, C<callback> and the active C<backends>. Used by
C<www-crawl4ai-doctor>.

=head1 SEE ALSO

L<WWW::Crawl4AI::Client>, L<WWW::Crawl4AI::Result>, L<WWW::Crawl4AI::Detect>,
L<Net::Async::Crawl4AI>, L<https://github.com/unclecode/crawl4ai>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-www-crawl4ai/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudss.us/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use WWW::Crawl4AI;

# A mock client that returns a pre-programmed normalized page per backend name,
# so the chain runs with zero I/O.
package Mock::Client {
  sub new   { my ( $c, %a ) = @_; bless { pages => $a{pages} || {}, calls => [] }, $c }
  sub calls { $_[0]->{calls} }
  sub crawl {
    my ( $self, $req, $backend ) = @_;
    push @{ $self->{calls} }, $backend;
    my $p = $self->{pages}{$backend};
    die "mock: no page configured for $backend\n" unless $p;
    return [$p];
  }
  sub health { 1 }
}

my $thin    = { status_code => 200, markdown => 'too short' };
# A real bot wall is structural, not a fat "Access Denied" body: a thin
# Cloudflare interstitial (200) whose markup carries the __cf_chl token and whose
# title is "Just a moment...". (A bare 403 would surface as http_403 instead.)
my $blocked = {
  status_code => 200,
  markdown    => 'Just a moment...',
  raw_html    => '<script>window.__cf_chl_opt={}</script>',
  title       => 'Just a moment...',
};
my $good    = { status_code => 200, markdown => ( 'real useful content ' x 40 ), title => 'OK' };

# Clear env so applicability is deterministic.
local $ENV{CLOAKBROWSER_CDP_URL};
local $ENV{CRAWL4AI_PROXY_URL};
delete $ENV{CLOAKBROWSER_CDP_URL};
delete $ENV{CRAWL4AI_PROXY_URL};

subtest 'escalates plain -> browser -> stealth and stops at first good' => sub {
  my $mock = Mock::Client->new( pages => {
    crawl4ai_plain   => $thin,
    crawl4ai_browser => $blocked,
    crawl4ai_stealth => $good,
  } );
  my $c = WWW::Crawl4AI->new( client => $mock );
  my $r = $c->markdown('https://example.com');

  ok $r->ok, 'overall ok';
  is $r->backend, 'crawl4ai_stealth', 'stealth won';
  is $r->cost_class, 'stealth', 'cost class reported';
  is_deeply $mock->calls, [qw( crawl4ai_plain crawl4ai_browser crawl4ai_stealth )], 'ran in order, stopped at stealth';
  is $r->attempt_count, 3, 'three attempts';
  is $r->attempts->[0]->why_failed, 'thin_content', 'plain failed thin';
  is $r->attempts->[1]->why_failed, 'bot_wall_detected', 'browser failed blocked';
  ok $r->attempts->[2]->ok, 'stealth attempt ok';
};

subtest 'all strategies fail -> ok=0 with history + reason' => sub {
  my $mock = Mock::Client->new( pages => {
    crawl4ai_plain   => $thin,
    crawl4ai_browser => $thin,
    crawl4ai_stealth => $blocked,
  } );
  my $c = WWW::Crawl4AI->new( client => $mock );
  my $r = $c->markdown('https://example.com');

  ok !$r->ok, 'not ok';
  is $r->attempt_count, 3, 'all three tried';
  is $r->why_failed, 'bot_wall_detected', 'last reason surfaced';
  isa_ok $r->error, 'WWW::Crawl4AI::Error';
  ok $r->error->is_content, 'content-type error';
};

subtest 'fallback => plain only runs Plain' => sub {
  my $mock = Mock::Client->new( pages => { crawl4ai_plain => $good } );
  my $c = WWW::Crawl4AI->new( client => $mock, fallback => 'plain' );
  is_deeply $c->available_backends, ['crawl4ai_plain'], 'only plain in chain';
  my $r = $c->markdown('https://example.com');
  ok $r->ok, 'plain-only ok';
  is $r->backend, 'crawl4ai_plain', 'plain backend';
};

subtest 'explicit arrayref fallback honours order + skips inapplicable' => sub {
  my $mock = Mock::Client->new( pages => {
    crawl4ai_stealth => $thin,
    crawl4ai_plain   => $good,
  } );
  # cloakbrowser requested but no url configured -> dropped
  my $c = WWW::Crawl4AI->new(
    client   => $mock,
    fallback => [qw( crawl4ai_stealth crawl4ai_cloakbrowser crawl4ai_plain )],
  );
  is_deeply $c->available_backends, [qw( crawl4ai_stealth crawl4ai_plain )], 'cloakbrowser dropped, order kept';
  my $r = $c->markdown('https://example.com');
  is $r->backend, 'crawl4ai_plain', 'plain won after stealth thin';
};

subtest 'cloakbrowser + proxy join chain when configured' => sub {
  my $mock = Mock::Client->new( pages => {} );
  my $c = WWW::Crawl4AI->new(
    client           => $mock,
    cloakbrowser_url => 'http://localhost:9222',
    proxy_url        => 'http://proxy:3128',
  );
  my %b = map { $_ => 1 } @{ $c->available_backends };
  ok $b{crawl4ai_cloakbrowser}, 'cloakbrowser present';
  ok $b{crawl4ai_proxy},        'proxy present';
};

subtest 'callback strategy as last resort' => sub {
  my $mock = Mock::Client->new( pages => {
    crawl4ai_plain   => $thin,
    crawl4ai_browser => $thin,
    crawl4ai_stealth => $blocked,
  } );
  my $called = 0;
  my $c = WWW::Crawl4AI->new(
    client   => $mock,
    callback => sub { $called++; return { status_code => 200, markdown => ( 'from callback ' x 60 ) } },
  );
  ok scalar( grep { $_ eq 'external_callback' } @{ $c->available_backends } ), 'callback in chain';
  my $r = $c->markdown('https://example.com');
  ok $r->ok, 'callback rescued the crawl';
  is $r->backend, 'external_callback', 'callback won';
  is $called, 1, 'callback invoked once';
};

subtest 'strategy that throws is recorded, chain continues' => sub {
  my $mock = Mock::Client->new( pages => { crawl4ai_stealth => $good } );  # plain/browser will die
  my $c = WWW::Crawl4AI->new( client => $mock );
  my $r = $c->markdown('https://example.com');
  ok $r->ok, 'recovered after throwing strategies';
  is $r->backend, 'crawl4ai_stealth';
  is $r->attempts->[0]->why_failed, 'error', 'throwing attempt marked error';
  ok defined $r->attempts->[0]->error, 'error object captured';
};

subtest 'markdown accepts positional url + per-call options' => sub {
  my $mock = Mock::Client->new(
    pages => { crawl4ai_plain => { status_code => 200, markdown => 'short but enough' } },
  );
  my $c = WWW::Crawl4AI->new( client => $mock, fallback => 'plain' );
  my $r = $c->markdown( 'https://example.com', min_markdown => 5 );   # would be thin at default 500
  ok $r->ok, 'positional url + min_markdown override honoured';
};

# URL-aware mock for deep_crawl: returns a good page per URL with configured links.
package Mock::SiteClient {
  sub new   { my ( $c, %a ) = @_; bless { site => $a{site}, calls => [] }, $c }
  sub calls { $_[0]->{calls} }
  sub crawl {
    my ( $self, $req, $backend ) = @_;
    my $url = $req->to_crawl_payload->{urls}[0];
    push @{ $self->{calls} }, $url;
    my $links = $self->{site}{$url} || [];
    return [ {
      status_code => 200,
      url         => $url,
      final_url   => $url,
      markdown    => ( 'real useful content ' x 40 ),
      links       => {
        internal => [ map { { href => $_ } } grep { m{\Ahttps://t\.test} } @$links ],
        external => [ map { { href => $_ } } grep { !m{\Ahttps://t\.test} } @$links ],
      },
    } ];
  }
  sub health { 1 }
}

subtest 'deep_crawl follows links BFS with depth + dedup + same-host' => sub {
  my $site = {
    'https://t.test/'  => [ 'https://t.test/b', 'https://t.test/c', 'https://ext.test/z' ],
    'https://t.test/b' => [ 'https://t.test/d', 'https://t.test/' ],   # back-link deduped
    'https://t.test/c' => [],
    'https://t.test/d' => [],
  };
  my $c = WWW::Crawl4AI->new( client => Mock::SiteClient->new( site => $site ), fallback => 'plain' );

  my @seen;
  my $results = $c->deep_crawl(
    'https://t.test/',
    max_depth => 2,
    on_page   => sub { push @seen, [ $_[0]->final_url, $_[1] ] },
  );

  is scalar @$results, 4, 'A,B,C,D crawled (ext.test dropped by same_host, back-link deduped)';
  is_deeply [ map { $_->final_url } @$results ],
    [ 'https://t.test/', 'https://t.test/b', 'https://t.test/c', 'https://t.test/d' ],
    'BFS visit order';
  is $seen[0][1], 0, 'start at depth 0';
  is $seen[3][1], 2, 'D reached at depth 2';
  ok !( grep { $_->final_url =~ /ext\.test/ } @$results ), 'off-host link not followed';
};

subtest 'deep_crawl respects max_depth and max_pages' => sub {
  my $site = {
    'https://t.test/'  => [ 'https://t.test/b', 'https://t.test/c' ],
    'https://t.test/b' => [ 'https://t.test/d' ],
    'https://t.test/c' => [],
    'https://t.test/d' => [],
  };
  my $shallow = WWW::Crawl4AI->new( client => Mock::SiteClient->new( site => $site ), fallback => 'plain' )
    ->deep_crawl( 'https://t.test/', max_depth => 1 );
  is scalar @$shallow, 3, 'depth 1: only start + its two children (D not reached)';

  my $capped = WWW::Crawl4AI->new( client => Mock::SiteClient->new( site => $site ), fallback => 'plain' )
    ->deep_crawl( 'https://t.test/', max_depth => 5, max_pages => 2 );
  is scalar @$capped, 2, 'max_pages caps the crawl';
};

subtest 'deep_crawl same_host => 0 follows off-host links' => sub {
  my $site = {
    'https://t.test/'   => [ 'https://ext.test/z' ],
    'https://ext.test/z' => [],
  };
  my $results = WWW::Crawl4AI->new( client => Mock::SiteClient->new( site => $site ), fallback => 'plain' )
    ->deep_crawl( 'https://t.test/', max_depth => 1, same_host => 0 );
  is scalar @$results, 2, 'off-host followed when same_host disabled';
  is $results->[1]->final_url, 'https://ext.test/z', 'external page crawled';
};

subtest 'deep_crawl url_filter skips matching urls' => sub {
  my $site = {
    'https://t.test/'      => [ 'https://t.test/keep', 'https://t.test/login' ],
    'https://t.test/keep'  => [],
    'https://t.test/login' => [],
  };
  my $results = WWW::Crawl4AI->new( client => Mock::SiteClient->new( site => $site ), fallback => 'plain' )
    ->deep_crawl( 'https://t.test/', max_depth => 1, url_filter => sub { $_[0] !~ m{/login} } );
  is_deeply [ sort map { $_->final_url } @$results ],
    [ 'https://t.test/', 'https://t.test/keep' ],
    'login filtered out, keep followed';
};

# A thin/dead child must show up in the results as ok=0, not be silently dropped.
package Mock::ThinChildClient {
  sub new { bless {}, shift }
  sub crawl {
    my ( $self, $req ) = @_;
    my $url  = $req->to_crawl_payload->{urls}[0];
    my $dead = $url =~ m{/dead$};
    return [ {
      status_code => 200,
      url         => $url,
      final_url   => $url,
      markdown    => $dead ? 'x' : ( 'good content ' x 60 ),
      links       => {
        internal => ( $url eq 'https://t.test/' ? [ { href => 'https://t.test/dead' } ] : [] ),
        external => [],
      },
    } ];
  }
  sub health { 1 }
}

subtest 'deep_crawl surfaces a dead child as ok=0 rather than dropping it' => sub {
  my $results = WWW::Crawl4AI->new( client => Mock::ThinChildClient->new, fallback => 'plain' )
    ->deep_crawl( 'https://t.test/', max_depth => 1 );
  is scalar @$results, 2, 'start + dead child both present';
  ok $results->[0]->ok,  'start page ok';
  ok !$results->[1]->ok, 'dead child surfaced as ok=0';
  is $results->[1]->final_url, 'https://t.test/dead', 'and it is the dead link';
};

# Start URL apex redirects to www.; links live on the www. host. same_host must
# take the host from final_url, not the raw start URL, or it drops everything.
package Mock::RedirectClient {
  sub new { bless {}, shift }
  sub crawl {
    my ( $self, $req ) = @_;
    my $url   = $req->to_crawl_payload->{urls}[0];
    my $final = $url eq 'https://t.test/' ? 'https://www.t.test/' : $url;
    my $links = $final eq 'https://www.t.test/' ? ['https://www.t.test/b'] : [];
    return [ {
      status_code => 200,
      url         => $url,
      final_url   => $final,
      markdown    => ( 'good content ' x 60 ),
      links       => { internal => [ map { { href => $_ } } @$links ], external => [] },
    } ];
  }
  sub health { 1 }
}

subtest 'deep_crawl locks onto the redirected host so www. links are followed' => sub {
  my $results = WWW::Crawl4AI->new( client => Mock::RedirectClient->new, fallback => 'plain' )
    ->deep_crawl( 'https://t.test/', max_depth => 1 );
  is scalar @$results, 2, 'start + www. child crawled (host taken from final_url)';
  is $results->[1]->final_url, 'https://www.t.test/b', 'followed the link on the redirected host';
};

subtest 'callback returning Crawl4AI-structured markdown is normalized to a string' => sub {
  my $mock = Mock::Client->new( pages => {
    crawl4ai_plain   => $thin,
    crawl4ai_browser => $thin,
    crawl4ai_stealth => $thin,
  } );
  my $c = WWW::Crawl4AI->new(
    client   => $mock,
    callback => sub {
      return {
        status_code => 200,
        markdown    => { raw_markdown => ( 'rescued content ' x 50 ), fit_markdown => '' },
      };
    },
  );
  my $r = $c->markdown('https://example.com');
  ok $r->ok, 'callback rescued the crawl';
  is $r->backend, 'external_callback', 'callback won';
  like $r->markdown, qr/rescued content/, 'structured markdown flattened to a string';
};

done_testing;

#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use WWW::Crawl4AI::Detect ();

my $good = {
  success     => 1,
  status_code => 200,
  markdown    => ( 'lorem ipsum dolor sit amet ' x 30 ),   # well over 500 chars
  html        => '<html><body>real content</body></html>',
  title       => 'Example Domain',
};

ok WWW::Crawl4AI::Detect::is_good($good), 'rich 200 page is good';
is WWW::Crawl4AI::Detect::why_failed($good), undef, 'good page has no failure reason';

subtest 'thin content' => sub {
  my $p = { status_code => 200, markdown => 'tiny' };
  ok !WWW::Crawl4AI::Detect::is_good($p), 'thin markdown not good';
  is WWW::Crawl4AI::Detect::why_failed($p), 'thin_content', 'reason thin_content';
  ok WWW::Crawl4AI::Detect::signals($p)->{thin_html}, 'thin_html signal';
};

subtest 'min_markdown override' => sub {
  my $p = { status_code => 200, markdown => 'x' x 100 };
  ok !WWW::Crawl4AI::Detect::is_good($p), 'below default 500';
  ok WWW::Crawl4AI::Detect::is_good( $p, min_markdown => 50 ), 'above lowered threshold';
};

subtest 'js required' => sub {
  my $p = { status_code => 200, markdown => 'Please enable JavaScript to continue ' x 20 };
  my $s = WWW::Crawl4AI::Detect::signals($p);
  ok $s->{js_required}, 'js_required signal';
  is WWW::Crawl4AI::Detect::why_failed($p), 'js_required', 'reason js_required';
};

subtest 'bot wall via html fingerprint' => sub {
  my $p = {
    status_code => 200,
    markdown    => ( 'filler text ' x 60 ),
    raw_html    => '<script>window.__cf_chl_opt</script>',
    title       => 'Just a moment...',
  };
  ok WWW::Crawl4AI::Detect::signals($p)->{blocked}, 'blocked via cf-chl + title';
  is WWW::Crawl4AI::Detect::why_failed($p), 'bot_wall_detected', 'reason bot_wall_detected';
};

subtest 'captcha' => sub {
  my $p = { status_code => 200, markdown => 'Please complete the hCaptcha challenge ' x 20 };
  ok WWW::Crawl4AI::Detect::signals($p)->{captcha}, 'captcha signal';
  is WWW::Crawl4AI::Detect::why_failed($p), 'captcha', 'captcha wins over thin/js';
};

subtest 'embedded captcha widget on rich page is not a wall' => sub {
  # A content-rich page (WordPress + reCAPTCHA comment form / Turnstile login)
  # carries the markers only in HTML markup, never in the rendered markdown.
  my $p = {
    success     => 1,
    status_code => 200,
    markdown    => ( 'real article body text ' x 60 ),        # well over 500 chars
    raw_html    => '<div class="g-recaptcha"></div><script src="cf-turnstile"></script>',
    title       => 'Trùm Excel - LeQuocThai.Com',
  };
  ok !WWW::Crawl4AI::Detect::signals($p)->{captcha}, 'html-only marker on rich page: no captcha signal';
  ok WWW::Crawl4AI::Detect::is_good($p), 'rich page with embedded widget is good';
  is WWW::Crawl4AI::Detect::why_failed($p), undef, 'no failure reason';
};

subtest 'html-only captcha marker on a thin page still walls' => sub {
  # JS-rendered captcha gate: markdown is empty, marker lives in the markup.
  my $p = {
    status_code => 200,
    markdown    => 'loading',
    raw_html    => '<div class="cf-turnstile"></div>',
  };
  ok WWW::Crawl4AI::Detect::signals($p)->{captcha}, 'html marker + thin = captcha signal';
  is WWW::Crawl4AI::Detect::why_failed($p), 'captcha', 'reason captcha';
};

subtest 'http soft/hard fail' => sub {
  ok !WWW::Crawl4AI::Detect::is_good( { status_code => 403, markdown => 'x' x 999 } ), '403 not good';
  is WWW::Crawl4AI::Detect::why_failed( { status_code => 403, markdown => 'x' x 999 } ), 'http_403', 'reason http_403';
  is WWW::Crawl4AI::Detect::why_failed( { status_code => 503, markdown => 'x' x 999 } ), 'http_503', 'reason http_503';
};

subtest 'success=false' => sub {
  ok !WWW::Crawl4AI::Detect::is_good( { success => 0, status_code => 200, markdown => 'x' x 999 } ),
    'explicit success=false not good';
};

subtest 'probe + proxy env' => sub {
  is WWW::Crawl4AI::Detect::probe_cloakbrowser(undef), 0, 'undef cdp url → 0';
  local $ENV{CRAWL4AI_PROXY_URL} = 'http://proxy:3128';
  is WWW::Crawl4AI::Detect::detect_proxy_env(), 'http://proxy:3128', 'proxy env read';
};

done_testing;

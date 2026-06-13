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

subtest 'thin JS shell fails as thin_content' => sub {
  # A real JS shell is THIN: its only text is the enable-JavaScript notice. As of
  # 0.005 there is no dedicated js_required signal -- the page is simply thin, and
  # thin_html already disqualifies it. The reason token is thin_content.
  my $p = { status_code => 200, markdown => 'Please enable JavaScript to continue.' };
  my $s = WWW::Crawl4AI::Detect::signals($p);
  ok !exists $s->{js_required}, 'js_required signal is gone';
  ok $s->{thin_html}, 'thin_html signal';
  ok !WWW::Crawl4AI::Detect::is_good($p), 'thin JS shell not good';
  is WWW::Crawl4AI::Detect::why_failed($p), 'thin_content', 'reason thin_content';
};

subtest 'rich page that merely mentions JavaScript is good' => sub {
  # A fully-rendered page (e.g. a CV with a "browsers without JavaScript / enable
  # JavaScript to explore" footer) must not be discarded by a bare word-match.
  # Once we hold 500+ chars of markdown the scrape succeeded.
  my $body = 'real rendered article body about an engineer and their work ' x 12;  # >500
  my $p = {
    success     => 1,
    status_code => 200,
    markdown    => $body . ' Enable JavaScript to explore the full interactive experience. ' . $body,
  };
  ok WWW::Crawl4AI::Detect::is_good($p), 'rich page mentioning JavaScript is good';
  is WWW::Crawl4AI::Detect::why_failed($p), undef, 'no failure reason';
};

subtest 'rich page carrying a passive Cloudflare beacon is good (delphin regression)' => sub {
  # THE 0.005 fix. www.delphin.de returns a full 386 KB page (200, real title)
  # that carries Cloudflare's passive JS-detections beacon
  # (/cdn-cgi/challenge-platform/.../jsd/main.js) -- injected on EVERY CF content
  # page, NOT an interstitial. The old $RE_WALL `__cf_` substring + $RE_TITLE
  # "Just a moment" arms fired on the full body/title and threw the whole scrape
  # away across all four strategies. A real content page that came back 200 with
  # 500+ chars of markdown is the scrape; a token in its markup can never prove
  # otherwise. final_url is the origin (no redirect to a challenge endpoint).
  my $body = 'Messdatenerfassung und Datenlogger fuer industrielle Messtechnik. ' x 30;  # >500
  my $p = {
    success     => 1,
    status_code => 200,
    markdown    => $body,
    raw_html    => $body
      . q{<script>var a=document.createElement('script');a.src='/cdn-cgi/challenge-platform/scripts/jsd/main.js';window.__cf_bm='x';</script>},
    title       => 'Just a moment with Delphin Technology AG',   # legit title even starting with the old trap phrase
    url         => 'https://www.delphin.de/',
    final_url   => 'https://www.delphin.de/',
  };
  my $s = WWW::Crawl4AI::Detect::signals($p);
  is $s->{blocked}, 0, 'passive __cf_ beacon in markup does NOT block';
  ok WWW::Crawl4AI::Detect::is_good($p), 'full content page is good despite CF beacon + trap title';
  is WWW::Crawl4AI::Detect::why_failed($p), undef, 'no failure reason';
};

subtest 'thin captcha gate fails as thin_content' => sub {
  # A real captcha gate is THIN: the challenge replaces the content. As of 0.005
  # the captcha signal is final_url-only, so a body captcha phrase no longer sets
  # it -- the page is simply thin.
  my $p = { status_code => 200, markdown => 'Please complete the hCaptcha challenge to continue.' };
  is WWW::Crawl4AI::Detect::signals($p)->{captcha}, 0, 'no captcha from body phrase';
  ok !WWW::Crawl4AI::Detect::is_good($p), 'thin captcha gate not good';
  is WWW::Crawl4AI::Detect::why_failed($p), 'thin_content', 'reason thin_content';
};

subtest 'rich page with captcha-prompt wording in its body is not a wall' => sub {
  # A content-rich page (a help article, a docs page about CAPTCHAs) may quote
  # "complete the captcha to continue" / "I'm not a robot" in its prose. With the
  # content present, body wording can never prove the scrape was walled.
  my $body = 'a long help article explaining how captchas protect web forms ' x 12;  # >500
  my $p = {
    success     => 1,
    status_code => 200,
    markdown    => $body . " To submit, complete the reCAPTCHA to continue. I'm not a robot. " . $body,
  };
  ok !WWW::Crawl4AI::Detect::signals($p)->{captcha}, 'no captcha on rich page with prompt wording';
  ok WWW::Crawl4AI::Detect::is_good($p), 'rich page is good';
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

subtest 'reCAPTCHA cookie-banner mention on rich page is not a wall' => sub {
  # The aquaponik regression: a content-rich page whose markdown ALSO carries a
  # cookie-banner / privacy-policy mention of reCAPTCHA -- but NO captcha-prompt
  # language. This is an incidental mention, not a gate. Must stay good.
  my $body = 'real article body text about aquaponik systems ' x 30;  # >500 chars

  my $de = {
    success     => 1,
    status_code => 200,
    markdown    => $body . ' Wird von Google reCAPTCHA gesetzt, um Spam zu verhindern. ' . $body,
    title       => 'Aquaponik Ratgeber',
  };
  ok !WWW::Crawl4AI::Detect::signals($de)->{captcha}, 'german cookie-banner mention: no captcha signal';
  ok WWW::Crawl4AI::Detect::is_good($de), 'rich page with german reCAPTCHA mention is good';

  my $en = {
    success     => 1,
    status_code => 200,
    markdown    => $body . ' This site uses Google reCAPTCHA to protect against spam. ' . $body,
    title       => 'Aquaponics Guide',
  };
  ok !WWW::Crawl4AI::Detect::signals($en)->{captcha}, 'english cookie-banner mention: no captcha signal';
  ok WWW::Crawl4AI::Detect::is_good($en), 'rich page with english reCAPTCHA mention is good';
};

subtest 'thin JS-rendered gate fails as thin_content' => sub {
  # JS-rendered captcha gate: markdown is empty, the marker lives only in the
  # markup. As of 0.005 html-token sniffing is gone -- but the gate is THIN, so
  # thin_html still disqualifies it. The page never yields content either way;
  # only the reason label changed from captcha to thin_content.
  my $p = {
    status_code => 200,
    markdown    => 'loading',
    raw_html    => '<div class="cf-turnstile"></div>',
  };
  is WWW::Crawl4AI::Detect::signals($p)->{captcha}, 0, 'no captcha from html marker';
  ok !WWW::Crawl4AI::Detect::is_good($p), 'thin gate not good';
  is WWW::Crawl4AI::Detect::why_failed($p), 'thin_content', 'reason thin_content';
};

subtest 'redirect to Cloudflare challenge URL walls a rich page' => sub {
  # WAF gate: the body looks fine (rich markdown), but the request was
  # redirected to a /cdn-cgi/challenge URL. Final_url is the tell.
  my $p = {
    success     => 1,
    status_code => 200,
    markdown    => ( 'plenty of real-looking content text ' x 30 ),  # >500 chars
    url         => 'https://site.de/',
    final_url   => 'https://site.de/cdn-cgi/challenge-platform/h/g/orchestrate/chl_page/v1',
  };
  ok WWW::Crawl4AI::Detect::signals($p)->{blocked}, 'blocked via challenge final_url';
  ok !WWW::Crawl4AI::Detect::is_good($p), 'challenge redirect not good';
  is WWW::Crawl4AI::Detect::why_failed($p), 'bot_wall_detected', 'reason bot_wall_detected';
};

subtest 'redirect to reCAPTCHA endpoint sets captcha' => sub {
  my $p = {
    success     => 1,
    status_code => 200,
    markdown    => ( 'otherwise rich body content here ' x 30 ),  # >500 chars
    url         => 'https://shop.example/',
    final_url   => 'https://www.google.com/recaptcha/api2/anchor?ar=1&k=abc',
  };
  ok WWW::Crawl4AI::Detect::signals($p)->{captcha}, 'captcha via recaptcha final_url';
  ok !WWW::Crawl4AI::Detect::is_good($p), 'recaptcha redirect not good';
  is WWW::Crawl4AI::Detect::why_failed($p), 'captcha', 'reason captcha';
};

subtest 'redirect to DataDome captcha-delivery walls' => sub {
  my $p = {
    success     => 1,
    status_code => 200,
    markdown    => ( 'rich content body filler ' x 30 ),  # >500 chars
    url         => 'https://retailer.fr/produit',
    final_url   => 'https://geo.captcha-delivery.com/captcha/?initialCid=xyz',
  };
  ok WWW::Crawl4AI::Detect::signals($p)->{blocked}, 'blocked via datadome final_url';
  ok !WWW::Crawl4AI::Detect::is_good($p), 'datadome redirect not good';
  is WWW::Crawl4AI::Detect::why_failed($p), 'bot_wall_detected', 'reason bot_wall_detected';
};

subtest 'cosmetic redirect (http->https upgrade) does not trigger' => sub {
  my $p = {
    success     => 1,
    status_code => 200,
    markdown    => ( 'real article body text ' x 60 ),  # >500 chars
    url         => 'http://site.de',
    final_url   => 'https://site.de/',
  };
  my $s = WWW::Crawl4AI::Detect::signals($p);
  is $s->{blocked}, 0, 'no blocked on https upgrade';
  is $s->{captcha}, 0, 'no captcha on https upgrade';
  ok WWW::Crawl4AI::Detect::is_good($p), 'cosmetic redirect stays good';
};

subtest 'final_url absent entirely is a graceful no-op' => sub {
  my $p = {
    success     => 1,
    status_code => 200,
    markdown    => ( 'real article body text ' x 60 ),  # >500 chars
  };
  my $s = WWW::Crawl4AI::Detect::signals($p);
  is $s->{blocked}, 0, 'no blocked when final_url absent';
  is $s->{captcha}, 0, 'no captcha when final_url absent';
  ok WWW::Crawl4AI::Detect::is_good($p), 'page with no url keys stays good';
};

subtest 'body mentioning "challenge" with a normal final_url stays good' => sub {
  # The regex keys on final_url host/path, not the body. A page that merely
  # talks about a "challenge" in its content must not be flagged.
  my $p = {
    success     => 1,
    status_code => 200,
    markdown    => ( 'we discuss the great challenge of our era at length ' x 20 ),
    url         => 'https://blog.example/the-challenge',
    final_url   => 'https://blog.example/the-challenge',
  };
  my $s = WWW::Crawl4AI::Detect::signals($p);
  is $s->{blocked}, 0, 'no blocked from body word "challenge"';
  is $s->{captcha}, 0, 'no captcha from body word "challenge"';
  ok WWW::Crawl4AI::Detect::is_good($p), 'body-only "challenge" stays good';
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

package WWW::Crawl4AI::Detect;
# ABSTRACT: service detection and content-quality classification for Crawl4AI
use strict;
use warnings;

our $VERSION = '0.001';


# Default: a result needs at least this many markdown characters to count.
our $MIN_MARKDOWN = 500;

# HTTP status codes that mean "the target pushed back", not "transport broke".
my %SOFT_FAIL = map { $_ => 1 } ( 401, 403, 429 );

# A WAF / bot-management gate (Cloudflare, DataDome, PerimeterX, Akamai) often
# does not embed a widget into the requested page -- it REDIRECTS to a dedicated
# challenge URL. reCAPTCHA / hCaptcha redirects land on the provider's own
# verification endpoint. We key purely on the final (post-redirect) URL's
# host+path matching a known challenge endpoint: a real content page's
# final_url never contains /cdn-cgi/challenge etc., so URL equality with the
# requested URL is irrelevant (and checking it would false-positive on cosmetic
# http->https / www<->apex / trailing-slash redirects).
my $RE_CHALLENGE_CAPTCHA = qr{
    (?:www\.)?google\.com/recaptcha   # reCAPTCHA verification endpoint
  | /recaptcha/api                    # reCAPTCHA api2/anchor frame
  | \bhcaptcha\.com\b                 # hCaptcha challenge host
}ix;
my $RE_CHALLENGE_WALL = qr{
    /cdn-cgi/challenge                 # Cloudflare managed challenge
  | __cf_chl                          # Cloudflare challenge query/path token
  | /challenge-platform/             # Cloudflare challenge-platform asset
  | datadome                          # DataDome (host or path)
  | geo\.captcha-delivery\.com        # DataDome captcha delivery host
  | /px/captcha                       # PerimeterX captcha path
  | perimeterx                        # PerimeterX (host or path)
}ix;

#----------------------------------------------------------------------
# Content classification
#----------------------------------------------------------------------

sub signals {
  my ( $page, %opt ) = @_;
  my $min = defined $opt{min_markdown} ? $opt{min_markdown} : $MIN_MARKDOWN;
  $page ||= {};
  my $md    = $page->{markdown} // '';
  my $code  = $page->{status_code} // 0;
  # The post-redirect URL, falling back to the requested URL when the normalized
  # page omits it. Either may be absent (signals() is also called on bare test
  # hashes) -- when so, the challenge-URL checks below simply find no match and
  # no signal is raised. Never warns/dies on missing keys.
  my $final = $page->{final_url} // $page->{url} // '';

  # Content volume is the master signal. A bot-wall / JS-shell / captcha gate
  # REPLACES the page content -- it is, by definition, thin. So a content-rich
  # page (>= $min markdown chars) that came back 200 IS the scrape: nothing in
  # its body text or <title> may discard it. The body/title phrase heuristics
  # ($RE_BLOCK, $RE_JS, $RE_CAPTCHA body arms, $RE_WALL HTML-token, $RE_TITLE)
  # were removed in 0.005: on a thin page they were redundant (thin_html already
  # fails the page), and on a full page they were pure false-positives -- a
  # 386 KB article carrying Cloudflare's passive __cf_ beacon, or a legit
  # "Access Denied" <title>, was wrongly thrown away. The ONLY size-independent
  # block signals kept are the fingerprints a real content page can never carry:
  # an HTTP push-back status, or a redirect whose final_url is a known WAF /
  # captcha challenge endpoint (the page physically left the origin).
  my $thin = length($md) < $min;

  # 'blocked' / 'captcha' fire only when the post-redirect final_url is a known
  # WAF / captcha challenge endpoint. Not HTTP status -- that lives on the
  # http_error axis. A site that soft-blocks us by serving one identical
  # interstitial for every URL (200, no redirect) is caught one level up, by the
  # caller comparing markdown across the fetched pages -- not here, per-page.
  my $blocked = ( $final =~ $RE_CHALLENGE_WALL )    ? 1 : 0;
  my $captcha = ( $final =~ $RE_CHALLENGE_CAPTCHA )  ? 1 : 0;

  return {
    blocked    => $blocked,
    captcha    => $captcha,
    thin_html  => $thin ? 1 : 0,
    http_error => ( $code >= 500 || $SOFT_FAIL{$code} ) ? 1 : 0,
  };
}


sub is_good {
  my ( $page, %opt ) = @_;
  return 0 unless ref $page eq 'HASH';
  return 0 if defined $page->{success} && !$page->{success};
  my $code = $page->{status_code} // 0;
  return 0 if $code && ( $code >= 500 || $SOFT_FAIL{$code} );
  my $sig = signals( $page, %opt );
  return 0 if $sig->{blocked} || $sig->{captcha} || $sig->{thin_html};
  return 1;
}


# Most specific reason first.
sub why_failed {
  my ( $page, %opt ) = @_;
  return 'empty' unless ref $page eq 'HASH';
  my $sig = signals( $page, %opt );
  return 'captcha'           if $sig->{captcha};
  return 'bot_wall_detected' if $sig->{blocked};
  my $code = $page->{status_code} // 0;
  return "http_$code"        if $code && ( $code >= 500 || $SOFT_FAIL{$code} );
  return 'thin_content'      if $sig->{thin_html};
  return undef;
}


#----------------------------------------------------------------------
# Service detection
#----------------------------------------------------------------------

sub _probe_ua {
  my ( $ua, $timeout ) = @_;
  return $ua if $ua;
  require LWP::UserAgent;
  return LWP::UserAgent->new( agent => "WWW-Crawl4AI/$VERSION", timeout => ( $timeout // 5 ) );
}

sub probe_cloakbrowser {
  my ( $cdp_url, %opt ) = @_;
  return 0 unless defined $cdp_url && length $cdp_url;
  ( my $base = $cdp_url ) =~ s{/+$}{};
  $base =~ s{\?.*$}{};    # strip CloakBrowser query params (fingerprint=...)
  my $ua  = _probe_ua( $opt{ua}, $opt{timeout} );
  my $res = $ua->get( $base . '/json/version' );
  return $res->is_success ? 1 : 0;
}


sub detect_proxy_env {
  return $ENV{CRAWL4AI_PROXY_URL} || undef;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Crawl4AI::Detect - service detection and content-quality classification for Crawl4AI

=head1 VERSION

version 0.005

=head1 SYNOPSIS

  use WWW::Crawl4AI::Detect ();

  my $sig = WWW::Crawl4AI::Detect::signals($page);
  # { blocked => 1, captcha => 0, thin_html => 0, http_error => 0 }

  if ( !WWW::Crawl4AI::Detect::is_good($page) ) {
    my $why = WWW::Crawl4AI::Detect::why_failed($page);  # 'bot_wall_detected'
  }

  WWW::Crawl4AI::Detect::probe_cloakbrowser('http://localhost:9222');  # 0/1

=head1 DESCRIPTION

The classifier that decides whether a normalized page (as produced by
L<WWW::Crawl4AI::Client>) is genuinely useful, and the probes that decide which
backends to put into the strategy chain. Pure functions; nothing is exported.

=head2 signals

Given a normalized page, returns a hashref of boolean signals: C<blocked>,
C<captcha>, C<thin_html>, C<http_error>. Accepts C<< min_markdown => N >> to
override the thin-content threshold (C<$WWW::Crawl4AI::Detect::MIN_MARKDOWN>,
default 500).

Master rule: content volume decides. A bot-wall, a JS shell, and a captcha gate
all I<replace> the page content, so they are thin by construction — C<thin_html>
catches them. A content-rich page (>= C<min_markdown> chars) that returned 200
B<is> the scrape, and nothing in its body text or C<< <title> >> may discard it.
As of 0.005 there are no body/title phrase heuristics: they were either redundant
(on a thin page C<thin_html> already fails it) or outright false-positives (a
full article carrying Cloudflare's passive C<__cf_> beacon in its markup, or a
legit "Access denied" C<< <title> >>, was wrongly thrown away). The only
size-independent block signals left are the ones a real content page can never
carry.

C<blocked> — the post-redirect C<final_url> is a known WAF challenge endpoint
(C</cdn-cgi/challenge>, C<__cf_chl>, C</challenge-platform/>, C<datadome>,
C<geo.captcha-delivery.com>, C</px/captcha>, C<perimeterx>): the request left the
origin and landed on the gate. Not HTTP status — that lives on the C<http_error>
axis, so a bare 403 reads C<http_403>.

C<captcha> — the post-redirect C<final_url> is a captcha provider's own
verification endpoint (C<google.com/recaptcha>, C</recaptcha/api>,
C<hcaptcha.com>).

A site that soft-blocks by serving one identical interstitial for every URL
(200, no redirect, no challenge final_url) is invisible to per-page C<signals>
by design — it is caught one level up, by the caller comparing markdown across
the fetched pages.

=head2 is_good

True when the page passed all checks: success not explicitly false, no soft/hard
HTTP failure, and no negative signal.

=head2 why_failed

Returns the most specific failure reason as a short token
(C<captcha>, C<bot_wall_detected>, C<http_NNN>, C<thin_content>) or C<undef>
when the page is good.

=head2 probe_cloakbrowser

True if a CloakBrowser CDP endpoint answers C<GET /json/version>. Query params
on the URL (e.g. C<?fingerprint=...>) are stripped before probing. Pass
C<< ua => $lwp >> and/or C<< timeout => $secs >> to control the probe.

=head2 detect_proxy_env

Returns C<$ENV{CRAWL4AI_PROXY_URL}> or C<undef>.

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

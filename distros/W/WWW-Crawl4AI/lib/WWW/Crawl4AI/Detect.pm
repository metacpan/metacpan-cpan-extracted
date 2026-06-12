package WWW::Crawl4AI::Detect;
# ABSTRACT: service detection and content-quality classification for Crawl4AI
use strict;
use warnings;

our $VERSION = '0.001';


# Default: a result needs at least this many markdown characters to count.
our $MIN_MARKDOWN = 500;

# HTTP status codes that mean "the target pushed back", not "transport broke".
my %SOFT_FAIL = map { $_ => 1 } ( 401, 403, 429 );

my $RE_JS      = qr/enable\s+javascript|please\s+enable\s+js|requires?\s+javascript/i;
my $RE_BLOCK   = qr/access\s+denied|checking\s+your\s+browser|are\s+you\s+(?:a\s+)?human|verify\s+you\s+are\s+human|unusual\s+traffic/i;
my $RE_CAPTCHA = qr/(?:\b(?:re)?captcha\b|hcaptcha|g-recaptcha|cf-turnstile)/i;
my $RE_WALL    = qr/cf-chl|cf_chl|__cf_|datadome|perimeterx|px-captcha|akamai|incapsula|imperva/i;
my $RE_TITLE   = qr/^\s*just\s+a\s+moment|^\s*attention\s+required|^\s*access\s+denied/i;

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
  my $html  = ( $page->{raw_html} // $page->{html} // '' );
  my $title = $page->{title} // '';
  my $code  = $page->{status_code} // 0;
  # The post-redirect URL, falling back to the requested URL when the normalized
  # page omits it. Either may be absent (signals() is also called on bare test
  # hashes) -- when so, the challenge-URL checks below simply find no match and
  # no signal is raised. Never warns/dies on missing keys.
  my $final = $page->{final_url} // $page->{url} // '';

  # Content volume is the master signal. A bot-wall / JS-shell / captcha gate
  # REPLACES the page content -- it is, by definition, thin. So every signal
  # derived from VISIBLE rendered text (the markdown) is only trustworthy on a
  # thin page: on a content-rich page those same words are incidental mentions
  # (a footer "enable JavaScript", an article quoting "unusual traffic", a
  # privacy note about reCAPTCHA) and must NOT discard a successful scrape --
  # body words can never prove a scrape was impossible once we hold the content.
  # STRUCTURAL fingerprints are exempt: WAF tokens in the HTML markup
  # (__cf_chl, datadome), a "Just a moment" <title>, or a redirect whose
  # final_url is a known challenge endpoint -- a real content page never carries
  # those, regardless of size.
  my $thin = length($md) < $min;

  # 'blocked' is a bot-wall fingerprint, not HTTP status (status lives on the
  # http_error axis, so a bare 403 reads http_403 while a Cloudflare body reads
  # bot_wall_detected). The visible-text match ($RE_BLOCK) only counts on a thin
  # page; the structural arms (WAF tokens in HTML, "Just a moment" title,
  # redirect to a challenge URL) stand alone.
  my $blocked =
       ( $thin  && $md  =~ $RE_BLOCK )
    || ( $html  =~ $RE_WALL )
    || ( $title =~ $RE_TITLE )
    || ( $final =~ $RE_CHALLENGE_WALL );

  # 'captcha' is a captcha *wall*, not an incidental widget or mention:
  #   * thin page + any marker (markdown OR html) -> wall. A near-empty page that
  #     carries a captcha marker is a JS-rendered gate (real content never loaded).
  #   * redirect to a CAPTCHA provider's own verification endpoint
  #     (google.com/recaptcha, hcaptcha.com) -> wall. The final_url left the
  #     origin and landed on the captcha provider; size-independent.
  #   * rich page + marker (markdown OR html-only) -> NOT a wall. A cookie-banner
  #     reCAPTCHA note, an embedded comment-form widget, a Turnstile login box --
  #     the real content is present, so the marker is incidental.
  my $captcha =
       ( $thin && ( $md =~ $RE_CAPTCHA || $html =~ $RE_CAPTCHA ) )
    || ( $final =~ $RE_CHALLENGE_CAPTCHA );

  return {
    # A thin JS shell whose only text is "enable JavaScript" -- the real content
    # never rendered. A rich page that merely mentions JavaScript is already
    # rendered, so the match is incidental.
    js_required => ( $thin && $md =~ $RE_JS ) ? 1 : 0,
    blocked     => $blocked ? 1 : 0,
    captcha     => $captcha ? 1 : 0,
    thin_html   => $thin ? 1 : 0,
    http_error  => ( $code >= 500 || $SOFT_FAIL{$code} ) ? 1 : 0,
  };
}


sub is_good {
  my ( $page, %opt ) = @_;
  return 0 unless ref $page eq 'HASH';
  return 0 if defined $page->{success} && !$page->{success};
  my $code = $page->{status_code} // 0;
  return 0 if $code && ( $code >= 500 || $SOFT_FAIL{$code} );
  my $sig = signals( $page, %opt );
  return 0 if $sig->{js_required} || $sig->{blocked} || $sig->{captcha} || $sig->{thin_html};
  return 1;
}


# Most specific reason first.
sub why_failed {
  my ( $page, %opt ) = @_;
  return 'empty' unless ref $page eq 'HASH';
  my $sig = signals( $page, %opt );
  return 'captcha'           if $sig->{captcha};
  return 'bot_wall_detected' if $sig->{blocked};
  return 'js_required'       if $sig->{js_required};
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

version 0.004

=head1 SYNOPSIS

  use WWW::Crawl4AI::Detect ();

  my $sig = WWW::Crawl4AI::Detect::signals($page);
  # { js_required => 0, blocked => 1, captcha => 0, thin_html => 0, http_error => 0 }

  if ( !WWW::Crawl4AI::Detect::is_good($page) ) {
    my $why = WWW::Crawl4AI::Detect::why_failed($page);  # 'bot_wall_detected'
  }

  WWW::Crawl4AI::Detect::probe_cloakbrowser('http://localhost:9222');  # 0/1

=head1 DESCRIPTION

The classifier that decides whether a normalized page (as produced by
L<WWW::Crawl4AI::Client>) is genuinely useful, and the probes that decide which
backends to put into the strategy chain. Pure functions; nothing is exported.

=head2 signals

Given a normalized page, returns a hashref of boolean signals: C<js_required>,
C<blocked>, C<captcha>, C<thin_html>, C<http_error>. Accepts
C<< min_markdown => N >> to override the thin-content threshold
(C<$WWW::Crawl4AI::Detect::MIN_MARKDOWN>, default 500).

Master rule: content volume decides. A bot-wall, a JS shell, and a captcha gate
all I<replace> the page content, so they are thin by construction. Every signal
derived from the B<visible rendered text> (the markdown) therefore only fires on
a B<thin> page — on a content-rich page the same words ("enable JavaScript" in a
footer, "unusual traffic" quoted in an article, a privacy note mentioning
reCAPTCHA) are incidental and never discard a successful scrape. B<Structural>
fingerprints are exempt and fire regardless of size, because a real content page
never carries them: WAF tokens in the HTML markup (C<__cf_chl>, C<datadome>), a
"Just a moment" / "Access denied" C<< <title> >>, and a redirect whose
C<final_url> (the post-redirect URL, falling back to C<url>) is a known WAF or
captcha challenge endpoint.

C<js_required> — thin page whose markdown asks to enable JavaScript: a JS shell
that never rendered.

C<blocked> — a bot-wall body phrase on a thin page (C<$RE_BLOCK>), OR a WAF token
in the HTML, OR a C<< <title> >> WAF banner, OR a redirect to a WAF challenge URL
(C</cdn-cgi/challenge>, C<__cf_chl>, C</challenge-platform/>, C<datadome>,
C<geo.captcha-delivery.com>, C</px/captcha>, C<perimeterx>). Not HTTP status —
that lives on the C<http_error> axis, so a bare 403 reads C<http_403> while a
Cloudflare body reads C<bot_wall_detected>.

C<captcha> — a captcha marker (markdown I<or> HTML markup) on a thin page, OR a
redirect to a captcha provider's own verification endpoint
(C<google.com/recaptcha>, C</recaptcha/api>, C<hcaptcha.com>). A captcha marker
on a content-rich page (cookie-banner note, embedded comment-form reCAPTCHA,
Turnstile login box) is B<not> a wall — the real content is present.

=head2 is_good

True when the page passed all checks: success not explicitly false, no soft/hard
HTTP failure, and no negative signal.

=head2 why_failed

Returns the most specific failure reason as a short token
(C<captcha>, C<bot_wall_detected>, C<js_required>, C<http_NNN>,
C<thin_content>) or C<undef> when the page is good.

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

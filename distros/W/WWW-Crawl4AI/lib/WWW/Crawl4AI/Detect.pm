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
# Prompt language that signals a captcha *wall* (a gate the visitor must clear)
# rather than an incidental mention (a cookie-banner / privacy-policy note about
# reCAPTCHA). A wall tells the visitor to act on the captcha, or that the page is
# being held until they prove they are human.
my $RE_CAPTCHA_PROMPT = qr/
    (?:complete|solve|finish|pass|verify)\b[^.]{0,40}$RE_CAPTCHA   # "complete the captcha"
  | $RE_CAPTCHA[^.]{0,40}(?:to\s+continue|to\s+proceed|to\s+access)  # "captcha to continue"
  | i['\x{2019}]?m\s+not\s+a\s+robot                              # "I'm not a robot"
  | (?:verify|prove|confirm)\s+(?:that\s+)?you\s+are\s+(?:a\s+)?human  # "verify you are human"
  | checking\s+your\s+browser
  | security\s+check
/ix;
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

  # 'blocked' is about content fingerprints (bot walls in the body), not HTTP
  # status — status lives on its own axis (http_error) so why_failed can report
  # a bare 403 as http_403 while a Cloudflare body still reads bot_wall_detected.
  # ADDITIONALLY: a WAF/bot-management gate often redirects to a challenge URL
  # (e.g. /cdn-cgi/challenge, geo.captcha-delivery.com). When the final_url
  # matches a known challenge endpoint we OR that in -- we never clear a signal
  # already raised by a body fingerprint.
  my $blocked =
       ( $md   =~ $RE_BLOCK )
    || ( $html =~ $RE_WALL )
    || ( $title =~ $RE_TITLE )
    || ( $final =~ $RE_CHALLENGE_WALL );

  # A captcha marker alone does not wall a page -- context decides. Three rules:
  #   * thin page + any marker (markdown OR html) -> wall. A near-empty page that
  #     mentions a captcha is a JS-rendered gate (the real content never loaded).
  #   * rich page + markdown marker + wall-PROMPT language -> wall. A verbose
  #     captcha page ("complete the hCaptcha to continue", "I'm not a robot")
  #     carries prompt language in its rendered text.
  #   * rich page + markdown marker but NO prompt language -> NOT a wall. This is
  #     an incidental mention -- a cookie banner / privacy policy noting that the
  #     site uses reCAPTCHA. The real content is present; do not punish it.
  #   * rich page + html-only marker -> NOT a wall. An embedded widget (comment-
  #     form reCAPTCHA, Turnstile login box) leaves markers only in the markup
  #     (class names, script src), never in the visible content.
  #   * redirect to a CAPTCHA provider's own verification endpoint
  #     (google.com/recaptcha, hcaptcha.com) -> wall. The final_url left the
  #     origin entirely and landed on the captcha provider. OR-ed in; an
  #     already-true captcha signal is never cleared.
  my $thin    = length($md) < $min;
  my $captcha =
       ( $thin && ( $md =~ $RE_CAPTCHA || $html =~ $RE_CAPTCHA ) )
    || ( $md =~ $RE_CAPTCHA && $md =~ $RE_CAPTCHA_PROMPT )
    || ( $final =~ $RE_CHALLENGE_CAPTCHA );

  return {
    js_required => ( $md =~ $RE_JS ) ? 1 : 0,
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

version 0.003

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

C<blocked> reflects content fingerprints (Cloudflare / DataDome / "Just a
moment" bodies) — not HTTP status, which lives on its own C<http_error> axis.
It is B<also> raised when the page's C<final_url> (the post-redirect URL, with
fallback to C<url>) matches a known WAF / bot-management challenge endpoint
(C</cdn-cgi/challenge>, C<__cf_chl>, C</challenge-platform/>, C<datadome>,
C<geo.captcha-delivery.com>, C</px/captcha>, C<perimeterx>) — many gates
redirect to a challenge URL rather than embedding a widget. This is OR-ed in;
a signal already raised by a body fingerprint is never cleared.

C<captcha> means the page is captcha-I<walled>, not merely that a captcha
widget or the word "reCAPTCHA" appears somewhere. Context decides:

=over 4

=item *

A B<thin> page with a captcha marker anywhere (rendered markdown I<or>
HTML/script markup) is walled — a near-empty page that mentions a captcha is a
JS-rendered gate.

=item *

A B<content-rich> page is walled only when a markdown marker co-occurs with
captcha-I<prompt> language ("complete the captcha to continue", "I'm not a
robot", "verify you are human", "checking your browser", "security check") —
the wording a real captcha gate uses to address the visitor.

=item *

A content-rich page whose markdown mentions a captcha B<without> prompt
language (a cookie-banner / privacy-policy note that the site uses reCAPTCHA),
or that carries the marker only in the HTML/script markup (an embedded
comment-form reCAPTCHA, a Turnstile login box), is B<not> walled — the real
content is present.

=item *

A page whose C<final_url> redirected to a CAPTCHA provider's own verification
endpoint (C<google.com/recaptcha>, C</recaptcha/api>, C<hcaptcha.com>) is
walled regardless of body content — the request left the origin and landed on
the captcha provider.

=back

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

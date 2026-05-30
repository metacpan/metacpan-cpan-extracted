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
my $RE_CAPTCHA = qr/\b(?:re)?captcha\b|hcaptcha|g-recaptcha|cf-turnstile/i;
my $RE_WALL    = qr/cf-chl|cf_chl|__cf_|datadome|perimeterx|px-captcha|akamai|incapsula|imperva/i;
my $RE_TITLE   = qr/^\s*just\s+a\s+moment|^\s*attention\s+required|^\s*access\s+denied/i;

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

  # 'blocked' is about content fingerprints (bot walls in the body), not HTTP
  # status — status lives on its own axis (http_error) so why_failed can report
  # a bare 403 as http_403 while a Cloudflare body still reads bot_wall_detected.
  my $blocked =
       ( $md   =~ $RE_BLOCK )
    || ( $html =~ $RE_WALL )
    || ( $title =~ $RE_TITLE );

  # A captcha marker only walls the page when its prompt shows up in the
  # *rendered* text (markdown). An embedded widget -- a comment-form reCAPTCHA,
  # a Cloudflare Turnstile login box -- leaves markers only in the HTML/script
  # markup (class names, script src), not the visible content, so an HTML-only
  # match on an otherwise content-rich page is NOT a wall. Treat an HTML-only
  # match as blocking only when the page is also thin (a JS-rendered gate).
  my $thin    = length($md) < $min;
  my $captcha = ( $md =~ $RE_CAPTCHA ) || ( $html =~ $RE_CAPTCHA && $thin );

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

version 0.001

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

C<captcha> means the page is captcha-I<walled>, not merely that a captcha
widget exists somewhere: a marker in the rendered markdown counts, but a
marker found only in the HTML/script markup (an embedded comment-form
reCAPTCHA, a Turnstile login box) counts only when the page is also thin —
otherwise a content-rich page with an embedded widget is treated as good.

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

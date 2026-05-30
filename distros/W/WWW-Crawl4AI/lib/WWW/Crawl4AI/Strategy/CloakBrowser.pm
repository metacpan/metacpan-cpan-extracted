package WWW::Crawl4AI::Strategy::CloakBrowser;
# ABSTRACT: Crawl4AI strategy attaching to CloakBrowser over CDP
use Moo;
use URI ();
use WWW::Crawl4AI::Request ();
with 'WWW::Crawl4AI::Strategy';

our $VERSION = '0.001';


sub name       { 'crawl4ai_cloakbrowser' }


sub cost_class { 'stealth' }


sub applicable {
  my ( $self, $crawler ) = @_;
  return $crawler->cloakbrowser_url ? 1 : 0;
}


sub build_request {
  my ( $self, $crawler, $url ) = @_;
  return $self->_request(
    $url,
    browser => {
      browser_mode            => 'custom',
      cdp_url                 => $self->_cdp_url( $crawler, $url ),
      cache_cdp_connection    => WWW::Crawl4AI::Request::JSON_true(),
      create_isolated_context => WWW::Crawl4AI::Request::JSON_true(),
    },
    crawler => { wait_until => 'networkidle' },
  );
}

# Per-domain stable fingerprint: if the configured CDP URL has no query string,
# append ?fingerprint=<seed> so each domain gets a consistent CloakBrowser
# identity. CloakBrowser requires the seed to be a NON-NEGATIVE INTEGER — a
# non-numeric value (e.g. a raw host string) is rejected with HTTP 400. So the
# host is folded into a deterministic 32-bit hash: same domain → same seed,
# different domains → different seeds. A URL that already carries query params
# is used verbatim.
sub _cdp_url {
  my ( $self, $crawler, $url ) = @_;
  my $cdp = $crawler->cloakbrowser_url;
  return $cdp if $cdp =~ /\?/;
  my $host = eval { URI->new($url)->host } || 'default';
  ( my $base = $cdp ) =~ s{/+$}{};
  return "$base?fingerprint=" . $self->_fingerprint_seed($host);
}

# Deterministic 32-bit FNV-1a hash of the host. Zero-dependency, stable across
# runs and processes, yields a non-negative integer CloakBrowser accepts.
sub _fingerprint_seed {
  my ( $self, $host ) = @_;
  my $hash = 2166136261;                       # FNV-1a 32-bit offset basis
  for my $byte ( unpack 'C*', $host ) {
    $hash ^= $byte;
    $hash = ( $hash * 16777619 ) & 0xFFFFFFFF;  # FNV prime, wrap to 32 bits
  }
  return $hash;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Crawl4AI::Strategy::CloakBrowser - Crawl4AI strategy attaching to CloakBrowser over CDP

=head1 VERSION

version 0.001

=head1 DESCRIPTION

Tells Crawl4AI to drive an external CloakBrowser via C<browser_mode: custom> and
a C<cdp_url>, rather than its own bundled browser. Only enters the chain when
the crawler has a C<cloakbrowser_url>.

If that URL has no query string, a per-domain C<?fingerprint=E<lt>seedE<gt>> is
appended so each target gets a stable CloakBrowser identity. CloakBrowser
requires the seed to be a non-negative integer, so the host is folded into a
deterministic 32-bit hash (same domain always maps to the same seed).
CloakBrowser also accepts C<timezone>, C<locale>, C<platform>, C<proxy>,
C<geoip> there.

B<Security:> the CDP port grants full browser control — never expose it to the
public internet.

=head2 name

C<crawl4ai_cloakbrowser>.

=head2 cost_class

C<stealth>.

=head2 applicable

True only when C<< $crawler->cloakbrowser_url >> is set.

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

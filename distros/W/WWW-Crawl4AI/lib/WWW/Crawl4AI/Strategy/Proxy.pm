package WWW::Crawl4AI::Strategy::Proxy;
# ABSTRACT: Crawl4AI strategy routing through a configured proxy
use Moo;
use WWW::Crawl4AI::Request ();
with 'WWW::Crawl4AI::Strategy';

our $VERSION = '0.001';


sub name       { 'crawl4ai_proxy' }


sub cost_class { 'paid' }


sub applicable {
  my ( $self, $crawler ) = @_;
  return $crawler->proxy_url ? 1 : 0;
}


sub build_request {
  my ( $self, $crawler, $url ) = @_;
  return $self->_request(
    $url,
    browser => {
      enable_stealth  => WWW::Crawl4AI::Request::JSON_true(),
      user_agent_mode => 'random',
      proxy_config    => { server => $crawler->proxy_url },
    },
    crawler => { wait_until => 'networkidle' },
  );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Crawl4AI::Strategy::Proxy - Crawl4AI strategy routing through a configured proxy

=head1 VERSION

version 0.001

=head1 DESCRIPTION

The escalation tier: a stealth crawl routed through Crawl4AI's C<proxy_config>.
Only enters the chain when the crawler has a C<proxy_url> (proxies usually cost
money or bandwidth, hence C<cost_class> C<paid>).

=head2 name

C<crawl4ai_proxy>.

=head2 cost_class

C<paid>.

=head2 applicable

True only when C<< $crawler->proxy_url >> is set.

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

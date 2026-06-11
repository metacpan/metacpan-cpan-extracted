package WWW::Crawl4AI::Strategy::Stealth;
# ABSTRACT: Crawl4AI strategy with enable_stealth and randomized fingerprint
use Moo;
use WWW::Crawl4AI::Request ();
with 'WWW::Crawl4AI::Strategy';

our $VERSION = '0.001';


sub name       { 'crawl4ai_stealth' }


sub cost_class { 'stealth' }


sub build_request {
  my ( $self, $crawler, $url ) = @_;
  return $self->_request(
    $url,
    browser => {
      enable_stealth  => WWW::Crawl4AI::Request::JSON_true(),
      user_agent_mode => 'random',
    },
    crawler => { wait_until => 'networkidle' },
  );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Crawl4AI::Strategy::Stealth - Crawl4AI strategy with enable_stealth and randomized fingerprint

=head1 VERSION

version 0.003

=head1 DESCRIPTION

Turns on Crawl4AI's C<enable_stealth> (Playwright-stealth-style fingerprint
adjustment) and a randomized user agent. Aimed at sites with light bot
protection that reject a vanilla headless browser.

=head2 name

C<crawl4ai_stealth>.

=head2 cost_class

C<stealth>.

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

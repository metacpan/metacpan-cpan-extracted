package WWW::Crawl4AI::Strategy::Browser;
# ABSTRACT: Crawl4AI strategy with full JS rendering (wait for networkidle)
use Moo;
use WWW::Crawl4AI::Request ();
with 'WWW::Crawl4AI::Strategy';

our $VERSION = '0.001';


sub name       { 'crawl4ai_browser' }


sub cost_class { 'browser' }


sub build_request {
  my ( $self, $crawler, $url ) = @_;
  return $self->_request(
    $url,
    browser => { headless => WWW::Crawl4AI::Request::JSON_true() },
    crawler => { wait_until => 'networkidle' },
  );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Crawl4AI::Strategy::Browser - Crawl4AI strategy with full JS rendering (wait for networkidle)

=head1 VERSION

version 0.001

=head1 DESCRIPTION

Full browser rendering: drops C<text_mode> and waits for C<networkidle>, so
script-heavy pages that come back thin or empty from
L<WWW::Crawl4AI::Strategy::Plain> get a real render.

=head2 name

C<crawl4ai_browser>.

=head2 cost_class

C<browser>.

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

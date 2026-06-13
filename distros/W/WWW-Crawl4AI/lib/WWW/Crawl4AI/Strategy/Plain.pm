package WWW::Crawl4AI::Strategy::Plain;
# ABSTRACT: cheapest Crawl4AI strategy — headless text mode, no escalation
use Moo;
use WWW::Crawl4AI::Request ();
with 'WWW::Crawl4AI::Strategy';

our $VERSION = '0.001';


sub name       { 'crawl4ai_plain' }


sub cost_class { 'cheap' }


sub build_request {
  my ( $self, $crawler, $url ) = @_;
  return $self->_request(
    $url,
    browser => { text_mode => WWW::Crawl4AI::Request::JSON_true() },
  );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Crawl4AI::Strategy::Plain - cheapest Crawl4AI strategy — headless text mode, no escalation

=head1 VERSION

version 0.005

=head1 DESCRIPTION

The first link in the chain: a plain Crawl4AI call with C<text_mode> on and no
special browser. Cheapest and fastest; good enough for most static pages.

=head2 name

C<crawl4ai_plain>.

=head2 cost_class

C<cheap>.

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

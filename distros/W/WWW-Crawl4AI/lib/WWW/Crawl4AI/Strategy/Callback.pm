package WWW::Crawl4AI::Strategy::Callback;
# ABSTRACT: last-resort Crawl4AI strategy delegating to a user coderef
use Moo;
with 'WWW::Crawl4AI::Strategy';
use WWW::Crawl4AI::Markdown qw( resolve_markdown_chain );

our $VERSION = '0.001';


sub name       { 'external_callback' }


sub cost_class { 'paid' }


sub applicable {
  my ( $self, $crawler ) = @_;
  return $crawler->callback ? 1 : 0;
}


# Does not go through Crawl4AI at all — hand the URL to the user's coderef and
# normalize whatever page-shaped hashref it returns. We accept markdown either
# as a plain string or as Crawl4AI's structured object, so Detect and Result
# see the same shape they get from every (Crawl4AI-backed) strategy.
sub crawl {
  my ( $self, $crawler, $url, %opts ) = @_;
  my $page = $crawler->callback->( $url, %opts );
  return undef unless ref $page eq 'HASH';
  $page->{markdown}  = resolve_markdown_chain( $page->{markdown} ) if ref $page->{markdown} eq 'HASH';
  $page->{url}       //= $url;
  $page->{final_url} //= $page->{url};
  return $page;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Crawl4AI::Strategy::Callback - last-resort Crawl4AI strategy delegating to a user coderef

=head1 VERSION

version 0.005

=head1 DESCRIPTION

The final link, only present when the crawler was given a C<callback> coderef.
When every Crawl4AI-backed strategy has failed, the URL is handed to that
coderef as C<< ->($url, %opts) >>; it should return a page-shaped hashref
(C<markdown>, C<html>, C<status_code>, C<title>, ...) or C<undef>. This is the
hook for paid scraping APIs or any external escalation you control.

C<markdown> may be a plain string or the structured object Crawl4AI itself
returns (C<< { raw_markdown => ..., fit_markdown => ... } >>); either is
accepted. C<links>, if present, is expected in the
C<< { internal => [...], external => [...] } >> shape.

=head2 name

C<external_callback>.

=head2 cost_class

C<paid>.

=head2 applicable

True only when C<< $crawler->callback >> is set.

=head2 crawl

Calls the user coderef and normalizes its return value into a page.

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

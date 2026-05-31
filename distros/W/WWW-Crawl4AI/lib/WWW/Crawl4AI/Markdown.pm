package WWW::Crawl4AI::Markdown;
# ABSTRACT: markdown field resolution across Crawl4AI response shapes
use strict;
use warnings;

our $VERSION = '0.001';


use Exporter qw( import );
our @EXPORT_OK = qw( resolve_markdown_chain );


sub resolve_markdown_chain {
  my ( $md ) = @_;
  return $md unless ref $md eq 'HASH';
  for my $key (qw( fit_markdown raw_markdown markdown_with_citations markdown )) {
    my $value = $md->{$key};
    return $value if defined $value && length $value;
  }
  return undef;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Crawl4AI::Markdown - markdown field resolution across Crawl4AI response shapes

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  use WWW::Crawl4AI::Markdown qw( resolve_markdown_chain );

  my $md = { fit_markdown => '', raw_markdown => 'content', ... };
  my $text = resolve_markdown_chain($md);  # returns 'content'

=head1 DESCRIPTION

Resolves the markdown field from Crawl4AI's structured response object.
Crawl4AI returns markdown as a hash C<< { fit_markdown, raw_markdown,
markdown_with_citations, markdown } >> — the chain prefers filtered (fit)
but skips empty candidates.

Shared by L<WWW::Crawl4AI::Client/_extract_markdown> and
L<WWW::Crawl4AI::Strategy::Callback/_flatten_markdown>.

=head2 resolve_markdown_chain

  my $text = resolve_markdown_chain($md);

Given a markdown hashref (or plain string), returns the first non-empty value
from this candidate chain: C<fit_markdown>, C<raw_markdown>,
C<markdown_with_citations>, C<markdown>. Returns C<undef> if none are defined
or non-empty, or the original string if a plain scalar was passed.

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

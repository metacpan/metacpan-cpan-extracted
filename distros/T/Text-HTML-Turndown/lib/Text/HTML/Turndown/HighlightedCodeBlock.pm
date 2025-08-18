package Text::HTML::Turndown::HighlightedCodeBlock 0.07;
use 5.020;
use experimental 'signatures';
use List::MoreUtils 'all';

our $highlightRegExp = qr/highlight-(?:text|source)-([a-z0-9]+)/;
our %RULES = (

    highlightedCodeBlock => {
        filter => sub ($rule, $node, $options) {
          my $firstChild = $node->firstChild;
          return (
            uc $node->nodeName eq 'DIV' &&
            $node->className =~ /$highlightRegExp/ &&
            $firstChild &&
            uc $firstChild->nodeName eq 'PRE'
          )
        },
        replacement => sub( $content, $node, $options, $context ) {
          my $className = $node->className || '';
          my $language = '';
          if( $className =~ /$highlightRegExp/) {
              $language = $1;
          };

          return (
            "\n\n" . $options->{fence} . $language . "\n" .
            $node->firstChild->textContent .
            "\n" . $options->{fence} . "\n\n"
          )
        }
    },
);

sub install ($class, $target) {
    for my $key (keys %RULES) {
        $target->addRule($key, $RULES{$key})
    }
}

1;

=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/Text-HTML-Turndown>.

=head1 SUPPORT

The public support forum of this module is L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the Github bug queue at
L<https://github.com/Corion/Text-HTML-Turndown/issues>

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2025- by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the Artistic License 2.0.

=cut

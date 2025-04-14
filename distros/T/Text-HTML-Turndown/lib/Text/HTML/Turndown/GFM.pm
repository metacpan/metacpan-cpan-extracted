package Text::HTML::Turndown::GFM 0.06;
use 5.020;
use experimental 'signatures';
use stable 'postderef';

=head1 NAME

Text::HTML::Turndown::GFM - rules for Github Flavoured Markdown

=head1 SYNOPSIS

  use Text::HTML::Turndown;
  my $turndown = Text::HTML::Turndown->new(%$options);
  $turndown->use('Text::HTML::Turndown::GFM');;

  my $markdown = $convert->turndown(<<'HTML');
    <table><tr><td>Hello</td><td>world!</td></tr></table>
  HTML
  # | Hello | world! |

=cut

sub install ($class, $target) {
    $target->use([
        'Text::HTML::Turndown::Tables',
        'Text::HTML::Turndown::Strikethrough',
        'Text::HTML::Turndown::Tasklistitems',
        'Text::HTML::Turndown::HighlightedCodeBlock',
    ]);
}

1;

=head1 SEE ALSO

L<Text::HTML::Turndown::Tables>

L<Text::HTML::Turndown::Strikethrough>

L<Text::HTML::Turndown::Tasklistitems>

L<Text::HTML::Turndown::HighlightedCodeBlock>

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

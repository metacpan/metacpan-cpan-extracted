package WWW::Noss::TextToHtml;
use 5.016;
use strict;
use warnings;
our $VERSION = '1.04';

use Exporter 'import';
our @EXPORT_OK = qw(text2html escape_html);

sub escape_html {

    my $text = shift;

    $text =~ s/&/&amp;/g;
    $text =~ s/</&lt;/g;
    $text =~ s/>/&gt;/g;

    return $text;

}

sub text2html {

    my $text = shift;

    $text = escape_html($text);

    my @paras = split /(\s*\n){2,}/, $text;

    my $html = join '',
        map { "<p>" . $_ . "</p>\n" }
        grep { /\S/ }
        @paras;

    return $html;

}

1;

=head1 NAME

WWW::Noss::TextToHtml - Convert text to HTML

=head1 USAGE

  use WWW::Noss::TextToHtml(text2html);

  my $html = text2html($text);

=head1 DESCRIPTION

B<WWW::Noss::TextToHtml> is a module that provides subroutines for converting
plain text to HTML. This is a private module, please consult the L<noss>
manual for user documentation.

=head1 SUBROUTINES

Subroutines are not exported automatically.

=over 4

=item $html = text2html($text)

Converts the given string C<$text> to HTML.

=item $escaped = escape_html($text)

Escapes the given text by converting special HTML characters (C<E<lt>>,
C<E<gt>>, and C<&>) into their entity equivalents.

=back

=head1 AUTHOR

Written by Samuel Young, E<lt>samyoung12788@gmail.comE<gt>.

This project's source can be found on its
L<Codeberg page|https://codeberg.org/1-1sam/noss.git>. Comments and pull
requests are welcome!

=head1 COPYRIGHT

Copyright (C) 2025 Samuel Young

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

=head1 SEE ALSO

L<noss>

=cut

# vim: expandtab shiftwidth=4

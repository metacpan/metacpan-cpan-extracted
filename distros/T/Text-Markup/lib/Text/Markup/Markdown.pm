package Text::Markup::Markdown;

use 5.8.1;
use strict;
use warnings;
use Text::Markup;
use File::BOM qw(open_bom);
use Text::Markdown::Discount;

our $VERSION = '0.41';

sub import {
    # Replace the regex if passed one.
    Text::Markup->register( markdown => $_[1] ) if $_[1];
}

sub parser {
    my ($file, $encoding, $opts) = @_;
    my %params = @{ $opts };

    unless (defined $params{flags}) {
          $params{flags} = Text::Markdown::Discount::MKD_NOHEADER
              | Text::Markdown::Discount::MKD_TOC
              | Text::Markdown::Discount::MKD_DLEXTRA
              | Text::Markdown::Discount::MKD_FENCEDCODE
              | Text::Markdown::Discount::MKD_EXTRA_FOOTNOTE
              | Text::Markdown::Discount::MKD_IDANCHOR;
    }
    open_bom my $fh, $file, ":encoding($encoding)";
    my $html = Text::Markdown::Discount::markdown(join('', <$fh>), $params{flags});
    return unless $html =~ /\S/;
    utf8::encode($html);
    return $html if $params{raw};
    return qq{<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
</head>
<body>
$html
</body>
</html>
};

}

1;
__END__

=head1 Name

Text::Markup::Markdown - Markdown parser for Text::Markup

=head1 Synopsis

  my $html = Text::Markup->new->parse(file => 'README.md');
  my $raw  = Text::Markup->new->parse(
      file    => 'README.md',
      options => [ raw => 1 ],
  );

=head1 Description

This is the L<Markdown|https://daringfireball.net/projects/markdown/> parser
for L<Text::Markup>. It reads in the file (relying on a
L<BOM|https://www.unicode.org/unicode/faq/utf_bom.html#BOM>), hands it off to
L<Text::Markdown::Discount> for parsing, and then returns the generated HTML as an
encoded UTF-8 string with an C<http-equiv="Content-Type"> element identifying
the encoding as UTF-8.

It recognizes files with the following extensions as Markdown:

=over

=item F<.md>

=item F<.mkd>

=item F<.mkdn>

=item F<.mdown>

=item F<.markdown>

=back

To change it the files it recognizes, load this module directly and pass a
regular expression matching the desired extension(s), like so:

  use Text::Markup::Markdown qr{markd?};

Normally this module returns the output wrapped in a minimal HTML document
skeleton. If you would like the raw output without the skeleton, you can pass
the C<raw> parameter to C<parse>.

The Text::Markup::Markdown C<parse> method supports an additional parameter,
C<flags>, a bitmask of
L<Text::Markdown::Discount options|https://github.com/Songmu/text-markdown-discount/blob/d6b1325/lib/Text/Markdown/Discount.xs#L16-L46>.
Use this parameter to replace the default, which is:

  MKD_NOHEADER | MKD_TOC | MKD_DLEXTRA | MKD_FENCEDCODE | MKD_EXTRA_FOOTNOTE | MKD_IDANCHOR

=head1 See Also

L<National Funk Congress Deadlocked On Get Up/Get Down Issue|https://www.theonion.com/national-funk-congress-deadlocked-on-get-up-get-down-is-1819565355>.
MarkI<up> or MarkI<down>?

=head1 Author

David E. Wheeler <david@justatheory.com>

=head1 Copyright and License

Copyright (c) 2011-2025 David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

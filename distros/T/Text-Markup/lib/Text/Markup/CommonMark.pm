package Text::Markup::CommonMark;

use 5.8.1;
use strict;
use warnings;
use CommonMark;
use Text::Markup;
use File::BOM qw(open_bom);

our $VERSION = '0.32';

sub import {
    # Replace Text::Markup::Markdown.
    Text::Markup->register( markdown => $_[1] || qr{m(?:d(?:own)?|kdn?|arkdown)} );
}

sub parser {
    my ($file, $encoding, $opts) = @_;
    open_bom my $fh, $file, ":encoding($encoding)";
    my %params = @{ $opts };
    my $html = CommonMark->parse(
        smart  => 1,
        unsafe => 1,
        %params,
        string => join( '', <$fh>),
    )->render(  %params, format => 'html' );
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

Text::Markup::CommonMark - CommonMark Markdown parser for Text::Markup

=head1 Synopsis

  use Text::Markup::CommonMark;
  my $html = Text::Markup->new->parse(file => 'README.md');
  my $raw  = Text::Markup->new->parse(
      file    => 'README.md',
      options => [ raw => 1 ],
  );

=head1 Description

This is the L<CommonMark|https://commonmark.org> parser
for L<Text::Markup>. On load, it replaces the default L<Text::Markup::Markdown>
parser for parsing L<Markdown|https://daringfireball.net/projects/markdown/>.
Note that L<Text::Markup> does not load this module by default, but when
loaded manually will be the preferred Markdown parser.

Text::Markup::CommonMark reads in the file (relying on a
L<BOM|https://www.unicode.org/unicode/faq/utf_bom.html#BOM>), hands it off to
L<CommonMark> for parsing, and then returns the generated HTML as an
encoded UTF-8 string with an C<http-equiv="Content-Type"> element identifying
the encoding as UTF-8.

It recognizes files with the following extensions as CommonMark Markdown:

=over

=item F<.md>

=item F<.mkd>

=item F<.mkdn>

=item F<.mdown>

=item F<.markdown>

=back

To change it the files it recognizes, load this module directly and pass a
regular expression matching the desired extension(s), like so:

  use Text::Markup::CommonMark qr{markd?};

Normally this module returns the output wrapped in a minimal HTML document
skeleton. If you would like the raw output without the skeleton, you can pass
the C<raw> option to C<parse>.

In addition Text::CommonMark supports all of the CommonMark
L<parse options|CommonMark/parse> and L<render options|CommonMark::Node/render>,
including:

=over

=item C<smart>

When true, convert straight quotes to curly, --- to em dashes, -- to en
dashes. Enabled by default.

=item C<sourcepos>

When true, include a data-sourcepos attribute on all block elements. Disabled
by default.

 =item C<hardbreaks>

When true, render soft-break elements as hard line breaks. Disabled by default.

 =item C<nobreaks>

When true, render soft-break elements as spaces. Disabled by default.

 =item C<validate_utf8>

When true, validate UTF-8 in the input before parsing, replacing illegal
sequences with the replacement character C<U+FFFD>. Disabled by default.

 =item C<unsafe>

Render raw HTML and unsafe links (C<javascript:>, C<vbscript:>, C<file:>, and
C<data:>, except for C<image/png>, C<image/gif>, C<image/jpeg>, or
C<image/webp> mime types). Raw HTML is replaced by a placeholder HTML comment.
Unsafe links are replaced by empty strings. Enabled by default.

=back

=head1 Author

David E. Wheeler <david@justatheory.com>

=head1 Copyright and License

Copyright (c) 2011-2024 David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

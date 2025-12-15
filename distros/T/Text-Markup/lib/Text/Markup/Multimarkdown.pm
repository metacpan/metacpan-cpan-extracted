package Text::Markup::Multimarkdown;

use 5.8.1;
use strict;
use warnings;
use Text::Markup;
use File::BOM qw(open_bom);
use Text::MultiMarkdown ();

our $VERSION = '0.40';

sub import {
    # Replace the regex if passed one.
    Text::Markup->register( multimarkdown => $_[1] ) if $_[1];
}

sub parser {
    my ($file, $encoding, $opts) = @_;
    my %params = @{ $opts };
    my $md = Text::MultiMarkdown->new(%params);
    open_bom my $fh, $file, ":encoding($encoding)";
    local $/;
    my $html = $md->markdown(<$fh>);
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

Text::Markup::Multimarkdown - MultiMarkdown parser for Text::Markup

=head1 Synopsis

  my $html = Text::Markup->new->parse(file => 'README.mmd');
  my $raw  = Text::Markup->new->parse(
      file    => 'README.mmd',
      options => [ raw => 1 ],
  );

=head1 Description

This is the L<MultiMarkdown|https://fletcherpenney.net/multimarkdown/> parser
for L<Text::Markup>. It reads in the file (relying on a
L<BOM|https://www.unicode.org/unicode/faq/utf_bom.html#BOM>), hands it off to
L<Text::MultiMarkdown> for parsing, and then returns the generated HTML as an
encoded UTF-8 string with an C<http-equiv="Content-Type"> element identifying
the encoding as UTF-8.

It recognizes files with the following extensions as MultiMarkdown:

=over

=item F<.mmd>

=item F<.mmkd>

=item F<.mmkdn>

=item F<.mmdown>

=item F<.multimarkdown>

=back

To change it the files it recognizes, load this module directly and pass a
regular expression matching the desired extension(s), like so:

  use Text::Markup::Multimarkdown qr{mmm+};

Normally this module returns the output wrapped in a minimal HTML document
skeleton. If you would like the raw output without the skeleton, you can pass
the C<raw> option to the format options argument to C<parse>.

In addition, Text::Markup::Mediawiki supports all of the
L<Text::MultiMarkdown options|Text::MultiMarkdown/OPTIONS>, including:

=over

=item C<use_metadata>

=item C<strip_metadata>

=item C<empty_element_suffix>

=item C<img_ids>

=item C<heading_ids>

=item C<bibliography_title>

=item C<tab_width>

=item C<disable_tables>

=item C<disable_footnotes>

=item C<disable_bibliography>

=item C<disable_definition_lists>

=back

=head1 Author

David E. Wheeler <david@justatheory.com>

=head1 Copyright and License

Copyright (c) 2011-2025 David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

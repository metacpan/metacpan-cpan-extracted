package Text::Markup::Mediawiki;

use 5.8.1;
use strict;
use warnings;
use Text::Markup;
use File::BOM qw(open_bom);
use Text::MediawikiFormat 1.0;

our $VERSION = '0.40';

sub import {
    # Replace the regex if passed one.
    Text::Markup->register( mediawiki => $_[1] ) if $_[1];
}

sub parser {
    my ($file, $encoding, $opts) = @_;
    open_bom my $fh, $file, ":encoding($encoding)";
    local $/;
    my $html = Text::MediawikiFormat::format(<$fh>, @{ $opts });
    return unless $html =~ /\S/;
    utf8::encode($html);
    return $html if $opts->[1] && $opts->[1]->{raw};
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

Text::Markup::Mediawiki - MediaWiki syntax parser for Text::Markup

=head1 Synopsis

  my $html = Text::Markup->new->parse(file => 'README.mediawiki');
  my $raw  = Text::Markup->new->parse(
      file    => 'README.mediawiki',
      options => [ {}, { raw => 1 } ],
  );

=head1 Description

This is the L<MediaWiki
syntax|https://en.wikipedia.org/wiki/Help:Contents/Editing_Wikipedia> parser
for L<Text::Markup>. It reads in the file (relying on a
L<BOM|https://www.unicode.org/unicode/faq/utf_bom.html#BOM>), hands it off to
L<Text::MediawikiFormat> for parsing, and then returns the generated HTML as
an encoded UTF-8 string with an C<http-equiv="Content-Type"> element
identifying the encoding as UTF-8.

It recognizes files with the following extensions as MediaWiki:

=over

=item F<.mediawiki>

=item F<.mwiki>

=item F<.wiki>

=back

To change it the files it recognizes, load this module directly and pass a
regular expression matching the desired extension(s), like so:

  use Text::Markup::Mediawiki qr{kwiki?};

Text::Markup::Mediawiki supports the two
L<Text::MediawikiFormat arguments|Text::MediawikiFormat/format>, a hash
reference for tags and a hash reference of options. The supported options
include:

=over

=item C<prefix>

=item C<extended>

=item C<implicit_links>

=item C<absolute_links>

=item C<process_html>

=back

Normally this module returns the output wrapped in a minimal HTML document
skeleton. If you would like the raw output without the skeleton, you can pass
the C<raw> option via that second hash reference of options.

=head1 Author

David E. Wheeler <david@justatheory.com>

=head1 Copyright and License

Copyright (c) 2011-2025 David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

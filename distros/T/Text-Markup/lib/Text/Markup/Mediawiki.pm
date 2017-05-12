package Text::Markup::Mediawiki;

use 5.8.1;
use strict;
use File::BOM qw(open_bom);
use Text::MediawikiFormat '1.0';

our $VERSION = '0.23';

sub parser {
    my ($file, $encoding, $opts) = @_;
    open_bom my $fh, $file, ":encoding($encoding)";
    local $/;
    my $html = Text::MediawikiFormat::format(<$fh>, @{ $opts || [] });
    return unless $html =~ /\S/;
    utf8::encode($html);
    return qq{<html>
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

=head1 Description

This is the L<MediaWiki
syntax|http://en.wikipedia.org/wiki/Help:Contents/Editing_Wikipedia> parser
for L<Text::Markup>. It reads in the file (relying on a
L<BOM|http://www.unicode.org/unicode/faq/utf_bom.html#BOM>), hands it off to
L<Text::MediawikiFormat> for parsing, and then returns the generated HTML as
an encoded UTF-8 string with an C<http-equiv="Content-Type"> element
identifying the encoding as UTF-8.

It recognizes files with the following extensions as MediaWiki:

=over

=item F<.mediawiki>

=item F<.mwiki>

=item F<.wiki>

=back

=head1 Author

David E. Wheeler <david@justatheory.com>

=head1 Copyright and License

Copyright (c) 2011-2014 David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

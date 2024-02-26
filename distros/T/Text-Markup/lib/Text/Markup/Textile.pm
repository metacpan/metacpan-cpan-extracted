package Text::Markup::Textile;

use 5.8.1;
use strict;
use warnings;
use Text::Markup;
use File::BOM qw(open_bom);
use Text::Textile 2.10;

our $VERSION = '0.33';

sub import {
    # Replace the regex if passed one.
    Text::Markup->register( textile => $_[1] ) if $_[1];
}

sub parser {
    my ($file, $encoding, $opts) = @_;
    my %params = @{ $opts };
    my $textile = Text::Textile->new(
        charset       => 'utf-8',
        char_encoding => 0,
        trim_spaces   => 1,
        %params,
    );
    open_bom my $fh, $file, ":encoding($encoding)";
    local $/;
    my $html = $textile->process(<$fh>);
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

Text::Markup::Textile - Textile parser for Text::Markup

=head1 Synopsis

  my $html = Text::Markup->new->parse(file => 'README.textile');
  my $raw  = Text::Markup->new->parse(
      file    => 'README.textile',
      options => [ raw => 1 ],
  );

=head1 Description

This is the L<Textile|https://textile-lang.com> parser for L<Text::Markup>.
It reads in the file (relying on a
L<BOM|https://www.unicode.org/unicode/faq/utf_bom.html#BOM>), hands it off to
L<Text::Textile> for parsing, and then returns the generated HTML as an
encoded UTF-8 string with an C<http-equiv="Content-Type"> element identifying
the encoding as UTF-8.

It recognizes files with the following extension as Textile:

=over

=item F<.textile>

=back

To change it the files it recognizes, load this module directly and pass a
regular expression matching the desired extension(s), like so:

  use Text::Markup::Textile qr{text(?:ile)?};

Normally this module returns the output wrapped in a minimal HTML document
skeleton. If you would like the raw output without the skeleton, you can pass
the C<raw> option to C<parse>.

In addition, Text::Markup::Mediawiki supports all of the
L<Text::Textile options|Text::Textile/METHODS>, including:

=over

=item C<disable_html>

=item C<flavor>

=item C<css>

=item C<charset>

=item C<docroot>

=item C<trim_spaces>

=item C<preserve_spaces>

=item C<filter_param>

=item C<filters>

=item C<char_encoding>

=item C<disable_encode_entities>

=item C<handle_quotes>

=back

=head1 Author

David E. Wheeler <david@justatheory.com>

=head1 Copyright and License

Copyright (c) 2011-2024 David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

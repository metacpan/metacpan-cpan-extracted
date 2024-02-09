package Text::Markup::Markdown;

use 5.8.1;
use strict;
use warnings;
use Text::Markup;
use File::BOM qw(open_bom);
use Text::Markdown ();

our $VERSION = '0.32';

sub import {
    # Replace the regex if passed one.
    Text::Markup->register( markdown => $_[1] ) if $_[1];
}

sub parser {
    my ($file, $encoding, $opts) = @_;
    my %params = @{ $opts };
    my $md = Text::Markdown->new(%params);
    open_bom my $fh, $file, ":encoding($encoding)";
    my $html = $md->markdown(join '', <$fh>);
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
L<Text::Markdown> for parsing, and then returns the generated HTML as an
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
the C<raw> option to C<parse>.

In addition, Text::Markup::Markdown supports all of the
L<Text::Markdown options|Text::Markdown/OPTIONS>, including:

=over

=item C<empty_element_suffix>

=item C<tab_width>

=item C<trust_list_start_value>

=back

=head1 See Also

L<National Funk Congress Deadlocked On Get Up/Get Down Issue|https://www.theonion.com/national-funk-congress-deadlocked-on-get-up-get-down-is-1819565355>.
MarkI<up> or MarkI<down>?

=head1 Author

David E. Wheeler <david@justatheory.com>

=head1 Copyright and License

Copyright (c) 2011-2024 David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

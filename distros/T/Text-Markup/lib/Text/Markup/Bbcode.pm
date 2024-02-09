package Text::Markup::Bbcode;

use 5.8.1;
use strict;
use warnings;
use Text::Markup;
use File::BOM qw(open_bom);
use Parse::BBCode;

our $VERSION = '0.32';

sub import {
    # Replace the regex if passed one.
    Text::Markup->register( bbcode => $_[1] ) if $_[1];
}

sub parser {
    my ($file, $encoding, $opts) = @_;
    my %params = @{ $opts };
    my $parse = Parse::BBCode->new(\%params);
    open_bom my $fh, $file, ":encoding($encoding)";
    local $/;
    my $html = $parse->render(<$fh>);
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

Text::Markup::Bbcode - BBcode parser for Text::Markup

=head1 Synopsis

  my $html = Text::Markup->new->parse(file => 'file.bbcode');
  my $raw  = Text::Markup->new->parse(
      file => 'file.bbcode',
      options => [ raw => 1 ],
  );

=head1 Description

This is the L<BBcode|https://www.bbcode.org/> parser for L<Text::Markup>. It
reads in the file (relying on a
L<BOM|https://www.unicode.org/unicode/faq/utf_bom.html#BOM>), hands it off to
L<Text::Markdown> for parsing, and then returns the generated HTML as an
encoded UTF-8 string with an C<http-equiv="Content-Type"> element identifying
the encoding as UTF-8.

It recognizes files with the following extensions as Markdown:

=over

=item F<.bb>

=item F<.bbcode>

=back

To change it the files it recognizes, load this module directly and pass a
regular expression matching the desired extension(s), like so:

  use Text::Markup::Bbcode qr{beebee};

Normally this module returns the output wrapped in a minimal HTML document
skeleton. If you would like the raw output with the raw skeleton, you can pass
the C<raw> option to C<parse>.

In addition Text::Markup::Bbcode supports all of the
L<Parse::BBCode options|Parse::BBCode/METHODS>, including:

=over

=item C<tags>

=item C<escapes>

=item C<url_finder>

=item C<smileys>

=item C<linebreaks>

=item C<text_processor>

=item C<close_open_tags>

=item C<strict_attributes>

=item C<direct_attributes>

=item C<attribute_quote>

=item C<attribute_parser>

=item C<strip_linebreaks>

=back

=head1 Author

Lucas Kanashiro <kanashiro.duarte@gmail.com>

=head1 Copyright and License

Copyright (c) 2011-2023 Lucas Kanashiro. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

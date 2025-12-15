package Text::Markup::Asciidoctor;

use 5.8.1;
use strict;
use warnings;
use Text::Markup;
use Text::Markup::Cmd;
use utf8;

our $VERSION = '0.40';

sub import {
    # Replace Text::Markup::Asciidoc.
    Text::Markup->register( asciidoc => $_[1] || qr{a(?:sc(?:iidoc)?|doc)?} );
}

# Find Asciidoc.
my $ASCIIDOC = find_cmd([
    (map { (WIN32 ? ("$_.exe", "$_.bat") : ($_)) } qw(asciidoctor)),
    'asciidoctor.py',
], '--version');

# Arguments to pass to asciidoc.
# Restore --safe if Asciidoc ever fixes it with the XHTML back end.
# https://groups.google.com/forum/#!topic/asciidoc/yEr5PqHm4-o
my @OPTIONS = qw(
    --no-header-footer
    --out-file -
    --attribute newline=\\n
);

sub parser {
    my ($file, $encoding, $opts) = @_;
    my $html = do {
        my $fh = open_pipe(
            $ASCIIDOC, @OPTIONS,
            '--attribute' => "encoding=$encoding",
            $file
        );

        binmode $fh, ":encoding($encoding)";
        local $/;
        <$fh>;
    };

    # Make sure we have something.
    return unless $html =~ /\S/;
    utf8::encode $html;
    return $html if { @{ $opts } }->{raw};
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

Text::Markup::Asciidoc - Asciidoc parser for Text::Markup

=head1 Synopsis

  use Text::Markup::Asciidoctor;
  my $html = Text::Markup->new->parse(file => 'hello.adoc');
  my $raw = Text::Markup->new->parse(
      file    => 'hello.adoc',
      options => [raw => 1],
  );

=head1 Description

This is the L<Asciidoc|https://asciidoc.org/> parser for L<Text::Markup>. It
depends on the C<asciidoctor> command-line application; see the
L<installation docs|https://asciidoctor.org/#installation> for details, or
use the command C<gem install asciidoctor>. Note that L<Text::Markup> does
not load this module by default, but when loaded manually will replace
Text::Markup::Asciidoc as preferred Asciidoc parser.

Text::Markup::Asciidoctor reads in the file (relying on a
L<BOM|https://www.unicode.org/unicode/faq/utf_bom.html#BOM>), hands it off to
L<C<asciidoctor>|https://asciidoctor.org> for parsing, and then returns the
generated HTML as an encoded UTF-8 string with an C<http-equiv="Content-Type">
element identifying the encoding as UTF-8.

Text::Markup::Asciidoctor recognizes files with the following extensions as
Asciidoc:

=over

=item F<.asciidoc>

=item F<.asc>

=item F<.adoc>

=back

To change it the files it recognizes, load this module directly and pass a
regular expression matching the desired extension(s), like so:

  use Text::Markup::AsciiDoctor qr{ski?doc};

Normally this parser returns the output of C<asciidoctor> wrapped in a minimal
HTML page skeleton. If you would prefer to just get the exact output returned
by C<asciidoctor>, you can pass in a true value for the C<raw> option.

=head1 Author

David E. Wheeler <david@justatheory.com>

=head1 Copyright and License

Copyright (c) 2012-2025 David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

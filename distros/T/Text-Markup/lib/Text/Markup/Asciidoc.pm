package Text::Markup::Asciidoc;

use 5.8.1;
use strict;
use warnings;
use Text::Markup;
use Text::Markup::Cmd;
use utf8;

our $VERSION = '0.40';

sub import {
    # Replace the regex if passed one.
    Text::Markup->register( asciidoc => $_[1] ) if $_[1];
}

my $ASCIIDOC = find_cmd([
    (map { (WIN32 ? ("$_.exe", "$_.bat") : ($_)) } qw(asciidoc)),
    'asciidoc.py',
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

  use Text::Markup;
  my $html = Text::Markup->new->parse(file => 'hello.adoc');
  my $raw = Text::Markup->new->parse(
      file    => 'hello.adoc',
      options => [raw => 1],
  );

=head1 Description

This is the L<Asciidoc|https://asciidoc.org/> parser for L<Text::Markup>. It
depends on the L<C<asciidoc>|https://asciidoc-py.github.io> command-line
application. See the L<installation docs|https://asciidoc-py.github.io/INSTALL.html>
for details, or use the command C<pip3 install asciidoc>.

Text::Markup::Asciidoc recognizes files with the following extensions as
Asciidoc:

=over

=item F<.asciidoc>

=item F<.asc>

=item F<.adoc>

=back

To change it the files it recognizes, load this module directly and pass a
regular expression matching the desired extension(s), like so:

  use Text::Markup::Asciidoc qr{ski?doc};

Normally this parser returns the output of C<asciidoc> wrapped in a minimal
HTML page skeleton. If you would prefer to just get the exact output returned
by C<asciidoc>, you can pass in a true value for the C<raw> option.

=head1 Author

David E. Wheeler <david@justatheory.com>

=head1 Copyright and License

Copyright (c) 2012-2025 David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

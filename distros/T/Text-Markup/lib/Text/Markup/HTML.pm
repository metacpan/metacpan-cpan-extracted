package Text::Markup::HTML;

use 5.8.1;
use strict;
use warnings;

our $VERSION = '0.31';

sub parser {
    my ($file, $encoding, $opts) = @_;
    my $html = do {
        open my $fh, '<:raw', $file or die "Cannot open $file: $!\n";
        local $/;
        <$fh>;
    };
    return $html =~ /\S/ ? $html : undef
}

1;
__END__

=head1 Name

Text::Markup::HTML - HTML parser for Text::Markup

=head1 Synopsis

  use Text::Markup;
  my $html = Text::Markup->new->parse(file => 'hello.html');

=head1 Description

This is the L<HTML|https://whatwg.org/html/> parser for L<Text::Markup>. All
it does is read in the HTML file and return it as a string. It makes no
assumptions about encoding, and returns the string raw as read from the file,
with no decoding. It recognizes files with the following extensions as HTML:

=over

=item F<.html>

=item F<.htm>

=item F<.xhtml>

=item F<.xhtm>

=back

=head1 Author

David E. Wheeler <david@justatheory.com>

=head1 Copyright and License

Copyright (c) 2011-2023 David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

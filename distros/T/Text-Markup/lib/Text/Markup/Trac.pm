package Text::Markup::Trac;

use 5.8.1;
use strict;
use warnings;
use File::BOM qw(open_bom);
use Text::Trac '0.10';

our $VERSION = '0.24';

sub parser {
    my ($file, $encoding, $opts) = @_;
    my $trac = Text::Trac->new(@{ $opts || [] });
    open_bom my $fh, $file, ":encoding($encoding)";
    local $/;
    my $html = $trac->parse(<$fh>);
    return unless $html =~ /\S/;
    utf8::encode($html);
    return $html if $opts->{raw};
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

Text::Markup::Trac - Trac wiki syntax parser for Text::Markup

=head1 Synopsis

  my $html = Text::Markup->new->parse(file => 'README.trac');
  my $raw  = Text::Markup->new->parse(file => 'README.trac', raw => 1);

=head1 Description

This is the L<Trac wiki
syntax|http://projects.edgewall.com/trac/wiki/WikiFormatting> parser for
L<Text::Markup>. It reads in the file (relying on a
L<BOM|http://www.unicode.org/unicode/faq/utf_bom.html#BOM>), hands it off to
L<Text::Trac> for parsing, and then returns the generated HTML as an encoded
UTF-8 string with an C<http-equiv="Content-Type"> element identifying the
encoding as UTF-8.

It recognizes files with the following extensions as Trac:

=over

=item F<.trac>

=item F<.trc>

=back

Normally this module returns the output wrapped in a minimal HTML document
skeleton. If you would like the raw output without the skeleton, you can pass
the C<raw> option to C<parse>.

=head1 Author

David E. Wheeler <david@justatheory.com>

=head1 Copyright and License

Copyright (c) 2011-2019 David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

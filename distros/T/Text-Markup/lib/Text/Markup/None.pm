package Text::Markup::None;

use 5.8.1;
use strict;
use HTML::Entities;
use File::BOM qw(open_bom);

our $VERSION = '0.23';

sub parser {
    my ($file, $encoding, $opts) = @_;
    open_bom my $fh, $file, ":encoding($encoding)";
    local $/;
    my $html = encode_entities(<$fh>, '<>&"');
    utf8::encode($html);
    return qq{<html>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
</head>
<body>
<pre>$html</pre>
</body>
</html>
};
}

1;
__END__

=head1 Name

Text::Markup::None - Turn a file with no known markup into HTML

=head1 Synopsis

  use Text::Markup;
  my $html = Text::Markup->new->parse(file => 'README');

=head1 Description

This is the default parser used by Text::Markdown in the event that it cannot
determine the format of a text file. All it does is read the file in (relying
on a L<BOM|http://www.unicode.org/unicode/faq/utf_bom.html#BOM>, encodes all
entities, and then returns an HTML string with the file in a C<< <pre> >>
element. This will be handy for files that really are nothing but plain text,
like F<README> files.

=head1 Author

David E. Wheeler <david@justatheory.com>

=head1 Copyright and License

Copyright (c) 2011-2014 David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

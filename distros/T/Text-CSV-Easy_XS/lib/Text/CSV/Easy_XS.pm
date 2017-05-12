package Text::CSV::Easy_XS;
use 5.010;
use strict;
use warnings FATAL => 'all';

our $VERSION = '0.53';

require Exporter;

our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(csv_build csv_parse);

# version numbering to ensure PP and XS stay in sync.
our $TCE_VERSION = 2;

require XSLoader;
XSLoader::load( 'Text::CSV::Easy_XS', $VERSION );

1;

__END__

=head1 NAME

Text::CSV::Easy_XS - Easy (and fast) CSV parsing and building

=head1 VERSION

Version 0.53

=head1 SYNOPSIS

  use Text::CSV::Easy_XS qw(csv_build csv_parse);

  my @fields = csv_parse($string);
  my $string = csv_build(@fields);

=head1 DESCRIPTION

Text::CSV::Easy_XS is a simple module for parsing and building CSV lines. This module is written in XS, which is much faster than the PurePerl alternative (L<Text::CSV::Easy_PP>). You can use L<Text::CSV::Easy> directly and it will make the best decision on which module to use.

This module conforms to RFC 4180 (L<http://tools.ietf.org/html/rfc4180>) for both parsing and building of CSV strings.

=over 4

=item 1. Use commas to separate fields. Spaces will be considered part of the field.

 abc,def, ghi        => ( 'abc', 'def', ' ghi' )

=item 2. You may enclose fields in quotes.

 "abc","def"         => ( 'abc', 'def' )

=item 3. If your field contains a line break, a comma, or a quote, you need to enclose it in quotes. A quote should be escaped with another quote.

 "a,b","a\nb","a""b" => ( 'a,b', "a\nb", 'a"b' )

=item 4. A trailing newline is acceptable (both LF and CRLF).

 abc,def\n           => ( 'abc', 'def' )
 abc,def\r\n         => ( 'abc', 'def' )

=back

When building a string using csv_build, all non-numeric strings will always be enclosed in quotes.

=head1 SUBROUTINES

=head2 csv_build( List @fields ) : Str

Takes a list of fields and will generate a csv string. This subroutine will raise an exception if any errors occur.

=head2 csv_parse( Str $string ) : List[Str]

Parses a CSV string. Returns a list of fields it found. This subroutine will raise an exception if a string could not be properly parsed.

=head1 TCE_VERSION

Version 2

This module will be used by L<Text::CSV::Easy> over the PurePerl version if the TCE_VERSION numbers match.

=head1 DISCLAIMER

Note: this module is still in an *alpha* state. This has not been tested with threads. Use at your own risk.

=head1 SEE ALSO

=over 4

=item L<Text::CSV>

=item L<Text::CSV::Easy>

=item L<Text::CSV::Easy_PP>

=back

=head1 AUTHOR

Thomas Peters, E<lt>weters@me.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Thomas Peters

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.

=cut

package Text::CSV::Easy;
use strict;
use warnings FATAL => 'all';
use 5.010;

use B qw(svref_2object);
use Exporter qw(import);

=head1 NAME

Text::CSV::Easy - Easy CSV parsing and building

=head1 VERSION

Version 0.54

=cut

our $VERSION = '0.54';

our @EXPORT_OK = qw(csv_build csv_parse);

# used to ensure XS and PP stay in sync.
our $TCE_VERSION;
BEGIN { $TCE_VERSION = 2 }

=head1 SYNOPSIS

 use Text::CSV::Easy qw( csv_build csv_parse );
 $csv = csv_build(@fields);
 @fields = csv_parse($csv);

=head1 DESCRIPTION

Text::CSV::Easy is a simple module for parsing and building CSV strings. This module itself is
a lightweight wrapper around L<Text::CSV::Easy_XS> or L<Text::CSV::Easy_PP>.

This module conforms to RFC 4180 (L<http://tools.ietf.org/html/rfc4180>) for both parsing and building of CSV lines.

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

=cut

my $MODULE;

BEGIN {
    my $xs_loaded = eval { require Text::CSV::Easy_XS; 1 };
    if ( $xs_loaded && $Text::CSV::Easy_XS::TCE_VERSION == $TCE_VERSION ) {
        $MODULE = 'Text::CSV::Easy_XS';
    }
    else {
        $MODULE = 'Text::CSV::Easy_PP';
        require Text::CSV::Easy_PP;
    }

    no strict 'refs';
    for ( keys %{ $MODULE . '::' } ) {

        if ( defined &{"${MODULE}::$_"} ) {
            my $ref = \&{"${MODULE}::$_"};
            my $obj = svref_2object($ref);
            next unless $obj->isa('B::CV') && $obj->GV->STASH->NAME eq $MODULE;
            *$_ = $ref;
        }
    }
}

=head1 SUBROUTINES

=head2 csv_build( List @fields ) : Str

Takes a list of fields and will generate a csv string. This subroutine will raise an exception if any errors occur.

=head2 csv_parse( Str $string ) : List[Str]

Parses a CSV string. Returns a list of fields it found. This subroutine will raise an exception if a string could not be properly parsed.

=head2 module( ) : Str

Returns the underlying module used for CSV processing.

=cut

sub module { return $MODULE }

1;

__END__

=head1 TCE_VERSION

Version 2

The TCE_VERSION ensures that the XS and PP versions of Text::CSV::Easy are consistent.

=head1 SEE ALSO

=over 4

=item L<Text::CSV>

=item L<Text::CSV::Easy_PP>

=item L<Text::CSV::Easy_XS>

=back

=head1 AUTHOR

Thomas Peters, E<lt>weters@me.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Thomas Peters

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.

=cut

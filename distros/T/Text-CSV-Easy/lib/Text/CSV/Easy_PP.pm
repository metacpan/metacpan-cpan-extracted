package Text::CSV::Easy_PP;
use 5.010;
use strict;
use warnings FATAL => 'all';

use Carp;
use Exporter qw(import);

our @EXPORT_OK = qw(csv_build csv_parse);

=head1 NAME

Text::CSV::Easy_PP - Easy CSV parsing and building implemented in PurePerl

=head1 SYNOPSIS

  use Text::CSV::Easy_PP qw(csv_build csv_parse);

  my @fields = csv_parse($string);
  my $string = csv_build(@fields);

=head1 DESCRIPTION

Text::CSV::Easy_PP is a simple module for parsing and building CSV lines. This module is written in PurePerl. For a faster alternative, see L<Text::CSV::Easy_XS>. Either way, you should just be able to use L<Text::CSV::Easy> directly and it will determine which version to use.

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

=head1 SUBROUTINES

=head2 csv_build( List @fields ) : Str

Takes a list of fields and will generate a CSV string. This subroutine will raise an exception if any errors occur.

=cut

sub csv_build {
    my @fields = @_;
    return join ',', map {
        if ( !defined )
        {
            '';
        }
        elsif (/^\d+$/) {
            $_;
        }
        else {
            ( my $str = $_ ) =~ s/"/""/g;
            qq{"$str"};
        }
    } @fields;
}

=head2 csv_parse( Str $string ) : List[Str]

Parses a CSV string. Returns a list of fields it found. This subroutine will raise an exception if a string could not be properly parsed.

=cut

sub csv_parse {
    my ($str) = @_;

    return () unless $str;

    my $last_pos = 0;

    my @fields;
    while (
        $str =~ / (?:^|,) 
          (?: ""                # don't want a capture group here
            | "(.*?)(?<![^"]")" # find quote which isn't being escaped
            | ([^",\r\n]*)      # try to match an unquoted field
          )
          (?:\r?\n(?=$)|)       # allow a trailing newline only
          (?=,|$) /xsg
        )
    {
        my $field = $1 || $2;
        my $match = $&;

        # is the field a numeric 0.
        if ( defined($field) && $field =~ /^0+$/ ) {

            # don't do anything.
        }
        else {

            # if we don't have a value, we have either an undef or an empty string.
            # "" will be an empty string, otherwise it should be undef.
            $field ||= ( $match =~ /^,?""(?:\r?\n)?$/ ? "" : undef );
        }

        # track the pos($str) to ensure each field happends immediately after the
        # previous match. also, account for a leading comma when $last_pos != 0
        croak("invalid line: $str")
            if pos($str) > $last_pos + length($match) + ( $last_pos != 0 ? 1 : 0 );

        $last_pos = pos($str);

        if ($field) {
            croak("quote is not properly escaped")
                if ( $field =~ /(?<!")"(?!")/ );

            # unescape the quotes.
            $field =~ s/""/"/g;
        }
        push @fields, $field;
    }

    croak("invalid line: $str") if $last_pos != length($str);

    return @fields;
}

1;

=head1 SEE ALSO

=over 4

=item L<Text::CSV>

=item L<Text::CSV::Easy>

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

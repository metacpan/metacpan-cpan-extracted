package Text::CSV::Encoded::Coder::EncodeGuess;
$Text::CSV::Encoded::Coder::EncodeGuess::VERSION = '0.25';
use 5.008;
use strict;
use warnings;

# VERSION

use base qw( Text::CSV::Encoded::Coder::Encode );

use Carp ();
use Encode ();
use Encode::Guess;


sub decode {
    my ( $self, $encoding, $str ) = @_;

    return undef unless defined $str;

    if ( ref $encoding ) {
        my $enc = Encode::Guess::guess_encoding( $str, @$encoding );
        $enc = $self->find_encoding( $encoding->[0] ) unless ref $enc;
        return $enc->decode( $str, $self->decode_check_value );
    }

    $self->find_encoding( $encoding )->decode( $str, $self->decode_check_value );
}


sub decode_fields_ref {
    my ( $self, $encoding, $arrayref ) = @_;

    if ( ref $encoding ) {
        for ( @$arrayref ) {
            my $enc = Encode::Guess::guess_encoding( $_, @$encoding );
            $enc = $self->find_encoding( $encoding->[0] ) unless ref $enc;
            $_ = $enc->decode( $_, $self->decode_check_value );
        }
    }
    else {
        my $enc = $self->find_encoding( $encoding ) || return;
        for ( @$arrayref ) {
            $_ = $enc->decode( $_, $self->decode_check_value );
        }
    }

}


1;
__END__

=pod

=head1 NAME

Text::CSV::Encoded::Coder::EncodeGuess - Text::CSV::Encoded coder class using Encode::Guess

=head1 VERSION

version 0.25

=head1 SYNOPSIS

    use Text::CSV::Encoded  coder_class => 'Text::CSV::Encoded::Coder::EncodeGuess';
    use Spreadsheet::ParseExcel;
    
    my $csv = Text::CSV::Encoded->new();
    
    $csv->encoding( ['ucs2', 'ascii'] ); # guessing ucs2 or ascii?
    $csv->encoding_to_combine('shiftjis');
    
    my $excel = Spreadsheet::ParseExcel::Workbook->Parse( $file );
    my $sheet = $excel->{Worksheet}->[0];
    
    for my $row ( $sheet->{MinRow} .. $sheet->{MaxRow} ) {
        my @fields;
        
        for my $col ( $sheet->{MinCol} ..  $sheet->{MaxCol} ) {
            my $cell = $sheet->{Cells}[$row][$col];
            push @fields, $cell->{Val};
        }
        
        $csv->combine( @fields ) or die;
        print $csv->string, "\n";
    }

=head1 DESCRIPTION

This module is inherited from L<Text::CSV::Encoded::Coder::Encode>.

=head1 USE

Except for 2 attributes, same as L<Text::CSV::Encoded::Coder::Encode>.

=head2 encoding_in

    $csv = $csv->encoding_in( $encoding_list_ref );

The accessor to an encoding for pre-parsing CSV strings.
If no encoding is given, returns current C<$encoding>, otherwise the object itself.

    $encoding_list_ref = $csv->encoding_in()

When you pass a list reference, it might guess the encoding from the given list.

    $csv->encoding_in( ['shiftjis', 'euc-jp', 'iso-20022-jp'] );

If it cannot guess the encoding, the first encoding of the list is used.

=head2 encoding

    $csv = $csv->encoding( $encoding_list_ref );
    $encoding_list_ref = $csv->encoding();

You can pass a list reference to this attribute only:

  * For list data consumed by combine().
  * For list reference returned by getline().

In other word, in C<combine> and C<print>, it might guess an encoding for the passing list data.
If it cannot guess the encoding, the first encoding of the list is used.

=head1 SEE ALSO

L<Encode>, L<Encode::Guess>

=head1 AUTHOR

Makamaka Hannyaharamitu, E<lt>makamaka[at]cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2013 by Makamaka Hannyaharamitu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

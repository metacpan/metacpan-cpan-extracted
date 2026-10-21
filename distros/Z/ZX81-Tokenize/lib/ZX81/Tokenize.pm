package ZX81::Tokenize;

use Modern::Perl;
use POSIX qw(frexp);

our $VERSION = '0.006';

use Exporter qw(import);

our @EXPORT_OK = qw(
  tokenize_basic
  encode_chars
  encode_float
);

#------------------------------------------------------------------------------

sub tokenize_line {
    my ($line) = @_;

    # get line number
    $line =~ s/^\s*(\d+)\s*// or die "line number expected in '$line'";
    my $line_num = $1;

    # convert line tokens
    my $bin = "";
    if ( $line =~ s/^\s*REM ?//i ) {

        # don't expand numbers and keywords within REM comments
        $bin .= pack( "C", 0xEA );    # REM token
        while ( $line ne "" ) {
            ( my $char_bin, $line ) = encode_char($line);
            $bin .= $char_bin;
        }
        $bin .= $line;                # rest of the comment
        $line = "";                   # end processing this line
    }
    else {
        # tokenize BASIC keywords and characters
        while (1) {
            $line =~ s/^\s+//;
            last if $line eq "";

            if ( $line =~ s/^\\([0-9a-f][0-9a-f])//i ) {
                $bin .= pack( "C", hex($1) );
            }
            elsif ( $line =~ s/^RND\b//i )    { $bin .= pack( "C", 0x40 ); }
            elsif ( $line =~ s/^INKEY\$//i )  { $bin .= pack( "C", 0x41 ); }
            elsif ( $line =~ s/^PI\b//i )     { $bin .= pack( "C", 0x42 ); }
            elsif ( $line =~ s/^AT\b//i )     { $bin .= pack( "C", 0xC1 ); }
            elsif ( $line =~ s/^TAB\b//i )    { $bin .= pack( "C", 0xC2 ); }
            elsif ( $line =~ s/^CODE\b//i )   { $bin .= pack( "C", 0xC4 ); }
            elsif ( $line =~ s/^VAL\b//i )    { $bin .= pack( "C", 0xC5 ); }
            elsif ( $line =~ s/^LEN\b//i )    { $bin .= pack( "C", 0xC6 ); }
            elsif ( $line =~ s/^SIN\b//i )    { $bin .= pack( "C", 0xC7 ); }
            elsif ( $line =~ s/^COS\b//i )    { $bin .= pack( "C", 0xC8 ); }
            elsif ( $line =~ s/^TAN\b//i )    { $bin .= pack( "C", 0xC9 ); }
            elsif ( $line =~ s/^ASN\b//i )    { $bin .= pack( "C", 0xCA ); }
            elsif ( $line =~ s/^ACS\b//i )    { $bin .= pack( "C", 0xCB ); }
            elsif ( $line =~ s/^ATN\b//i )    { $bin .= pack( "C", 0xCC ); }
            elsif ( $line =~ s/^LN\b//i )     { $bin .= pack( "C", 0xCD ); }
            elsif ( $line =~ s/^EXP\b//i )    { $bin .= pack( "C", 0xCE ); }
            elsif ( $line =~ s/^INT\b//i )    { $bin .= pack( "C", 0xCF ); }
            elsif ( $line =~ s/^SQR\b//i )    { $bin .= pack( "C", 0xD0 ); }
            elsif ( $line =~ s/^SGN\b//i )    { $bin .= pack( "C", 0xD1 ); }
            elsif ( $line =~ s/^ABS\b//i )    { $bin .= pack( "C", 0xD2 ); }
            elsif ( $line =~ s/^PEEK\b//i )   { $bin .= pack( "C", 0xD3 ); }
            elsif ( $line =~ s/^USR\b//i )    { $bin .= pack( "C", 0xD4 ); }
            elsif ( $line =~ s/^STR\$//i )    { $bin .= pack( "C", 0xD5 ); }
            elsif ( $line =~ s/^CHR\$//i )    { $bin .= pack( "C", 0xD6 ); }
            elsif ( $line =~ s/^NOT\b//i )    { $bin .= pack( "C", 0xD7 ); }
            elsif ( $line =~ s/^OR\b//i )     { $bin .= pack( "C", 0xD9 ); }
            elsif ( $line =~ s/^AND\b//i )    { $bin .= pack( "C", 0xDA ); }
            elsif ( $line =~ s/^THEN\b//i )   { $bin .= pack( "C", 0xDE ); }
            elsif ( $line =~ s/^TO\b//i )     { $bin .= pack( "C", 0xDF ); }
            elsif ( $line =~ s/^STEP\b//i )   { $bin .= pack( "C", 0xE0 ); }
            elsif ( $line =~ s/^LPRINT\b//i ) { $bin .= pack( "C", 0xE1 ); }
            elsif ( $line =~ s/^LLIST\b//i )  { $bin .= pack( "C", 0xE2 ); }
            elsif ( $line =~ s/^STOP\b//i )   { $bin .= pack( "C", 0xE3 ); }
            elsif ( $line =~ s/^SLOW\b//i )   { $bin .= pack( "C", 0xE4 ); }
            elsif ( $line =~ s/^FAST\b//i )   { $bin .= pack( "C", 0xE5 ); }
            elsif ( $line =~ s/^NEW\b//i )    { $bin .= pack( "C", 0xE6 ); }
            elsif ( $line =~ s/^SCROLL\b//i ) { $bin .= pack( "C", 0xE7 ); }
            elsif ( $line =~ s/^CONT\b//i )   { $bin .= pack( "C", 0xE8 ); }
            elsif ( $line =~ s/^DIM\b//i )    { $bin .= pack( "C", 0xE9 ); }
            elsif ( $line =~ s/^REM\b//i )    { $bin .= pack( "C", 0xEA ); }
            elsif ( $line =~ s/^FOR\b//i )    { $bin .= pack( "C", 0xEB ); }
            elsif ( $line =~ s/^GOTO\b//i )   { $bin .= pack( "C", 0xEC ); }
            elsif ( $line =~ s/^GOSUB\b//i )  { $bin .= pack( "C", 0xED ); }
            elsif ( $line =~ s/^INPUT\b//i )  { $bin .= pack( "C", 0xEE ); }
            elsif ( $line =~ s/^LOAD\b//i )   { $bin .= pack( "C", 0xEF ); }
            elsif ( $line =~ s/^LIST\b//i )   { $bin .= pack( "C", 0xF0 ); }
            elsif ( $line =~ s/^LET\b//i )    { $bin .= pack( "C", 0xF1 ); }
            elsif ( $line =~ s/^PAUSE\b//i )  { $bin .= pack( "C", 0xF2 ); }
            elsif ( $line =~ s/^NEXT\b//i )   { $bin .= pack( "C", 0xF3 ); }
            elsif ( $line =~ s/^POKE\b//i )   { $bin .= pack( "C", 0xF4 ); }
            elsif ( $line =~ s/^PRINT\b//i )  { $bin .= pack( "C", 0xF5 ); }
            elsif ( $line =~ s/^PLOT\b//i )   { $bin .= pack( "C", 0xF6 ); }
            elsif ( $line =~ s/^RUN\b//i )    { $bin .= pack( "C", 0xF7 ); }
            elsif ( $line =~ s/^SAVE\b//i )   { $bin .= pack( "C", 0xF8 ); }
            elsif ( $line =~ s/^RAND\b//i )   { $bin .= pack( "C", 0xF9 ); }
            elsif ( $line =~ s/^IF\b//i )     { $bin .= pack( "C", 0xFA ); }
            elsif ( $line =~ s/^CLS\b//i )    { $bin .= pack( "C", 0xFB ); }
            elsif ( $line =~ s/^UNPLOT\b//i ) { $bin .= pack( "C", 0xFC ); }
            elsif ( $line =~ s/^CLEAR\b//i )  { $bin .= pack( "C", 0xFD ); }
            elsif ( $line =~ s/^RETURN\b//i ) { $bin .= pack( "C", 0xFE ); }
            elsif ( $line =~ s/^COPY\b//i )   { $bin .= pack( "C", 0xFF ); }
            elsif ( $line =~ s/^\\\"//i )     { $bin .= pack( "C", 0xC0 ); }
            elsif ( $line =~ s/^\*\*//i )     { $bin .= pack( "C", 0xD8 ); }
            elsif ( $line =~ s/^<=//i )       { $bin .= pack( "C", 0xDB ); }
            elsif ( $line =~ s/^>=//i )       { $bin .= pack( "C", 0xDC ); }
            elsif ( $line =~ s/^<>//i )       { $bin .= pack( "C", 0xDD ); }
            elsif ( $line =~ s/^((\d*\.\d+|\d+\.\d*|\d+)(e[-+]?\d+)?)//i ) {

                # number
                my $num       = $1;
                my $num_chars = encode_chars($num);
                my $num_bin   = encode_float($num);
                $bin .= $num_chars . pack( "C", 0x7E ) . $num_bin;
            }
            elsif ( $line =~ s/^(\w+)//i ) {

                # identifier
                my $ident = $1;
                $bin .= encode_chars($ident);
            }
            elsif ( $line =~ s/^\"//i ) {

                # string
                ( my $str_bin, $line ) = encode_string($line);
                $bin .= $str_bin;
            }
            else {
                ( my $char_bin, $line ) = encode_char($line);
                $bin .= $char_bin;
            }
        }
    }

    # appends newline
    $bin .= pack( "C", 0x76 );

    # pack line number, size and packed line
    my $size = length($bin);
    return pack( "nv", $line_num, $size ) . $bin;
}

sub tokenize_basic {
    my ($basic) = @_;
    my $bin = "";
    $basic =~ s/\\\n/ /g;    # join continuation lines
    for my $line ( split( /\n/, $basic ) ) {
        $line =~ s/^\s*#.*//;                # remove comments
        next unless $line =~ /\S/;           # ignore empty lines

        $bin .= tokenize_line($line);
    }
    return $bin;
}

#------------------------------------------------------------------------------
sub encode_char {
    my ($text) = @_;

    my $bin;
    if ( $text =~ s/^\\([0-9a-f][0-9a-f])//i ) { $bin = pack( "C", hex($1) ); }
    elsif ( $text =~ s/^\\  //i )              { $bin = pack( "C", 0x00 ); }
    elsif ( $text =~ s/^\\' //i )              { $bin = pack( "C", 0x01 ); }
    elsif ( $text =~ s/^\\ '//i )              { $bin = pack( "C", 0x02 ); }
    elsif ( $text =~ s/^\\''//i )              { $bin = pack( "C", 0x03 ); }
    elsif ( $text =~ s/^\\\. //i )             { $bin = pack( "C", 0x04 ); }
    elsif ( $text =~ s/^\\: //i )              { $bin = pack( "C", 0x05 ); }
    elsif ( $text =~ s/^\\\.'//i )             { $bin = pack( "C", 0x06 ); }
    elsif ( $text =~ s/^\\:'//i )              { $bin = pack( "C", 0x07 ); }
    elsif ( $text =~ s/^\\##//i )              { $bin = pack( "C", 0x08 ); }
    elsif ( $text =~ s/^\\,,//i )              { $bin = pack( "C", 0x09 ); }
    elsif ( $text =~ s/^\\~~//i )              { $bin = pack( "C", 0x0a ); }
    elsif ( $text =~ s/^\\:://i )              { $bin = pack( "C", 0x80 ); }
    elsif ( $text =~ s/^\\\.://i )             { $bin = pack( "C", 0x81 ); }
    elsif ( $text =~ s/^\\:\.//i )             { $bin = pack( "C", 0x82 ); }
    elsif ( $text =~ s/^\\\.\.//i )            { $bin = pack( "C", 0x83 ); }
    elsif ( $text =~ s/^\\'://i )              { $bin = pack( "C", 0x84 ); }
    elsif ( $text =~ s/^\\ ://i )              { $bin = pack( "C", 0x85 ); }
    elsif ( $text =~ s/^\\'\.//i )             { $bin = pack( "C", 0x86 ); }
    elsif ( $text =~ s/^\\ \.//i )             { $bin = pack( "C", 0x87 ); }
    elsif ( $text =~ s/^\\\@\@//i )            { $bin = pack( "C", 0x88 ); }
    elsif ( $text =~ s/^\\;;//i )              { $bin = pack( "C", 0x89 ); }
    elsif ( $text =~ s/^\\!!//i )              { $bin = pack( "C", 0x8a ); }
    elsif ( $text =~ s/^\n//i )                { $bin = pack( "C", 0x76 ); }
    elsif ( $text =~ s/^ //i )                 { $bin = pack( "C", 0x00 ); }
    elsif ( $text =~ s/^\"//i )                { $bin = pack( "C", 0x0b ); }
    elsif ( $text =~ s/^\#//i )                { $bin = pack( "C", 0x0c ); }
    elsif ( $text =~ s/^\$//i )                { $bin = pack( "C", 0x0d ); }
    elsif ( $text =~ s/^://i )                 { $bin = pack( "C", 0x0e ); }
    elsif ( $text =~ s/^\?//i )                { $bin = pack( "C", 0x0f ); }
    elsif ( $text =~ s/^\(//i )                { $bin = pack( "C", 0x10 ); }
    elsif ( $text =~ s/^\)//i )                { $bin = pack( "C", 0x11 ); }
    elsif ( $text =~ s/^>//i )                 { $bin = pack( "C", 0x12 ); }
    elsif ( $text =~ s/^<//i )                 { $bin = pack( "C", 0x13 ); }
    elsif ( $text =~ s/^=//i )                 { $bin = pack( "C", 0x14 ); }
    elsif ( $text =~ s/^\+//i )                { $bin = pack( "C", 0x15 ); }
    elsif ( $text =~ s/^-//i )                 { $bin = pack( "C", 0x16 ); }
    elsif ( $text =~ s/^\*//i )                { $bin = pack( "C", 0x17 ); }
    elsif ( $text =~ s/^\///i )                { $bin = pack( "C", 0x18 ); }
    elsif ( $text =~ s/^;//i )                 { $bin = pack( "C", 0x19 ); }
    elsif ( $text =~ s/^,//i )                 { $bin = pack( "C", 0x1a ); }
    elsif ( $text =~ s/^\.//i )                { $bin = pack( "C", 0x1b ); }
    elsif ( $text =~ s/^(\d)//i ) {
        $bin = pack( "C", 0x1c + ord($1) - ord('0') );
    }
    elsif ( $text =~ s/^(\w)//i ) {
        $bin = pack( "C", 0x26 + ord( uc($1) ) - ord('A') );
    }
    elsif ( $text =~ s/^\% //i )  { $bin = pack( "C", 0x80 ); }
    elsif ( $text =~ s/^\%\"//i ) { $bin = pack( "C", 0x8b ); }
    elsif ( $text =~ s/^\%\#//i ) { $bin = pack( "C", 0x8c ); }
    elsif ( $text =~ s/^\%\$//i ) { $bin = pack( "C", 0x8d ); }
    elsif ( $text =~ s/^\%://i )  { $bin = pack( "C", 0x8e ); }
    elsif ( $text =~ s/^\%\?//i ) { $bin = pack( "C", 0x8f ); }
    elsif ( $text =~ s/^\%\(//i ) { $bin = pack( "C", 0x90 ); }
    elsif ( $text =~ s/^\%\)//i ) { $bin = pack( "C", 0x91 ); }
    elsif ( $text =~ s/^\%>//i )  { $bin = pack( "C", 0x92 ); }
    elsif ( $text =~ s/^\%<//i )  { $bin = pack( "C", 0x93 ); }
    elsif ( $text =~ s/^\%=//i )  { $bin = pack( "C", 0x94 ); }
    elsif ( $text =~ s/^\%\+//i ) { $bin = pack( "C", 0x95 ); }
    elsif ( $text =~ s/^\%-//i )  { $bin = pack( "C", 0x96 ); }
    elsif ( $text =~ s/^\%\*//i ) { $bin = pack( "C", 0x97 ); }
    elsif ( $text =~ s/^\%\///i ) { $bin = pack( "C", 0x98 ); }
    elsif ( $text =~ s/^\%;//i )  { $bin = pack( "C", 0x99 ); }
    elsif ( $text =~ s/^\%,//i )  { $bin = pack( "C", 0x9a ); }
    elsif ( $text =~ s/^\%\.//i ) { $bin = pack( "C", 0x9b ); }
    elsif ( $text =~ s/^\%(\d)//i ) {
        $bin = pack( "C", 0x9c + ord($1) - ord('0') );
    }
    elsif ( $text =~ s/^\%(\w)//i ) {
        $bin = pack( "C", 0xa6 + ord( uc($1) ) - ord('A') );
    }
    elsif ( $text =~ s/^\\\"//i ) { $bin .= pack( "C", 0xC0 ); }
    else                          { die "cannot encode '$text'"; }

    return ( $bin, $text );
}

# enters with the starting quote already consumed
sub encode_string {
    my ($text) = @_;
    my $orig_text = '"' . $text;

    my $str_bin = "";
    while ( $text ne "" && $text !~ /^\"/i ) {
        ( my $char_bin, $text ) = encode_char($text);
        $str_bin .= $char_bin;
    }
    if ( $text =~ /^\"/i ) {
        ( my $quote_bin, $text ) = encode_char($text);
        return ( $quote_bin . $str_bin . $quote_bin, $text );
    }
    else {
        die "unmatched '\"' in $orig_text";
    }
}

sub encode_chars {
    my ($text) = @_;
    my $bin = "";
    while ( $text ne "" ) {
        ( my $char_bin, $text ) = encode_char($text);
        $bin .= $char_bin;
    }
    return $bin;
}

#------------------------------------------------------------------------------

sub encode_float {
    my ($value) = @_;

    # Special case zero
    if ( $value == 0.0 ) {
        return pack( "C5", 0, 0, 0, 0, 0 );
    }

    # Work with the absolute value
    my $sign = ( $value < 0 );
    $value = abs($value);

    # Compute mantissa and exponent
    # frexp gives:
    # num = frac * 2**exp2
    # with 0.5 <= frac < 1
    my ( $frac, $exp2 ) = frexp($value);
    my $exp = $exp2 - 1;

    die "$value out of range" unless $exp >= -129 && $exp <= 126;

    my $normalized = $value / ( 2**$exp );
    my $man        = int( ( $normalized - 1.0 ) * 0x80000000 + 0.5 );

    # Apply the sign bit
    if ($sign) {
        $man |= 0x80000000;    # set sign bit
    }
    else {
        $man &= 0x7fffffff;    # clear sign bit
    }

    # Apply exponent bias
    $exp += 129;

    # pack the result
    return pack( "C C4",
        $exp,
        ( $man >> 24 ) & 0xFF,
        ( $man >> 16 ) & 0xFF,
        ( $man >> 8 ) & 0xFF,
        $man & 0xFF );
}

1;

__END__

#------------------------------------------------------------------------------

=pod

=head1 NAME

ZX81::Tokenize - Tokenize and convert to ZX81 encoding

=head1 SYNOPSIS

    use ZX81::Tokenize qw(tokenize_basic encode_chars);

    my $bytes = tokenize_basic(<<END);
    10 PRINT "HELLO"
    20 GOTO 10
    END
    
    my $bytes = encode_chars("HELLO");

    my $bytes = encode_float(3.141592654);

=head1 DESCRIPTION

Convert ZX81 BASIC source text into the tokenized internal format
used by the Sinclair ZX81.

This module provides the low-level tokenizer used to convert ZX81
BASIC source code into the encoded format used by ZX81 programs.

Modules such as L<ZX81::Tape> can use this encoding to create
complete ZX81 program and tape-image files.

=head1 FUNCTIONS

=head2 tokenize_basic

    my $bytes = tokenize_basic($source);

Convert ZX81 BASIC source code into the tokenized internal format
used by ZX81 programs.

=head2 encode_chars

    my $bytes = encode_chars($text);

Convert text into the ZX81 character encoding without performing
BASIC keyword tokenization.

=head2 encode_float

    my $bytes = encode_float(3.141592654);

Convert a floating point number to the 5-byte representation used 
by the ZX81.

=head1 SEE ALSO

L<ZX81>

=head1 AUTHOR

Paulo Custodio

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 Paulo Custodio.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

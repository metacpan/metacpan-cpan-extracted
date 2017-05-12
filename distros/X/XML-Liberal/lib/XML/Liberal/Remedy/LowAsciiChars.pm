package XML::Liberal::Remedy::LowAsciiChars;
use strict;

my @low_ascii = (0..8, 11..12, 14..31, 127);
my $dec_rx = do {
    my $pat = join '|', @low_ascii;
    qr/$pat/;
};
my $hex_rx = do {
    my $pat = join '|', map { sprintf '%x', $_ } @low_ascii;
    qr/$pat/i;
};

# optimized to fix all errors in one apply() call
sub apply {
    my $class = shift;
    my($driver, $error, $xml_ref) = @_;

    return 0 if $error->message !~
        /^parser error : xmlParseCharRef: invalid xmlChar value $dec_rx\b/;

    return 1 if $$xml_ref =~ s{&#(?:0*$dec_rx|[xX]0*$hex_rx);}{}g;

    Carp::carp("Can't find low ascii bytes, error was: ", $error->summary);
    return 0;
}

1;

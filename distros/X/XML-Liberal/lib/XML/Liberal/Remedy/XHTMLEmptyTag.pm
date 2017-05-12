package XML::Liberal::Remedy::XHTMLEmptyTag;
use strict;

use HTML::Tagset ();

my @ELEMENTS = sort keys %HTML::Tagset::emptyElement;
my $ERROR_RX = do {
    my $pat = join '|', @ELEMENTS;
    qr/^parser error : Opening and ending tag mismatch: (?i:$pat)/;
};
my $TAG_RX = do {
    my $pat = join '|', @ELEMENTS;
    qr{(<((?i:$pat)) (?: \s[^>]*)? ) (?<! /) (?= > (?! \s*</\2\s*>))}x;
};

# optimized to fix all errors in one apply() call
sub apply {
    my $class = shift;
    my($driver, $error, $xml_ref) = @_;

    return if $error->message !~ $ERROR_RX;

    return 1 if $$xml_ref =~ s{$TAG_RX}{$1 /}g;

    Carp::carp("Can't find XHTML empty-element tags, error was: ",
               $error->summary);
    return 0;
}

1;

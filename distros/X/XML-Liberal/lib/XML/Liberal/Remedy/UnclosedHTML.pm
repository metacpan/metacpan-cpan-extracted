package XML::Liberal::Remedy::UnclosedHTML;
use strict;

use HTML::Tagset ();

my $ERROR_RX = do {
    # Exclude void elements
    my $pat = join '|', reverse sort grep { !$HTML::Tagset::emptyElement{$_} }
        keys %HTML::Tagset::isKnown;
    qr/^parser error : Opening and ending tag mismatch: ((?i:$pat)) line \d+ and (\S+)/
};

sub apply {
    my $class = shift;
    my($driver, $error, $xml_ref) = @_;

    my ($unclosed, $detected) = $error->message =~ $ERROR_RX or return 0;

    my $index = $error->location;
    my $tail = substr $$xml_ref, $index, length($$xml_ref) - $index, '';

    return 1 if $$xml_ref =~ s{( </ \Q$detected\E \s* > \z )}{</$unclosed>$1$tail}xms;

    Carp::carp("Can't find incorrect close tag");
    return 0;
}

1;

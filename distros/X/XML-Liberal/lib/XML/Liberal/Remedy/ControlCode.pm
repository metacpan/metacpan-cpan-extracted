package XML::Liberal::Remedy::ControlCode;
use strict;

my $ERROR_RX = do {
    my $pat = join '|', (
        'CData section not finished',
        'PCDATA invalid Char value \d+',
        'Char 0x[0-9A-F]+ out of allowed range',
    );
    qr/^parser error : (?:$pat)/;
};

sub apply {
    my $class = shift;
    my($driver, $error, $xml_ref) = @_;

    return 0 if $error->message !~ $ERROR_RX;
    return 1 if $$xml_ref =~ s/[\x00-\x08\x0b-\x0c\x0e-\x1f\x7f]+//g;

    Carp::carp("Can't find control code line, error was: ", $error->summary);
    return 0;
}

1;

package XML::Liberal::Remedy::Declaration;
use strict;

# optimized to fix all errors in one apply() call
sub apply {
    my $class = shift;
    my($driver, $error, $xml_ref) = @_;

    return 0 if $error->message !~
        /^parser error : XML declaration allowed only at the start of the document/;

    return 1 if $$xml_ref =~ s/^\s+(?=<)//;  # s/^[^<]+//

    Carp::carp("No whitespace found at the start of the document, error was: ",
               $error->summary);
    return 0;
}

1;

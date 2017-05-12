package XML::Liberal::Remedy::TrailingDoctype;
use strict;

sub apply {
    my $class = shift;
    my($driver, $error, $xml_ref) = @_;

    return 0 if $error->message !~
        /^parser error : Extra content at the end of the document/;

    pos($$xml_ref) = $error->location;
    return $$xml_ref =~ s{\G <!doctype .*?> }{}xmsi;
}

1;

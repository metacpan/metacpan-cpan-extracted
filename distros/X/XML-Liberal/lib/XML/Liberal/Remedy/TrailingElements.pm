package XML::Liberal::Remedy::TrailingElements;
use strict;

sub apply {
    my $class = shift;
    my($driver, $error, $xml_ref) = @_;

    return 0 if $error->message !~
        /^parser error : Extra content at the end of the document/;

    my $pos = $error->location;
    pos($$xml_ref) = $pos;
    return 0 if $$xml_ref !~ /\G <[-:\w]+ (?:[>\s]|\z)/xms;

    while ($pos > 0) {
        pos($$xml_ref) = $pos--;
        return 1 if $$xml_ref =~ s{\G (</[^\s<>/]+ \s*>) (.*)}{$2$1}xms;
    }

    return 0;
}

1;

package XML::Liberal::Remedy::NestedCDATA;
use strict;

use HTML::Entities qw( encode_entities );

sub apply {
    my $class = shift;
    my($driver, $error, $xml_ref) = @_;

    return 0 if $error->message !~ /^parser error : Opening and ending tag mismatch:/;

    while ($$xml_ref =~ /(?<= <!\[CDATA\[ ) (.*? \]\]> )/xmsg) {
        my ($cdata, $start, $end) = ($1, $-[1], $+[1]);
        next if $cdata !~ /<!\[CDATA\[/;
        my $escaped = encode_entities($cdata, '<>&');
        substr($$xml_ref, $start, $end - $start) = "]]>$escaped<![CDATA[";
        return 1;
    }

    return 0;
}

1;

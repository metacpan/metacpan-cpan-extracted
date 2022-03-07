package XML::Liberal::Remedy::StandaloneAttribute;
use strict;

use List::Util qw( min );

sub apply {
    my $class = shift;
    my($driver, $error, $xml_ref) = @_;

    my ($attr) = $error->message =~
        /^parser error : Specification mandates? value for attribute (\w+)/
            or return 0;

    # In input like "<hr noshade />", the error location points to the slash
    # -- the first non-whitespace character after the attribute name.  We
    # can just insert an attribute value at that point; no need to look
    # backwards for where the attribute name starts or ends.
    substr $$xml_ref, $error->location, 0, qq[="$attr" ];
    return 1;
}

1;

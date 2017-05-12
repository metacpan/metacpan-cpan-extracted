package XML::Liberal::Remedy::EntityRef;
use strict;

sub apply {
    my $class = shift;
    my($driver, $error, $xml_ref) = @_;

    return 0 if $error->message !~
        /^parser error : (?:EntityRef: expecting ';'|xmlParseEntityRef: no name)/;

    # If the document doesn't contain any PIs or CDATA sections, we might as
    # well try to fix all broken entity references and named character
    # references in one go.  (If it does contain one of those, fixing
    # everything would risk changing the content in ways the author wouldn't
    # expect.)
    #
    # In principle, we should take care not to change comments either; but
    # in practice, I'm prepared to consider comments fair game, given that
    # the author can preserve them by merely generating a well-formed XML
    # document.
    if ($$xml_ref !~ / .<\? | <!\[CDATA\[/xms) {
        return 1 if $$xml_ref =~
            s/&(?!\w+;|#(?:x[a-fA-F0-9]+|\d+);)/&amp;/g;
    }
    else {
        my $pos = $error->location;
        while ($pos > 0) {
            pos($$xml_ref) = $pos--;
            return 1 if $$xml_ref =~ s/\G&/&amp;/
        }
    }

    Carp::carp("Can't find unescaped &, error was: ", $error->summary);
    return 0;
}

1;

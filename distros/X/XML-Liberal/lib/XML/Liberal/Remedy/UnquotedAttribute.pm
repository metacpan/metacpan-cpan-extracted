package XML::Liberal::Remedy::UnquotedAttribute;
use strict;

use List::Util qw( min );

sub apply {
    my $class = shift;
    my($driver, $error, $xml_ref) = @_;

    return 0 if $error->message !~ /^parser error : AttValue: \" or \' expected/;

    pos($$xml_ref) = $error->location;
    return 1 if $$xml_ref =~ s/\G([^\s>"]*)/"$1"/;

    Carp::carp("Can't find unquoted attribute in line, error was: ",
               $error->summary);
    return 0;
}

1;

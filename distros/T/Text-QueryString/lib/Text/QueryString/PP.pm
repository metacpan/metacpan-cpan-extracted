package Text::QueryString::PP;
use strict;
use URI::Escape ();
use constant BACKEND => "PP";

# Stolen from URI::_query, and modified a bit
sub parse {
    my ($self, $query_string) = @_;
    my @query;
    if ($query_string =~ /=/) {
        # Handle  ?foo=bar&bar=foo type of query
        @query =
            map { s/\+/ /g; URI::Escape::uri_unescape($_) }
            map { /=/ ? split(/=/, $_, 2) : ($_ => '')}
            split(/[&;]/, $query_string);
    } else {
        # Handle ...?dog+bones type of query
        @query =
            map { (URI::Escape::uri_unescape($_), '') }
            split(/\+/, $query_string, -1);
    }
    return @query;
}

1;
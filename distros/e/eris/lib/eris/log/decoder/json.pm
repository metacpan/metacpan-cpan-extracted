package eris::log::decoder::json;
# ABSTRACT: Decodes any detected JSON in a log line from then opening curly brace

use JSON::MaybeXS;
use Moo;
use namespace::autoclean;

with qw(
    eris::role::decoder
);

our $VERSION = '0.008'; # VERSION


sub _build_priority { 99; }


sub decode_message {
    my ($self,$msg) = @_;
    my $decoded;
    # JSON Docs will start with a '{', check for it.
    my $start = index($msg, '{');
    if( $start >= 0 ) {
        my $json_str = substr($msg, $start);
        eval {
            $decoded = decode_json( $json_str );
            1;
        };
    }
    return $decoded;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

eris::log::decoder::json - Decodes any detected JSON in a log line from then opening curly brace

=head1 VERSION

version 0.008

=head1 SYNOPSIS

This decoder checks for the presence of an opening curly brace in the raw
message.  If detected, it assumes the entire rest of the string is valid JSON
and attempted to decode.

This means the whole message doesn't need to be JSON, so you can syslog JSON
and the L<eris::log::decoder::syslog> will properly handle the syslog headers
and structure.  This decoder will then grab that JSON hashref and parse it
correctly.

=head1 ATTRIBUTES

=head2 priority

Defaults to 99, run almost last

=head1 METHODS

=head2 decode_message

Takes a raw string. Find the first occurrence of an opening curly brace '{' and parses
from that point to the end of the message as if it were valid JSON.

=head1 SEE ALSO

L<eris::log::decoders>, L<eris::role::decoder>, L<JSON::MaybeXS>

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

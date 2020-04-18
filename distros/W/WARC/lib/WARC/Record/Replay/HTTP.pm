package WARC::Record::Replay::HTTP;				# -*- CPerl -*-

use strict;
use warnings;

use WARC; *WARC::Record::Replay::HTTP::VERSION = \$WARC::VERSION;

=for autoload
[WARC::Record::Replay]
field(Content-Type)=^application/http

=cut

our $Content_Deferred_Loading_Threshold;
our $Content_Maximum_Length;

# set defaults only if not already set
$Content_Deferred_Loading_Threshold = 2 * (1<<20)	#   2 MiB
  unless defined $Content_Deferred_Loading_Threshold;
$Content_Maximum_Length = 128 * (1<<20)			# 128 MiB
  unless defined $Content_Maximum_Length;

# From RFC2616:

#	CHAR		= <any US-ASCII character (octets 0 - 127)>
#	CTL		= <any US-ASCII control character
#			   (octets 0 - 31) and DEL (127)>
#	LWS		= [CRLF] 1*( SP | HT )
#	separators	= "(" | ")" | "<" | ">" | "@"
#			| "," | ";" | ":" | "\" | <">
#			| "/" | "[" | "]" | "?" | "="
#			| "{" | "}" | SP | HT
#	token		= 1*<any CHAR except CTLs or separators>

our $HTTP__LWS =		qr/(?:\015\012)?[ \t]+/;
our $HTTP__separator =		qr[[][)(><}{@,;:/"\\?=[:space:]]];
our $HTTP__not_separator =	qr[[^][)(><}{@,;:/"\\?=[:space:]]];
our $HTTP__token =		qr/[!#$%'*+-.0-9A-Z^_`a-z|~]+/;
our $HTTP__Version =		qr[HTTP/\d+.\d+];

#	Request-Line	= Method SP Request-URI SP HTTP-Version CRLF
#	Status-Line	= HTTP-Version SP Status-Code SP Reason-Phrase CRLF

our $HTTP__Request_Line = qr[^($HTTP__token)\s+([^ ]+)\s+($HTTP__Version)$];
our $HTTP__Status_Line  = qr[^($HTTP__Version)\s+(\d{3})\s+(.*)$];

use constant HTTP_PARSE_REs =>
  qw/ HTTP__LWS HTTP__separator HTTP__not_separator HTTP__token HTTP__Version
      HTTP__Request_Line HTTP__Status_Line /;

require WARC::Record::Replay::HTTP::Message;
require WARC::Record::Replay::HTTP::Request;
require WARC::Record::Replay::HTTP::Response;

1;
__END__

=head1 NAME

WARC::Record::Replay::HTTP - HTTP protocol replay hub module

=head1 SYNOPSIS

  use WARC::Record;

  $record->replay;		# if record is an HTTP request or response
  $record->replay(as => 'http');# if translation to HTTP is desired

=head1 DESCRIPTION

This is an internal module that defines a few global variables and loads
other modules for HTTP replay support.

=over

=item $WARC::Record::Replay::HTTP::Content_Deferred_Loading_Threshold

This sets the maximum length, in bytes, of an HTTP entity body that will be
immediately loaded when replaying an HTTP message.  Messages larger than
this trigger deferred loading.

=item $WARC::Record::Replay::HTTP::Content_Maximum_Length

This sets the maximum length, in bytes, of an HTTP entity body that will be
loaded upon demand.  Messages larger than this cause the method call for
retrieving the content to croak instead.

=back

=head1 CAVEATS

The "previous" method on a replayed HTTP response is currently a stub.

=head1 AUTHOR

Jacob Bachmeyer, E<lt>jcb@cpan.orgE<gt>

=head1 SEE ALSO

L<WARC::Record>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Jacob Bachmeyer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

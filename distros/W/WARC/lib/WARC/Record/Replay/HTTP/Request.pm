package WARC::Record::Replay::HTTP::Request;			# -*- CPerl -*-

use strict;
use warnings;

require HTTP::Request;
require WARC::Record::Replay::HTTP::Message;
our @ISA = qw(WARC::Record::Replay::HTTP::Message HTTP::Request);

use WARC; *WARC::Record::Replay::HTTP::Request::VERSION = \$WARC::VERSION;

require WARC::Record::Replay;

WARC::Record::Replay::register
  { $_->field('Content-Type') =~ m|^application/http; msgtype=request| }
  \&_load_record;
WARC::Record::Replay::register
  { $_->field('Content-Type') =~ m|^application/http| && $_->type eq 'request' }
  \&_load_record;

BEGIN {
  use WARC::Record::Replay::HTTP;
  $WARC::Record::Replay::HTTP::Request::{$_} =
    $WARC::Record::Replay::HTTP::{$_}
      for WARC::Record::Replay::HTTP::HTTP_PARSE_REs;
}


sub _load_record {
  my $record = shift;

  my $handle = $record->open_continued;

  if ($record->field('Content-Length')
      < $WARC::Record::Replay::HTTP::Content_Deferred_Loading_Threshold) {
    # The entire WARC block is smaller than the deferred loading threshold;
    # this is an easy special case.
    my $block;
    {
      local $/ = undef;	# slurp
      $block = <$handle>;
    }
    my $request = HTTP::Request->parse($block);
    return $request->protocol =~ $HTTP__Version ? $request : undef;
  }

  my $method; my $uri; my $http_version;
  {
    local $/ = "\012";
    my $line = <$handle>;
    $line =~ s/[[:space:]]+$//; # trim trailing CR if present
    return undef unless $line =~ $HTTP__Request_Line;
    # $1 -- HTTP Method		$2 -- Request-URI	$3 -- HTTP-Version
    $method = $1; $uri = $2; $http_version = $3;
  }

  my $ob = HTTP::Request->new($method, $uri);
  $ob->protocol($http_version);

  WARC::Record::Replay::HTTP::Message::_load_record($ob, $record, $handle);
}

1;
__END__

=head1 NAME

WARC::Record::Replay::HTTP::Request - HTTP request loaded from WARC record

=head1 SYNOPSIS

  use WARC::Record;

  $request = $record->replay;	# if $record is an HTTP request

=head1 DESCRIPTION

...

=head1 AUTHOR

Jacob Bachmeyer, E<lt>jcb@cpan.orgE<gt>

=head1 SEE ALSO

L<WARC::Record>, L<HTTP::Request>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Jacob Bachmeyer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

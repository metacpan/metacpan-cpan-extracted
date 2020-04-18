package WARC::Record::Replay::HTTP::Response;			# -*- CPerl -*-

use strict;
use warnings;

require HTTP::Response;
require WARC::Record::Replay::HTTP::Message;
our @ISA = qw(WARC::Record::Replay::HTTP::Message HTTP::Response);

use WARC; *WARC::Record::Replay::HTTP::Response::VERSION = \$WARC::VERSION;

require WARC::Record::Replay;

WARC::Record::Replay::register
  { $_->field('Content-Type') =~ m|^application/http; msgtype=response| }
  \&_load_record;
WARC::Record::Replay::register
  { $_->field('Content-Type') =~ m|^application/http| && $_->type eq 'response' }
  \&_load_record;

BEGIN {
  use WARC::Record::Replay::HTTP;
  $WARC::Record::Replay::HTTP::Response::{$_} =
    $WARC::Record::Replay::HTTP::{$_}
      for WARC::Record::Replay::HTTP::HTTP_PARSE_REs;
}

sub _load_record {
  my $record = shift;

  my $handle = $record->open_continued;
  my $ob;

  if ($record->field('Content-Length')
      < $WARC::Record::Replay::HTTP::Content_Deferred_Loading_Threshold) {
    # The entire WARC block is smaller than the deferred loading threshold;
    # this is an easy special case.
    my $block;
    {
      local $/ = undef;	# slurp
      $block = <$handle>;
    }
    # Work around a bug in LWP that can append a trailing CR to the status
    # message in an HTTP response parsed from a string.
    #
    #  The response status message can contain spaces and LWP uses the
    #   LIMIT parameter to split to collect all text after the status code.
    #   This causes the parsed message to include the trailing CR.
    #
    #  This problem does not occur with requests; the protocol version in a
    #   request cannot contain spaces, so the trailing CR is counted as
    #   whitespace and removed as the delimiter for a trailing empty field.
    my $response = HTTP::Response->parse($block);
    { my $m;
      if (($m = $response->message) =~ s/\015\z//) { $response->message($m) } }
    if ($response->protocol =~ $HTTP__Version)
      { $ob = $response; close $handle; $handle = undef }
    else
      { return undef }
  } else {
    my $code; my $reason; my $http_version;
    {
      local $/ = "\012";
      my $line = <$handle>;
      $line =~ s/[[:space:]]+$//; # trim trailing CR if present
      return undef unless $line =~ $HTTP__Status_Line;
      # $1 -- HTTP-Version	$2 -- Status-Code	$3 -- Reason-Phrase
      $http_version = $1; $code = $2; $reason = $3;
    }

    $ob = HTTP::Response->new($code, $reason);
    $ob->protocol($http_version);
  }

  $ob->{_warc_defer}{request} = 1;

  WARC::Record::Replay::HTTP::Message::_load_record($ob, $record, $handle);
}

## overridden methods for deferred loading of requests and redirects
sub request {
  my $self = shift;

  if ($self->{_warc_defer}{request} && $self->{_warc_record}{collection}) {
    # replay other record
    my $timestamp = $self->{_warc_record}->date;
    my @requests = grep { $_->type eq 'request' and $_->date <= $timestamp }
      ($self->{_warc_record}{collection}->search
       (record_id => $self->{_warc_record}->fields->{'WARC-Concurrent-To'},
	time => $timestamp)); # sorted by nearest timestamp
    # filter removes all records after "this" record
    # Therefore the list is sorted/filtered to "timestamp descending"
    my $record = $requests[0]; # use latest record from the list

    $self->SUPER::request($record->replay) if $record;
    $self->{_warc_defer}{request} = 0;
  }

  return $self->SUPER::request(@_)
}

sub previous {
  my $self = shift;

  # This is a stub until a good way to find these is found.
  # Additional metadata and/or index support will probably be needed.
  # Lack of support is documented in WARC::Record::Replay::HTTP.

  return $self->SUPER::previous(@_)
}

1;
__END__

=head1 NAME

WARC::Record::Replay::HTTP::Response - HTTP response loaded from WARC record

=head1 SYNOPSIS

  use WARC::Record;

  $response = $record->replay;	# if $record is an HTTP response

=head1 DESCRIPTION

...

=head1 AUTHOR

Jacob Bachmeyer, E<lt>jcb@cpan.orgE<gt>

=head1 SEE ALSO

L<WARC::Record>, L<HTTP::Response>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019, 2020 by Jacob Bachmeyer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

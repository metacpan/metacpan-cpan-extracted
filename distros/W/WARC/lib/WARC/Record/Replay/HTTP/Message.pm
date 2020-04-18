package WARC::Record::Replay::HTTP::Message;			# -*- CPerl -*-

use strict;
use warnings;

use Carp;
use Fcntl qw(:seek);

require HTTP::Message;
our @ISA = qw(HTTP::Message);

use WARC; *WARC::Record::Replay::HTTP::Message::VERSION = \$WARC::VERSION;

require WARC::Record::Replay;

BEGIN {
  use WARC::Record::Replay::HTTP;
  $WARC::Record::Replay::HTTP::Message::{$_} =
    $WARC::Record::Replay::HTTP::{$_}
      for WARC::Record::Replay::HTTP::HTTP_PARSE_REs;
}

sub _load_record {
  my $ob = shift;	# partially constructed request/response object
  my $record = shift;	# WARC::Record object
  my $handle = shift;	# open handle for reading record data or undef

  local *_;

  $ob->{_warc_record} = $record;

  if ($handle) {
  # Read headers from $handle.
    {
      my @headers = ();
      local $/ = "\012";
      while (<$handle>) {
	s/[\015\012]+$//;
	if (m/^($HTTP__token):\s+(.*)/o)	# $1 -- name	$2 -- value
	  { push @headers, $1, $2 }
	elsif (m/^(\s+\S.*)$/)			# $1 -- continued value
	  { $headers[-1] .= $1 }
	elsif (m/^$/) { last }
	else { warn "unrecogized input:  $_"; return undef }
      }
      local $HTTP::Headers::TRANSLATE_UNDERSCORE;
      $ob->headers->push_header(@headers);
    }

    my $data_offset = tell *$handle;
    $ob->{_warc_data_offset} = $data_offset;
    $record->{payload_offset} = $data_offset;

    # Decide whether to read or defer loading the message body.
    if ($record->field('Content-Length') == $data_offset) {
      # There is no content.  Set an empty message body.
      $ob->content('')
    } elsif (($record->field('Content-Length') - $data_offset)
	     < $WARC::Record::Replay::HTTP::Content_Deferred_Loading_Threshold) {
      # After reading headers, the length of the remaining data is less than
      # the deferred loading threshold.  Load the message body immediately.
      { local $/ = undef; $ob->content(<$handle>) } # slurp data
    } else {
      # Defer loading the message body.
      $ob->{_warc_defer}{content} = 1
    }
  }

  bless $ob, 'WARC::Record::Replay::'.(ref $ob)
    if scalar grep $ob->{_warc_defer}{$_}, keys %{$ob->{_warc_defer}};

  return $ob;
}

sub _load_content {
  my $self = shift;

  croak "loading content larger than maximum length"
    unless (($self->{_warc_record}->field('Content-Length')
	     - $self->{_warc_data_offset})
	    < $WARC::Record::Replay::HTTP::Content_Maximum_Length);

  my $handle = $self->{_warc_record}->open_continued;
  seek($handle, $self->{_warc_data_offset}, SEEK_SET) or confess "seek: $!";
  { local $/ = undef; $self->SUPER::content(<$handle>) } # slurp data

  $self->{_warc_defer}{content} = 0;
}

## overridden methods for deferred message body loading
sub content {
  my $self = shift;

  $self->_load_content if $self->{_warc_defer}{content};

  return $self->SUPER::content(@_);
}

sub content_ref {
  my $self = shift;

  $self->_load_content if $self->{_warc_defer}{content};

  return $self->SUPER::content_ref(@_);
}

1;
__END__

=head1 NAME

WARC::Record::Replay::HTTP::Message - HTTP message loaded from WARC record

=head1 SYNOPSIS

  use WARC::Record;

  $message = $record->replay;	# if $record is an HTTP message

=head1 DESCRIPTION

The C<WARC::Record::Replay::HTTP::Message> class is the internal
implementation supporting deferred loading of HTTP entity bodies.

=head1 AUTHOR

Jacob Bachmeyer, E<lt>jcb@cpan.orgE<gt>

=head1 SEE ALSO

L<WARC::Record>, L<HTTP::Message>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Jacob Bachmeyer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

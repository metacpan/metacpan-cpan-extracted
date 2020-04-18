package WARC::Record;						# -*- CPerl -*-

use strict;
use warnings;

use Carp;
use Scalar::Util;

our @ISA = qw();

require WARC; *WARC::Record::VERSION = \$WARC::VERSION;
require WARC::Date;

=head1 NAME

WARC::Record - one record from a WARC file

=head1 SYNOPSIS

  use WARC;		# or ...
  use WARC::Volume;	# or ...
  use WARC::Collection;

  # WARC::Record objects are returned from ->record_at and ->search methods

  # Construct a record, as when preparing a WARC file
  $warcinfo = new WARC::Record (type => 'warcinfo');

  # Accessors

  $value = $record->field($name);

  $version = $record->protocol;	# analogous to HTTP::Message::protocol
  $volume = $record->volume;
  $offset = $record->offset;
  $record = $record->next;

  $fields = $record->fields;

  # Supply a data block for an in-memory record
  $warcinfo->block(new WARC::Fields ( ... ));

=cut

use overload '<=>' => 'compareTo', 'cmp' => 'compareTo';
use overload fallback => 1;

# This implementation uses a hash as the underlying object.
#  Keys defined by this class:
#
#   fields
#	Embedded WARC::Fields object
#
#  Keys defined by this class but overridden and unused in subclasses:
#
#   block
#	Data block for this record

sub _dbg_dump {
  my $self = shift;

  my $out = "WARC record [dumping as base class]\n";
  my @out = map {s/^/  /gm; $_} $self->fields->as_string;
  $out .= join("\n", @out);

  return $out;
}

=head1 DESCRIPTION

C<WARC::Record> objects come in two flavors with a common interface.
Records read from WARC files are read-only and have meaningful return
values from the methods listed in "Methods on records from WARC files".
Records constructed in memory can be updated and those same methods all
return undef.

=head2 Common Methods

=over

=item $record-E<gt>fields

Get the internal C<WARC::Fields> object that contains WARC record headers.

=cut

sub fields { (shift)->{fields} }

=item $record-E<gt>field( $name )

Get the value of the WARC header named $name from the internal
C<WARC::Fields> object.

=cut

sub field {
  my $self = shift;
  return $self->fields->field(shift);
}

=item $record E<lt>=E<gt> $other_record

=item $record-E<gt>compareTo( $other_record )

Compare two C<WARC::Record> objects according to a simple total order:
ordering by starting offset for two records in the same file, and by
filename of the containing C<WARC::Volume> objects for records in different
files.  Constructed C<WARC::Record> objects are assumed to come from a
volume named "" (the empty string) for this purpose, and are ordered in an
arbitrary but stable manner amongst themselves.  Distinct constructed
C<WARC::Record> objects never compare as equal.

Perl constructs a C<==> operator using this method, so WARC record objects
will compare as equal iff they refer to the same physical record.

=cut

sub compareTo {
  my $a = shift;
  my $b = shift;
  my $swap = shift;

  # sort in-memory-only records ahead of on-disk records
  return $swap ? 1 : -1 if defined $b->volume;

  # neither record is from a WARC volume
  my $cmp = (Scalar::Util::refaddr $a) <=> (Scalar::Util::refaddr $b);

  return $swap ? 0-$cmp : 0+$cmp;
}

=back

=head3 Convenience getters

=over

=item $record-E<gt>type

Alias for C<$record-E<gt>field('WARC-Type')>.

=cut

sub type { (shift)->field('WARC-Type') }

=item $record-E<gt>id

Alias for C<$record-E<gt>field('WARC-Record-ID')>.

=cut

sub id { (shift)->field('WARC-Record-ID') }

=item $record-E<gt>content_length

Alias for C<$record-E<gt>field('Content-Length')>.

=cut

sub content_length { (shift)->field('Content-Length') }

=item $record-E<gt>date

Return the C<'WARC-Date'> field as a C<WARC::Date> object.

=cut

sub date { WARC::Date->from_string((shift)->field('WARC-Date')) }

=back

=head2 Methods on records from WARC files

These methods all return undef if called on a C<WARC::Record> object that
does not represent a record in a WARC file.

=over

=item $record-E<gt>protocol

Return the format and version tag for this record.  For WARC 1.0, this
method returns 'WARC/1.0'.

=cut

sub protocol { return undef }

=item $record-E<gt>volume

Return the C<WARC::Volume> object representing the file in which this
record is located.

=cut

sub volume { return undef }

=item $record-E<gt>offset

Return the file offset at which this record can be found.

=cut

sub offset { return undef }

=item $record-E<gt>logical

Return the logical record object for this record.  Logical records
reassemble WARC continuation segments.  Records recorded without using WARC
segmentation are their own logical records.  Reassembled logical records
are also their own logical records.

=cut

sub logical { return undef }

=item $record-E<gt>segments

Return a list of segments for this record.  A record recorded without using
WARC segmentation, including a segment of a larger logical record, is
considered its own only segment.  A constructed record is considered to
have no segments at all.

This method exists on all records to allow
C<$record-E<gt>logical-E<gt>segments> to work.

=cut

sub segments { return () }

=item $record-E<gt>next

Return the next C<WARC::Record> in the WARC file that contains this record.
Returns an undefined value if called on the last record in a file.

=cut

sub next { return undef }

=item $record-E<gt>open_block

Return a tied filehandle that reads the WARC record block.

The WARC record block is the content of a WARC record, analogous to the
entity body in an C<HTTP::Message>.

=cut

sub open_block { return undef }

=item $record-E<gt>open_continued

Return a tied filehandle that reads the logical WARC record block.

For records that do not use WARC segmentation, this is effectively an alias
for C<$record-E<gt>open_block>.  For records that span multiple segments,
this is an alias for C<$record-E<gt>logical-E<gt>open_block>.

=cut

sub open_continued { return undef }

=item $record-E<gt>replay

=item $record-E<gt>replay( as =E<gt> $type )

Return a protocol-specific object representing the record contents.

This method returns undef if the library does not recognize the protocol
message stored in the record and croaks if a requested conversion is not
supported.

A record with Content-Type "application/http" with an appropriate "msgtype"
parameter produces an C<HTTP::Request> or C<HTTP::Response> object.  The
returned object may be a subclass to support deferred loading of entity
bodies.

A request to replay a record "as =E<gt> http" attempts to convert whatever
is stored in the record to an HTTP exchange, analogous to the "everything
is HTTP" interface that C<LWP> provides.

=cut

sub replay { return undef }

=item $record-E<gt>open_payload

Return a tied filehandle that reads the WARC record payload.

The WARC record payload is defined as the decoded content of the protocol
response or other resource stored in the record.  This method returns undef
if called on a WARC record that has no payload or that has content that we
do not recognize.

=cut

sub open_payload { return undef }

=back

=head2 Methods on fresh WARC records

=over

=item $record = new WARC::Record (I<key> =E<gt> I<value>, ...)

Construct a fresh WARC record, suitable for use with C<WARC::Builder>.

=cut

sub new {
  my $class = shift;
  my %opt = @_;

  foreach my $name (qw/type/)
    { croak "required field '$name' not specified" unless $opt{$name} }

  my $fields = new WARC::Fields ('WARC-Type' => $opt{type});

  bless { fields => $fields }, $class;
}

=item $record-E<gt>block

=item $record-E<gt>block( $new_value )

Get or set the block contents of an in-memory record.  This method returns
undef if called on a WARC record from a volume and croaks if setting the
contents is attempted on a record from a volume.

=cut

sub block {
  my $self = shift;
  my $block = $self->{block};

  if (@_) {
    my $new = shift;

    if (ref $new) {
      if ($new->can('as_block'))
	{ $self->{block} = $new->as_block }
      elsif ($new->isa('HTTP::Message'))
	{ $self->{block} = $new->as_string(WARC::CRLF()) }
      elsif ($new->can('as_string'))
	{ $self->{block} = $new->as_string }
      else
	{ croak "unrecognized object submitted as WARC record block" }
    } else { $self->{block} = $new }

    use bytes;
    $self->{fields}->field('Content-Length', length $self->{block});
  }

  return $block;
}

=back

=cut

1;
__END__

=head2 Quick Reference to Record Types and Field Names

The WARC specification defines eight standard record types and nineteen
standard named fields, at length across several pages.  This section is a
brief summary with emphasis on the applicability of the standard named
fields to the standard record types.

=head3 Record Types

=over

=item S<C<[I Z<> Z<> Z<> Z<> Z<> Z<> ]>> warcinfo

=item S<C<[ M Z<> Z<> Z<> Z<> Z<> ]>> metadata

=item S<C<[ Z<> S Z<> Z<> Z<> Z<> ]>> resource

=item S<C<[ Z<> Z<> Q Z<> Z<> Z<> ]>> request

=item S<C<[ Z<> Z<> Z<> P Z<> Z<> ]>> response

=item S<C<[ Z<> Z<> Z<> Z<> V Z<> ]>> revisit

=item S<C<[ Z<> Z<> Z<> Z<> Z<> R ]>> conversion

=item S<C<[ Z<> Z<> Z<> Z<> Z<> Z<> T]>> continuation

=back

=head3 Field Names

=over

=item S<C<[IMSQPVRT]>>
Content-Type I<MIME-type>

=item S<C<[IMSQPVRT]>>
Content-Length I<octet-count>

=item S<C<[IMSQPVRT]>>
WARC-Type I<type-name>

=item S<C<[IMSQPVRT]>>
WARC-Date I<datestamp>

=item S<C<[IMSQPVRT]>>
WARC-Record-ID I<URI-for-record-ID>

=item S<C<[ MSQPVRT]>>
WARC-Warcinfo-ID I<record-ID>

=item S<C<[ MSQPV Z<> ]>>
WARC-Concurrent-To I<record-ID>

=item S<C<[ M Z<> Z<> VR ]>>
WARC-Refers-To I<record-ID>

=item S<C<[IMSQPVRT]>>
WARC-Block-Digest I<digest>

=item S<C<[IMSQPVRT]>>
WARC-Payload-Digest I<digest>

=item S<C<[ Z<> SQPVRT]>>
WARC-Identified-Payload-Type I<MIME type>

=item S<C<[ MSQPVRT]>>
WARC-Target-URI I<URI>

=item S<C<[ MSQPV Z<> ]>>
WARC-IP-Address I<address>

=item S<C<[IMSQPVRT]>>
WARC-Truncated I<reason>

=item S<C<[IMSQPVRT]>>
WARC-Segment-Number I<ordinal>

=item S<C<[ Z<> Z<> Z<> Z<> Z<> Z<> T]>>
WARC-Segment-Origin-ID I<record-ID>

=item S<C<[ Z<> Z<> Z<> Z<> Z<> Z<> T]>>
WARC-Segment-Total-Length I<octet-count>

=item S<C<[I Z<> Z<> Z<> Z<> Z<> Z<> ]>>
WARC-Filename I<original-WARC-filename>

=item S<C<[ Z<> Z<> Z<> Z<> V Z<> ]>>
WARC-Profile I<namespace-URI>

=back

=head3 Required ("shall") Fields

=over

=item All records require:  (listed once instead of in every set)

    WARC-Type
    WARC-Date
    WARC-Record-ID
    Content-Length

=item Any record written using WARC segmentation requires:

    WARC-Segment-Number
      This always has the value "1" if present, except in "continuation"
      records, where it provides the segment ordering.

=item Last continuation record in a segmented record requires:

    WARC-Segment-Total-Length
      This is the "Content-Length" of the reassembled record.

=item Type "resource" requires:

    WARC-Target-URI

=item Type "request" requires:

    WARC-Target-URI

=item Type "response" requires:

    WARC-Target-URI

=item Type "revisit" requires:

    WARC-Target-URI
    WARC-Profile

=item Type "conversion" requires:

    WARC-Target-URI

=item Type "continuation" requires:

    WARC-Target-URI
    WARC-Segment-Number
    WARC-Segment-Origin-ID

=back

=head3 Recommended ("should") and Available ("may") Fields

=over

=item All records

    Content-Type
      Default is "application/octet-stream" or the result of analysis.
      This default should not be relied upon and this header should be
      used.  May be safely omitted if Content-Length is zero.
    WARC-Block-Digest
    WARC-Truncated

=item Any record that has a "well-defined payload"

    WARC-Payload-Digest
    WARC-Identified-Payload-Type

=item Any record not of type "warcinfo"

    WARC-Warcinfo-ID

=item Type "warcinfo"

    WARC-Filename

=item Type "metadata"

    WARC-Concurrent-To
    WARC-Refers-To
    WARC-Target-URI
    WARC-IP-Address

=item Type "resource"

    WARC-Concurrent-To
    WARC-IP-Address

=item Type "request"

    WARC-Concurrent-To
    WARC-IP-Address

=item Type "response"

    WARC-Concurrent-To
    WARC-IP-Address

=item Type "revisit"

    WARC-Concurrent-To
    WARC-Refers-To
    WARC-IP-Address

=item Type "conversion"

    WARC-Refers-To

=back

=head1 AUTHOR

Jacob Bachmeyer, E<lt>jcb@cpan.orgE<gt>

=head1 SEE ALSO

L<WARC>, L<HTTP::Message>

L<WARC::Builder/"Extension subfield 'sl' in gzip header">

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Jacob Bachmeyer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

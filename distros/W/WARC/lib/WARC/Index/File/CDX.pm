package WARC::Index::File::CDX;					# -*- CPerl -*-

use strict;
use warnings;

require WARC::Index;
our @ISA = qw(WARC::Index);

require WARC; *WARC::Index::File::CDX::VERSION = \$WARC::VERSION;

use Carp;
use File::Spec;
use Fcntl 'SEEK_SET';
require File::Spec::Unix;

require WARC::Date;
require WARC::Index::File::CDX::Entry;
require WARC::Volume;

WARC::Index::register(filename => qr/[.]cdx$/);

our %CDX_Field_Index_Key_Map =
  (a => 'url', b => 'time', u => 'record_id');

our %CDX_Import_Map =
  (time => sub {
     my $cdx_date = shift;
     croak "invalid CDX datestamp"
       unless $cdx_date =~ m/^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})$/;
     return WARC::Date->from_string(sprintf('%04d-%02d-%02dT%02d:%02d:%02dZ',
					       $1,  $2,  $3,  $4,  $5,  $6))},
  );

# This implementation uses a hash as the underlying structure.
#  Keys defined by this class:
#
#   cdx_file
#	file name of CDX file
#   delimiter
#	delimiter character used in CDX file
#   fields
#	array of CDX field codes, in order
#   field_index
#	hash mapping CDX field code letter => position
#   key_index
#	hash mapping WARC::Index search keys => position
#   volumes
#	hash mapping WARC file names => WARC::Volume objects

sub _dbg_dump {
  my $self = shift;

  my $out = __PACKAGE__ . "\n in " . $self->{cdx_file} . "\n";
  $out .= sprintf ' delimiter ASCII %d/%d  ',
    (ord $self->{delimiter})/16, (ord $self->{delimiter})%16;
  $out .= ' '.join(' ', 'CDX', @{$self->{fields}})."\n";

  return $out;
}

sub attach {
  my $class = shift;
  my $cdx_file = shift;

  local $/ = "\012";	# ASCII 0/10 LF
  open my $cdx, '<', $cdx_file or croak "$cdx_file: $!";
  binmode $cdx, ':raw';

  my $header = <$cdx>;
  croak "could not read CDX header line from $cdx_file: $!"
    unless defined $header;

  chomp $header;
  my $delimiter = substr $header, 0, 1;
  croak "no CDX marker found in $cdx_file"
    unless 'CDX' eq substr $header, 1, 3
      and $delimiter eq substr $header, 4, 1;

  my @fields = split /\Q$delimiter/, substr $header, 5;

  my %field_index = map {$fields[$_] => $_} 0 .. $#fields;
  my %key_index =
    map {$CDX_Field_Index_Key_Map{$fields[$_]} => $_}
      grep defined $CDX_Field_Index_Key_Map{$fields[$_]}, 0 .. $#fields;

  croak "CDX file $cdx_file does not index WARC file name"
    unless defined $field_index{g};
  croak "CDX file $cdx_file does not index record offset"
    unless defined $field_index{v} or defined $field_index{V};

  bless {cdx_file => $cdx_file, delimiter => $delimiter, fields => \@fields,
	 field_index => \%field_index, key_index => \%key_index}, $class
}

sub _get_volume {
  my $self = shift;
  my $name = shift;

  return $self->{volumes}{$name} if defined $self->{volumes}{$name};

  # otherwise...
  my ($vol, $cdx_dirs, $file) = File::Spec->splitpath($self->{cdx_file});
  my @cdx_dirs = File::Spec->splitdir($cdx_dirs);
  my ($wvol, $warc_dirs, $warc_file) = File::Spec::Unix->splitpath($name);
  my @warc_dirs = File::Spec::Unix->splitdir($warc_dirs);
  my $warcfilename =
    File::Spec->catpath($vol, File::Spec->catdir(@cdx_dirs,
						 @warc_dirs), $warc_file);
  return $self->{volumes}{$name} = mount WARC::Volume ($warcfilename);
}

sub _parse_cdx_entry {
  my $self = shift;
  my $pos = shift;
  my $entry = shift;
  # uncoverable condition right
  my $entry_length = $entry && length $entry;

  return undef unless $entry_length;	# as occurs at end-of-file

  chomp $entry;
  my @fields = split /\Q$self->{delimiter}/, $entry;
  my $volname = $fields[$self->{field_index}{g}];
  my %entry =
    ( _index => $self, _entry_offset => $pos, _entry_length => $entry_length,
      _g__volume => $self->_get_volume($volname),
      _Vv__record_offset =>
      $fields[$self->{field_index}{($volname =~ m/[.]w?arc$/ ? 'v' : 'V')}],
      map {$_ => (defined $CDX_Import_Map{$_}
		  ? $CDX_Import_Map{$_}->($fields[$self->{key_index}{$_}])
		  : $fields[$self->{key_index}{$_}])} keys %{$self->{key_index}}
    );

  bless \%entry, (ref $self).'::Entry';
}

sub searchable {
  my $self = shift;
  my $key = shift;

  return defined $self->{key_index}{url} if $key eq 'url_prefix';
  return defined $self->{key_index}{$key};
}

sub _search_all {
  my $self = shift;

  local $/ = "\012";	# ASCII 0/10 LF
  my @results = ();

  open my $cdx, '<', $self->{cdx_file} or croak "$self->{cdx_file}: $!";
  binmode $cdx, ':raw';

  my $header = <$cdx>;	# skip header to reach first entry
  my $offset = tell $cdx;
  my $entry = $self->_parse_cdx_entry($offset, scalar <$cdx>);
  return () unless defined $entry->distance(@_);

  while (defined $entry) {
    push @results, $entry unless 0 > $entry->distance(@_);
    $offset = tell $cdx;	# ... and advance ...
    $entry = $self->_parse_cdx_entry($offset, scalar <$cdx>);
  }

  return @results;
}

sub _search_best_match {
  my $self = shift;

  local $/ = "\012";	# ASCII 0/10 LF
  my $result = undef;
  my $result_distance = -1;

  open my $cdx, '<', $self->{cdx_file} or croak "$self->{cdx_file}: $!";
  binmode $cdx, ':raw';

  my $header = <$cdx>;	# skip header to reach first entry
  my $offset = tell $cdx;
  my $entry = $self->_parse_cdx_entry($offset, scalar <$cdx>);
  return undef unless defined $entry->distance(@_);

  while (defined $entry) {
    my $distance = $entry->distance(@_);
    unless (0 > $distance) {
      if ($result_distance < 0			# first match found
	  or $distance < $result_distance)	# or better match found
	{ $result = $entry; $result_distance = $distance }
    }
    return $result if $result_distance == 0;	# no better match possible
    $offset = tell $cdx;	# ... and advance ...
    $entry = $self->_parse_cdx_entry($offset, scalar <$cdx>);
  }

  return $result;
}

sub search {
  my $self = shift;

  unless (defined wantarray)
    { carp "calling 'search' method in void context"; return }

  croak "no arguments given to 'search' method"
    unless scalar @_;
  croak "odd number of arguments given to 'search' method"
    if scalar @_ % 2;

  if (wantarray) { return $self->_search_all(@_) }
  else		 { return $self->_search_best_match(@_) }
}

sub first_entry {
  my $self = shift;

  local $/ = "\012";	# ASCII 0/10 LF

  open my $cdx, '<', $self->{cdx_file} or croak "$self->{cdx_file}: $!";
  binmode $cdx, ':raw';

  my $header = <$cdx>;	# skip header to reach first entry
  my $offset = tell $cdx;
  return $self->_parse_cdx_entry($offset, scalar <$cdx>);
}

sub entry_at {
  my $self = shift;
  my $offset = shift;

  local $/ = "\012";	# ASCII 0/10 LF

  open my $cdx, '<', $self->{cdx_file} or croak "$self->{cdx_file}: $!";
  binmode $cdx, ':raw';

  # one octet before requested position must be an end-of-line marker
  seek $cdx, $offset - 1, SEEK_SET or croak "seek $self->{cdx_file}: $!";
  my $eol; defined(read $cdx, $eol, 1) or croak "read $self->{cdx_file}: $!";
  croak "offset $offset in $self->{cdx_file} not a record boundary"
    unless $eol eq $/;

  return $self->_parse_cdx_entry($offset, scalar <$cdx>);
}

1;
__END__

=head1 NAME

WARC::Index::File::CDX - CDX index support for WARC library

=head1 SYNOPSIS

  use WARC::Index::File::CDX;

  $index = attach WARC::Index::File::CDX ($cdx_file);

=head1 DESCRIPTION

A C<WARC::Index::File::CDX> object represents a CDX index file and provides
access to the entries within as C<WARC::Index::Entry> objects, which
provide access to the indexed WARC records.

The CDX format is a sequential index format and every search involves a
scan over the entire CDX file.  This is still useful because CDX files are
considerably smaller than the WARC volumes that they index.

=head2 The CDX Format

The CDX index format appears to be a simplification of Alexa's DAT format
originating at the Internet Archive.  The Internet Archive Wayback Machine
was originally loaded using the pages collected by the crawler for the
Alexa search engine and used Alexa's internal data formats.  (This was a
very different "Alexa" from the service offered by Amazon as of this
writing.)  The official list of CDX field codes is described as meaningful
for both CDX and DAT files, but some of the codes may only be relevant for
the latter.

The CDX index format is a simple line-oriented format similar to an Apache
server log, including the use of C<-> as a placeholder for an unknown or
irrelevant value.  CDX indexes often store only response records.  The CDX
format is very simple, which is good, because the documentation is very
lacking.

A CDX file begins with the single character that will be used as field
delimiter throughout the file.  This is normally a space, S<ASCII 2/0 SP>,
but is not actually required to be so.  The field delimiter is followed by
the magic string "CDX", a field delimiter, and the list of field codes,
using the delimiter to separate the elements, and continuing until the
first newline, S<ASCII 0/10 LF>.  CDX files always use Unix-style line
endings, consisting of a single S<ASCII 0/10 LF> character.

In practice, the CDX field delimiter probably must be chosen from 7-bit
ASCII, and some implementations incorrectly assume that the delimiter is
always ASCII horizontal whitespace.

This library supports the following CDX field codes, with each item in the
list showing the level of support, the field code letter, the description
of the field, a fat comma, and the key(s) derived in this implementation
from the field value.  The level of support is indicated with "C<[RW]>" for
fields both read and written, S<"C<[ W]>"> for fields supported when
building an index but not used when reading an entry, and S<"C<[R ]>"> for
fields used when reading an entry but not produced by this implementation.

=over

=item C<[RW]> B<C<a>> "original url" =E<gt> C<url>

The URL that was used in the request that produced this response.

The C<url_prefix> search key matches a prefix of this value.

This value is copied from the WARC-Target-URI header and is written as "-"
if the record does not have that header.

=item C<[RW]> B<C<b>> "date" =E<gt> C<time>

A timestamp for this record, stored as the 14 digits from the text form of
a C<WARC::Date> without the associated marker characters,
i.e. YYYYmmddHHMMSS instead of YYYY-mm-ddTHH:MM:SSZ.

=item C<[RW]> B<C<g>> "file name"

The name of the WARC volume containing this record.  This value is assumed
to be relative to the directory containing the CDX file and to always be a
Unix-style filename, regardless of the local file name conventions.

This does not appear as a searchable field key, but is used by the
C<$entry-E<gt>volume> method on a CDX index entry to return a
C<WARC::Volume> object.

=item C<[ W]> B<C<k>> "new style checksum"

Typically the base32-encoded SHA1 digest of the response payload.  This
value is copied from the WARC-Payload-Digest header of a record if
available, otherwise "-" is written.

=item C<[ W]> B<C<m>> "mime type of original document"

The MIME type reported in the Content-Type header of the response.  Written
as "-" if the record does not contain an HTTP response with an entity body.

=item C<[ W]> B<C<r>> "redirect"

The contents of the Location header of the response, URL-escaped.  Some
implementations do not properly set this field.  Written as "-" if not
present or if the record does not contain an HTTP response.

=item C<[ W]> B<C<s>> "response code"

The HTTP status code used in the response.  Written as "-" if the record
does not contain an HTTP response.

=item C<[ Z<> ]> B<C<M>> "meta tags (AIF)"

This field seems to be very common in CDX files, but no values have been
observed and this field appears to be completely undocumented.  Ignored on
read, but written as "-" if included when building an index.

B<I<Support for this field is a stub at this time.>>

=item C<[ W]> B<C<N>> "massaged url"

The URL used in the request, as for the C<a> field, but with the hostname
translated to SURT form and the scheme component removed so that the value
starts with the TLD.

B<I<This is based on observed data in samples from a single source and may
change without warning in future versions if better semantics are found.>>

=item C<[ W]> B<C<S>> "compressed record size"

The number of octets in the compressed record in the WARC file.

This field is supported when writing an index, but not used in this library
due to loose coupling between the index and record readers.

=item C<[RW]> B<C<V>> "compressed arc file offset"

=item C<[RW]> B<C<v>> "uncompressed arc file offset"

The offset of the record within a WARC file.  This is the value that can be
passed to C<$volume-E<gt>record_at> to retrieve the record.

This does not appear as a searchable field key, but is used by the
C<$entry-E<gt>record> method on a CDX index entry to return a
C<WARC::Record> object for the record.

The uncompressed offset is used if the file name in the record matches
C<m/[.]w?arc$/>, otherwise the archive is assumed to be compressed.  When
writing an index, the B<C<V>> field is written as "-" if the volume is not
compressed and the B<C<v>> field is written as if the volume were not
compressed if that information is available or as "-" if the volume is
compressed and the uncompressed record sizes are not known.

=back

There is an additional field that GNU Wget writes:

=over

=item C<[RW]> B<C<u>> "record-id" =E<gt> C<record_id>

The WARC-Record-ID of the record.

=back

The B<C<g>> and B<C<v>>/B<C<V>> fields are required for this implementation and
attaching a CDX file that does not have those fields will croak.

The documentation at the Internet Archive also lists the upper-case letters
ABCDFGHIJKLPQRUXYZ, the lower-case letters cdefhijlmnoptxyz, and the #
symbol.  The # symbol is labeled as indicating a comment and is almost
certainly a leftover from the older Alexa DAT format.

=head1 AUTHOR

Jacob Bachmeyer, E<lt>jcb@cpan.orgE<gt>

=head1 SEE ALSO

L<WARC>, L<WARC::Index>

The CDX file format definition at the Internet Archive:
L<http://archive.org/web/researcher/cdx_file_format.php>

The list of CDX field codes at the Internet Archive:
L<http://archive.org/web/researcher/cdx_legend.php>

IIPC 2006 CDX format specification:
L<https://iipc.github.io/warc-specifications/specifications/cdx-format/cdx-2006/>

IIPC 2015 CDX format specification:
L<https://iipc.github.io/warc-specifications/specifications/cdx-format/cdx-2015/>

SURT form at the Internet Archive:
L<http://crawler.archive.org/articles/user_manual/glossary.html#surt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019, 2020 by Jacob Bachmeyer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

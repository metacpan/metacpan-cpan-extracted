package WARC::Builder;						# -*- CPerl -*-

use strict;
use warnings;

use Carp;

our @ISA = qw();

require WARC; *WARC::Builder::VERSION = \$WARC::VERSION;

require WARC::Record;

=head1 NAME

WARC::Builder - Web ARChive construction support for Perl

=head1 SYNOPSIS

  use WARC::Builder;

  $warcinfo_data = new WARC::Fields (software => 'MyWebCrawler/1.2.3 ...',
				     format => 'WARC File Format 1.0',
				     # other fields omitted ...
				     );

  $warcinfo = new WARC::Record (type => 'warcinfo',
				content => $warcinfo_data);

  # for a small-scale crawl
  $build = new WARC::Builder (warcinfo => $warcinfo,
			      filename => $warcfilename);

  # for a large-scale crawl
  $index1 = build WARC::Index::File::CDX (into => $indexprefix.'.cdx');
  $index2 = build WARC::Index::File::SDBM (into => $indexprefix.'.sdbm');
  $build = new WARC::Builder (warcinfo => $warcinfo,
			      filename_template =>
				$warcprefix.'-%s-%05d-'.$hostname.'.warc.gz',
			      index => [$index1, $index2]);

  # for each collected object
  $build->append(@records);	# or ...
  $build->append($record1, $record2, ... );

=head1 DESCRIPTION

The C<WARC::Builder> class is the high-level interface for writing WARC
archives.  It is a very simple interface, because, at this level, WARC is a
very simple format: a simple sequence of WARC records, which
C<WARC::Builder> accepts as C<WARC::Record> objects to append to the
in-progress WARC file.

WARC file size limits are handled automatically if configured.

=head2 Methods

=over

=item $build = new WARC::Builder (I<key> =E<gt> I<value>, ...)

Construct a C<WARC::Builder> object.  The following keys are supported:

=over

=item index =E<gt> [$index]

=item index =E<gt> [$index1, $index2, ...]

If set, must be an array reference of a list of index builder objects.
Each newly-added WARC::Record will be presented to all index builder
objects in this list.

=item filename =E<gt> $warcfilename

If set, create a single WARC file with the given file name.  The file name
must match m/\.warc(?:\.gz)?$/.  The presence of a final ".gz" indicates
that the WARC file should be written with per-record gzip compression.

This option is mutually exclusive with the C<filename_template> option.

Using this option inhibits starting a new WARC file and causes the
C<max_file_size> option to be ignored.  A warning is emitted in this case.

=item filename_template =E<gt> $warcprefix.'-%s-%05d-'.$hostname.'.warc.gz'

Establish an sprintf format string to construct file names.  The file name
produced by the template string must match m/\.warc(?:\.gz)?$/.  The
presence of a final ".gz" indicates that the WARC file should be written
with per-record gzip compression.

The C<filename_template> option gives the format string, while
C<filename_template_vars> gives an array reference of named parameters to
be used with the format.

If constructing file names in accordance with the IIPC WARC implementation
guidelines, this string should be of the form
'PREFIX-%s-%05d-HOSTNAME.warc.gz' where PREFIX is any chosen prefix to name
the crawl and HOSTNAME is the name or other identifier for the machine
writing the file.

This option is mutually exclusive with the C<filename> option.

=item filename_template_vars =E<gt> [qw/timestamp serial/]

Provide the list of parameters to the sprintf call used to produce a WARC
filename from the C<filename_template> option.

The available variables are:

=over

=item serial

A number, incremented each time adding a record causes a new WARC file to
be started.

=item timestamp

A 14-digit timestamp in the YYYYmmddHHMMSS format recommended in the IIPC
WARC implementation guidelines.  The timestamp is always in UTC.  The time
used is the time at which the C<WARC::Builder> object was constructed and
is constant between WARC files.  This should be substituted as a string.

=back

Default [qw/timestamp serial/] in accordance with IIPC guidelines.

=item first_serial =E<gt> $count

The initial value of the C<serial> filename variable for this object.
Default 0.

=item max_file_size =E<gt> $size

Maximum size of a WARC file.  A new WARC file is started if appending a
record would cause the current file to exceed this length.

The limit can be specified as an exact number of bytes, or a number
followed by a size suffix m/[KMG]i?/.  The "K", "M", and "G" suffixes
indicate base-10 multiples (10**(3*n)), while the "Ki", "Mi", and "Gi"
suffixes indicate base-2 multiples (2**(10*n)) widely used in computing.

Default "1G" == 1_000_000_000.

=item warcinfo =E<gt> $warcinfo_record

A C<WARC::Record> object of type "warcinfo" that will be written at the
start of each WARC file.  This record will be cloned and written with a
distinct "WARC-Record-ID" as the first record in each WARC file, including
the first.  As a consequence, it does not require a "WARC-Record-ID" header
and any "WARC-Record-ID" given is silently ignored.

Each clone of this record will also have the "WARC-Filename" header added.

Each clone of this record will also have the "WARC-Date" header set to the
time at which the C<WARC::Builder> object was constructed.

=item warcversion =E<gt> 'WARC/1.0'

Set the version of the WARC format to be written.  This string is the first
line of each WARC record.  It must begin with the prefix 'WARC/' and should
be the version from the WARC specification that the crawler follows.

Default "WARC/1.0".

=back

=cut

sub new {
}

=item $build-E<gt>append( $record1, ... )

Add any number of C<WARC::Record> objects to the growing WARC file.  If
WARC file size limits are configured, and a record would cause the current
WARC file to exceed the configured size limits, a new WARC file is opened
automatically.

All records passed to a single C<append> call are added to the same WARC
file.  If a new WARC file is to be started, it will be started B<before>
any records are written.

All records passed to a single C<append> call are considered "concurrent"
and all subsequent records will have a "WARC-Concurrent-To" header added
referencing the first record, if they do not already have a
"WARC-Concurrent-To" header.  This is a convenience feature for simpler
crawlers and is inhibited if any record already has a "WARC-Concurrent-To"
header when C<append> is called.

If a C<WARC::Record> passed to this method lacks a "WARC-Record-ID" header,
a warning will be emitted using carp(), a UUID will be generated, and a
record ID of the form "urn:uuid:UUID" will be assigned.  If the record
object is read-only, this method will croak() instead.

If a C<WARC::Record> passed to this method lacks any of the "WARC-Date",
"WARC-Type", or "Content-Length" headers, this method will croak().

=cut

sub append {
}

=back

=cut

1;
__END__

=head2 Extension subfield 'sl' in gzip header

The C<WARC::Builder> class can write a "skip length" extension subfield in
the GZIP extra header like that produced by GNU Wget.  The Wget sources
claim that this header is defined by a "WARC standard" but the
publically-available document that Wget cites with "conformsTo" in the
warcinfo records it writes seems to have no mention of the concept.

The C<WARC::Record> class understands this header and can use it to improve
the performance of the C<next> method if it is present.

This extension does not seem to be documented anywhere and the definition
used in this library was extracted from the source code of GNU Wget.

=over

=item subfield ID:  ASCII 'sl'

Encode as:  C<pack> "a2":  (hex) [73 6c]

=item subfield length:  8 bytes

Encode as:  C<pack> "v":  16-bit little-endian integer; (hex) [08 00]

=item compressed size in bytes

Encode as:  C<pack> "V":  32-bit little-endian integer

=item uncompressed size in bytes

Encode as:  C<pack> "V":  32-bit little-endian integer

=back

=head1 AUTHOR

Jacob Bachmeyer, E<lt>jcb@cpan.orgE<gt>

=head1 SEE ALSO

L<WARC>, L<WARC::Record>

International Internet Preservation Consortium (IIPC) WARC implementaion
guidelines.  L<https://netpreserve.org/resources/WARC_Guidelines_v1.pdf>

RFC1952 "GZIP file format specification version 4.3". P. Deutsch. May 1996.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Jacob Bachmeyer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

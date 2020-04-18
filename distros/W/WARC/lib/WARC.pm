package WARC;							# -*- CPerl -*-

use strict;
use warnings;

our @ISA = qw();

require v5.8.1;
use version; our $VERSION = version->declare('v0.0.1');

use constant CRLF => qq[\015\012];

require WARC::Volume;
require WARC::Collection;

our @KNOWN_FORMAT_VERSIONS = qw[WARC/1.0];

our %KNOWN_FORMAT_VERSIONS = map { $_ => 1 } @KNOWN_FORMAT_VERSIONS;

1;
__END__

=head1 NAME

WARC - Web ARChive support for Perl

=head1 SYNOPSIS

  use WARC;

  $collection = assemble WARC::Collection (@indexes);

  $record = $collection->search(url => $url, time => $when);

  $volume = mount WARC::Volume ($filename);

  $record = $volume->first_record;
  $next_record = $record->next;

  $record = $volume->record_at($offset);

  # $record is a WARC::Record object

=head1 DESCRIPTION

The C<WARC> module is a convenience module for loading basic WARC support.
After loading this module, the C<WARC::Volume> and C<WARC::Collection>
classes are available.

=head2 Overview of the WARC reader support modules

=over

=item L<WARC::Collection>

A C<WARC::Collection> object represents a set of indexed WARC files.

=item L<WARC::Volume>

A C<WARC::Volume> object represents a single WARC file.

=item L<WARC::Record>

Each record in a WARC volume is analogous to an C<HTTP::Message>, with
headers specific to the WARC format.

=item L<WARC::Record::Logical>

Support class for WARC records that span multiple segments.

=item L<WARC::Record::Payload>

Planned support for tied filehandles reading WARC payloads.

=item L<WARC::Fields>

A C<WARC::Fields> object represents the set of headers in a WARC record,
analogous to the use of C<HTTP::Headers> with C<HTTP::Message>.  The
C<HTTP::Headers> class is not reused because it has protocol-specific
knowledge of a set of valid headers and a standard ordering.  WARC headers
come from a different set and order is preserved.

The key-value format used in WARC headers has its own MIME type
"application/warc-fields" and is also usable as the contents of a
"warcinfo" record and elsewhere.  The C<WARC::Fields> class also provides
support for objects of this type.

=item L<WARC::Index>

C<WARC::Index> is the base class for WARC index formats and also holds a
registry of loaded index formats for convenience when assembling
C<WARC::Collection> objects.

=item L<WARC::Index::Entry>

C<WARC::Index::Entry> is the base class for WARC index entries returned
from the various index formats.

=item L<WARC::Index::File::CDX>

Access module for the common CDX WARC index format.

=item L<WARC::Index::File::SDBM>

Planned "fast index" format using "SDBM_File" to index multiple CDX indexes
for fast lookup by URL/timestamp pairs.  Planned because sdbm is included
with Perl and the 1008 byte record limit should be a minor problem by
storing URL prefixes and splitting records.

=item L<WARC::Index::File::SQLite>

Another planned "fast index" format using DBI and DBD::SQLite.  This module
avoids the limitations of SDBM, but depends on modules from CPAN.

=item L<WARC::Index::Volatile>

Simple in-memory index module for small-scale applications that need index
support but want to avoid requiring additional files beyond the WARC volume
itself.  This reads an entire WARC volume to build and attach an index.

=back

=head2 Overview of the WARC writer support modules

=over

=item L<WARC::Builder>

The C<WARC::Builder> class provides a means to write new WARC files.

=item L<WARC::Index::Builder>

C<WARC::Index::Builder> is the base class for the index-building tools.

=item L<WARC::Index::File::CDX::Builder>

=item L<WARC::Index::File::SDBM::Builder>

=item L<WARC::Index::File::SQLite::Builder>

The C<WARC::Index::File::*::Builder> classes provide tools for building
indexes either incrementally while writing the corresponding WARC file or
after-the-fact by scanning an existing WARC file.

The C<build> constructor that C<WARC::Index> provides uses one of these
classes for the actual work.

=back

=head1 CAVEATS

Support for the RFC 2047 "encoded-words" mechanism is required by the WARC
specification but not yet implemented.

Support for WARC record segmentation is planned but not yet implemented.

Handling segmented WARC records requires using the C<WARC::Collection>
interface to find the next segment in a different WARC file.  The
C<WARC::Volume> interface is only usable for access within one WARC file.

The older ARC format is not yet supported, nor are other archival formats
directly supported.  Interfaces for "WARC-alike" handlers are planned as
C<WARC::Alike::*>.  Metadata normally present in WARC volumes may not be
available from other formats.

Formats planned for eventual inclusion include MAFF described at
L<http://maf.mozdev.org/maff-specification.html> and the MHTML format
defined in RFC 2557.

=head1 AUTHOR

Jacob Bachmeyer, E<lt>jcb@cpan.orgE<gt>

=head1 SEE ALSO

Information about the WARC format at L<http://bibnum.bnf.fr/WARC/>.

An overview of the WARC format at
L<https://www.loc.gov/preservation/digital/formats/fdd/fdd000236.shtml>.

# TODO: add relevant RFCs.

The POD pages for the modules mentioned in the overview lists.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Jacob Bachmeyer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut

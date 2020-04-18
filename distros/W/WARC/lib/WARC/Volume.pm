package WARC::Volume;						# -*- CPerl -*-

use strict;
use warnings;

use Carp;
use Cwd qw//;

our @ISA = qw();

use WARC; *WARC::Volume::VERSION = \$WARC::VERSION;

use WARC::Record;
use WARC::Record::FromVolume;

=head1 NAME

WARC::Volume - Web ARChive file access for Perl

=head1 SYNOPSIS

  use WARC::Volume;

  $volume = mount WARC::Volume ($filename);

  $filename = $volume->filename;

  $handle = $volume->open;

  $record = $volume->first_record;

  $record = $volume->record_at($offset);

=cut

use overload '""' => 'filename';
use overload fallback => 1;

# This implementation is almost laughably simple, needing to store only a
#  single data value: the absolute filename of the WARC file.  As such, the
#  underlying implementation, is, in fact, a blessed string.

=head1 DESCRIPTION

A C<WARC::Volume> object represents a WARC file in the filesystem and
provides access to the WARC records within as C<WARC::Record> objects.

=head2 Methods

=over

=item $volume = mount WARC::Volume ($filename)

Construct a C<WARC::Volume> object.  The parameter is the name of an
existing WARC file.  An exception is raised if the first record does not
have a valid WARC header.

=cut

sub mount {
  my $class = shift;
  my $filename = shift;

  my $fullfilename = Cwd::abs_path($filename);
  my $ob = bless \$fullfilename, $class;

  $ob->first_record;

  return $ob;
}

=item $volume-E<gt>filename

Return the filename for this volume.

=cut

sub filename { ${(shift)} }

=item $volume-E<gt>open

Return a readable and seekable file handle for this volume.  The returned
value may be a tied handle.  Do not assume that it is an C<IO::Handle>.

=cut

sub open {
  my $self = shift;
  my $filename = $$self;

  open my $fh, '<', $filename or die "$filename: $!";
  binmode $fh, ':raw';	# WARC files contain binary data and UTF-8 headers
  return $fh;
}

=item $volume-E<gt>first_record

Construct and return a C<WARC::Record> object representing the first WARC
record in $volume.  This should be a "warcinfo" record, but it is not
required to be so.

=cut

sub first_record { (shift)->record_at(0) }

=item $volume-E<gt>record_at( $offset )

Construct and return a C<WARC::Record> object representing the WARC record
beginning at $offset within $volume.  An exception is raised if an
appropriate magic number is not found at $offset.

=cut

sub record_at { _read WARC::Record::FromVolume @_ }

=back

=cut

# $volume->_file_tag
#
# Return a "file tag" for this volume.
#
# This is an internal procedure.  The exact definition of "file tag" is
# platform-dependent, but it will be the same value if both file names can
# be proven to be the same underlying file.

BEGIN {
  use constant ();

  my $have_valid_inodes = 0;

  # We accept DEV:INO as valid if two files in the same directory have the
  #  same DEV and different INO values.  We use two modules from this
  #  library for this test and retrieve their actual locations from %INC.
  my @stat_record = stat $INC{'WARC/Record.pm'};
  my @stat_volume = stat $INC{'WARC/Volume.pm'};

  $have_valid_inodes = 1
    if (scalar @stat_record && scalar @stat_volume # both stat calls worked
	&& $stat_record[0] == $stat_volume[0]	   # both have same DEV
	&& $stat_record[1] != $stat_volume[1]);	   # different INO values

  constant->import(HAVE_VALID_INODES => $have_valid_inodes);
}
sub _file_tag {
  if (HAVE_VALID_INODES) {
    # Two modules have been found to have distinct inode numbers, therefore
    #  we are probably running in a POSIX environment.  Use the dev:ino
    #  pair from the stat builtin as file tag.

    # POSIX requires that this be sufficient to distinguish files, although
    # there are situations, particularly in complex network environments,
    # where two different dev:ino pairs may correspond to the same file.
    # Such situations can be avoided with careful administration.
    return join ':', ((stat shift)[0, 1])
  } else {
    # Use the absolute filename and assume no links on other platforms

    # The file name stored in the WARC::Volume object is already absolute.
    return (shift)->filename
  }
}

1;
__END__

=head1 CAVEATS

The internal tags used to distinguish volumes assume that only Unix-like
systems have hard links.  On all other platforms, the absolute filename is
used.

=head1 AUTHOR

Jacob Bachmeyer, E<lt>jcb@cpan.orgE<gt>

=head1 SEE ALSO

L<WARC>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Jacob Bachmeyer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

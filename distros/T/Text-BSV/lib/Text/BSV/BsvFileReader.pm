####
# BsvFileReader.pm:  A Perl module defining a class for reading BSV data
# from a file and then turning the data into an array of field names plus
# one hash encapsulating each record.
#
####
#
# Copyright 2010 by Benjamin Fitch.
#
# This library is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
####
package Text::BSV::BsvFileReader;

use 5.010001;
use strict;
use warnings;
use utf8;

use English "-no_match_vars";
use Hash::Util ("lock_keys");
use List::Util ("first", "max", "min", "sum");
use Scalar::Util ("looks_like_number");

use Text::BSV::BsvParsing;
use Text::BSV::Exception;

# Version:
our $VERSION = '1.04';

# Constants:
my $POUND     = "#";
my $SQ        = "'";
my $DQ        = "\"";
my $SEMICOLON = ";";
my $CR        = "\r";
my $LF        = "\n";
my $SPACE     = " ";
my $EMPTY     = "";
my $TRUE      = 1;
my $FALSE     = 0;

# Constructor:
sub new {
    my ($class, $bsv_file_path) = @_;
    my %bsv_file_reader;
    my $header_row;

    unless (defined($bsv_file_path) && -f $bsv_file_path) {
        my $file_path = $bsv_file_path // "(undefined)";

        die Text::BSV::Exception->new($Text::BSV::Exception::FILE_NOT_FOUND,
          "$DQ$file_path$DQ is not a valid file path.");
    } # end unless

    # Bless the hash into the class:
    bless \%bsv_file_reader, $class;

    # Restrict the hash keys:
    lock_keys(%bsv_file_reader,
      "_FILE", "_current_record", "_field_delimiter", "_field_names");

    # Open the file:
    unless (open $bsv_file_reader{"_FILE"}, "<:utf8", $bsv_file_path) {
        die Text::BSV::Exception->new($Text::BSV::Exception::IO_ERROR,
          "Couldn't open $DQ$bsv_file_path$DQ for reading.");
    } # end unless

    # Get the header row and the first non-header row, and strip their
    # end-of-line characters:
    my $FYLE = $bsv_file_reader{"_FILE"};

    $header_row = <$FYLE>;

    if (defined $header_row) {
        chomp $header_row;
        $header_row =~ s/\r//gs;
    }
    else {
        close $FYLE;
        die Text::BSV::Exception->new(
          $Text::BSV::Exception::INVALID_DATA_FORMAT,
          "Couldn't find a header row in the specified BSV file.");
    } # end unless

    $bsv_file_reader{"_current_record"} = <$FYLE>;

    if (defined $bsv_file_reader{"_current_record"}) {
        chomp $bsv_file_reader{"_current_record"};
        $bsv_file_reader{"_current_record"} =~ s/\r//gs;
    }
    else {
        close $FYLE;
        die Text::BSV::Exception->new(
          $Text::BSV::Exception::INVALID_DATA_FORMAT,
          "Couldn't find any records in the specified BSV file.");
    } # end unless

    # Get the field delimiter:
    $bsv_file_reader{"_field_delimiter"} = get_field_delimiter(
      $header_row, $bsv_file_reader{"_current_record"});

    # Get the field names:
    $bsv_file_reader{"_field_names"} = parse_header_row(
      $header_row, $bsv_file_reader{"_field_delimiter"});

    # Return the object:
    return \%bsv_file_reader;
} # end constructor

# Methods:
sub get_field_names {
    return $_[0]->{"_field_names"};
} # end sub

sub has_next {
    return defined($_[0]->{"_current_record"}) ? $TRUE : $FALSE;
} # end sub

sub get_record {
    my $bsv_file_reader = $_[0];
    my $record;

    unless ($bsv_file_reader->has_next()) {
        die Text::BSV::Exception->new(
          $Text::BSV::Exception::UNSUPPORTED_OPERATION,
          "There is no next record.");
    } # end unless

    $record = parse_row(
      $bsv_file_reader->{"_current_record"},
      $bsv_file_reader->{"_field_delimiter"},
      $bsv_file_reader->{"_field_names"});

    # Update the file reader's "_current_record" field to the next record
    # (or undef) for next time:
    my $FYLE = $bsv_file_reader->{"_FILE"};

    $bsv_file_reader->{"_current_record"} = <$FYLE>;

    if (defined $bsv_file_reader->{"_current_record"}) {
        chomp $bsv_file_reader->{"_current_record"};
        $bsv_file_reader->{"_current_record"} =~ s/\r//gs;
    }
    else {
        $bsv_file_reader->close();
    } # end unless

    # Return the requested record:
    return $record;
} # end sub

sub close {
    close $_[0]->{"_FILE"};
} # end sub

# Module return value:
1;
__END__

=head1 NAME

Text::BSV::BsvFileReader - read BSV data from a file and then turn the data
into an array of field names plus one hash encapsulating each record.

=head1 SYNOPSIS

  use Text::BSV::BsvFileReader;
  use Text::BSV::Exception;

  # Constants:
  my $DQ = "\"";

  # Create a Text::BSV::BsvFileReader instance:
  my $bsv_file_path = $ARGV[0];
  my $bsv_file_reader;

  eval {
      $bsv_file_reader = Text::BSV::BsvFileReader->new($bsv_file_path);
  };

  if ($EVAL_ERROR) {
      my $exception = $EVAL_ERROR;

      given ($exception->get_type()) {
          when ($Text::BSV::Exception::FILE_NOT_FOUND) {
              say STDERR "$DQ$bsv_file_path$DQ is not a valid file path.";
              exit(1);
          }
          when ($Text::BSV::Exception::IO_ERROR) {
              say STDERR "Couldn't open $DQ$bsv_file_path$DQ for reading.";
              exit(1);
          }
          when ($Text::BSV::Exception::INVALID_DATA_FORMAT) {
              say STDERR "Invalid BSV data:  " . $exception->get_message();
              exit(1);
          }
          default {
              say STDERR $exception->get_message();
              exit(1);
          } # end when
      } # end given
  } # end if

  # Get the field names:
  my @field_names = @{ $bsv_file_reader->get_field_names() };

  # Get the records:
  my @records;

  while ($bsv_file_reader->has_next()) {
      eval {
          push @records, $bsv_file_reader->get_record();
      };

      if ($EVAL_ERROR) {
          say STDERR $EVAL_ERROR->get_message();
          exit(1);
      } # end if
  } # end while

  # Close the connection to the underlying BSV file:
  $bsv_file_reader->close();

  # Do something with the records.

=head1 DESCRIPTION

This module defines a class for reading BSV data from a file and then
turning the data into an array of field names plus one hash encapsulating
each record.

For a complete specification of the BSV (Bar-Separated Values) format, see
F<bsv_format.txt>.

In addition to the class-name argument, which is passed in automatically
when you use the C<Text::BSV::BsvFileReader-E<gt>new()> syntax, the
constructor takes a string containing the path to a BSV file.

The constructor returns a reference to a Text::BSV::BsvFileReader object,
which is implemented internally as a hash.  All functionality is exposed
through methods.

  NOTE:  This module uses the Text::BSV::Exception module for error
  handling.  When an error occurs during the execution of a method
  (including the constructor), the method creates a new
  Text::BSV::Exception object of the appropriate type and then passes
  it to "die".  When you call the constructor or a method documented
  to throw an exception, do so within an "eval" statement and then
  query $EVAL_ERROR ($@) to catch any exceptions that occurred.  For
  more information, see the documentation for Text::BSV::Exception.

=head1 PREREQUISITES

This module requires Perl 5 (version 5.10.1 or later), the
Text::BSV::BsvParsing module, and the Text::BSV::Exception module.

=head1 METHODS

=over

=item Text::BSV::BsvFileReader->new($bsv_file_path);

This is the constructor.  If the specified file does not exist, the
constructor throws an exception of type
$Text::BSV::Exception::FILE_NOT_FOUND.  If the file cannot be opened
for reading, the constructor throws an exception of type
$Text::BSV::Exception::IO_ERROR.  If the header row or the first
non-header row in the BSV data is not valid, the constructor throws
an exception of type $Text::BSV::Exception::INVALID_DATA_FORMAT.

=item $bsv_file_reader->get_field_names();

Returns a reference to an array containing the field names, preserving
the order in which they appear in the BSV data.

=item $bsv_file_reader->has_next();

Returns a Boolean value indicating whether there is a next record
available.

=item $bsv_file_reader->get_record();

Returns a reference to a hash encapsulating the next record.  The keys
are the field names, and the values are the field values for the
record encapsulated by the hash.

If there is no next record, this method throws an exception of type
$Text::BSV::Exception::UNSUPPORTED_OPERATION.  If the BSV data in the
next record is not valid, this method throws an exception of type
$Text::BSV::Exception::INVALID_DATA_FORMAT.

=item $bsv_file_reader->close();

Closes the connection to the underlying BSV file.

=back

=head1 AUTHOR

Benjamin Fitch, <blernflerkl@yahoo.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2010 by Benjamin Fitch.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

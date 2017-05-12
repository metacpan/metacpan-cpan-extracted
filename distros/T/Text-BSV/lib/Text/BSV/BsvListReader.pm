####
# BsvListReader.pm:  A Perl module defining a class for reading BSV data
# from a list of strings containing the rows (without end-of-line
# characters), including the header row, and then turning the data into
# an array of field names plus one hash encapsulating each record.
#
####
#
# Copyright 2010 by Benjamin Fitch.
#
# This library is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
####
package Text::BSV::BsvListReader;

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
    my ($class, $bsv_rows) = @_;
    my %bsv_list_reader;

    # Make sure that there is at least a header row and one other row:
    unless (scalar(@{ $bsv_rows }) >= 2) {
        die Text::BSV::Exception->new(
          $Text::BSV::Exception::INVALID_DATA_FORMAT,
          "BSV data must have at least a header row plus one record.");
    } # end unless

    # Bless the hash into the class:
    bless \%bsv_list_reader, $class;

    # Restrict the hash keys:
    lock_keys(%bsv_list_reader,
      "_field_delimiter", "_field_names", "_records");

    # Get the field delimiter:
    $bsv_list_reader{"_field_delimiter"} = get_field_delimiter(
      $bsv_rows->[0], $bsv_rows->[1]);

    # Get the field names:
    $bsv_list_reader{"_field_names"} = parse_header_row(
      $bsv_rows->[0], $bsv_list_reader{"_field_delimiter"});

    # Get the records:
    for my $dex (1..$#{ $bsv_rows }) {
        push @{ $bsv_list_reader{"_records"} }, parse_row(
          $bsv_rows->[$dex],
          $bsv_list_reader{"_field_delimiter"},
          $bsv_list_reader{"_field_names"});
    } # next $dex

    # Return the object:
    return \%bsv_list_reader;
} # end constructor

# Methods:
sub get_field_names {
    return $_[0]->{"_field_names"};
} # end sub

sub get_records {
    return $_[0]->{"_records"};
} # end sub

# Module return value:
1;
__END__

=head1 NAME

Text::BSV::BsvListReader - read BSV data from a list of strings containing
the rows (without end-of-line characters), including the header row, and
then turn the data into an array of field names plus one hash encapsulating
each record.

=head1 SYNOPSIS

  use Text::BSV::BsvListReader;
  use Text::BSV::Exception;

  # Create a Text::BSV::BsvListReader instance:
  my $bsv_rows = $ARGV[0];
  my $bsv_list_reader;

  eval {
      $bsv_list_reader = Text::BSV::BsvListReader->new($bsv_rows);
  };

  if ($EVAL_ERROR) {
      say STDERR $EVAL_ERROR->get_message();
      exit(1);
  } # end if

  # Get the field names:
  my @field_names = @{ $bsv_list_reader->get_field_names() };

  # Get the records:
  my @records = @{ $bsv_list_reader->get_records() };

  # Do something with the records.

=head1 DESCRIPTION

This module defines a class for reading BSV data from a list of strings
containing the rows (without end-of-line characters), including the header
row, and then turning the data into an array of field names plus one hash
encapsulating each record.

For a complete specification of the BSV (Bar-Separated Values) format, see
F<bsv_format.txt>.

In addition to the class-name argument, which is passed in automatically
when you use the C<Text::BSV::BsvListReader-E<gt>new()> syntax, the
constructor takes a reference to an array containing the BSV rows,
including the header row, with no end-of-line characters.

The constructor returns a reference to a Text::BSV::BsvListReader object,
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

=item Text::BSV::BsvListReader->new($bsv_rows);

This is the constructor.  If the header row or the first record in the
BSV data is not valid, the constructor throws an exception of type
$Text::BSV::Exception::INVALID_DATA_FORMAT.

=item $bsv_list_reader->get_field_names();

Returns a reference to an array containing the field names, preserving
the order in which they appear in the BSV data.

=item $bsv_list_reader->get_records();

Returns a reference to an array of hash references that encapsulate
the BSV data records.  The keys in each hash are the field names.

=back

=head1 AUTHOR

Benjamin Fitch, <blernflerkl@yahoo.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2010 by Benjamin Fitch.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

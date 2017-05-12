####
# BsvParsing.pm:  A Perl module containing helper functions for parsing and
# generating BSV data.
#
#   NOTE:  For a complete specification of the BSV (Bar-Separated Values)
#   format, see "bsv_format.txt".
#
####
#
# Copyright 2010 by Benjamin Fitch.
#
# This library is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
####
package Text::BSV::BsvParsing;

use 5.010001;
use strict;
use warnings;
use utf8;

use English "-no_match_vars";
use Hash::Util ("lock_keys");
use List::Util ("first", "max", "min", "sum");
use Scalar::Util ("looks_like_number");
use Exporter;

use Text::BSV::Exception;

# Version:
our $VERSION = '1.04';

# Specify default exports:
our @ISA = ("Exporter");
our @EXPORT = (
  "get_field_delimiter",
  "parse_header_row",
  "parse_row",
  "generate_header_row",
  "generate_row",
  );

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

my $INCLUDE_TRAILING_EMPTY_FIELDS = -1;

####
# Exported helper functions for use by the other Text::BSV::* modules:
####

# The get_field_delimiter() function takes a string containing the header
# row and a string containing the first non-header row.  The function
# returns a string containing the field delimiter.
#
# If the field delimiter cannot be unambiguously determined, the function
# throws an exception of type $Text::BSV::Exception::INVALID_DATA_FORMAT.
sub get_field_delimiter {
    my $header_row = $_[0];
    my $first_nonheader_row = $_[1];
    my $field_delimiter;

    if (index($header_row, "|") > -1) {
        $field_delimiter = "|";
    }
    elsif (index($header_row, $DQ) > -1
      || index($first_nonheader_row, $DQ) > -1) {
        die Text::BSV::Exception->new(
          $Text::BSV::Exception::INVALID_DATA_FORMAT,
          "There is no vertical bar in the header row, but there is a "
          . "double quotation mark in the header row or in the first "
          . "non-header row.");
    }
    else {
        my @potential_delimiters;

        for my $delim (",", $SEMICOLON, "\t") {
            if (index($header_row, $delim) > -1) {
                push @potential_delimiters, $delim;
            } # end if
        } # next $delim

        given (scalar @potential_delimiters) {
            when (0) {
                die Text::BSV::Exception->new(
                  $Text::BSV::Exception::INVALID_DATA_FORMAT,
                  "The field delimiter in the BSV data cannot be "
                  . "unambiguously determined.");
            }
            when (1) {
                $field_delimiter = $potential_delimiters[0];
            }
            default {
                my $found_winner = $FALSE;

                for my $potential_delimiter (@potential_delimiters) {
                    if (num_delimiters($header_row, $potential_delimiter)
                      == num_delimiters(
                      $first_nonheader_row, $potential_delimiter)) {
                        if ($found_winner) {
                            die Text::BSV::Exception->new(
                              $Text::BSV::Exception::INVALID_DATA_FORMAT,
                              "The field delimiter in the BSV data "
                              . "cannot be unambiguously determined.");
                        }
                        else {
                            $found_winner = $TRUE;
                            $field_delimiter = $potential_delimiter;
                        } # end if
                    } # end if
                } # next $potential_delimiter

                unless ($found_winner) {
                    die Text::BSV::Exception->new(
                      $Text::BSV::Exception::INVALID_DATA_FORMAT,
                      "The field delimiter in the BSV data cannot be "
                          . "unambiguously determined.");
                } # end unless
            } # end when
        } # end given
    } # end if

    return $field_delimiter;
} # end sub

# The parse_header_row() function takes a string containing the header row
# (without end-of-line characters) and a string containing the field
# delimiter.  The function parses the header row, verifies that the field
# names are unique, and then returns a reference to an array of strings
# containing the field names.  If the field delimiter is the vertical bar,
# the function translates any escape sequences in the field names into the
# corresponding actual characters.
#
# If the header row contains any newline or carriage-return characters or
# the specified field delimiter is not supported by the BSV format, the
# function throws an exception of type
# $Text::BSV::Exception::ILLEGAL_ARGUMENT.  If the field names are not
# unique, or if the header row contains a double quotation mark but the
# field delimiter is not the vertical bar, the function throws an exception
# of type $Text::BSV::Exception::INVALID_DATA_FORMAT.
sub parse_header_row {
    my $header_row = $_[0];
    my $field_delimiter = $_[1];
    my @field_names;

    if ($header_row =~ /[\r\n]/s) {
        die Text::BSV::Exception->new(
          $Text::BSV::Exception::ILLEGAL_ARGUMENT,
          "The header row passed to the parse_header_row() function "
          . "contains newline or carriage-return characters.");
    } # end if

    if ($field_delimiter eq "|") {
        my $bsv_data = $header_row;
        my @pieces;

        $bsv_data =~ s/\\\\/\n/gs;
        @pieces = split /(?<!\\)\|/s, $header_row,
          $INCLUDE_TRAILING_EMPTY_FIELDS;

        for my $piece (@pieces) {
            my $field_name = $piece;

            $field_name =~ s/\n/\\\\/gs;
            $field_name = translate_from_bsv($field_name);

            if ($field_name ~~ @field_names) {
                die Text::BSV::Exception->new(
                  $Text::BSV::Exception::INVALID_DATA_FORMAT,
                  "Duplicate field names.");
            } # end if

            push @field_names, $field_name;
        } # next $piece
    }
    elsif (index($header_row, $DQ) > -1) {
        die Text::BSV::Exception->new(
          $Text::BSV::Exception::INVALID_DATA_FORMAT,
          "The field delimiter in the BSV data is not the vertical bar, "
          . "but there is a double quotation mark in the header row.");
    }
    elsif ($field_delimiter eq ","
      || $field_delimiter eq $SEMICOLON
      || $field_delimiter eq "\t") {
        my @pieces = split /$field_delimiter/s, $header_row,
          $INCLUDE_TRAILING_EMPTY_FIELDS;

        for my $piece (@pieces) {
            if ($piece ~~ @field_names) {
                die Text::BSV::Exception->new(
                  $Text::BSV::Exception::INVALID_DATA_FORMAT,
                  "Duplicate field names.");
            } # end if

            push @field_names, $piece;
        } # next $piece
    }
    else {
        die Text::BSV::Exception->new(
          $Text::BSV::Exception::ILLEGAL_ARGUMENT,
          "The field delimiter passed to the parse_header_row() function "
          . "is not supported by the BSV format.");
    } # end if

    return \@field_names;
} # end sub

# The parse_row() function takes a string containing a non-header row
# (without end-of-line characters), a string containing the field delimiter,
# and a reference to an array of strings containing the field names.  The
# function parses the row, verifies that the number of field values is
# correct, and then returns a reference to a hash in which the keys are the
# field names and the values are the record's field values.  If the field
# delimiter is the vertical bar, the function translates any escape
# sequences in the field values into the appropriate actual characters.
#
# The function assumes that the field names passed in are already translated
# from BSV format into ordinary text.
#
# If the row contains any newline or carriage-return characters or the
# specified field delimiter is not supported by the BSV format, the
# function throws an exception of type
# $Text::BSV::Exception::ILLEGAL_ARGUMENT.  If the row does not contain the
# number of fields matching the number of field names passed in, or if the
# row contains a double quotation mark but the field delimiter is not the
# vertical bar, the function throws an exception of type
# $Text::BSV::Exception::INVALID_DATA_FORMAT.
sub parse_row {
    my $row = $_[0];
    my $field_delimiter = $_[1];
    my $field_names = $_[2];
    my $record = {};

    if ($row =~ /[\r\n]/s) {
        die Text::BSV::Exception->new(
          $Text::BSV::Exception::ILLEGAL_ARGUMENT,
          "The row passed to the parse_row() function contains "
          . "newline or carriage-return characters.");
    } # end if

    if ($field_delimiter eq "|") {
        my $bsv_data = $row;
        my @pieces;

        $bsv_data =~ s/\\\\/\n/gs;
        @pieces = split /(?<!\\)\|/s, $row,
          $INCLUDE_TRAILING_EMPTY_FIELDS;

        unless (scalar(@pieces) == scalar(@{ $field_names })) {
            die Text::BSV::Exception->new(
              $Text::BSV::Exception::INVALID_DATA_FORMAT,
              "The number of fields in a row passed to the "
              . "parse_row() function does not match the number of "
              . "field names passed in.");
        } # end unless

        for my $dex (0..$#pieces) {
            my $field_value = $pieces[$dex];

            $field_value =~ s/\n/\\\\/gs;
            $field_value = translate_from_bsv($field_value);
            $record->{$field_names->[$dex]} = $field_value;
        } # next $piece
    }
    elsif (index($row, $DQ) > -1) {
        die Text::BSV::Exception->new(
          $Text::BSV::Exception::INVALID_DATA_FORMAT,
          "The field delimiter in the BSV data is not the vertical bar, "
          . "but there is a double quotation mark in at least one "
          . "of the rows.");
    }
    elsif ($field_delimiter eq ","
      || $field_delimiter eq $SEMICOLON
      || $field_delimiter eq "\t") {
        my @pieces = split /$field_delimiter/s, $row,
          $INCLUDE_TRAILING_EMPTY_FIELDS;

        unless (scalar(@pieces) == scalar(@{ $field_names })) {
            die Text::BSV::Exception->new(
              $Text::BSV::Exception::INVALID_DATA_FORMAT,
              "The number of fields in a row passed to the "
              . "parse_row() function does not match the number of "
              . "field names passed in.");
        } # end unless

        for my $dex (0..$#pieces) {
            $record->{$field_names->[$dex]} = $pieces[$dex];
        } # next $dex
    }
    else {
        die Text::BSV::Exception->new(
          $Text::BSV::Exception::ILLEGAL_ARGUMENT,
          "The field delimiter passed to the parse_row() function "
          . "is not supported by the BSV format.");
    } # end if

    return $record
} # end sub

# The generate_header_row() function takes a reference to an array of
# strings containing field names, and returns a string containing a BSV
# header row (with no end-of-line characters added).
#
# If the field names passed in are not unique, the function throws an
# exception of type $Text::BSV::Exception::ILLEGAL_ARGUMENT.
sub generate_header_row {
    my $field_names = $_[0];
    my @validated_field_names = ();
    my $header_row = $EMPTY;

    for my $dex (0..$#{ $field_names }) {
        if ($field_names->[$dex] ~~ @validated_field_names) {
            die Text::BSV::Exception->new(
              $Text::BSV::Exception::ILLEGAL_ARGUMENT,
              "Field names are not unique.");
        } # end if

        push @validated_field_names, $field_names->[$dex];

        if ($dex > 0) {
            $header_row .= "|";
        } # end if

        $header_row .= translate_to_bsv($field_names->[$dex]);
    } # next $dex

    return $header_row;
} # end sub

# The generate_row() function takes a reference to a hash that encapsulates
# a BSV record and a reference to an array of strings containing the field
# names.  Using the array of field names to determine the order of the
# fields, the function generates and returns a string containing a BSV
# non-header row (with no end-of-line characters added).
#
# If the number and names of the fields in the passed-in hash do not match
# the passed-in array of field names, the function throws an exception of
# type $Text::BSV::Exception::ILLEGAL_ARGUMENT.
sub generate_row {
    my $record = $_[0];
    my $field_names = $_[1];
    my $row = $EMPTY;

    unless (scalar(keys %{ $record }) == scalar(@{ $field_names })) {
        die Text::BSV::Exception->new(
          $Text::BSV::Exception::ILLEGAL_ARGUMENT,
          "The number of field names passed to the generate_row() function "
          . "does not match the number field values in the record.");
    } # end unless

    for my $dex (0..$#{ $field_names }) {
        unless (exists $record->{$field_names->[$dex]}) {
            die Text::BSV::Exception->new(
              $Text::BSV::Exception::ILLEGAL_ARGUMENT,
              "The record passed to the generate_row() function does not "
              . "match the list of field names passed in.");
        } # end unless

        if ($dex > 0) {
            $row .= "|";
        } # end if

        $row .= translate_to_bsv($record->{$field_names->[$dex]});
    } # next $dex

    return $row;
} # end sub

####
# Private helper functions for use by this module:
####

# The private num_delimiters() function takes a string to be searched and a
# string containing a delimiter.  The function returns the number of
# occurrences of the delimiter within the string to be searched.
sub num_delimiters {
    my $str = $_[0];
    my $delim = $_[1];
    my $result = 0;

    for my $dex (0..(length($str) - 1)) {
        if (substr($str, $dex, 1) eq $delim) {
            $result++;
        } # end if
    } # next $dex

    return $result;
} # end sub

# The private translate_from_bsv() function takes a string containing a BSV
# field name or value and returns a string containing the translated version
# in which escape sequences have been replaced with the correct
# corresponding characters.
#
# If the field name or value contains any instances of invalid backslash
# usage, the function throws an exception of type
# $Text::BSV::Exception::INVALID_DATA_FORMAT.  If the field name or value
# contains any newline or carriage-return characters, the function throws an
# exception of type $Text::BSV::Exception::ILLEGAL_ARGUMENT.
sub translate_from_bsv {
    my $bsv_str = $_[0];
    my $normal_str = $bsv_str;

    if ($bsv_str =~ /[\r\n]/s) {
        die Text::BSV::Exception->new(
          $Text::BSV::Exception::ILLEGAL_ARGUMENT,
          "A BSV field name or value cannot contain newline or "
          . "carriage-return characters.");
    } # end if

    $normal_str =~ s/\\\\/\n/gs;

    if ($normal_str =~ /\\[^|n]/s) {
        die Text::BSV::Exception->new(
          $Text::BSV::Exception::INVALID_DATA_FORMAT,
          "Invalid backslash usage in BSV data.");
    } # end if

    $normal_str =~ s/\n/\\z/gs;
    $normal_str =~ s/\\\|/|/gs;
    $normal_str =~ s/\\n/\n/gs;
    $normal_str =~ s/\\z/\\/gs;

    return $normal_str;
} # end sub

# The private translate_to_bsv() function takes a string containing a
# field name or value and returns a string containing the BSV version,
# in which carriage returns have been stripped and then backslashes,
# vertical bars, and newline characters have been escaped.
sub translate_to_bsv {
    my $bsv_str = $_[0];

    $bsv_str =~ s/\r/$EMPTY/gs;
    $bsv_str =~ s/\\/\\\\/gs;
    $bsv_str =~ s/\|/\\|/gs;
    $bsv_str =~ s/\n/\\n/gs;

    return $bsv_str;
} # end sub

# Module return value:
1;

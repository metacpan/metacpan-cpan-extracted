#!/usr/bin/perl

# bsv_test.t:  Test the Text::BSV::* modules.
use 5.010001;
use strict;
use warnings;
use utf8;

use Test::More ("tests" => 46);

use English "-no_match_vars";
use File::Compare ("compare_text");

use Text::BSV::BsvFileReader;
use Text::BSV::BsvListReader;
use Text::BSV::BsvWriter;
use Text::BSV::Exception;

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

# Main script:
my $bsv_file_reader;
my $bsv_list_reader;
my $bsv_writer;

for my $file_path (
  "nonexistent_file.bsv", "fake_stock.csv",
  "ambiguous.csv", "bad_backslash.bsv", "no_records.bsv",
  "wombats.csv", "wombats.bsv") {
    # Tests for file reading and writing:
    eval {
        $bsv_file_reader = Text::BSV::BsvFileReader->new($file_path);
    };

    given ($file_path) {
        when ("nonexistent_file.bsv") {
            ok($EVAL_ERROR && $EVAL_ERROR->get_type()
              == $Text::BSV::Exception::FILE_NOT_FOUND,
              "Attempting to read a nonexistent BSV file generates an "
              . "exception of type \$Text::BSV::Exception::FILE_NOT_FOUND");
        }
        when (/\A(?:(?:ambiguous|wombats)\.csv|no_records\.bsv)\z/s) {
            ok($EVAL_ERROR && $EVAL_ERROR->get_type()
              == $Text::BSV::Exception::INVALID_DATA_FORMAT,
              "Constructing a BSV file reader from a file that contains "
              . "invalid BSV data in the header row or the first "
              . "non-header row generates an exception of type "
              . "\$Text::BSV::Exception::INVALID_DATA_FORMAT");
        }
        when ("bad_backslash.bsv") {
            my $field_names = $bsv_file_reader->get_field_names();

            ok(scalar(@{ $field_names }) == 3,
              "There are three field names in ${DQ}bad_backslash.bsv${DQ}");
            ok($field_names->[0] eq "Animal",
              "The first field name in ${DQ}bad_backslash.bsv${DQ} "
              . "is ${DQ}Animal${DQ}");
            ok($field_names->[1] eq "Vegetable|Mineral",
              "The second field name in ${DQ}bad_backslash.bsv${DQ} "
              . "is ${DQ}Vegetable|Mineral${DQ}");
            ok($field_names->[2] eq "Description",
              "The third field name in ${DQ}bad_backslash.bsv${DQ} "
              . "is ${DQ}Description${DQ}");

            ok($bsv_file_reader->has_next(),
              "${DQ}bad_backslash.bsv${DQ} has a first record");

            eval {
                $bsv_file_reader->get_record();
            };

            ok(! $EVAL_ERROR,
              "The first record in ${DQ}bad_backslash.bsv${DQ} does not "
              . "generate an exception");

            ok($bsv_file_reader->has_next(),
              "${DQ}bad_backslash.bsv${DQ} has a second record");

            eval {
                $bsv_file_reader->get_record();
            };

            ok($EVAL_ERROR && $EVAL_ERROR->get_type()
              == $Text::BSV::Exception::INVALID_DATA_FORMAT,
              "The second record in ${DQ}bad_backslash.bsv${DQ} generates "
              . "an exception of type "
              . "\$Text::BSV::Exception::INVALID_DATA_FORMAT");
        }
        when ("wombats.bsv") {
            my $field_names;
            my @records;

            if ($EVAL_ERROR) {
                say STDERR $EVAL_ERROR->get_message();
            } # end if

            ok(! $EVAL_ERROR,
              "Successfully constructed a BSV file reader from "
              . "${DQ}wombats.bsv${DQ}");

            $field_names = $bsv_file_reader->get_field_names();

            # Make sure that there are the expected number of true values
            # for has_next(), test the BSV file writer using data generated
            # from "wombats.bsv", and then compare the new file with the
            # original file:
            while ($bsv_file_reader->has_next()) {
                my $record;

                eval {
                    $record = $bsv_file_reader->get_record();
                };

                ok(! $EVAL_ERROR,
                  "The record just obtained from ${DQ}wombats.bsv${DQ} "
                  . "does not generate an exception");

                push @records, $record;
            } # end while

            ok(scalar(@records) == 2,
              "${DQ}wombats.bsv${DQ} produces two records");

            eval {
                $bsv_writer = Text::BSV::BsvWriter->new(
                  $field_names, \@records);
            };

            ok(! $EVAL_ERROR,
              "Constructing a BSV file writer with valid arguments "
              . "does not generate an exception");

            eval {
                $bsv_writer->write_to_file("wombats_copy.bsv");
            };

            ok(! $EVAL_ERROR,
              "Writing BSV data to ${DQ}wombats_copy.bsv${DQ} does not "
              . "generate an exception");
            ok(compare_text("wombats.bsv", "wombats_copy.bsv") == 0,
              "The copy of ${DQ}wombats.bsv${DQ} is textually equavalent "
              . "to the original");
        }
        when ("fake_stock.csv") {
            my $field_names;
            my $first_record;

            if ($EVAL_ERROR) {
                say STDERR $EVAL_ERROR->get_message();
            } # end if

            ok(! $EVAL_ERROR,
              "Successfully constructed a BSV file reader from "
              . "${DQ}fake_stock.csv${DQ}");

            $field_names = $bsv_file_reader->get_field_names();

            ok(scalar(@{ $field_names }) == 6,
              "There are six field names in ${DQ}fake_stock.csv${DQ}");
            ok($field_names->[0] eq "Date",
              "The first field name in ${DQ}fake_stock.csv${DQ} "
              . "is ${DQ}Date${DQ}");
            ok($bsv_file_reader->has_next(),
              "${DQ}fake_stock.csv${DQ} has a first record");

            eval {
                $first_record = $bsv_file_reader->get_record();
            };

            ok (! $EVAL_ERROR,
              "The first record in ${DQ}fake_stock.csv${DQ} does not "
              . "generate an exception");
            ok($first_record->{$field_names->[0]} =~ /\A\d{8}\z/s,
              "The first value in the first record in "
              . "${DQ}fake_stock.csv${DQ} looks like a date");
        } # end when
    } # end given

    if (defined $bsv_file_reader) {
        $bsv_file_reader->close();
    } # end if

    # Tests for Text::BSV::BsvListReader:
    my @lines;

    next if $file_path eq "nonexistent_file.bsv";

    if (open my $BSV_FILE, "<:utf8", $file_path) {
        ok($TRUE, "Successfully opened $DQ$file_path$DQ for reading");
        @lines = <$BSV_FILE>;

        for my $line (@lines) {
            chomp $line;
            $line =~ s/\r//gs;
        } # next $line

        close $BSV_FILE;
    }
    else {
        exit(1);
    } # end if

    eval {
        $bsv_list_reader = Text::BSV::BsvListReader->new(\@lines);
    };

    given ($file_path) {
        when (/\A(?:(?:ambiguous|wombats)\.csv|no_records\.bsv)\z/s) {
            ok($EVAL_ERROR && $EVAL_ERROR->get_type()
              == $Text::BSV::Exception::INVALID_DATA_FORMAT,
              "Constructing a BSV list reader from lines that contain "
              . "invalid BSV data in the header row or the first "
              . "non-header row generates an exception of type "
              . "\$Text::BSV::Exception::INVALID_DATA_FORMAT");
        }
        when ("bad_backslash.bsv") {
            ok($EVAL_ERROR && $EVAL_ERROR->get_type()
              == $Text::BSV::Exception::INVALID_DATA_FORMAT,
              "Constructing a BSV list reader from BSV lines that contain "
              . "invalid backslash usage generates an exception of type "
              . "\$Text::BSV::Exception::INVALID_DATA_FORMAT");
        }
        when ("wombats.bsv") {
            my $field_names;
            my $records;

            if ($EVAL_ERROR) {
                say STDERR $EVAL_ERROR->get_message();
            } # end if

            ok(! $EVAL_ERROR,
              "Successfully constructed a BSV list reader from the lines "
              . "in ${DQ}wombats.bsv${DQ}");

            $field_names = $bsv_list_reader->get_field_names();
            $records = $bsv_list_reader->get_records();

            # Verify the number of fields and records, and check the second
            # field name as well as the third value in each record:
            ok(scalar(@{ $field_names }) == 3,
              "${DQ}wombats.bsv${DQ} contains three fields");
            ok(scalar(@{ $records }) == 2,
              "${DQ}wombats.bsv${DQ} contains two records");
            ok($field_names->[1] eq "Vegetable|Mineral",
              "The second field name in ${DQ}wombats.bsv${DQ} "
              . "is ${DQ}Vegetable|Mineral${DQ}");
            ok($records->[0]->{"Description"} =~ /\ACute and\r?\nfurry\z/s,
              "The third value in the first record in "
              . "${DQ}wombats.bsv${DQ} is correct");
            ok($records->[1]->{"Description"} eq "C:\\Delicious",
              "The third value in the second record in "
              . "${DQ}wombats.bsv${DQ} is correct");
        }
        when ("fake_stock.csv") {
            my $field_names;
            my $records;

            if ($EVAL_ERROR) {
                say STDERR $EVAL_ERROR->get_message();
            } # end if

            ok(! $EVAL_ERROR,
              "Successfully constructed a BSV list reader from the lines "
              . "in ${DQ}fake_stock.csv${DQ}");

            $field_names = $bsv_list_reader->get_field_names();

            ok(scalar(@{ $field_names }) == 6,
              "There are six field names in ${DQ}fake_stock.csv${DQ}");
            ok($field_names->[0] eq "Date",
              "The first field name in ${DQ}fake_stock.csv${DQ} "
              . "is ${DQ}Date${DQ}");

            eval {
                $records = $bsv_list_reader->get_records();
            };

            if ($EVAL_ERROR) {
                say STDERR $EVAL_ERROR->get_message();
            } # end if

            ok (! $EVAL_ERROR,
              "The records in ${DQ}fake_stock.csv${DQ} do not generate "
              . "an exception");
            ok (scalar(@{ $records }) == 660,
              "${DQ}fake_stock.csv${DQ} produces 660 records");
        } # end when
    } # end given
} # next $file_path

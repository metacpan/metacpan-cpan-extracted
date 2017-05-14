# $Id$
$VERSION{''.__FILE__} = '$Revision$';
#
# >>Title::     Table Processing Library
#
# >>Copyright::
# Copyright (c) 1992-1996, Ian Clatworthy (ianc@mincom.com).
# You may distribute under the terms specified in the LICENSE file.
#
# >>History::
# -----------------------------------------------------------------------
# Date      Who     Change
# 29-Feb-96 ianc    SDF 2.000
# -----------------------------------------------------------------------
#
# >>Purpose::
# This library provides routines for reading, processing and
# writing {{FMT:TBL}} files.
#
# >>Description::
# Tables are stored in arrays.
# The first element in the array is the {{input format specification}}.
# Remaining elements are data, one record per element.
#
# The routines are often used together as follows:
#
# !block verbatim
#      # Read in the table (using the default format)
#      ($ok, @table) = &TableFetch($table_name);
# 
#      # Process the data records
#      $format = shift @table;
#      @flds = &TableFields($format);
#      for $rec (@table) {
#              %value = &TableRecSplit(*flds, $rec);
#              $value{'Age'}++;        # say ...
#              $rec = &TableRecJoin(*flds, %value);
#      }
#      unshift(@table, $format);
# 
#      # Ouptut the new table (using the default flags)
#      &TablePrint(STDOUT, *table);
# !endblock
#
# Note: Multi-line fields are stored with a newline as the first character
# so be sure to allow for this when processing them.
#
# >>Limitations::
# When validating field-names, the line number and context should be
# set to something meaningful. To achieve this, the line number of
# the format string in the file (if it's in the file, that is!) needs
# to be saved as part of the table.
#
# >>Resources::
#
# >>Implementation::
#

require "sdf/misc.pl";

######### Constants #########

# Tab size used in expanding fixed-width TBL data
$_TABLE_TAB_SIZE = 8;

#
# >>Description::
# {{Y:TABLE_MODEL_MODEL}} is the model for model files.
#
@TABLE_MODEL_MODEL = &TableParse (
    'Field,Category,Rule,AuxRule',
    'Field,key,<\w+>',
    'Category,mandatory,<key|partkey|mandatory|expected|optional|routine>',
    'Rule,optional',
    'AuxRule,optional',
    '_ENTRY_,routine,-,&_TableValRules("ENTRY")',
    '_RECORD_,routine,-,&_TableValRules("RECORD")',
    '_EXIT_,routine ,-,&_TableValRules("EXIT")',
);

# These are the tables of custom read/write routines indexed on type
%_TABLE_CUSTOM_READ = (
);
%_TABLE_CUSTOM_WRITE = (
);

######### Variables #########

# Counter used to ensure {{Y:TableFetch}} is re-entrant
$_table_cnt = 0;

# Counters used by TableValRules()
$_table_keys = 0;
$_table_partkeys = 0;

######### Routines #########

#
# >>Description::
# {{Y:TableFetch}} reads {{file}} as a table defined in {{TBL}} format.
# If the first data line of the file is not an input format specification,
# it can be specified using {{format}}.
# {{success}} is 1 if the file is opened successfully.
# {{records}} is an array of records,
# the first of which is the format specification.
#
sub TableFetch {
    local($file, $format) = @_;
    local($success, @records);
    local($strm);

    # Open the file (ensuring stream_id is unique)
    $strm = sprintf("tbl_s%d", $_table_cnt++);
    open($strm, $file) || return (0);

    # Input the records
    @records = &TableParse($format, <$strm>);

    # close the output
    close($strm);

    # return results
    return (1, @records);
}

#
# >>Description::
# {{Y:TableParse}} converts a list of strings into a table.
#
sub TableParse {
    local(@strings) = @_;
    local(@records);

    # Read in the data
    &_TableReadText(*strings, *records);

    # Return result
    return @records;
}

#
# >>Description::
# {{Y:TableValidate}} validates {{@table}} against {{@rules}}.
#
sub TableValidate {
    local(*table, *rules) = @_;
#   local();
    local($i);
    local(@partkeys, $rulesep, @ruleflds, %rule);
    local($fld, %fldcat, %fldrule, %fldauxrule);
    local(@flds, %keylist);

    # Build the validation lookup tables
    @partkeys = ();
    @ruleflds = &TableFields($rules[0]);
    for ($i = 1; $i <= $#rules; $i++) {
        %rule = &TableRecSplit(*ruleflds, $rules[$i]);
        $fld = $rule{"Field"};
        $fldcat{$fld} = $rule{"Category"};
        push(@partkeys, $fld) if $fldcat{$fld} eq 'partkey';
        $fldrule{$fld} = $rule{"Rule"};
        $fldrule{$fld} =~ s#^\<(.*)\>$#/^($1)\$/#;
        $fldauxrule{$fld} = $rule{"AuxRule"};
        $fldauxrule{$fld} =~ s#^\<(.*)\>$#/^($1)\$/#;
    }

    # Check the data
    @flds = &TableFieldsCheck($table[0], "error", %fldcat);
    &MiscDoAction($fldauxrule{"_ENTRY_"}, "_ENTRY_ routine");
    %keylist = ();
    for ($i = 1; $i <= $#table; $i++) {
        next if $table[$i] =~ /^!/;
        &_TableRecordCheck($table[$i], *flds,
          *fldcat, *fldrule, *fldauxrule, *keylist, @partkeys);
    }
    &MiscDoAction($fldauxrule{"_EXIT_"}, "_EXIT_ routine");
}

#
# >>Description::
# {{Y:TablePrint}} outputs {{@table}} to {{strm}}.
# The {{flags}} supported are outlined below.
#
# !block table
# Flag        Description
# TBL format:
# behead      column headings are not included at the top of the output
# delimited   use delimited format - delimiter is the argument (default is tab)
# !endblock
#
sub TablePrint {
    local($strm, *table, %flags) = @_;
#   local();
    local($format, $i);

    # Get the format and output it, unless explicitly asked not to
    $format = $table[0];
    if ($format eq '' || $format =~ /^\w/) {
        &_TableWriteText(*table, $strm, '', %flags);
    }
    else {
        &_TableWriteCustom(*table, $strm, '', %flags);
    }
}

#
# >>Description::
# {{Y:TableFormat}} formats {{@table}} using {{flags}} and
# returns a set of strings. See {{Y:TablePrint}} for a list
# of the flags supported.
#
sub TableFormat {
    local(*table, %flags) = @_;
    local(@strings);

    &_TableWriteText(*table, '', *strings, %flags);

    # Return results
    return @strings;
}

#
# >>Description::
# {{Y:TableFields}} returns the list of fields in {{format}}.
# Behaviour for custom formats is currently undefined.
#
sub TableFields {
    local($format) = @_;
    local(@fields);
    local($sep);

    ($sep, @fields) = &_TableFormatSplit($format);
    return @fields;
}

#
# >>_Description::
# {{Y:_TableFormatSplit}} converts a format string into a separator
# and a list of fields.
#
sub _TableFormatSplit {
    local($format) = @_;
    local($sep, @fields);
    local($sep_regexp);

    # Trim leading whitespace
    $format =~ s/^\s+//;

    # find the field separator
    ($sep) = $format =~ /(\W)/;

    # for custom formats, handling is currently undecided
    if ($format !~ /^\w/) {
        &AppMsg("failure", "TableFields() does not support custom formats yet");
    }

    # for single column tables, the field is the format
    elsif ($sep eq '') {
        @fields = ($format);
    }

    # for fixed-width fields, split on whitespace
    elsif ($sep =~ /\s/) {
        @fields = split(/\s+/, $format);
    }

    # for delimited fields, split on the delimiter
    else {
        # escape any regular expression characters
        $sep_regexp = $sep;
        $sep_regexp =~ s/(\W)/\\$1/g;
        @fields = split(/$sep_regexp/, $format);
    }

    # return results
    return ($sep, @fields);
}

#
# >>_Description::
# {{Y:_TableFormatJoin}} converts a separator and a list of fields
# into a format string.
#
sub _TableFormatJoin {
    local($sep, @fields) = @_;
    local($format);

    # return results
    return join($sep, @fields);
}

#
# >>Description::
# {{Y:TableRecSplit}} converts a record into a set of name-value pairs
# using a set of fields (typically returned from {{Y:TableFields}}).
#
sub TableRecSplit {
    local(*fields, $record) = @_;
    local(%values);

    # store the field values into an associative array, after
    # splitting the record into an (ordinary) array of field values,
    # remembering that the .line pseudo-field always exists
    @values{".line", @fields} = split(/\000/, $record, scalar(@fields) + 1);

    # return results
    %values;
}

#
# >>Description::
# {{Y:TableRecJoin}} converts a set of name-value pairs into a record
# using a set of fields (typically returned from {{Y:TableFields}}).
#
sub TableRecJoin {
    local(*fields, %values) = @_;
    local($record);

    # return results
    return join("\000", @values{".line", @fields});
}

#
# >>Description::
# {{Y:TableRecFormat}} formats a set of name-value pairs into a string
# using a format string.
# Behaviour for custom formats is currently undefined.
#
sub TableRecFormat {
    local($format, %values) = @_;
    local($string);
    local(@values, @fields, $sep, $packfmt);

    # Get the format-related stuff
    @fields = &TableFields($format);
    ($sep) = $format =~ /(\W)/;
    if ($sep =~ /^\s/) {
        $packfmt = &_TablePackStr($format);
    }

    # Get the list of values
    @values = @values{@fields};

    # return results
    return &_TableFmtText(*values, *fields, $sep, $packfmt);
}

#
# >>Description::
# {{Y:TableFilter}} filters a table using an expression.
#
sub TableFilter {
    local(*table, $where, *var) = @_;
    local(@result);
    local($format, @data);
    local(@fields);
    local($_, %o);

    # Split the table into its components
    ($format, @data) = @table;
    @fields = &TableFields($format);

    # Filter the data
    @result = ($format);
    for $_ (@data) {
        next if /^\!/;
        %o = &TableRecSplit(*fields, $_);
        push(@result, $_) if eval $where;
        if ($@) {
            &AppMsg("warning", "table filter '$where' failed: $@");
        }
    }

    # Return result
    return @result;
}

#
# >>Description::
# {{Y:TableDeleteFields}} deletes a list of fields from a table.
#
sub TableDeleteFields {
    local(*table, @junk) = @_;
    local(@result);
    local($format, @data);
    local(%junk);
    local($sep, @fields, @new_fields);
    local($_, %o);

    # Split the table into its components
    ($format, @data) = @table;
    ($sep, @fields) = &_TableFormatSplit($format);

    # Build the new format
    grep($junk{$_}++, @junk);
    @new_fields = ();
    for $_ (@fields) {
        push(@new_fields, $_) unless $junk{$_};
    }
    $format = &_TableFormatJoin($sep, @new_fields);

    # Build the new data records
    @result = ($format);
    for $_ (@data) {
        next if /^\!/;
        %o = &TableRecSplit(*fields, $_);
        push(@result, &TableRecJoin(*new_fields, %o));
    }

    # Return result
    return @result;
}

#
# >>Description::
# {{Y:TableSelectFields}} selects a list of fields from a table.
#
sub TableSelectFields {
    local(*table, @new_fields) = @_;
    local(@result);
    local($format, @data);
    local($sep, @fields);
    local($_, %o);

    # Split the table into its components
    ($format, @data) = @table;
    ($sep, @fields) = &_TableFormatSplit($format);

    # Build the new format
    $format = &_TableFormatJoin($sep, @new_fields);

    # Build the new data records
    @result = ($format);
    for $_ (@data) {
        next if /^\!/;
        %o = &TableRecSplit(*fields, $_);
        push(@result, &TableRecJoin(*new_fields, %o));
    }

    # Return result
    return @result;
}

#
# >>Description::
# {{Y:TableSort}} sorts a table by one of more fields.
# The fields to use are passed in {{by}}.
# If no fields are specified, all fields are used in the order
# they appear in the table.
#
sub TableSort {
    local(*table, @by) = @_;
    local(@result);
    local($format, @data);
    local(@fields);

    # Split the table into its components
    ($format, @data) = @table;
    @fields = &TableFields($format);

    # Sort the data
    if (@by && $by[0] ne '-') {
        @data = sort _TableSortFn @data;

    }
    else {
        @data = sort @data;
    }

    # Return result
    return ($format, @data);
}

#
# >>_Description::
# {{Y:_TableSortFn}} is used by {{Y:TableSort}} as the sorting function.
# This routine compares two records ($a and $b) and return -1, 0 or 1
# depending on whether the first record is greater than, equal to or
# less than the second record respectively.
# {{@by}}, {{$sep}} and {{@fields}} are dynamically scoped within
# {{Y:TableSort}} and are used by this routine.
#
sub _TableSortFn {
    local(%data1, %data2);
    %data1 = &TableRecSplit(*fields, $a);
    %data2 = &TableRecSplit(*fields, $b);
    return join("\000", @data1{@by}) cmp join("\000", @data2{@by});
}

#
# >>Description::
# {{Y:TableIndex}} indexes a table by one of more fields.
# The fields to use are passed in {{by}}.
# If no fields are specified, all fields are used in the order
# they appear in the table. {{index}} is an associative array where:
#
# * the key is the value of the {{by}} fields
# * the data is the index in {{table}} of the matching record
#
# For multiple-field keys, values are separated by a null character (\000).
# The index of the first data record is 1 (the field specification
# record has an index of 0).
# {{@duplicates}} is the list of indices which do not appear in {{%index}}.
# If duplicate keys are found, the highest index is stored in {{%index}}
# for each key.
#
sub TableIndex {
    local(*table, *duplicates, @by) = @_;
    local(%index);
    local(@fields, %values);
    local($index);

    # Get the fields
    @fields = &TableFields($table[0]);

    # Use all fields if none specified
    @by = @fields unless @by;

    # Build the index
    @duplicates = ();
    for ($index = 1; $index <= $#table; $index++) {
        %values = &TableRecSplit(*fields, $table[$index]);
        $key = join("\000", @values{@by});
        if ($index{$key}) {
            push(@duplicates, $index{$key});
        }
        $index{$key} = $index;
    }

    # Return result
    return %index;
}

#
# >>Description::
# {{Y:TableLookup}} returns the name-value pairs for a given key.
# {{@table}} is the data table. {{%index}} is an index created
# using {{Y:TableIndex}}. An empty associative array is returned
# if no matching record is found.
#
sub TableLookup {
    local(*table, *index, @key_values) = @_;
    local(%values);
    local(@fields);
    local($idx);

    $idx = $index{join("\000", @key_values)};
    if ($idx) {
        @fields = &TableFields($table[0]);
        %values = &TableRecSplit(*fields, $table[$idx]);
    }

    # Return result
    return %values;
}

#
# >>Description::
# {{Y:TableFieldsCheck}} is a wrapper around {{Y:TableFields}}
# which checks that the fields contains no duplicates. If {{known}} is
# defined, its keys are used to find unknown fields, if any.
# Any errors encountered are output as such using {{Y:AppMsg}}.
# {{msg_type}} can be used to control the message type - {{error}}
# is the default.
#
sub TableFieldsCheck {
    local($format, $msg_type, %known) = @_;
    local(@flds);
    local(%fldcnt, $fld);
    local(@unknown);

    # The default message type is error
    $msg_type = "error" unless $msg_type;

    # Check that each field only exists once
    %fldcnt = ();
    @flds = &TableFields($format);
    for $fld (@flds) {
        if ($fldcnt{$fld}++) {
            &AppMsg($msg_type, "field '$fld' is duplicated");
        }
    }

    # Check for unknown fields
    if (%known) {
        @unknown = grep(!$known{$_}, @flds);
        if (@unknown) {
            &AppMsg($msg_type, sprintf("unknown field(s): %s",
              join(", ", @unknown)));
        }
    }

    # Return result
    return @flds;
}

#
# >>_Description::
# {{Y:_TableValRules}} is used by {{Y:TABLE_MODEL_MODEL}} to check
# table-wide semantics for validation files. The rules are:
#
# * a key of some form is expected
# * a single partkey is an error
#
# Note that this logic is not directly embedded within
# {{Y:TABLE_MODEL_MODEL}} as doing so greatly reduces readability.
#
sub _TableValRules {
    local($state) = @_;
#       local();

    if ($state eq 'ENTRY') {
        $_table_keys = 0;
        $_table_partkeys = 0;
    }
    elsif ($state eq 'RECORD') {
        $_table_keys++     if $o{"Category"} eq "key";
        $_table_partkeys++ if $o{"Category"} eq "partkey";
    }
    elsif ($state eq 'EXIT') {
        if ($_table_partkeys == 0) {
            &AppMsg("warning", "no keys defined") unless $_table_keys;
        }
        elsif ($_table_partkeys == 1) {
            &AppMsg("error", "bad key definition - only 1 'partkey' field");
        }
    }
    else {
        &AppExit("failure", "unknown state '$state' in _TableValRules()");
    }
}

#
# >>_Description::
# {{Y:_TableRecordCheck}} validates a table record ({{record}})
# against the validation rules defined by {{%fldcat}}, {{%fldrule}}
# and {{%fldauxrule}}. These lookup tables are indexed on field name.
# {{@flds}} is the list of fields in the table.
# {{%keylist}} is an associative array which this routine
# needs for key checking. i.e. checking keys in this record are unique
# and storing the key values from this record for checking by subsequent
# calls. Before this routine is called for the first
# record in a table, it should be cleared by the caller. {{@partkeys}}
# is the list of fields in the key.
#
sub _TableRecordCheck {
    local($record, *flds, *fldcat, *fldrule, *fldauxrule, *keylist, @partkeys) = @_;
#   local();
    local(%o, $fld, $fld_cat, $key_value);
    local($orig_lineno, $orig_context);

    # Setup message parameters
    %o = &TableRecSplit(*flds, $record);
    $orig_lineno = $app_lineno;
    $orig_context = $app_context;
    $app_lineno = $o{'.line'};
    $app_context = 'line ';

    # Check the fields
    for $fld (@flds) {

        # Get the field value
        $_ = $o{$fld};

        # Check the category - for performance, we only check the first letter
        $fld_cat = $fldcat{$fld};
        if ($fld_cat =~ /^k/) {     # key
            $key_value = "$fld:$_";
            &AppMsg("error", "duplicate key on field '$fld', value '$_'") if
              $keylist{$key_value}++;
        }
        elsif ($fld_cat =~ /^m/) {  # mandatory
            &AppMsg("error", "field '$fld' is missing") if $_ eq '';
        }
        elsif ($fld_cat =~ /^e/) {  # expected
            &AppMsg("warning", "field '$fld' is missing") if $_ eq '';
        }
                
        # If there is a value, check the rules, if any.
        if ($_ ne '') {

            # "Rule" validation
            unless (&MiscDoAction($fldrule{$fld}, "rule")) {
                &AppMsg("error", "bad value '$_' for field '$fld'");
            }
            else {
                # "AuxRule" validation
                unless (&MiscDoAction($fldauxrule{$fld}, "rule")) {
                    &AppMsg("warning", "unexpected value '$_' for field '$fld'");
                }
            }
        }
    }

    # Check uniqueness of multi-part keys
    if (@partkeys) {
        $key_value = join("\000", ":", @o{@partkeys});
        &AppMsg("error", sprintf("duplicate key on fields (%s)",
          join(", ", @partkeys))) if $keylist{$key_value}++;
    }

    # If a 'record' rule routine is defined, do it.
    &MiscDoAction($fldauxrule{"_RECORD_"}, "_RECORD_ routine");

    # Restore the original message parameters
    $app_lineno = $orig_lineno;
    $app_context = $orig_context;
}

#
# >>_Description::
# {{Y:_TableReadText}} parses {{@strings}} as {{TBL}} format data.
# The table is returned in {{@table}}.
#
sub _TableReadText {
    local(*strings, *table) = @_;
#   local();
    local($i, $linenum, $_);
    local($format);
    local($sep);
    local($unpackfmt);
    local(@fields, $field_count, $sep_re);
    local($record, $field);

    # Preprocess text:
    # * expand tabs
    # * remove comments and blank lines
    # * convert multi-line records into a single record
    # * record line numbers (needed for meaningful validation messages)
    @table = ();
    for ($i = 0; $i <= $#strings; $i++) {
        $_ = $strings[$i];

        # Trim control-Ms (in case this file came from DOS), the newline
        # and trailing whitespace & expand tabs
        s/\r$//;
        s/\s+$//;
        1 while s/\t+/' ' x (length($&) * $_TABLE_TAB_SIZE - length($`) % $_TABLE_TAB_SIZE)/e;

        unless ($field) {

            # Skip comments and blank lines
            next if /^\s*#/ || /^$/;

            # Get the line number
            $linenum = $i + 1;

            # Lines ending in \ are continued onto the next line,
            # unless there are exactly 2 backslashes at the end of the line
            if (/[^\\]\\\\$/) {
                s/\\$//;
            }
            elsif (s/\\$//) {
                $line = $_;
                for ($i++; $i <= $#strings; $i++) {
                    $_ = $strings[$i];

                    # Trim trailing whitespace, expand tabs & trim leading
                    # whitespace
                    s/\r$//;
                    s/\s+$//;
                    1 while s/\t+/' ' x (length($&) * $_TABLE_TAB_SIZE - length($`) % $_TABLE_TAB_SIZE)/e;
                    s/^\s+//;

                    # Build the logical line
                    $last = ($_ !~ /\\$/ || /[^\\]\\\\$/);
                    s/\\$//;
                    $line .= $_;
                    last if $last;
                }
                $_ = $line;
            }

            # Copy macros into the output
            if (/^\s*\!/) {
                push(@table, $_);
                next;
            }
        }

        # get the format specification, if we haven't already
        if ($format eq '') {
            $format = $_;
            push(@table, $format);
            ($sep) = $format =~ /(\W)/;
            if ($sep =~ /\s/) {
                $unpackfmt = &_TablePackStr($format);
            }
            elsif ($sep ne '') {
                $sep_re = $sep;
                $sep_re =~ s/(\W)/\\$1/g;
                @fields = &TableFields($format);
                $field_count = scalar(@fields);
            }
            next;
        }

        # get records, including those with multi-line cells
        if ($field) {
            if (s/^\>\>//) {

                # Finalise this field
                chop($field);
                $field =~ s/$sep_re/\000/g if $sep_re;
                $record .= $field;

                if (/\<\<$/) {
                    $record .= $`;
                    $field = "\n";
                    next;
                }
                else {
                    $record .= $_;
                    $field = '';
                }
            }
            else {
                $field .= "$_\n";
                next;
            }
        }
        elsif (/\<\<$/) {
            $record = $`;
            $field = "\n";
            next;
        }
        else {
            $record = $_;
        }

        # If we reach here, the record can be saved
        push(@table, &_TableBuildRec($record, $sep, $linenum, $unpackfmt,
          $sep_re, $field_count));
    }

    # If a multi-line field was not explicitly terminated,
    # the EOF terminates it
    if ($field) {
        chop($field);
        $field =~ s/$sep_re/\000/g if $sep_re;
        $record .= $field;
        push(@table, &_TableBuildRec($record, $sep, $linenum, $unpackfmt,
          $sep_re, $field_count));
    }
}

sub _TableBuildRec {
    local($rec, $sep, $linenum, $unpackfmt, $sep_re, $field_count) = @_;
    local($result);
    local(@values);
    local($str);
    local($val);

    # Handle single field tables
    if ($sep eq '') {
        @values = ($rec);
    }

    # For fixed-width fields, trim whitespace at the end of each field
    elsif ($sep =~ /\s/) {
        @values = unpack($unpackfmt, $rec);
    }

    # For delimited fields:
    # * split on the delimiter (unless its inside double-quotes), and
    # * process double-quotes, if any
    else {
        $rec =~ s/("[^"]*")/do{$a=$1; $a=~s"$sep_re"\000"g; $a}/eg;
        @values = split(/$sep_re/, $rec, $field_count);
        for $val (@values) {
            $val =~ s/\000/$sep/g;
            if ($val =~ /^"(.*)"$/) {
                $val = $1;
                $val =~ s/""/"/g;
            }
        }
    }

    # Return result
    return join("\000", $linenum, @values);
}

#
# >>_Description::
# {{Y:_TablePackStr}} builds a Perl pack/unpack string for
# a fixed-width format specification.
#
sub _TablePackStr {
    local($format) = @_;
    local($packfmt);

    $packfmt = '';
    while ($format =~ s/\w+\s+//e) {
        $packfmt .= 'A' . length($&);
    }
    $packfmt .= 'A*';
    return $packfmt;
}

#
# >>_Description::
# {{Y:_TableReadCustom}} parses {{@strings}} as custom format data.
# {{format}} is the format specification.
# The list of data records is returned in {{@data}}.
#
sub _TableReadCustom {
    local($format, *strings, *table) = @_;
#   local();
    local($type, $spec, $fn);

    # Get the format type and specification
    @table = ();
    if ($format =~ /^\!(\w+):?/) {
        $type = $1;
        $spec = $';
        $fn = $_TABLE_CUSTOM_READ{$type};
        if ($fn) {
            eval {&$fn(*strings, *table, $type, $spec)};
            &AppExit('failed', $@) if $@;
        }
        else {
            &AppMsg("error", "unsupported custom table type '$type'");
        }
    }
    else {
        &AppMsg("error", "bad table format '$format'");
    }
}

#
# >>_Description::
# {{Y:_TableWriteText}} outputs a table into {{TBL}} format.
# If {{strm}} is true, the table is output to that stream.
# Otherwise, the strings are appended to {{@strings}}.
#
sub _TableWriteText {
    local(*table, $strm, *strings, %flags) = @_;
#       local();
    local($format);
    local(@values, @fields, $sep, $packfmt);
    local($fmtsep, $fmtsep_re);
    local($i);
    local($string);

    # Get the formatting parameters
    $format = $table[0];
    @fields = &TableFields($format);
    ($sep) = $format =~ /(\W)/;
    if ($sep eq '') {
        # do nothing
    }
    elsif ($flags{'delimited'}) {
        $fmtsep = $sep;
        $fmtsep_re = $fmtsep;
        $fmtsep_re =~ s/(\W)/\\$1/g;
        $sep = $flags{'delimited'};
        if ($sep == 1) {
            $sep = "\t";
            if ($fmtsep =~ /\s/) {
                $format =~ s/\s+/\t/g;
            }
            else {
                $format =~ s/$fmtsep_re/\t/g;
            }
        }
        else {
            $format =~ s/$fmtsep_re/$sep/g;
        }
    }
    elsif ($sep =~ /^\s/) {
        $sep = ' ';
        $packfmt = &_TablePackStr($format);
    }

    # Output the header, unless asked not to
    unless ($flags{'behead'}) {
        if ($strm) {
            print $strm $format, "\n";
        }
        else {
            push(@strings, $format);
        }
    }

    # Output the data
    for ($i = 1; $i <= $#table; $i++) {
        @values = split(/\000/, $table[$i]);
        shift(@values);         # skip the .line field
        $string = &_TableFmtText(*values, *fields, $sep, $packfmt);
        if ($strm) {
            print $strm $string, "\n";
        }
        else {
            push(@strings, $string);
        }
    }
}

#
# >>_Description::
# {{Y:_TableFmtText}} formats a text record.
# {{sep}} should be one of the following:
#
# * a space - format is fixed width columns using {{packfmt}}
# * a tab - format is tab-delimited output
# * another character - format is delimited by that character
# 
sub _TableFmtText {
    local(*values, *fields, $sep, $packfmt) = @_;
    local($string);
    local($multiline);
    local($sep_re);
    local($i);

if ($tjhdebug) {
print STDERR "1-------------------------------------------------\n";
for $igc (@values) {
print STDERR "value: $igc<\n";
}
for $igc (@fields) {
print STDERR "field: $igc<\n";
}
print STDERR "2-------------------------------------------------\n";
}

    # Get the list of values, reformatting the last if its multi-line
#       if (substr($values[$#fields], 0, 1) eq "\n") {
#               $values[$#fields] = "<<" . $values[$#fields] . "\n>>";
#               $multiline = $values[$#fields];
#       }
#       else {
#               $multiline = '';
#       }

    # handle single column tables
    if ($sep eq '') {
        $string = $values[0];
    }

    # handle fixed width format
    elsif ($sep eq ' ') {
        $string = pack($packfmt, @values);
    }

    # handle tab-delimited format (skip double quote handling)
    elsif ($sep eq "\t") {
        # remove trailing empty elements
        while (@values && $values[$#values] eq '') {
            pop(@values);
        }
        # TJH 
        for $val (@values) {
            if (substr($val,0,1) eq "\n") {
                print STDERR "\nHACK $val\n" if ($tjhdebug);
                $val = "<<" . $val . ">>";
            }
        }
        $string = join($sep, @values);
    }

    # handle delimited format
    else {
        # remove trailing empty elements
        while (@values && $values[$#values] eq '') {
            pop(@values);
        }

        # Double quote handling - enclose in double quotes if
        # the value contains double quotes or the separator
        $sep_re = $sep;
        $sep_re =~ s/(\W)/\\$1/g;
#               pop(@values) if $multiline;
        for $val (@values) {
            if (substr($val,0,1) eq "\n") {
                print STDERR "\nHACK $val\n" if ($tjhdebug);
                $val = "<<" . $val . ">>";
            } else {
                if ($val =~ s/"/""/g || $val =~ /$sep_re/) {
                    $val = '"' . $val . '"';
                }
            }
            $i++;
        }
#               push(@values, $multiline) if $multiline;
        $string = join($sep, @values);
    }

    # Return result
    return $string;
}

#
# >>_Description::
# {{Y:_TableWriteCustom}} formats a table into a custom format.
#
sub _TableWriteCustom {
    local(*table, $strm, *strings, %flags) = @_;
#       local();

    &AppMsg("failure", "TableWriteCustom() not implemented yet");
}

# package return value
1;

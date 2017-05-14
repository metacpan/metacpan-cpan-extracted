# $Id$
$VERSION{''.__FILE__} = '$Revision$';
#
# >>Title::     Dictionary Library
#
# >>Copyright::
# Copyright (c) 1992-1996, Ian Clatworthy (ianc@mincom.com).
# You may distribute under the terms specified in the LICENSE file.
#
# >>History::
# -----------------------------------------------------------------------
# Date      Who     Change
# 04-Oct-97 ianc    Fixed bug with * in reports
# 29-Feb-96 ianc    SDF 2.000
# -----------------------------------------------------------------------
#
# >>Purpose::
# This library provides support for reading and processing
# dictionaries stored in text files.
#
# >>Description::
# A dictionary is a collection of items where each item has:
#
# * a unique key
# * a description
#
# >>Limitations::
#
# >>Resources::
#
# >>Implementation::
#


##### Constants #####

#
# >>Description::
# {{Y:DICT_DFLT_REPORT}} is the default report for {{Y:DictPrint}}. It:
#
# * outputs items in the order found, separated by blank lines
# * outputs each item as:
# - key on one line
# - description on the next
#
@DICT_DFLT_REPORT = &TableParse (
    'Key    Format',
    '*      "$key\n$data\n\n"',
);

##### Variables #####

#
# >>Description::
# {{Y:dict_rest}} is the set of lines in the last file processed
# by {{Y:DictFetch}} which are not in the dictionary.
#
@dict_rest = ();

$_dict_cnt = 0;

$_dict_debug = 0;


##### Routines #####

#
# >>Description::
# {{Y:DictFetch}} inputs filename as a dictionary.
#
sub DictFetch {
    local($file, $begin, $delimiter, $end, $prefix) = @_;
    local($success);
    local($strm, $line, $key, @desc, $new_key, $rest, $ch);

    local($Buffers);
    local(@bufferlist) = 'main';    # array of buffer names
    local($get_scope) = 0;
    local($doc_scope) = 0;          # scope of doco to be extracted
    local($bufref);

    # initialise the default buffer entry
    $Buffers = new Sdfget;

    # set the scope for the documentation to be extracted
    $get_scope = $Buffers->getScope($scope);

    # Open the input stream
    $strm = sprintf("dct_s%d", $_dict_cnt++);
    open($strm, $file) || return (0, ());

    # Input the data
    @dict_rest = ();
    line:
    while (<$strm>) {

        # Handle the line prefix, if any
        $line = $_;
        if ($prefix && ! s/^$prefix//) {
            # Save away the previous record, if any.
	    if ($key) {
		print STDERR "Key: $key - Text: @desc...\n" if $_dict_debug;
		$Buffers->addText ($key, \@desc, @bufferlist);
		$key = "";
		@desc = ();
	    }
            push(@dict_rest, $line);
            next line;
        }

        # Check for end line. Note that this test must be before
        # the "check for begin line", so that things work as expected.
        # (Thanks to Keith Ponting for fixing this.)
        if (/^$end/) {

            # Save away the previous record, if any.
            if ($key) {
		print STDERR "Key: $key - Text: @desc...\n" if $_dict_debug;
		$Buffers->addText($key, \@desc, @bufferlist);
                $key = "";
                @desc = ();
            }
        }

        # process possible `sdfget' directives
        if ( /^$begin!use .*$/ ) {
	    print STDERR "In use...line: $line\n" if $_dict_debug;

	    ($doc_scope, @bufferlist) = &Sdfget::UseArgs($line);
	    
	    while ($doc_scope > $get_scope ) {
		# terminate processing of there is no more input
		last line if ! $doc_scope;

		# consume the rest of this section
		($doc_scope, @bufferlist) = $Buffers->NextSection ($strm);
	    }
	    next line;
	}		

        # Check for begin line
        elsif (/^$begin(.+)$delimiter(.*)$/) {
            $new_key = $1;
            $rest = $2;
	    print STDERR "Key: $key - Text: @desc...\n" if $key && $_dict_debug;

            # Save away the previous record, if any.
	    $Buffers->addText($key, \@desc, @bufferlist) if $key;

            # Check for description on same line
            if ($rest) {
                # Save away the new record
		@desc = ($rest);
		print STDERR "Key: $new_key - Text: @desc...\n" if $_dict_debug;
		$Buffers->addText($new_key, \@desc, @bufferlist);
                $key = "";
                @desc = ();
            }
            else {
                $key = $new_key;
                @desc = ();
            }
        }

        # Check for description line
        elsif ($key) {
            push(@desc, $_);
        }

        # Otherwise, not part of dictionary
        else {
            push(@dict_rest, $line);
        }
    }
    close($strm);

    # Save away the previous record, if any.
    if ($key) {
	print STDERR "Key: $key - Text: @desc...\n" if $_dict_debug;
	$Buffers->addText($key, \@desc, \@bufferlist);
    }

    # trim the trailing new-line on each description
    $Buffers->TrimDesc();

    # return results
    return (1, $Buffers);
}

#
# >>Description::
# {{Y:DictPrint}} outputs a dictionary using report. If no
# report is specified, {{Y:DICT_DFLT_REPORT}} is used.
#
sub DictPrint {
    local($strm, $level, $buffer_name, $bufref, @report) = @_;
    local($ok);
    local(@item, $itemarrayref, %item, $itemhashref);
    local(@rep_field, %val, @local_report);
    local($key, $fmt, $err);
    local($dict_ref, $dict_hash, $dict_keys);
    local($alt_buffer);

    # Init things
    ($itemarrayref, $itemhashref) = $bufref->Sdfget::getKeysDocs($buffer_name);
    @item = @$itemarrayref;
    %item = %$itemhashref;
    @report = @DICT_DFLT_REPORT unless @report;
    @my_report = @report;

    # Check report table has required fields
    @rep_field = &TableFields(shift(@my_report));
    return 0 unless grep(/^Key$/, @rep_field);
    return 0 unless grep(/^Format$/, @rep_field);

    # Output report
    for $report (@my_report) {
        %val = &TableRecSplit(*rep_field, $report);
        $key = $val{'Key'};
        $fmt = $val{'Format'};

        # Handle 'all remaining'
        if ($key eq '*') {
            for $item (@item) {
                if (defined $item{$item}) {
                    $err += &_DictItemFmt($strm, $fmt, $item,
                      $item{$item});
                }
            }
        }

        # Handle free text
        elsif ($key eq '-') {
            $err += &_DictItemFmt($strm, $fmt);
        }
	elsif ($key =~ /\+.*/ && ! $level) {
	    $key =~ /\+(.*)/;
	    if ($1 eq '*') {
		foreach $alt_buffer (keys %$bufref){
		    next if ( $alt_buffer eq 'main');
		    print $strm "# Buffer: $alt_buffer\n";
		    print $strm "!slide_down\n";
		    &DictPrint($strm, ++$level, $alt_buffer, $bufref, @report);
		    print $strm "!slide_up\n";
		}
	    }
	    else {
		print $strm "!slide_down\n";
		print $strm "Buffer: $alt_buffer\n";
		&DictPrint($strm, ++$level, $1, $bufref, @report);
		print $strm "!slide_up\n";
	    }
	}

        # Handle this item
        else {
            if ($fmt && $item{$key}) {
                $err += &_DictItemFmt($strm, $fmt, $key,
                  $item{$key});
            }
            delete $item{$key};
        }
    }

    # Return result
    return $err == 0;
}

#
# >>_Description::
# {{Y:_DictItemFmt}} formats and prints an item on a stream.
# {{$fmt}} is a Perl string to be evaluated.
# {{$key}} and {{$data}} are the key and description of the item.
# {{$ARGV}} is assumed to be the current file.
#
sub _DictItemFmt {
    local($strm, $fmt, $key, $data) = @_;
    local($err);
    local($str);
    local($dir, $base, $ext, $short);

    # Get file info
    ($dir, $base, $ext, $short) = &NameSplit($ARGV);

    # Print item
    $str = eval $fmt;
    if ($@) {
        &AppMsg('error', $@);
        return 1;
    }
    print $strm $str;

    # Return result
    return 0;
}

# package return value
1;
